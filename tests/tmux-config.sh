#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmux-config-test.XXXXXX")"
SOCKET="tmux-config-test-$$"

cleanup() {
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p \
  "$TEST_ROOT/home/dotfiles/scripts" \
  "$TEST_ROOT/home/dotfiles/tmux/.tmux" \
  "$TEST_ROOT/home/.tmux/plugins/tpm" \
  "$TEST_ROOT/state"
cp "$SOURCE_ROOT/scripts/tmux-residency.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh"
cp "$SOURCE_ROOT/tmux/.tmux.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf"
chmod +x "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh"
: >"$TEST_ROOT/home/dotfiles/tmux/.tmux/flume-theme.conf"
: >"$TEST_ROOT/home/dotfiles/tmux/.tmux/workspace-status.conf"
printf '#!/bin/sh\nexit 0\n' >"$TEST_ROOT/home/.tmux/plugins/tpm/tpm"
chmod +x "$TEST_ROOT/home/.tmux/plugins/tpm/tpm"

HOME="$TEST_ROOT/home" XDG_STATE_HOME="$TEST_ROOT/state" \
  tmux -L "$SOCKET" -f "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf" new-session -d -s smoke

hook="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-hooks -g client-detached)"
[[ "$hook" == *'request-reconcile'* ]] || fail 'client-detached hook missing asynchronous reconciliation'
binding="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-keys -T prefix)"
[[ "$binding" == *workspace_residency_script*sleep* ]] || fail 'Workspace sleep binding missing'
[[ "$binding" != *'toggle-workspace-pin'* ]] || fail 'obsolete Workspace pin binding remains'
script="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -gqv @workspace_residency_script)"
[[ "$script" == "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh" ]] || fail 'legacy residency fallback was not selected'

# The session-created hook is coalesced, then observes the detached session.
for _ in $(seq 1 30); do
  deadline="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -qv -t smoke @workspace_residency_deadline 2>/dev/null || true)"
  [[ "$deadline" =~ ^[0-9]+$ ]] && break
  sleep 0.1
done
[[ "$deadline" =~ ^[0-9]+$ ]] || fail 'session-created hook did not reconcile the Workspace'

printf 'PASS: tmux residency configuration\n'
