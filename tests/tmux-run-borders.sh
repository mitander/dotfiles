#!/usr/bin/env bash
set -euo pipefail

SOURCE_ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SOCKET="tmux-run-borders-$$"
cleanup() { tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true; }
trap cleanup EXIT INT TERM
fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

tmux -L "$SOCKET" -f /dev/null new-session -d -s proof 'sleep 300'
ordinary="$(tmux -L "$SOCKET" display-message -p -t proof '#{pane_id}')"
theme="$SOURCE_ROOT/tmux/.tmux/workspace-status.conf"
# Both files share one parse so tmux's hidden color variables remain available.
load_theme() {
  tmux -L "$SOCKET" source-file - <<EOF
source-file "$SOURCE_ROOT/extras/tmux/colors.conf"
source-file "$theme"
EOF
}
load_theme
runner="$(tmux -L "$SOCKET" new-window -d -P -F '#{pane_id}' -t proof: -n run 'sleep 300')"
run_window="$(tmux -L "$SOCKET" display-message -p -t "$runner" '#{window_id}')"
run_pid="$(tmux -L "$SOCKET" display-message -p -t "$runner" '#{pane_pid}')"
tmux -L "$SOCKET" set-option -w -t "$run_window" @myran.run.window 1
tmux -L "$SOCKET" set-option -w -t "$run_window" pane-border-status top
# Simulate an existing server with the retired hooks, plus one unrelated hook.
for hook in after-new-window after-split-window after-kill-pane pane-exited window-layout-changed; do
  tmux -L "$SOCKET" set-hook -g "${hook}[99]" 'set-option -w pane-border-status bottom'
done
tmux -L "$SOCKET" set-hook -g 'after-split-window[98]' 'set-option -g @unrelated-hook kept'
load_theme
hooks="$(tmux -L "$SOCKET" show-hooks -g)"
[[ "$hooks" != *'[99]'*'pane-border-status bottom'* ]] || fail 'forcing hooks survived reload'
[[ "$(tmux -L "$SOCKET" show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'theme reload moved the run title'
manual="$(tmux -L "$SOCKET" split-window -h -P -F '#{pane_id}' -t "$runner" 'sleep 300')"
[[ "$(tmux -L "$SOCKET" show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'manual split moved the run title'
[[ "$(tmux -L "$SOCKET" show-option -gqv @unrelated-hook)" == kept ]] || fail 'unrelated hook lost'
tmux -L "$SOCKET" kill-pane -t "$manual"
[[ "$(tmux -L "$SOCKET" show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'closing manual split moved the run title'
[[ "$(tmux -L "$SOCKET" display-message -p -t "$runner" '#{pane_pid}')" == "$run_pid" ]] ||
  fail 'runner process changed'
[[ "$(tmux -L "$SOCKET" display-message -p -t "$ordinary" '#{pane-border-status}')" == bottom ]] ||
  fail 'ordinary-window appearance changed'
load_theme
[[ "$(tmux -L "$SOCKET" show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'repeated theme reload moved the run title'
printf 'PASS: native splits, close and theme reload preserve run borders and unrelated hooks\n'
