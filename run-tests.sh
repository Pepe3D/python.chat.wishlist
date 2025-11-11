#!/usr/bin/env bash
set -euo pipefail

# run-tests.sh
# Activates a virtualenv (if present), exports .env, and runs pytest in the
# `modules` subdirectory. Accepts additional pytest args.

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

# Export variables from .env so child processes see them (optional)
if [ -f "$ROOT_DIR/.env" ]; then
  # shellcheck disable=SC1090
  set -a
  source "$ROOT_DIR/.env"
  set +a
fi

# Move to modules directory and run pytest using the interpreter's -m pytest so
# we don't depend on the pytest binary being on PATH.
cd "$ROOT_DIR/modules"

# Default args: -q (quiet) if none provided
if [ "$#" -eq 0 ]; then
  EXTRA_ARGS=("-q")
else
  EXTRA_ARGS=("$@")
fi

echo "Running pytest in $PWD with python: $(python -V 2>&1)"
python -m pytest "${EXTRA_ARGS[@]}"
