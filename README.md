# Platform Onboarding

Single-command setup wizard for the Pursuit platform. Gets non-technical staff from zero to running the full stack locally.

## Onboarding a New Staff Member

Send them this message:

```
1. Open Terminal (Cmd+Space, type "Terminal", hit Enter)
2. Paste this and hit Enter:
   curl -fsSL https://raw.githubusercontent.com/cgodoy720/platform-onboarding/main/setup.sh | bash -s -- --passphrase "THE_PASSPHRASE"
3. Follow the prompts. That's it.
```

Replace `THE_PASSPHRASE` with the actual passphrase used to encrypt `env.secrets.gpg`.

## Managing Secrets

All environment variables live in an encrypted file (`env.secrets.gpg`) in this repo.

### Update env vars (e.g., rotate a key)

1. Edit your local `.env.secrets` file with the new values
2. Re-encrypt: `gpg --symmetric --cipher-algo AES256 -o env.secrets.gpg .env.secrets`
3. Enter the same passphrase when prompted
4. Commit and push `env.secrets.gpg`

Existing staff don't need to do anything — the next time they run `pursuit-sync --refresh-env --passphrase "..."` they'll get the updated values.

### Change the passphrase

Re-encrypt with a new passphrase and update the onboarding message. Existing staff will need the new passphrase if they run `--refresh-env`.

### First-time setup of the encrypted file

1. Copy `.env.secrets.template` to `.env.secrets`
2. Fill in all real values
3. Encrypt: `gpg --symmetric --cipher-algo AES256 -o env.secrets.gpg .env.secrets`
4. Commit and push `env.secrets.gpg` (never commit `.env.secrets` — it's in `.gitignore`)

## Returning Users

Staff who already have everything set up can sync with:

```
pursuit-sync
```

This alias is installed during setup. It pulls the latest `dev` branch from upstream for both repos and runs `npm install` if dependencies changed.

Options:
- `pursuit-sync --rebase` — also rebases current feature branch on dev
- `pursuit-sync --refresh-env --passphrase "..."` — re-downloads env vars from the encrypted file

## What the Setup Wizard Does

| Phase | What happens |
|-------|-------------|
| 1. Preflight | Checks macOS, Xcode CLT, architecture |
| 2. Tools | Installs Homebrew, Node, Git, GitHub CLI, gum, iTerm2, Oh My Zsh, Nodemon |
| 3. GitHub | Browser-based auth, SSH key, adds as collaborator, accepts invite |
| 4. Repos | Forks both repos, clones forks, sets upstream, checks out dev |
| 5. Env | Decrypts secrets, writes .env files |
| 6. Deps | npm install for both repos |
| 7. AI | Installs Cursor + Claude Code CLI, feature-kickoff command |
| 8. Verify | Starts both servers, checks ports, prints summary |

## Troubleshooting

**Script fails at Xcode CLT**: Click "Install" in the dialog that appears, wait for it to finish, then re-run the script.

**GitHub auth fails**: Run `gh auth login` manually, then re-run the script.

**SSH connection fails**: Check `~/.ssh/id_ed25519` exists. If not, run `ssh-keygen -t ed25519` then `gh ssh-key add ~/.ssh/id_ed25519.pub`.

**npm install fails**: Try `rm -rf node_modules package-lock.json && npm install` in the failing repo.

**Backend won't start**: Check `test-pilot-server/.env` has all required vars (PG_HOST, PG_PASSWORD, SECRET at minimum).

**"Workspace not found" on pursuit-sync**: Run the full setup script first.
