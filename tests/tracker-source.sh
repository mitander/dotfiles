#!/usr/bin/env bash
# Exercise source routing without evaluating Nix or activating Home Manager.
set -euo pipefail
SCRIPT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/scripts/dotfiles-nix.sh}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tracker-source-test.XXXXXX")"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"
export HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:$PATH" NIX_CALLS="$TEST_ROOT/nix-calls"
unset DOTFILES_TRACKER_SOURCE DOTFILES_ALLOW_ACTIVATE

cat >"$TEST_ROOT/bin/nix" <<'EOF'
#!/usr/bin/env bash
printf '<%s>\n' "$@" >>"$NIX_CALLS"
EOF
chmod +x "$TEST_ROOT/bin/nix"

bash "$SCRIPT" build 2>"$TEST_ROOT/log"
grep -q 'locked remote input (no local checkout)' "$TEST_ROOT/log"
grep -qx '<--no-write-lock-file>' "$NIX_CALLS"
if grep -q '<--override-input>' "$NIX_CALLS"; then
  echo 'FAIL: missing checkout selected as local' >&2
  exit 1
fi

checkout="$HOME/c/p/ltui"
mkdir -p "$checkout/ltui" "$checkout/flume-theme"
touch "$checkout/ltui/pyproject.toml" "$checkout/flume-theme/pyproject.toml"
for command in build check generations; do
  : >"$NIX_CALLS"
  bash "$SCRIPT" "$command" 2>"$TEST_ROOT/log"
  grep -qx '<--override-input>' "$NIX_CALLS"
  grep -qx '<tracker-tui>' "$NIX_CALLS"
  grep -qx "<path:$checkout>" "$NIX_CALLS"
  grep -qx '<--no-write-lock-file>' "$NIX_CALLS"
done

: >"$NIX_CALLS"
DOTFILES_TRACKER_SOURCE=remote bash "$SCRIPT" build 2>"$TEST_ROOT/log"
if grep -q '<--override-input>' "$NIX_CALLS"; then
  echo 'FAIL: remote override ignored' >&2
  exit 1
fi

custom="$TEST_ROOT/checkout with spaces"
cp -R "$checkout" "$custom"
: >"$NIX_CALLS"
DOTFILES_TRACKER_SOURCE="$custom" bash "$SCRIPT" build 2>"$TEST_ROOT/log"
grep -qx "<path:$custom>" "$NIX_CALLS"

: >"$NIX_CALLS"
if DOTFILES_TRACKER_SOURCE="$TEST_ROOT/missing" bash "$SCRIPT" build 2>"$TEST_ROOT/log"; then
  echo 'FAIL: invalid explicit checkout accepted' >&2
  exit 1
fi
[[ ! -s "$NIX_CALLS" ]]

# Load functions only. Stub checkout verification so the activation guard and
# both layers of argument forwarding can be tested in a disposable directory.
awk '/^command=/{exit} {print}' "$SCRIPT" >"$TEST_ROOT/functions.sh"
: >"$NIX_CALLS"
if bash -c 'source "$1"; verify_checkout() { :; }; switch_generation' -- "$TEST_ROOT/functions.sh" 2>"$TEST_ROOT/log"; then
  echo 'FAIL: activation guard bypassed' >&2
  exit 1
fi
grep -q 'Refusing to modify your home directory' "$TEST_ROOT/log"
[[ ! -s "$NIX_CALLS" ]]

DOTFILES_ALLOW_ACTIVATE=1 bash -c 'source "$1"; verify_checkout() { :; }; switch_generation' -- "$TEST_ROOT/functions.sh" >"$TEST_ROOT/out" 2>"$TEST_ROOT/log"
[[ "$(grep -cx '<--override-input>' "$NIX_CALLS")" == 2 ]]
[[ "$(grep -cx '<--no-write-lock-file>' "$NIX_CALLS")" == 2 ]]
grep -qx '<switch>' "$NIX_CALLS"

rm "$checkout/flume-theme/pyproject.toml"
if bash "$SCRIPT" build 2>"$TEST_ROOT/log"; then
  echo 'FAIL: broken default checkout silently fell back to remote' >&2
  exit 1
fi

printf 'PASS: local tracker routing, remote fallback, explicit overrides, and no lock writes\n'
