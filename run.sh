#!/bin/bash
set -euo pipefail

# Run script for the project. It will:
# - activate a virtualenv at .venv/ or venv/ if present
# - export variables from .env (so subprocesses see them)
# - run the project's main entrypoint

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Activate virtualenv if available
if [ -f "$ROOT_DIR/.venv/bin/activate" ]; then
	# shellcheck disable=SC1091
	source "$ROOT_DIR/.venv/bin/activate"
elif [ -f "$ROOT_DIR/venv/bin/activate" ]; then
	# shellcheck disable=SC1091
	source "$ROOT_DIR/venv/bin/activate"
else
	echo "Warning: no virtualenv found at .venv/ or venv/. Continuing without activating a venv."
fi

# Export variables from .env so child processes see them (optional; code also uses python-dotenv)
if [ -f "$ROOT_DIR/.env" ]; then
	# shellcheck disable=SC1090
	set -a
	source "$ROOT_DIR/.env"
	set +a
fi

# Run the application
python3 "$ROOT_DIR/main.py"
