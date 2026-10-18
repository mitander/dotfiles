#!/usr/bin/env bash
# Exercise command routing without reloading the live shell or activating Home Manager.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-command.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/scripts" "$TEST_ROOT/bin"
cp "$ROOT/scripts/dotfiles" "$TEST_ROOT/scripts/dotfiles"
printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/scripts/dotfiles-nix.sh"
cat >>"$TEST_ROOT/scripts/dotfiles-nix.sh" <<'EOF'
printf '%s %s\n' "$*" "${DOTFILES_ALLOW_ACTIVATE:-0}" >>"$CALLS"
exit "${APPLY_STATUS:-0}"
EOF
printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/bin/tmux"
cat >>"$TEST_ROOT/bin/tmux" <<'EOF'
printf 'tmux %s\n' "$*" >>"$CALLS"
EOF
printf '#!%s\n' "$(command -v bash)" >"$TEST_ROOT/scripts/check"
cat >>"$TEST_ROOT/scripts/check" <<'EOF'
printf 'check\n' >>"$CALLS"
EOF
chmod +x "$TEST_ROOT/scripts/"* "$TEST_ROOT/bin/tmux"
export DOTFILES_DIR="$TEST_ROOT" CALLS="$TEST_ROOT/calls" PATH="$TEST_ROOT/bin:$PATH"
export HOME="$TEST_ROOT/home" TMUX=test
unset DOTFILES_ALLOW_ACTIVATE APPLY_STATUS

for command in '' reload; do
  : >"$CALLS"
  if [[ -n "$command" ]]; then
    bash "$TEST_ROOT/scripts/dotfiles" "$command" >/dev/null
  else
    bash "$TEST_ROOT/scripts/dotfiles" >/dev/null
  fi
  [[ "$(cat "$CALLS")" == "tmux source-file $HOME/.tmux.conf" ]]
done

: >"$CALLS"
bash "$TEST_ROOT/scripts/dotfiles" apply >/dev/null
printf 'switch 1\ntmux source-file %s/.tmux.conf\n' "$HOME" >"$TEST_ROOT/expected"
cmp "$TEST_ROOT/expected" "$CALLS"

: >"$CALLS"
if APPLY_STATUS=42 bash "$TEST_ROOT/scripts/dotfiles" apply >/dev/null; then
  echo 'FAIL: apply failure was hidden' >&2
  exit 1
fi
[[ "$(cat "$CALLS")" == 'switch 1' ]]

: >"$CALLS"
bash "$TEST_ROOT/scripts/dotfiles" check
[[ "$(cat "$CALLS")" == check ]]
printf 'PASS: reload never activates Nix; explicit apply stops on failure; check runs the local gate\n'
