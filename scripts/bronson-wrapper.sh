#!/usr/bin/env bash
# Launch the bronson dashboard from its live private checkout. The nix
# wrapper sets BRONSON_PYTHON and the Flume theme env; the script itself
# lives in the checkout so edits apply without rebuilding.
set -euo pipefail

script="${BRONSON_SCRIPT:-$HOME/c/p/bronson/scripts/bronson.py}"
if [[ ! -f "$script" ]]; then
  echo "bronson: checkout missing at ${script}" >&2
  echo "run: gh repo clone mitander/bronson ~/c/p/bronson" >&2
  exit 127
fi

exec "${BRONSON_PYTHON:-python3}" "$script" "$@"
