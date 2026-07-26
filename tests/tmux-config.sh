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
cp "$SOURCE_ROOT/scripts/tmux-project.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh"
cp "$SOURCE_ROOT/tmux/.tmux.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf"
chmod +x "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh"
: >"$TEST_ROOT/home/dotfiles/tmux/.tmux/flume-theme.conf"
: >"$TEST_ROOT/home/dotfiles/tmux/.tmux/workspace-status.conf"
printf '#!/bin/sh\nexit 0\n' >"$TEST_ROOT/home/.tmux/plugins/tpm/tpm"
chmod +x "$TEST_ROOT/home/.tmux/plugins/tpm/tpm"

HOME="$TEST_ROOT/home" XDG_STATE_HOME="$TEST_ROOT/state" \
  tmux -L "$SOCKET" -f "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf" new-session -d -s smoke

hook="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-hooks -g client-detached)"
[[ "$hook" == *'request-reconcile'* ]] || fail 'client-detached hook missing asynchronous reconciliation'
exit_hook="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-hooks -g pane-died)"
[[ "$exit_hook" == *'__run-pane-exited'* ]] || fail 'run completion hook missing'
binding="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-keys -T prefix)"
[[ "$binding" == *workspace_residency_script*sleep* ]] || fail 'Workspace sleep binding missing'
[[ "$binding" != *'toggle-workspace-pin'* ]] || fail 'obsolete Workspace pin binding remains'
root_bindings="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-keys -T root)"
[[ "$root_bindings" == *'@workspace_navigation'* ]] || fail 'metadata navigation binding missing'
[[ "$root_bindings" != *'ps -o state='* ]] || fail 'navigation still probes processes on keypress'
script="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -gqv @workspace_residency_script)"
[[ "$script" == "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh" ]] || fail 'legacy residency fallback was not selected'

# The session-created hook is coalesced, then observes the detached session.
for _ in $(seq 1 30); do
  deadline="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -qv -t smoke @workspace_residency_deadline 2>/dev/null || true)"
  [[ "$deadline" =~ ^[0-9]+$ ]] && break
  sleep 0.1
done
[[ "$deadline" =~ ^[0-9]+$ ]] || fail 'session-created hook did not reconcile the Workspace'

# Arm completion only after respawn, so the replaced shell's exit cannot finish
# the new generation. The run process then publishes its marker and exits.
window="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" display-message -p -t smoke '#{window_id}')"
pane="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" display-message -p -t smoke '#{pane_id}')"
marker="$TEST_ROOT/completion"
channel="tmux-config-run-$$"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -wq -t "$window" @myran_run_watch_token "$marker"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -wq -t "$window" @myran_run_state active
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -pq -t "$pane" @workspace_pane_role run
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -pq -t "$pane" remain-on-exit on
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -pu -t "$pane" @myran_run_marker >/dev/null 2>&1 || true
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" respawn-pane -k -t "$pane" "tmux wait-for '$channel' && printf '2\\n0\\nresult\\n' >'$marker'"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -pq -t "$pane" @myran_run_marker "$marker"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" wait-for -S "$channel"
for _ in $(seq 1 50); do
  state="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-options -wqv -t "$window" @myran_run_state 2>/dev/null || true)"
  [[ "$state" == completed ]] && break
  sleep 0.02
done
[[ "$state" == completed ]] || fail 'pane-exited hook did not complete the run'

printf 'PASS: tmux residency and run-event configuration\n'
