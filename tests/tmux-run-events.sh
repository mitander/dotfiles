#!/usr/bin/env bash
set -euo pipefail

ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT="$ROOT/scripts/tmux-project.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmux-run-events.XXXXXX")"
SOCKET="tmux-run-events-$$"

cleanup() {
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
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

window_option() {
  tmux -L "$SOCKET" show-options -wqv -t "$1" "$2" 2>/dev/null || true
}

pane_option() {
  tmux -L "$SOCKET" show-options -pqv -t "$1" "$2" 2>/dev/null || true
}

run_handler() {
  local pane="$1" window="$2" marker="$3"
  tmux -L "$SOCKET" run-shell "'$PROJECT' __run-pane-exited '$pane' '$window' '$marker'"
}

wait_for_window_state() {
  local window="$1" expected="$2"
  for _ in $(seq 1 50); do
    [[ "$(window_option "$window" @myran_run_state)" == "$expected" ]] && return 0
    sleep 0.02
  done
  return 1
}

tmux -L "$SOCKET" -f /dev/null new-session -d -s events -n run -c "$TEST_ROOT" 'sleep 100'
window="$(tmux -L "$SOCKET" display-message -p -t events:run '#{window_id}')"
pane="$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')"

# A published Result completion is consumed exactly once and leaves its pane.
marker="$TEST_ROOT/result"
printf '2\n0\nresult\n' >"$marker"
tmux -L "$SOCKET" set-option -wq -t "$window" @myran_run_watch_token "$marker"
tmux -L "$SOCKET" set-option -wq -t "$window" @myran_run_state active
tmux -L "$SOCKET" set-option -pq -t "$pane" @myran_run_marker "$marker"
run_handler "$pane" "$window" "$marker"
wait_for_window_state "$window" completed || fail 'Result completion was not handled'
[[ -n "$(window_option "$window" @myran_run_status)" ]] || fail 'Result status is empty'
assert_eq '' "$(pane_option "$pane" @myran_run_marker)" 'Result marker metadata cleared'
[[ ! -e "$marker" ]] || fail 'Result marker file was not removed'

# A stale pane-exit event cannot complete a newer generation.
old_marker="$TEST_ROOT/old"
new_marker="$TEST_ROOT/new"
printf '2\n0\nresult\n' >"$old_marker"
tmux -L "$SOCKET" set-option -wq -t "$window" @myran_run_watch_token "$new_marker"
tmux -L "$SOCKET" set-option -wq -t "$window" @myran_run_state active
run_handler "$pane" "$window" "$old_marker"
for _ in $(seq 1 50); do
  [[ ! -e "$old_marker" ]] && break
  sleep 0.02
done
assert_eq active "$(window_option "$window" @myran_run_state)" 'stale event state'
assert_eq "$new_marker" "$(window_option "$window" @myran_run_watch_token)" 'stale event generation'

# A successful Application completion removes only its run window.
app_window="$(tmux -L "$SOCKET" new-window -d -P -F '#{window_id}' -t events: -n app -c "$TEST_ROOT" 'sleep 100')"
app_pane="$(tmux -L "$SOCKET" display-message -p -t "$app_window" '#{pane_id}')"
app_marker="$TEST_ROOT/application"
printf '2\n0\napplication\n' >"$app_marker"
tmux -L "$SOCKET" set-option -wq -t "$app_window" @myran_run_watch_token "$app_marker"
tmux -L "$SOCKET" set-option -wq -t "$app_window" @myran_run_state active
tmux -L "$SOCKET" set-option -pq -t "$app_pane" @myran_run_marker "$app_marker"
run_handler "$app_pane" "$app_window" "$app_marker"
for _ in $(seq 1 50); do
  tmux -L "$SOCKET" list-windows -a -F '#{window_id}' | grep -qxF "$app_window" || break
  sleep 0.02
done
if tmux -L "$SOCKET" list-windows -a -F '#{window_id}' | grep -qxF "$app_window"; then
  fail 'successful Application window remains'
fi
tmux -L "$SOCKET" has-session -t events || fail 'Application completion removed the session'

printf 'PASS: tmux run completion events\n'
