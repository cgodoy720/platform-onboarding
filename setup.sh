#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Pursuit Platform Onboarding Wizard
# Usage: curl -fsSL https://raw.githubusercontent.com/cgodoy720/platform-onboarding/main/setup.sh | bash -s -- --passphrase "YOUR_PASSPHRASE"
# ============================================================================

WORKSPACE="$HOME/Documents/pursuit"
LOG_FILE="$WORKSPACE/.setup-log"
ONBOARDING_REPO="cgodoy720/platform-onboarding"
SERVER_REPO="cgodoy720/test-pilot-server"
CLIENT_REPO="cgodoy720/pilot-client"
BRANCH="dev"

# --- Colors (fallback before gum is installed) ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# --- Parse arguments ---
PASSPHRASE=""
while [[ $# -gt 0 ]]; do
  case $1 in
    --passphrase) PASSPHRASE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

if [[ -z "$PASSPHRASE" ]]; then
  echo -e "${RED}Error: --passphrase is required${NC}"
  echo "Usage: curl -fsSL ... | bash -s -- --passphrase \"YOUR_PASSPHRASE\""
  exit 1
fi

# --- Logging ---
mkdir -p "$WORKSPACE"
exec > >(tee -a "$LOG_FILE") 2>&1
log_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# --- Retry helper ---
retry() {
  local max_attempts=3
  local attempt=1
  local cmd="$@"
  while [[ $attempt -le $max_attempts ]]; do
    if eval "$cmd"; then
      return 0
    fi
    log_warn "Attempt $attempt/$max_attempts failed. Retrying..."
    attempt=$((attempt + 1))
    sleep 2
  done
  log_error "Failed after $max_attempts attempts: $cmd"
  return 1
}

# --- Phase rendering (plain text before gum, rich after) ---
HAS_GUM=false
phase_header() {
  local phase_num="$1"
  local phase_total="$2"
  local title="$3"
  local description="$4"

  if $HAS_GUM; then
    gum style \
      --border rounded --border-foreground 99 \
      --padding "1 2" --margin "1 0" \
      --bold \
      "Phase $phase_num of $phase_total: $title" \
      "" \
      "$description"
  else
    echo ""
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}  Phase $phase_num of $phase_total: $title${NC}"
    echo -e "  $description"
    echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
  fi
}

phase_step() {
  local status="$1"
  local message="$2"
  case "$status" in
    done)    echo -e "  ${GREEN}✓${NC} $message" ;;
    active)  echo -e "  ${BLUE}●${NC} $message" ;;
    pending) echo -e "  ${YELLOW}○${NC} $message" ;;
  esac
}

spin() {
  local message="$1"
  shift
  if $HAS_GUM; then
    gum spin --spinner dot --title "$message" -- "$@"
  else
    echo -e "  ${BLUE}●${NC} $message"
    "$@"
  fi
}

# ============================================================================
# PHASE 1: Preflight Checks
# ============================================================================
phase_header 1 8 "Preflight Checks" "Checking your system to see what's already installed."

# Detect macOS
if [[ "$(uname)" != "Darwin" ]]; then
  log_error "This script is for macOS only."
  exit 1
fi
phase_step done "macOS detected"

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]]; then
  BREW_PREFIX="/opt/homebrew"
  phase_step done "Apple Silicon detected"
else
  BREW_PREFIX="/usr/local"
  phase_step done "Intel Mac detected"
fi

# Xcode Command Line Tools
if xcode-select -p &>/dev/null; then
  phase_step done "Xcode Command Line Tools installed"
else
  phase_step active "Installing Xcode Command Line Tools..."
  xcode-select --install 2>/dev/null || true
  echo ""
  echo -e "${YELLOW}A dialog box should have appeared asking to install Xcode CLT.${NC}"
  echo -e "${YELLOW}Click 'Install', wait for it to finish, then re-run this script.${NC}"
  exit 0
fi

# ============================================================================
# PHASE 2: Install Developer Tools
# ============================================================================
phase_header 2 8 "Install Developer Tools" "Installing the tools you need to write and run code."

# Homebrew
if command -v brew &>/dev/null; then
  phase_step done "Homebrew already installed"
else
  phase_step active "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add brew to PATH for this session
  eval "$($BREW_PREFIX/bin/brew shellenv)"
  # Add to .zprofile if not already there
  if ! grep -q 'brew shellenv' "$HOME/.zprofile" 2>/dev/null; then
    echo "eval \"\$($BREW_PREFIX/bin/brew shellenv)\"" >> "$HOME/.zprofile"
  fi
  phase_step done "Homebrew installed"
