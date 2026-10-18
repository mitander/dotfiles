#!/usr/bin/env bash
# Nix command routing and the activation guard, without invoking Nix.
set -euo pipefail
SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/dotfiles-nix.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/nix-command.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/bin"
export PATH="$TEST_ROOT/bin:$PATH" NIX_CALLS="$TEST_ROOT/nix-calls"
unset DOTFILES_ALLOW_ACTIVATE
printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/bin/nix"
cat >>"$TEST_ROOT/bin/nix" <<'EOF'
printf '<%s>\n' "$@" >>"$NIX_CALLS"
EOF
chmod +x "$TEST_ROOT/bin/nix"
for command in build check generations; do
  : >"$NIX_CALLS"
  bash "$SCRIPT" "$command"
  grep -qx '<--no-write-lock-file>' "$NIX_CALLS"
  if grep -q '<--override-input>' "$NIX_CALLS"; then
    echo 'FAIL: environment commands must not select application source' >&2
    exit 1
  fi
done

# Keep the real guard and argument forwarding. Bypass only the fixed checkout path
# so this test can also run in the Nix sandbox's disposable source directory.
awk '/^command=/{exit} {print}' "$SCRIPT" >"$TEST_ROOT/functions.sh"
: >"$NIX_CALLS"
if bash -c 'source "$1"; verify_checkout() { :; }; switch_generation' -- "$TEST_ROOT/functions.sh" 2>"$TEST_ROOT/log"; then
  echo 'FAIL: activation guard bypassed' >&2
  exit 1
fi
grep -q 'Refusing to modify your home directory' "$TEST_ROOT/log"
[[ ! -s "$NIX_CALLS" ]]
DOTFILES_ALLOW_ACTIVATE=1 bash -c 'source "$1"; verify_checkout() { :; }; switch_generation' -- "$TEST_ROOT/functions.sh" >/dev/null
[[ "$(grep -cx '<--no-write-lock-file>' "$NIX_CALLS")" == 2 ]]
grep -qx '<switch>' "$NIX_CALLS"
printf 'PASS: Nix routing preserves the activation guard and never writes the lockfile\n'
