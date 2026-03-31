#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Pursuit Platform Sync (returning users)
# Usage: pursuit-sync
#    or: pursuit-sync --refresh-env --passphrase "YOUR_PASSPHRASE"
#    or: pursuit-sync --rebase
# ============================================================================

WORKSPACE="$HOME/Documents/pursuit"
ONBOARDING_REPO="cgodoy720/platform-onboarding"
BRANCH="dev"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Parse arguments
REFRESH_ENV=false
REBASE=false
PASSPHRASE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --refresh-env) REFRESH_ENV=true; shift ;;
    --rebase) REBASE=true; shift ;;
    --passphrase) PASSPHRASE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# Check workspace exists
if [[ ! -d "$WORKSPACE/test-pilot-server" ]] || [[ ! -d "$WORKSPACE/pilot-client" ]]; then
  echo -e "${RED}Workspace not found at $WORKSPACE${NC}"
  echo "Run the setup script first."
  exit 1
fi

echo -e "${BLUE}Syncing Pursuit workspace...${NC}"
echo ""

for REPO_NAME in test-pilot-server pilot-client; do
  DIR="$WORKSPACE/$REPO_NAME"
  cd "$DIR"
  CURRENT_BRANCH=$(git branch --show-current)

  echo -e "${BLUE}[$REPO_NAME]${NC}"

  # Stash uncommitted work
  STASHED=false
  if [[ -n "$(git status --porcelain)" ]]; then
    git stash push -m "pursuit-sync auto-stash $(date +%Y%m%d-%H%M%S)"
    STASHED=true
    echo -e "  ${YELLOW}Stashed uncommitted changes${NC}"
  fi

  # Pull latest dev from upstream
  git fetch upstream "$BRANCH"
  git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH" "upstream/$BRANCH"
  git pull upstream "$BRANCH" --ff-only
  echo -e "  ${GREEN}✓${NC} Pulled latest $BRANCH"

  # Show what changed
  COMMITS=$(git log --oneline -3)
  echo -e "  Latest commits:"
  echo "$COMMITS" | while read -r line; do echo "    $line"; done

  # Rebase feature branch if requested
  if $REBASE && [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
    git checkout "$CURRENT_BRANCH"
    if git rebase "$BRANCH"; then
      echo -e "  ${GREEN}✓${NC} Rebased $CURRENT_BRANCH on $BRANCH"
    else
      echo -e "  ${RED}Rebase conflict! Resolve manually, then: git rebase --continue${NC}"
      git rebase --abort
    fi
  fi

  # Smart npm install (only if package-lock.json changed)
  if git diff HEAD@{1} --name-only 2>/dev/null | grep -q 'package-lock.json'; then
    echo -e "  ${BLUE}●${NC} Dependencies changed, running npm install..."
    npm install
    echo -e "  ${GREEN}✓${NC} Dependencies updated"
  fi

  # Pop stash
  if $STASHED; then
    if git stash pop 2>/dev/null; then
      echo -e "  ${GREEN}✓${NC} Restored stashed changes"
    else
      echo -e "  ${YELLOW}Stash conflict — your changes are in 'git stash list'${NC}"
    fi
  fi

  echo ""
done

# Refresh env if requested
if $REFRESH_ENV; then
  if [[ -z "$PASSPHRASE" ]]; then
    echo -e "${RED}--refresh-env requires --passphrase${NC}"
    exit 1
  fi
  ONBOARDING_DIR=$(mktemp -d)
  git clone --depth 1 "https://github.com/$ONBOARDING_REPO.git" "$ONBOARDING_DIR" 2>/dev/null
  DECRYPTED=$(mktemp)
  gpg --quiet --batch --yes --passphrase "$PASSPHRASE" --output "$DECRYPTED" --decrypt "$ONBOARDING_DIR/env.secrets.gpg"
  sed '/^ADMIN_GITHUB_TOKEN=/d; /^# /d' "$DECRYPTED" | sed '/^$/N;/^\n$/d' > "$WORKSPACE/test-pilot-server/.env"
  cat > "$WORKSPACE/pilot-client/.env" <<EOF
VITE_API_URL=http://localhost:7001
EOF
  rm -f "$DECRYPTED"
  rm -rf "$ONBOARDING_DIR"
  echo -e "${GREEN}✓${NC} Environment variables refreshed"
fi

echo -e "${GREEN}Sync complete!${NC}"
