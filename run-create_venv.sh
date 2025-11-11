#!/usr/bin/env bash
set -euo pipefail

# create_venv.sh — create a Python venv and install requirements
# Defaults:
#   VENV_DIR=.venv
#   REQ_FILE=requirements.txt

show_help() {
  cat <<EOF
Usage: $0 [--venv DIR] [--requirements FILE] [--python PYTHON]

Options:
  --venv DIR         Path to venv directory (default: .venv)
  --requirements FILE  Requirements file to install (default: requirements.txt)
  --python PYTHON    Python executable to use (default: python3 then python)
  -h, --help         Show this help

Examples:
  $0                        # create .venv using python3 and install requirements.txt
  $0 --venv .env --requirements modules/requirements.txt
  $0 --python /usr/bin/python3.11
EOF
}

# defaults
VENV_DIR=.venv
REQ_FILE=requirements-dev.txt
PYTHON=""

# parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --venv)
      VENV_DIR="$2"; shift 2;;
    --requirements)
      REQ_FILE="$2"; shift 2;;
    --python)
      PYTHON="$2"; shift 2;;
    -h|--help)
      show_help; exit 0;;
    --) shift; break;;
    -* ) echo "Unknown option: $1" >&2; show_help; exit 2;;
    * ) break;;
  esac
done

# find python if not provided
if [[ -z "${PYTHON}" ]]; then
  if command -v python3 >/dev/null 2>&1; then
    PYTHON=python3
  elif command -v python >/dev/null 2>&1; then
    PYTHON=python
  else
    echo "No python executable found (tried python3 and python). Install Python or pass --python." >&2
    exit 1
  fi
fi

echo "Using Python: ${PYTHON}"

# create venv
if [[ -d "${VENV_DIR}" ]]; then
  echo "Virtualenv directory '${VENV_DIR}' already exists. Skipping creation."
else
  echo "Creating virtual environment in '${VENV_DIR}'..."
  "${PYTHON}" -m venv "${VENV_DIR}"
  echo "Virtual environment created."
fi

# check activate script
ACTIVATE_SCRIPT="${VENV_DIR}/bin/activate"
if [[ ! -f "${ACTIVATE_SCRIPT}" ]]; then
  echo "Could not find activate script at ${ACTIVATE_SCRIPT}. Virtualenv creation may have failed." >&2
  exit 1
fi

# Use the venv's pip to install
PIP_EXEC="${VENV_DIR}/bin/pip"
PY_EXEC="${VENV_DIR}/bin/python"

# verify pip exists
if [[ ! -x "${PIP_EXEC}" ]]; then
  echo "pip not found in venv. Trying to bootstrap pip..."
  "${PY_EXEC}" -m ensurepip --upgrade || true
fi

if [[ ! -x "${PIP_EXEC}" ]]; then
  echo "pip still not available in venv. Exiting." >&2
  exit 1
fi

# verify requirements file exists
if [[ ! -f "${REQ_FILE}" ]]; then
  echo "Requirements file '${REQ_FILE}' not found. Skipping install." >&2
  echo "If you want to install later, run: ${PIP_EXEC} install -r /path/to/requirements.txt"
  echo "To activate: source ${ACTIVATE_SCRIPT}"
  exit 0
fi

# install
echo "Upgrading pip inside venv..."
"${PIP_EXEC}" install --upgrade pip setuptools wheel

echo "Installing requirements from ${REQ_FILE}..."
"${PIP_EXEC}" install -r "${REQ_FILE}"

cat <<EOF
Done.
To activate the venv run:
  source ${ACTIVATE_SCRIPT}
To run python directly from the venv without activating:
  ${PY_EXEC} script.py
EOF
