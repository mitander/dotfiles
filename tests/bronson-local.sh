#!/usr/bin/env bash
# Verify local setup and launch routing without provider access or package downloads.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bronson-local.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
export HOME="$TEST_ROOT/home" CALLS="$TEST_ROOT/calls"
export BRONSON_CHECKOUT="$HOME/c/p/checkout with spaces"
mkdir -p "$TEST_ROOT/bin"
if bash "$ROOT/scripts/setup-bronson" >"$TEST_ROOT/error" 2>&1; then
  echo 'FAIL: missing checkout was accepted' >&2
  exit 1
fi
mkdir -p "$BRONSON_CHECKOUT/bronson"
touch "$BRONSON_CHECKOUT/pyproject.toml" "$BRONSON_CHECKOUT/bronson/cli.py"
if bash "$ROOT/scripts/bronson" 2>"$TEST_ROOT/error"; then
  echo 'FAIL: missing environment was accepted' >&2
  exit 1
fi
grep -q setup-bronson "$TEST_ROOT/error"
[[ ! -e "$BRONSON_CHECKOUT/.venv" ]]

printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/bin/python"
cat >>"$TEST_ROOT/bin/python" <<'EOF'
printf '<%s>\n' "$@" >>"$CALLS"
if [[ "$1 $2" == '-m venv' ]]; then
  mkdir -p "$3/bin"
  cp "$0" "$3/bin/python"
fi
EOF
chmod +x "$TEST_ROOT/bin/python"
PYTHON="$TEST_ROOT/bin/python" bash "$ROOT/scripts/setup-bronson" >/dev/null
grep -Fxq '<venv>' "$CALLS"
grep -Fxq '<--editable>' "$CALLS"
grep -Fxq "<$BRONSON_CHECKOUT>" "$CALLS"
: >"$CALLS"
PYTHON=/missing/python bash "$ROOT/scripts/setup-bronson" >/dev/null
if grep -Fxq '<venv>' "$CALLS"; then
  echo 'FAIL: existing environment was recreated' >&2
  exit 1
fi

printf '#!%s\n' "$(command -v bash)" >"$BRONSON_CHECKOUT/.venv/bin/bronson"
cat >>"$BRONSON_CHECKOUT/.venv/bin/bronson" <<'EOF'
printf '<%s>\n' "$@"
exit 42
EOF
chmod +x "$BRONSON_CHECKOUT/.venv/bin/bronson"
: >"$CALLS"
literal="literal \$(touch '$TEST_ROOT/BAD');"
status=0
bash "$ROOT/scripts/bronson" --provider gitlab --repo "$literal" >"$TEST_ROOT/out" || status=$?
[[ "$status" == 42 && ! -s "$CALLS" && ! -e "$TEST_ROOT/BAD" ]]
printf '<--provider>\n<gitlab>\n<--repo>\n<%s>\n' "$literal" >"$TEST_ROOT/expected"
cmp "$TEST_ROOT/expected" "$TEST_ROOT/out"
printf 'PASS: Bronson setup is explicit and editable; launch preserves arguments and exit status without installing\n'