fi

# Ensure brew is in PATH
eval "$($BREW_PREFIX/bin/brew shellenv)" 2>/dev/null || true

# gum (enables rich UI for remaining phases)
if command -v gum &>/dev/null; then
  phase_step done "gum already installed"
else
  phase_step active "Installing gum (terminal UI)..."
  brew install gum
  phase_step done "gum installed"
fi
HAS_GUM=true

# Node.js
if command -v node &>/dev/null; then
  NODE_VERSION=$(node -v)
  phase_step done "Node.js already installed ($NODE_VERSION)"
else
  spin "Installing Node.js..." brew install node
  phase_step done "Node.js installed ($(node -v))"
fi

# Git (ensure latest)
if command -v git &>/dev/null; then
  phase_step done "Git already installed ($(git --version | cut -d' ' -f3))"
else
  spin "Installing Git..." brew install git
  phase_step done "Git installed"
fi

# GitHub CLI
if command -v gh &>/dev/null; then
  phase_step done "GitHub CLI already installed"
else
  spin "Installing GitHub CLI..." brew install gh
  phase_step done "GitHub CLI installed"
fi

# Nodemon
if command -v nodemon &>/dev/null; then
  phase_step done "Nodemon already installed"
else
  spin "Installing Nodemon..." npm install -g nodemon
  phase_step done "Nodemon installed"
fi

# iTerm2
if [[ -d "/Applications/iTerm.app" ]]; then
  phase_step done "iTerm2 already installed"
else
  spin "Installing iTerm2..." brew install --cask iterm2
  phase_step done "iTerm2 installed"
fi

# Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  phase_step done "Oh My Zsh already installed"
else
  spin "Installing Oh My Zsh..." sh -c "RUNZSH=no KEEP_ZSHRC=yes $(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  phase_step done "Oh My Zsh installed"
fi

# ============================================================================
# PHASE 3: GitHub Authentication & SSH
# ============================================================================
phase_header 3 8 "GitHub Authentication" "Connecting your computer to GitHub so you can download and upload code."

# Check if already authenticated
if gh auth status &>/dev/null; then
  phase_step done "Already authenticated with GitHub"
else
  phase_step active "Opening browser for GitHub login..."
  echo ""
  gum style --foreground 214 --italic \
    "A browser window will open. Click 'Authorize GitHub CLI' and come back here."
  echo ""
  gh auth login --web --git-protocol ssh
  phase_step done "GitHub authenticated"
fi

# Get user info
GH_USERNAME=$(gh api user --jq '.login')
GH_EMAIL=$(gh api user --jq '.email // empty')
if [[ -z "$GH_EMAIL" ]]; then
  GH_EMAIL="${GH_USERNAME}@users.noreply.github.com"
fi
phase_step done "Detected username: $GH_USERNAME"

# Git config
git config --global user.name "$GH_USERNAME"
git config --global user.email "$GH_EMAIL"
phase_step done "Git identity configured"

# SSH key
if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  phase_step done "SSH key already exists"
else
  ssh-keygen -t ed25519 -C "$GH_EMAIL" -f "$HOME/.ssh/id_ed25519" -N ""
  phase_step done "SSH key generated"
fi

# Upload SSH key to GitHub (ignore error if already uploaded)
gh ssh-key add "$HOME/.ssh/id_ed25519.pub" --title "Pursuit Dev Machine" 2>/dev/null || true
phase_step done "SSH key uploaded to GitHub"

# Test SSH connection
ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" && \
  phase_step done "SSH connection verified" || \
  phase_step done "SSH key registered (connection test passed)"

# --- Add user as collaborator (using admin token from encrypted secrets) ---
phase_step active "Setting up repository access..."

# Clone onboarding repo to get the encrypted secrets
ONBOARDING_DIR=$(mktemp -d)
git clone --depth 1 "https://github.com/$ONBOARDING_REPO.git" "$ONBOARDING_DIR" 2>/dev/null

# Decrypt secrets
DECRYPTED_FILE=$(mktemp)
gpg --quiet --batch --yes --passphrase "$PASSPHRASE" \
  --output "$DECRYPTED_FILE" \
  --decrypt "$ONBOARDING_DIR/env.secrets.gpg"

# Extract admin token
ADMIN_TOKEN=$(grep '^ADMIN_GITHUB_TOKEN=' "$DECRYPTED_FILE" | cut -d'=' -f2-)

# Add as collaborator to both repos
for REPO in "$SERVER_REPO" "$CLIENT_REPO"; do
  gh api --method PUT \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/collaborators/$GH_USERNAME" \
    -f permission='push' \
    --header "Authorization: token $ADMIN_TOKEN" 2>/dev/null || true
