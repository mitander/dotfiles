#!/usr/bin/env bash
set -euo pipefail

ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
RESIDENCY="$ROOT/scripts/tmux-residency.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmux-residency-test.XXXXXX")"
SOCKET="residency-test-$$"
REAL_SOCKET="residency-real-test-$$"
CONTROL_PIDS=()

cleanup() {
  local pid
  for pid in "${CONTROL_PIDS[@]:-}"; do
    kill "$pid" >/dev/null 2>&1 || true
  done
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
  tmux -L "$REAL_SOCKET" kill-server >/dev/null 2>&1 || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_eq() {
  local expected="$1" actual="$2" message="$3"
  [[ "$actual" == "$expected" ]] || fail "$message: expected '$expected', got '$actual'"
}

option() {
  tmux -L "$SOCKET" show-options -qv -t "$1" "$2" 2>/dev/null || true
}

session_id() {
  tmux -L "$SOCKET" display-message -p -t "$1" '#{session_id}'
}

run_residency() {
  TMUX_RESIDENCY_SOCKET="$SOCKET" \
    TMUX_RESIDENCY_DISABLE_SCHEDULE=1 \
    TMUX_RESIDENCY_SCHEDULER_LOG="$TEST_ROOT/scheduler.log" \
    TMUX_RESIDENCY_GRACE_SECONDS=900 \
    TMUX_RESIDENCY_NOW="$TMUX_RESIDENCY_NOW" \
    "$RESIDENCY" "$@"
}

mkdir -p "$TEST_ROOT/project-a" "$TEST_ROOT/project-b"
: >"$TEST_ROOT/scheduler.log"
tmux -L "$SOCKET" -f /dev/null new-session -d -s alpha -c "$TEST_ROOT/project-a"
tmux -L "$SOCKET" new-session -d -s beta -c "$TEST_ROOT/project-b"
alpha="$(session_id alpha)"
beta="$(session_id beta)"
tmux -L "$SOCKET" set-option -gq @workspace_residency_mode observe
tmux -L "$SOCKET" set-option -q -t "$alpha" @workspace_root "$TEST_ROOT/project-a"
tmux -L "$SOCKET" set-option -q -t "$beta" @workspace_root "$TEST_ROOT/project-b"

# A detached Workspace gets one grace deadline and one coalesced timer.
TMUX_RESIDENCY_NOW=1000
export TMUX_RESIDENCY_NOW
run_residency reconcile
assert_eq 1900 "$(option "$alpha" @workspace_residency_deadline)" 'detached deadline'
assert_eq 1900 "$(option "$alpha" @workspace_residency_timer_due)" 'detached timer'
assert_eq 2 "$(wc -l <"$TEST_ROOT/scheduler.log" | tr -d ' ')" 'one timer per detached session'
run_residency reconcile
assert_eq 2 "$(wc -l <"$TEST_ROOT/scheduler.log" | tr -d ' ')" 'reconcile coalesces timers'

# A stale timer cannot alter a newer timer.
run_residency timer-fired "$alpha" 1800
assert_eq 1900 "$(option "$alpha" @workspace_residency_timer_due)" 'stale timer ignored'

# A due timer records an observation but does not terminate panes.
TMUX_RESIDENCY_NOW=1900
run_residency timer-fired "$alpha" 1900
assert_eq observe:would-cool "$(option "$alpha" @workspace_residency_result)" 'due timer observation'
assert_eq '' "$(option "$alpha" @workspace_residency_deadline)" 'due deadline cleared'
tmux -L "$SOCKET" has-session -t "$alpha" || fail 'observation removed workspace'
run_residency reconcile
assert_eq '' "$(option "$alpha" @workspace_residency_deadline)" 'observed detach does not restart grace'
assert_eq 2 "$(wc -l <"$TEST_ROOT/scheduler.log" | tr -d ' ')" 'observed detach does not schedule again'

# An attached control-mode client makes the Workspace Active and clears grace.
control_fifo="$TEST_ROOT/control.fifo"
mkfifo "$control_fifo"
exec 9<>"$control_fifo"
tmux -L "$SOCKET" -C attach-session -t "$alpha" <&9 >"$TEST_ROOT/control.out" 2>&1 &
control_pid=$!
CONTROL_PIDS+=("$control_pid")
for _ in $(seq 1 50); do
  [[ "$(tmux -L "$SOCKET" display-message -p -t "$alpha" '#{session_attached}')" == 1 ]] && break
  sleep 0.02
done
assert_eq 1 "$(tmux -L "$SOCKET" display-message -p -t "$alpha" '#{session_attached}')" 'control client attached'
run_residency reconcile
assert_eq '' "$(option "$alpha" @workspace_residency_deadline)" 'active workspace clears deadline'
state="$(run_residency status "$alpha" | cut -f3)"
assert_eq attached "$state" 'derived attached state'

kill "$control_pid" >/dev/null 2>&1 || true
wait "$control_pid" 2>/dev/null || true
exec 9>&-
CONTROL_PIDS=()

# Manual sleep is observation-only in this phase.
run_residency sleep "$beta"
assert_eq observe:would-cool "$(option "$beta" @workspace_residency_result)" 'manual sleep observation'
tmux -L "$SOCKET" has-session -t "$beta" || fail 'manual sleep removed workspace'

# Picker metadata is only Workspace name and root. Legacy root metadata remains
# a valid fallback without exposing residency state.
tmux -L "$SOCKET" set-option -qu -t "$beta" @workspace_root
tmux -L "$SOCKET" set-option -q -t "$beta" @project_root "$TEST_ROOT/project-b"
listing="$(TMUX_SESSION_SOCKET="$SOCKET" "$ROOT/scripts/tmux-session.sh" list)"
printf '%s\n' "$listing" | grep -q "^${alpha}"$'\talpha' || fail 'picker metadata missing alpha'
printf '%s\n' "$listing" | grep -q "$TEST_ROOT/project-b" || fail 'picker metadata missing workspace root'

# Exercise one real tmux-delayed callback rather than only invoking handlers.
unset TMUX_RESIDENCY_NOW
mkdir -p "$TEST_ROOT/real-project"
tmux -L "$REAL_SOCKET" -f /dev/null new-session -d -s real -c "$TEST_ROOT/real-project"
real_id="$(tmux -L "$REAL_SOCKET" display-message -p -t real '#{session_id}')"
tmux -L "$REAL_SOCKET" set-option -gq @workspace_residency_mode observe
tmux -L "$REAL_SOCKET" set-option -q -t "$real_id" @workspace_root "$TEST_ROOT/real-project"
TMUX_RESIDENCY_SOCKET="$REAL_SOCKET" \
  TMUX_RESIDENCY_GRACE_SECONDS=1 \
  "$RESIDENCY" reconcile
for _ in $(seq 1 50); do
  [[ "$(tmux -L "$REAL_SOCKET" show-options -qv -t "$real_id" @workspace_residency_result 2>/dev/null || true)" == observe:would-cool ]] && break
  sleep 0.1
done
assert_eq observe:would-cool "$(tmux -L "$REAL_SOCKET" show-options -qv -t "$real_id" @workspace_residency_result)" 'real delayed callback'

# Direct reconciliation recovers stale coalescing metadata, and off mode clears
# all runtime residency behavior.
tmux -L "$SOCKET" set-option -gq @workspace_residency_reconcile_pending 1
TMUX_RESIDENCY_NOW=3000
export TMUX_RESIDENCY_NOW
run_residency reconcile
assert_eq '' "$(tmux -L "$SOCKET" show-option -gqv @workspace_residency_reconcile_pending 2>/dev/null || true)" 'stale reconciliation lease cleared'
tmux -L "$SOCKET" set-option -gq @workspace_residency_mode off
run_residency reconcile
assert_eq '' "$(option "$alpha" @workspace_residency_deadline)" 'off mode clears deadline'
assert_eq '' "$(option "$alpha" @workspace_residency_result)" 'off mode clears observation'

printf 'PASS: tmux residency state machine\n'
