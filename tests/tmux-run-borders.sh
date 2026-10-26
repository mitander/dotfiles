#!/usr/bin/env bash
set -euo pipefail

# Private server
SOURCE_ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
SOCKET="tmux-run-borders-$$"
TEST_ROOT="$(mktemp -d)"
theme="$SOURCE_ROOT/tmux/.tmux/workspace-status.conf"

tmux_test() {
  command tmux -L "$SOCKET" "$@"
}

cleanup() {
  tmux_test kill-server >/dev/null 2>&1 || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

# Theme and border assertions
load_theme() {
  # Both files share one parse so tmux's hidden color variables remain available.
  tmux_test source-file - <<EOF
source-file "$SOURCE_ROOT/extras/tmux/colors.conf"
source-file "$theme"
EOF
}

assert_ordinary_border() {
  [[ "$(tmux_test display-message -p -t "$ordinary" '#{pane-border-status}')" == "$1" ]] ||
    fail "ordinary window should have pane-border-status=$1"
}

assert_zoom_geometry() {
  local width height actual size_command
  [[ "$(tmux_test display-message -p -t "$ordinary" '#{window_zoomed_flag}')" == 1 ]] ||
    fail 'picker or reload lost zoom'

  width="$(tmux_test display-message -p -t "$ordinary" '#{window_width}')"
  height="$(tmux_test display-message -p -t "$ordinary" '#{window_height}')"
  actual="$(tmux_test display-message -p -t "$ordinary" '#{pane_height} #{pane_width}')"
  [[ "$actual" == "$height $width" ]] || fail "zoomed pane is not full size: $actual"

  # Ask the application to report its PTY size, not just tmux's pane dimensions.
  # Expand $size in the pane's Bash, not this test driver.
  rm -f "$TEST_ROOT/size" "$TEST_ROOT/size.done"
  # shellcheck disable=SC2016
  printf -v size_command '
for ((attempt = 0; attempt < 100; attempt++)); do
  stty size > %q
  read -r size < %q
  [[ $size == %q ]] && break
  sleep 0.02
done
touch %q
' "$TEST_ROOT/size" "$TEST_ROOT/size" "$height $width" "$TEST_ROOT/size.done"
  tmux_test send-keys -t "$ordinary" -l "$size_command"
  tmux_test send-keys -t "$ordinary" Enter

  for ((attempt = 0; attempt < 100; attempt++)); do
    if [[ -f "$TEST_ROOT/size.done" && -s "$TEST_ROOT/size" ]]; then
      read -r actual <"$TEST_ROOT/size"
      [[ "$actual" == "$height $width" ]] && return
    fi
    sleep 0.02
  done
  fail "application PTY did not reach zoomed size $height $width"
}

assert_picker_border() {
  local expected="$1" picker
  # Myran workspace/run pickers are modal floating panes, not tiled splits.
  picker="$(tmux_test new-pane -O -C -K -P -F '#{pane_id}' -t "$ordinary" 'sleep 300')"
  [[ "$(tmux_test display-message -p -t "$picker" '#{pane_floating_flag}')" == 1 ]] ||
    fail 'picker regression did not create a floating pane'

  assert_ordinary_border "$expected"
  if [[ "$(tmux_test display-message -p -t "$ordinary" '#{window_zoomed_flag}')" == 1 ]]; then
    assert_zoom_geometry
  fi

  load_theme
  assert_ordinary_border "$expected"
  if [[ "$(tmux_test display-message -p -t "$ordinary" '#{window_zoomed_flag}')" == 1 ]]; then
    assert_zoom_geometry
  fi

  tmux_test kill-pane -t "$picker"
  assert_ordinary_border "$expected"
}

# Scroll positions belong to a pane border only while that row is visible.
assert_format() {
  local pane="$1" option="$2" expected="$3" actual
  actual="$(tmux_test display-message -p -t "$pane" "#{E:$option}")"
  if [[ -z "$expected" ]]; then
    [[ -z "$actual" ]] || fail "$option should be empty, got '$actual'"
  else
    [[ "$actual" == *"$expected"* ]] || fail "$option should contain '$expected', got '$actual'"
  fi
}

test_copy_positions() {
  local direction pane sibling attempt
  for direction in -h -v; do
    pane="$(tmux_test new-window -P -F '#{pane_id}' -t proof: -n copy-position 'sleep 300')"
    assert_format "$pane" status-right ''
    tmux_test copy-mode -t "$pane"
    assert_format "$pane" status-right '≡ 0/0'

    sibling="$(tmux_test split-window "$direction" -P -F '#{pane_id}' -t "$pane" 'sleep 300')"
    assert_format "$pane" status-right ''
    assert_format "$pane" pane-border-format '≡ '
    assert_format "$sibling" pane-border-format ''
    load_theme
    assert_format "$pane" status-right ''
    assert_format "$pane" pane-border-format '≡ '

    # Give only the first pane scrollback, then focus its scrolling sibling.
    tmux_test send-keys -X -t "$pane" cancel
    tmux_test respawn-pane -k -t "$pane" 'seq 1 100; printf "position-ready\n"; sleep 300'
    for ((attempt = 0; attempt < 100; attempt++)); do
      [[ "$(tmux_test capture-pane -p -t "$pane")" == *position-ready* ]] && break
      sleep 0.02
    done
    [[ "$(tmux_test capture-pane -p -t "$pane")" == *position-ready* ]] || fail 'scroll history did not arrive'
    tmux_test copy-mode -t "$pane"
    tmux_test copy-mode -t "$sibling"
    tmux_test send-keys -X -N 1 -t "$pane" scroll-up
    assert_format "$pane" pane-border-format '≡ 1/'
    assert_format "$sibling" pane-border-format '≡ 0/0'
    tmux_test send-keys -X -t "$sibling" cancel
    assert_format "$sibling" pane-border-format ''

    # Resizing can change the offset. The location must follow visibility.
    tmux_test resize-pane -Z -t "$pane"
    assert_format "$pane" status-right '≡ '
    tmux_test resize-pane -Z -t "$pane"
    assert_format "$pane" status-right ''
    assert_format "$pane" pane-border-format '≡ '
    tmux_test kill-pane -t "$sibling"
    assert_format "$pane" status-right '≡ '
    tmux_test send-keys -X -t "$pane" cancel
    assert_format "$pane" status-right ''
    assert_format "$pane" pane-border-format ''
    tmux_test kill-window -t "$pane"
  done
}

# Run-window reload
# Use a shell that can report its PTY size in the later zoom checks.
tmux_test -f /dev/null new-session -d -x 160 -y 50 -s proof 'bash --noprofile --norc'
ordinary="$(tmux_test display-message -p -t proof '#{pane_id}')"
load_theme

runner="$(tmux_test new-window -d -P -F '#{pane_id}' -t proof: -n run 'sleep 300')"
run_window="$(tmux_test display-message -p -t "$runner" '#{window_id}')"
run_pid="$(tmux_test display-message -p -t "$runner" '#{pane_pid}')"
tmux_test set-option -w -t "$run_window" @myran.run.window 1
tmux_test set-option -w -t "$run_window" pane-border-status top

# Loading the theme must preserve unrelated hooks and Myran's run title.
tmux_test set-hook -g 'after-split-window[98]' 'set-option -g @unrelated-hook kept'
load_theme

[[ "$(tmux_test show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'theme reload moved the run title'

manual="$(tmux_test split-window -h -P -F '#{pane_id}' -t "$runner" 'sleep 300')"
[[ "$(tmux_test show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'manual split moved the run title'
[[ "$(tmux_test show-option -gqv @unrelated-hook)" == kept ]] || fail 'unrelated hook lost'

tmux_test kill-pane -t "$manual"
[[ "$(tmux_test show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'closing manual split moved the run title'
[[ "$(tmux_test display-message -p -t "$runner" '#{pane_pid}')" == "$run_pid" ]] ||
  fail 'runner process changed'

# Tiled splits and floating pickers
assert_ordinary_border off
assert_picker_border off

split="$(tmux_test split-window -h -P -F '#{pane_id}' -t "$ordinary" 'sleep 300')"
assert_ordinary_border bottom
assert_picker_border bottom
load_theme
assert_ordinary_border bottom

tmux_test kill-pane -t "$split"
assert_ordinary_border off
load_theme
assert_ordinary_border off

# Zoom and application geometry
# Picker churn and reload must preserve full-size panes and the application's PTY.
for direction in -h -v; do
  split="$(tmux_test split-window "$direction" -P -F '#{pane_id}' -t "$ordinary" 'sleep 300')"
  tmux_test select-pane -t "$ordinary"
  layout="$(tmux_test display-message -p -t "$ordinary" '#{window_layout}')"
  tmux_test resize-pane -Z -t "$ordinary"
  assert_ordinary_border off
  assert_zoom_geometry

  for ((cycle = 0; cycle < 3; cycle++)); do
    assert_picker_border off
    assert_zoom_geometry
  done

  tmux_test resize-pane -Z -t "$ordinary"
  assert_ordinary_border bottom
  [[ "$(tmux_test display-message -p -t "$ordinary" '#{window_layout}')" == "$layout" ]] ||
    fail 'unzoom did not restore tiled layout'
  tmux_test kill-pane -t "$split"
  assert_ordinary_border off
done

# Pane exit
# A shell exiting must remove the border row without an explicit kill-pane.
exiting="$(tmux_test split-window -v -P -F '#{pane_id}' -t "$ordinary" 'sleep 300')"
exiting_pid="$(tmux_test display-message -p -t "$exiting" '#{pane_pid}')"
assert_ordinary_border bottom
kill "$exiting_pid"

for ((attempt = 0; attempt < 100; attempt++)); do
  [[ "$(tmux_test display-message -p -t "$ordinary" '#{window_panes}')" == 1 ]] && break
  sleep 0.02
done
[[ "$(tmux_test display-message -p -t "$ordinary" '#{window_panes}')" == 1 ]] ||
  fail 'exiting pane did not close'
assert_ordinary_border off
load_theme
[[ "$(tmux_test show-option -wv -t "$run_window" pane-border-status)" == top ]] ||
  fail 'repeated theme reload moved the run title'

test_copy_positions
printf 'PASS: tiled-only borders, pane-local scroll positions, floating pickers, zoom/PTY geometry, pane exit, reload and run titles\n'