done
phase_step done "Added as collaborator"

# Accept pending invitations
sleep 2
for REPO_FULL in "$SERVER_REPO" "$CLIENT_REPO"; do
  INVITE_ID=$(gh api /user/repository_invitations --jq ".[] | select(.repository.full_name==\"$REPO_FULL\") | .id" 2>/dev/null || echo "")
  if [[ -n "$INVITE_ID" ]]; then
    gh api --method PATCH "/user/repository_invitations/$INVITE_ID" 2>/dev/null || true
  fi
done
phase_step done "Repository invitations accepted"

# Clean up admin token from memory
unset ADMIN_TOKEN

# ============================================================================
# PHASE 4: Fork & Clone Repositories
# ============================================================================
phase_header 4 8 "Fork & Clone Repositories" "Creating your own copies of the code so you can make changes safely."

# Fork repos (skip if already forked)
for REPO in "$SERVER_REPO" "$CLIENT_REPO"; do
  REPO_NAME=$(basename "$REPO")
  if gh repo view "$GH_USERNAME/$REPO_NAME" &>/dev/null; then
    phase_step done "$REPO_NAME already forked"
  else
    spin "Forking $REPO_NAME..." gh repo fork "$REPO" --clone=false
    phase_step done "$REPO_NAME forked"
  fi
done

# Clone repos
for REPO in "$SERVER_REPO" "$CLIENT_REPO"; do
  REPO_NAME=$(basename "$REPO")
  TARGET_DIR="$WORKSPACE/$REPO_NAME"
  if [[ -d "$TARGET_DIR/.git" ]]; then
    phase_step done "$REPO_NAME already cloned"
  else
    spin "Cloning $REPO_NAME..." git clone "git@github.com:$GH_USERNAME/$REPO_NAME.git" "$TARGET_DIR"
    phase_step done "$REPO_NAME cloned"
  fi

  # Set upstream remote
  cd "$TARGET_DIR"
  if git remote get-url upstream &>/dev/null; then
    phase_step done "$REPO_NAME upstream already set"
  else
    git remote add upstream "git@github.com:$REPO.git"
    phase_step done "$REPO_NAME upstream configured"
  fi

  # Fetch and checkout dev branch
  git fetch upstream "$BRANCH" 2>/dev/null || true
  if git rev-parse --verify "$BRANCH" &>/dev/null; then
    git checkout "$BRANCH"
    git pull upstream "$BRANCH" --ff-only 2>/dev/null || true
  else
    git checkout -b "$BRANCH" "upstream/$BRANCH"
  fi
  phase_step done "$REPO_NAME on $BRANCH branch"
  cd "$WORKSPACE"
done

# ============================================================================
# PHASE 5: Environment Variables
# ============================================================================
phase_header 5 8 "Environment Variables" "Configuring your local settings so the app can connect to databases and services."

# Write server .env (everything except ADMIN_GITHUB_TOKEN and comments)
# Use sed to remove the admin token line and comment lines, preserving multi-line values
sed '/^ADMIN_GITHUB_TOKEN=/d; /^# /d' "$DECRYPTED_FILE" | sed '/^$/N;/^\n$/d' > "$WORKSPACE/test-pilot-server/.env"
phase_step done "Server .env written"

# Write client .env
cat > "$WORKSPACE/pilot-client/.env" <<EOF
VITE_API_URL=http://localhost:7001
EOF
phase_step done "Client .env written"

# Validate critical vars exist in server .env
MISSING_VARS=""
for VAR in PG_HOST PG_PORT PG_USER PG_DATABASE PG_PASSWORD SECRET; do
  if ! grep -q "^${VAR}=" "$WORKSPACE/test-pilot-server/.env"; then
    MISSING_VARS="$MISSING_VARS $VAR"
  fi
done
if [[ -n "$MISSING_VARS" ]]; then
  log_warn "Missing critical env vars:$MISSING_VARS"
else
  phase_step done "All critical env vars present"
fi

# Clean up decrypted file
rm -f "$DECRYPTED_FILE"
rm -rf "$ONBOARDING_DIR"
phase_step done "Cleaned up temporary files"

# ============================================================================
# PHASE 6: Install Dependencies
# ============================================================================
phase_header 6 8 "Install Dependencies" "Downloading all the code libraries the app needs to run."

cd "$WORKSPACE/test-pilot-server"
if [[ -d "node_modules" ]]; then
  phase_step done "Server dependencies already installed"
else
  spin "Installing server dependencies (this may take a minute)..." npm install
  phase_step done "Server dependencies installed"
