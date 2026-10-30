#!/usr/bin/env bash
# Exercise the real pinned opener templates without opening any host application.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/yazi-native.XXXXXX")
TEST_ROOT=$(cd "$TEST_ROOT" && pwd)
SOCKET="yazi-native-$$"
cleanup() {
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT
fail() {
  tmux -L "$SOCKET" capture-pane -p -t trial:files >&2 || true
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}
wait_for() {
  local _attempt
  for _attempt in {1..100}; do
    if "$@"; then return; fi
    sleep 0.05
  done
  fail "Timed out: $*"
}
pane_contains() { tmux -L "$SOCKET" capture-pane -p -t trial:files | grep -Fq -- "$1"; }
pane_at_directory() { [[ $(tmux -L "$SOCKET" capture-pane -p -t trial:files -S 0 -E 0) == "$1" ]]; }
assert_flat_chrome() {
  local screen
  screen=$(tmux -L "$SOCKET" capture-pane -p -t trial:files)
  [[ $screen != *''* && $screen != *''* ]] || fail 'Stock rounded chrome is still visible'
  screen=$(tmux -L "$SOCKET" capture-pane -p -e -t trial:files)
  [[ $screen == *$'\e[48;5;5m'* ]] || fail 'Selection does not use the terminal magenta palette'
  if [[ -n ${YAZI_TEST_CAPTURE:-} ]]; then
    printf '%s\n' "$screen" >"$YAZI_TEST_CAPTURE"
  fi
}

YAZI_BINARY=$(command -v yazi)
[[ $("$YAZI_BINARY" --version) == 'Yazi 26.5.6'* ]] || fail 'This fixture targets Yazi 26.5.6'
export TEST_ROOT
export HOME="$TEST_ROOT/home" XDG_CONFIG_HOME="$TEST_ROOT/config" XDG_CACHE_HOME="$TEST_ROOT/cache"
export XDG_DATA_HOME="$TEST_ROOT/data" XDG_STATE_HOME="$TEST_ROOT/state"
export YAZI_CONFIG_HOME="$XDG_CONFIG_HOME/yazi"
mkdir -p "$HOME" "$TEST_ROOT/bin" "$YAZI_CONFIG_HOME" "$TEST_ROOT/one" "$TEST_ROOT/two" \
  "$TEST_ROOT/outside" "$TEST_ROOT/media" "$TEST_ROOT/directories/folder λ"
cp "$ROOT/yazi/.config/yazi/"*.toml "$YAZI_CONFIG_HOME/"
ln -s "$YAZI_BINARY" "$TEST_ROOT/bin/yazi"
ln -s "$ROOT/scripts/myran-yazi" "$TEST_ROOT/bin/myran-yazi"
cat >"$TEST_ROOT/bin/myran" <<'SH'
#!/usr/bin/env bash
printf '%s\0' "$PWD" "$MYRAN_TMUX_SERVER_ID" "$@" >"$TEST_ROOT/editor"
SH
cat >"$TEST_ROOT/bin/open" <<'SH'
#!/usr/bin/env bash
printf '%s\0' "$@" >"$TEST_ROOT/system"
SH
chmod +x "$TEST_ROOT/bin/myran" "$TEST_ROOT/bin/open"
ln -s open "$TEST_ROOT/bin/xdg-open"
export PATH="$TEST_ROOT/bin:$PATH"
# Test-only navigation shortcuts avoid depending on the stock interactive cd prompt.
cat >>"$YAZI_CONFIG_HOME/keymap.toml" <<TOML
append_keymap = [
  { on = "<F2>", run = 'cd "$TEST_ROOT/outside"' },
  { on = "<F4>", run = 'cd "$TEST_ROOT/media"' },
  { on = "<F5>", run = 'cd "$TEST_ROOT/directories"' },
]
TOML
# Shell punctuation is literal filename data, including the command substitution.
# shellcheck disable=SC2016
name='sp ace-λ;$(touch INJECTED)*.rs'
printf 'fn main() {}\n' >"$TEST_ROOT/outside/$name"
printf '%%PDF-1.7\n' >"$TEST_ROOT/media/document.pdf"
# Automation accounts may have nologin as their passwd shell. Never inherit it here.
TMUX='' SHELL=/bin/sh tmux -L "$SOCKET" -f /dev/null new-session -d -s trial -x 180 -y 40 sleep 300
tmux -L "$SOCKET" set-option -g default-shell /bin/sh
tmux -L "$SOCKET" set-environment -g MYRAN_TMUX_SERVER_ID retained
start_browser() {
  local project=$1
  rm -f "$TEST_ROOT/editor" "$TEST_ROOT/system"
  tmux -L "$SOCKET" set-option -t trial @workspace_root "$TEST_ROOT/$project"
  tmux -L "$SOCKET" new-window -t trial: -n files -c "$TEST_ROOT/$project" 'myran-yazi'
  wait_for pane_contains "$TEST_ROOT/$project"
}
for project in one two; do
  start_browser "$project"
  tmux -L "$SOCKET" send-keys -t trial:files F2
  wait_for pane_contains "$name"
  assert_flat_chrome
  tmux -L "$SOCKET" send-keys -t trial:files Enter
  wait_for test -s "$TEST_ROOT/editor"
  printf '%s\0' "$TEST_ROOT/$project" retained open -- "$TEST_ROOT/outside/$name" >"$TEST_ROOT/expected"
  cmp "$TEST_ROOT/expected" "$TEST_ROOT/editor" || fail 'Editor argv or Project drifted'
  [[ ! -e "$TEST_ROOT/outside/INJECTED" ]] || fail 'Filename executed as shell code'
  tmux -L "$SOCKET" kill-window -t trial:files
  # Start a fresh browser rather than send input while a blocking opener resumes its terminal.
  start_browser "$project"
  tmux -L "$SOCKET" send-keys -t trial:files F4
  wait_for pane_contains document.pdf
  tmux -L "$SOCKET" send-keys -t trial:files o
  wait_for test -s "$TEST_ROOT/system"
  printf '%s\0' "$TEST_ROOT/media/document.pdf" >"$TEST_ROOT/expected"
  cmp "$TEST_ROOT/expected" "$TEST_ROOT/system" || fail 'System-app argv drifted'
  [[ ! -e "$TEST_ROOT/editor" ]] || fail 'System-open key also launched the editor'
  tmux -L "$SOCKET" kill-window -t trial:files

  start_browser "$project"
  tmux -L "$SOCKET" send-keys -t trial:files F5
  wait_for pane_contains 'folder λ'
  tmux -L "$SOCKET" send-keys -t trial:files Enter
  wait_for test -s "$TEST_ROOT/editor"
  printf '%s\0' "$TEST_ROOT/$project" retained open -- "$TEST_ROOT/directories/folder λ" >"$TEST_ROOT/expected"
  cmp "$TEST_ROOT/expected" "$TEST_ROOT/editor" || fail 'Folder Enter did not route to the editor'
  [[ ! -e "$TEST_ROOT/system" ]] || fail 'Folder Enter launched a system application'
  tmux -L "$SOCKET" kill-window -t trial:files

  start_browser "$project"
  tmux -L "$SOCKET" send-keys -t trial:files F5
  wait_for pane_contains 'folder λ'
  tmux -L "$SOCKET" send-keys -t trial:files l
  wait_for pane_at_directory "$TEST_ROOT/directories/folder λ"
  tmux -L "$SOCKET" send-keys -t trial:files Left
  wait_for pane_at_directory "$TEST_ROOT/directories"
  tmux -L "$SOCKET" send-keys -t trial:files Right
  wait_for pane_at_directory "$TEST_ROOT/directories/folder λ"
  tmux -L "$SOCKET" send-keys -t trial:files Left
  wait_for pane_at_directory "$TEST_ROOT/directories"
  [[ ! -e "$TEST_ROOT/system" && ! -e "$TEST_ROOT/editor" ]] || fail 'Navigation launched an application'
  tmux -L "$SOCKET" send-keys -t trial:files o
  wait_for test -s "$TEST_ROOT/system"
  printf '%s\0' "$TEST_ROOT/directories/folder λ" >"$TEST_ROOT/expected"
  cmp "$TEST_ROOT/expected" "$TEST_ROOT/system" || fail 'Folder o did not use the system opener'
  [[ ! -e "$TEST_ROOT/editor" ]] || fail 'Folder o launched the editor'
  tmux -L "$SOCKET" kill-window -t trial:files
done
printf '%s\n' 'Yazi 26.5.6: real editor and system opener routing passed in two Workspace roots'
