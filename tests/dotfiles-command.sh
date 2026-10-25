#!/usr/bin/env bash
# Exercise the public commands with recording tools, never a live activation or server.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-command.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/home/dotfiles/scripts" "$TEST_ROOT/bin"
cp "$ROOT/scripts/dotfiles" "$TEST_ROOT/home/dotfiles/scripts/dotfiles"
touch "$TEST_ROOT/home/dotfiles/flake.nix"
export HOME="$TEST_ROOT/home" DOTFILES_DIR="$TEST_ROOT/home/dotfiles"
export CALLS="$TEST_ROOT/calls" PATH="$TEST_ROOT/bin:$PATH" TMUX=test
export PROFILE_HOME="$HOME"
unset APPLY_STATUS

printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/bin/nix"
cat >>"$TEST_ROOT/bin/nix" <<'EOF'
printf 'nix' >>"$CALLS"
printf ' <%s>' "$@" >>"$CALLS"
printf '\n' >>"$CALLS"
case " $* " in
  *config.home.homeDirectory*)
    printf '%s' "$PROFILE_HOME"
    exit "${EVAL_STATUS:-0}"
    ;;
  *' switch '*) exit "${APPLY_STATUS:-0}" ;;
esac
EOF
printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/bin/tmux"
cat >>"$TEST_ROOT/bin/tmux" <<'EOF'
printf 'tmux <%s> <%s>\n' "$1" "$2" >>"$CALLS"
EOF
printf '#!%s\n' "$(command -v bash)" >"$DOTFILES_DIR/scripts/check"
cat >>"$DOTFILES_DIR/scripts/check" <<'EOF'
printf 'check\n' >>"$CALLS"
EOF
printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/bin/uname"
cat >>"$TEST_ROOT/bin/uname" <<'EOF'
case "$1" in
  -s) printf '%s\n' "${TEST_OS:-Darwin}" ;;
  -m) printf '%s\n' "${TEST_ARCH:-arm64}" ;;
esac
EOF
chmod +x "$DOTFILES_DIR/scripts/"* "$TEST_ROOT/bin/"*

run() {
  : >"$CALLS"
  "$DOTFILES_DIR/scripts/dotfiles" "$@" >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
}

# Default, reload, help and checks must not invoke Nix, even with activation opt-in inherited.
export DOTFILES_ALLOW_ACTIVATE=1
for command in '' reload; do
  if [[ -n "$command" ]]; then run "$command"; else run; fi
  printf 'tmux <source-file> <%s/.tmux.conf>\n' "$HOME" >"$TEST_ROOT/expected"
  cmp "$TEST_ROOT/expected" "$CALLS"
done
run help
[[ ! -s "$CALLS" ]]
run check
[[ "$(<"$CALLS")" == check ]]
for command in switch nonsense; do
  if run "$command"; then exit 1; fi
  [[ ! -s "$CALLS" ]]
done
if run apply unexpected; then exit 1; fi
[[ ! -s "$CALLS" ]]

# Non-activating Nix commands preserve the lockfile and never request switch.
for command in build doctor eval generations; do
  run "$command"
  grep -q '<--no-write-lock-file>' "$CALLS"
  if grep -q '<switch>\|<--override-input>' "$CALLS"; then exit 1; fi
done
run eval
grep -q '<--all-systems> <--no-build>' "$CALLS"
run build
grep -q '<--no-link>' "$CALLS"

# Select all supported native profiles, not the host's profile by accident.
for platform in Darwin:arm64 Linux:aarch64 Linux:x86_64; do
  export TEST_OS="${platform%:*}" TEST_ARCH="${platform#*:}"
  run build
  case "$platform" in
  Darwin:*) expected='mitander@darwin' ;;
  Linux:aarch64) expected='mitander@linux-aarch64' ;;
  Linux:x86_64) expected='mitander@linux-x86_64' ;;
  esac
  grep -Fq "homeConfigurations.\"$expected\".activationPackage>" "$CALLS"
done
if TEST_OS=Unknown run build; then exit 1; fi
[[ ! -s "$CALLS" ]]

# Explicit apply validates the link source, keeps conflict backups, then reloads.
run apply
grep -q '<switch> <--flake>' "$CALLS"
grep -Eq '<-b> <pre-nix-[0-9]{8}-[0-9]{6}> <--no-write-lock-file>' "$CALLS"
[[ "$(grep -c '<--no-write-lock-file>' "$CALLS")" == 2 ]]
[[ "$(tail -n 1 "$CALLS")" == "tmux <source-file> <$HOME/.tmux.conf>" ]]

# Wrong live-link sources and failed evaluation/activation must stop before reload.
if PROFILE_HOME="$TEST_ROOT/elsewhere" run apply; then exit 1; fi
if grep -q '<switch>\|^tmux' "$CALLS"; then exit 1; fi
if EVAL_STATUS=42 run apply; then exit 1; fi
if grep -q '<switch>\|^tmux' "$CALLS"; then exit 1; fi
if APPLY_STATUS=42 run apply; then exit 1; fi
grep -q '<switch>' "$CALLS"
if grep -q '^tmux' "$CALLS"; then exit 1; fi
printf 'PASS: command/profile routing, explicit activation, checkout validation, backups, failure propagation and unchanged locks\n'