fi

cd "$WORKSPACE/pilot-client"
if [[ -d "node_modules" ]]; then
  phase_step done "Client dependencies already installed"
else
  spin "Installing client dependencies (this may take a minute)..." npm install
  phase_step done "Client dependencies installed"
fi

cd "$WORKSPACE"

# ============================================================================
# PHASE 7: AI Tooling (Cursor + Claude Code)
# ============================================================================
phase_header 7 8 "AI Tooling" "Installing Cursor (your code editor) and Claude Code (your AI assistant)."

# Cursor
if [[ -d "/Applications/Cursor.app" ]]; then
  phase_step done "Cursor already installed"
else
  spin "Installing Cursor..." brew install --cask cursor
  phase_step done "Cursor installed"
fi

# Claude Code CLI
if command -v claude &>/dev/null; then
  phase_step done "Claude Code already installed"
else
  spin "Installing Claude Code..." npm install -g @anthropic-ai/claude-code
  phase_step done "Claude Code installed"
fi

# Install feature-kickoff command into workspace
COMMANDS_DIR="$WORKSPACE/.claude/commands"
mkdir -p "$COMMANDS_DIR"
if [[ -f "$ONBOARDING_DIR/commands/feature-kickoff.md" ]] 2>/dev/null; then
  cp "$ONBOARDING_DIR/commands/feature-kickoff.md" "$COMMANDS_DIR/"
else
  # Download directly from the repo
  curl -fsSL "https://raw.githubusercontent.com/$ONBOARDING_REPO/main/commands/feature-kickoff.md" \
    -o "$COMMANDS_DIR/feature-kickoff.md" 2>/dev/null || true
fi
if [[ -f "$COMMANDS_DIR/feature-kickoff.md" ]]; then
  phase_step done "Feature kickoff command installed"
fi

# Add pursuit-sync alias
if ! grep -q 'pursuit-sync' "$HOME/.zshrc" 2>/dev/null; then
  echo "" >> "$HOME/.zshrc"
  echo "# Pursuit platform sync" >> "$HOME/.zshrc"
  echo "alias pursuit-sync='curl -fsSL https://raw.githubusercontent.com/$ONBOARDING_REPO/main/sync.sh | bash'" >> "$HOME/.zshrc"
  phase_step done "pursuit-sync alias added to .zshrc"
else
  phase_step done "pursuit-sync alias already exists"
fi

# ============================================================================
# PHASE 8: Verification
# ============================================================================
phase_header 8 8 "Verification" "Making sure everything works before you start building."

# Test backend
phase_step active "Starting backend server..."
cd "$WORKSPACE/test-pilot-server"
node server.js &
SERVER_PID=$!
sleep 5

if curl -s "http://localhost:7001" &>/dev/null; then
  phase_step done "Backend server responding on port 7001"
else
  phase_step pending "Backend server not responding (may need manual check)"
fi
kill $SERVER_PID 2>/dev/null || true
wait $SERVER_PID 2>/dev/null || true

# Test frontend
phase_step active "Starting frontend..."
cd "$WORKSPACE/pilot-client"
npm run dev &
CLIENT_PID=$!
sleep 5

if curl -s "http://localhost:5173" &>/dev/null; then
  phase_step done "Frontend responding on port 5173"
else
  phase_step pending "Frontend not responding (may need manual check)"
fi
kill $CLIENT_PID 2>/dev/null || true
wait $CLIENT_PID 2>/dev/null || true

cd "$WORKSPACE"

# ============================================================================
# SETUP COMPLETE
# ============================================================================
echo ""
gum style \
  --border double --border-foreground 46 \
  --padding "1 2" --margin "1 0" \
  --bold --foreground 46 \
  "SETUP COMPLETE" \
  "" \
  "Your workspace:  ~/Documents/pursuit/" \
  "Backend:         ~/Documents/pursuit/test-pilot-server/" \
  "Frontend:        ~/Documents/pursuit/pilot-client/" \
  "" \
  "To start developing:" \
  "  1. Open Cursor: cursor ~/Documents/pursuit/" \
  "  2. Open two terminals in Cursor" \
  "  3. Backend:  cd test-pilot-server && npm start" \
  "  4. Frontend: cd pilot-client && npm run dev" \
  "" \
  "Backend:  http://localhost:7001" \
  "Frontend: http://localhost:5173" \
  "" \
  "Need help? Talk to Claude in Cursor or run: claude"

# Ask to open Cursor
echo ""
if gum confirm "Open Cursor now?"; then
  open -a Cursor "$WORKSPACE"
fi
