#!/usr/bin/env bash
set -euo pipefail

# create_new_repo_with_submodule.sh
# Usage: create_new_repo_with_submodule.sh [repo-name] [--private] [--https] [--no-push]
# If no repo-name is provided, the script uses the current directory name.
# By default uses SSH remotes for origin and the modules submodule. Use --https to prefer HTTPS URLs.

SUBMODULE_SSH_URL="git@github.com:Pepe3D/python.modules.utils.git"
SUBMODULE_HTTPS_URL="https://github.com/Pepe3D/python.modules.utils.git"

# repo name: first arg or current folder name. Trim whitespace to avoid accidental spaces
REPO_NAME_RAW="${1:-$(basename "$PWD") }"
shift || true
# trim leading/trailing whitespace
REPO_NAME="$(printf "%s" "$REPO_NAME_RAW" | sed -e 's/^[[:space:]]\+//' -e 's/[[:space:]]\+$//')"


PRIVATE=false
USE_HTTPS=false
NO_PUSH=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --private) PRIVATE=true; shift ;;
    --https) USE_HTTPS=true; shift ;;
    --no-push) NO_PUSH=true; shift ;;
    -h|--help) echo "Usage: $0 [repo-name] [--private] [--https] [--no-push]"; exit 0 ;;
    *) echo "Unknown arg: $1"; echo "Usage: $0 [repo-name] [--private] [--https] [--no-push]"; exit 1 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "Error: gh (GitHub CLI) is required. Install https://cli.github.com/" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required." >&2
  exit 1
fi

GH_USER="$(gh api user --jq .login 2>/dev/null || true)"
if [ -z "$GH_USER" ]; then
  echo "Not authenticated with gh. Please run: gh auth login" >&2
  exit 1
fi

VISIBILITY="public"
if [ "$PRIVATE" = true ]; then
  VISIBILITY="private"
fi

echo "Preparing local repository first..."

# Ensure local git repo exists
if [ ! -d .git ]; then
  echo "Initializing local git repository..."
  git init
fi

# Ensure .gitignore contains .env
if [ ! -f .gitignore ] || ! grep -qxF ".env" .gitignore 2>/dev/null; then
  echo ".env" >> .gitignore
  echo "Added .env to .gitignore"
fi

# Create .env.example sanitized from .env if present
if [ -f .env ]; then
  echo "Creating .env.example from .env (sanitizing TELEGRAM_BOT_TOKEN)..."
  sed -r "s/^(TELEGRAM_BOT_TOKEN=).*/\1<PUT_YOUR_TELEGRAM_TOKEN_HERE>/" .env > .env.example
  echo "Created .env.example"
fi

# Add or update submodule
SUBMODULE_URL="$SUBMODULE_SSH_URL"
if [ "$USE_HTTPS" = true ]; then
  SUBMODULE_URL="$SUBMODULE_HTTPS_URL"
fi

if [ -d modules ] && [ -d modules/.git ]; then
  echo "A modules directory with a git repo already exists; skipping submodule add."
else
  if git submodule status modules >/dev/null 2>&1; then
    echo "modules is already a submodule; skipping add."
  else
    echo "Adding submodule $SUBMODULE_URL -> modules"
    git submodule add "$SUBMODULE_URL" modules || echo "Warning: failed add submodule; you can run: git submodule add $SUBMODULE_URL modules"
  fi
fi

# Stage and commit changes
git add -A
if ! git diff --cached --quiet; then
  git commit -m "chore: initial import; add modules submodule and .env.example" || true
else
  echo "No changes to commit."
fi

# Now create the GitHub repo (without --source and --push, we'll push manually)
echo "Creating GitHub repo '$REPO_NAME' under user '$GH_USER' (visibility: $VISIBILITY)"
if gh repo view "$GH_USER/$REPO_NAME" >/dev/null 2>&1; then
  echo "Repository $GH_USER/$REPO_NAME already exists on GitHub. Will use the existing repo.";
else
  gh repo create "$GH_USER/$REPO_NAME" --$VISIBILITY
fi

# Choose remote URL (SSH vs HTTPS)
ORIGIN_SSH="git@github.com:$GH_USER/$REPO_NAME.git"
ORIGIN_HTTPS="https://github.com/$GH_USER/$REPO_NAME.git"

if [ "$USE_HTTPS" = true ]; then
  ORIGIN_URL="$ORIGIN_HTTPS"
else
  ORIGIN_URL="$ORIGIN_SSH"
fi

if git remote get-url origin >/dev/null 2>&1; then
  echo "Setting origin to $ORIGIN_URL"
  git remote set-url origin "$ORIGIN_URL"
else
  echo "Adding origin $ORIGIN_URL"
  git remote add origin "$ORIGIN_URL"
fi

# Ensure branch 'main' exists locally and is the current branch.
# After git init the default branch may be 'master'; rename it to 'main' so push works.
current_branch="$(git symbolic-ref --short HEAD 2>/dev/null || true)"
if [ -z "$current_branch" ]; then
  git checkout -b main
else
  # If the repo was initialized with 'master', rename it to 'main'
  if [ "$current_branch" = "master" ]; then
    git branch -M main
  else
    # ensure the branch is called 'main' (safe to force if user wants otherwise)
    git branch -M main || true
  fi
fi

if [ "$NO_PUSH" = false ]; then
  echo "Pushing to origin/main..."
  git push -u origin main
else
  echo "--no-push specified: skipping push to remote."
fi

echo "Repository ready: $ORIGIN_URL"
echo "Remember: fill local .env with TELEGRAM_BOT_TOKEN and other secrets. Do NOT commit .env."
