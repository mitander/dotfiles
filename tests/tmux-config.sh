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

# Execute the registered command list without attaching a client or sending keys
# to a real terminal. Keep tmux's quoting and brace syntax intact.
invoke_binding() {
  local table="$1" key="$2" binding
  binding="$(tmux -L "$SOCKET" list-keys -T "$table" "$key")"
  binding="${binding#* "$key" }"
  # list-keys escapes command separators for bind-key's outer parser.
  printf '%s\n' "${binding//\\;/;}" | tmux -L "$SOCKET" source-file -
}

# Stage production config with stubbed plugins on a private server.
MYRAN_BINARY="${MYRAN_TEST_BINARY:-$(command -v myran)}"
mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/home/.nix-profile/bin"
ln -s "$(command -v fish)" "$TEST_ROOT/home/.nix-profile/bin/fish"
ln -s "$MYRAN_BINARY" "$TEST_ROOT/bin/myran"
export PATH="$TEST_ROOT/bin:$PATH"
export XDG_CONFIG_HOME="$TEST_ROOT/home/.config"
export MYRAN_CONFIG_FILE="$XDG_CONFIG_HOME/myran/config.toml"

mkdir -p "$TEST_ROOT/home/dotfiles/scripts" "$TEST_ROOT/home/dotfiles/extras/tmux" \
  "$TEST_ROOT/home/dotfiles/tmux/.tmux" "$TEST_ROOT/home/.tmux/plugins/tpm" "$TEST_ROOT/state"
cp "$SOURCE_ROOT/tmux/.tmux.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf"
cp "$SOURCE_ROOT/tmux/.tmux/workspace-status.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux/workspace-status.conf"
cp "$SOURCE_ROOT/extras/tmux/colors.conf" "$TEST_ROOT/home/dotfiles/extras/tmux/colors.conf"
# Model Continuum's status append and TPM's default install chord without loading either plugin.
printf '#!/bin/sh\ntmux set-option -ag status-right "#(true)"\ntmux bind-key I display-message install\n' \
  >"$TEST_ROOT/home/.tmux/plugins/tpm/tpm"
chmod +x "$TEST_ROOT/home/.tmux/plugins/tpm/tpm"
HOME="$TEST_ROOT/home" XDG_STATE_HOME="$TEST_ROOT/state" SHELL=/obsolete/homebrew/bin/fish \
  tmux -L "$SOCKET" -f "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf" new-session -d -s smoke 'sleep 300'

# Wait for asynchronous Myran setup before inspecting bindings.
for _attempt in {1..100}; do
  [[ -n "$(tmux -L "$SOCKET" show-option -gqv @myran.integration.bindings)" ]] && break
  sleep 0.05
done
[[ -n "$(tmux -L "$SOCKET" show-option -gqv @myran.integration.bindings)" ]] ||
  fail "Myran setup failed: $(tmux -L "$SOCKET" show-messages)"

# Shell launches must not depend on the login shell or inherited PATH.
[[ "$(tmux -L "$SOCKET" show-option -gqv default-shell)" == "$TEST_ROOT/home/.nix-profile/bin/fish" ]] ||
  fail 'default shell bypasses the Nix profile'
[[ -z "$(tmux -L "$SOCKET" show-option -gqv default-command)" ]] ||
  fail 'default command overrides the managed shell'
[[ "$(tmux -L "$SOCKET" show-environment -g SHELL)" == "SHELL=$TEST_ROOT/home/.nix-profile/bin/fish" ]] ||
  fail 'shell environment bypasses the Nix profile'
tmux -L "$SOCKET" set-environment -g DOTFILES_TEST_SHELL_ENV "$TEST_ROOT/shell-env"
shell_pane="$(tmux -L "$SOCKET" new-window -d -P -F '#{pane_id}' -t smoke: -n shell)"
for _attempt in {1..100}; do
  [[ "$(tmux -L "$SOCKET" display-message -p -t "$shell_pane" '#{pane_current_command}')" == fish ]] && break
  sleep 0.05
done
[[ "$(tmux -L "$SOCKET" display-message -p -t "$shell_pane" '#{pane_current_command}')" == fish ]] ||
  fail 'default pane did not launch Fish'
# Expand these variables inside Fish, not in the test's Bash process.
# shellcheck disable=SC2016
tmux -L "$SOCKET" send-keys -t "$shell_pane" -l 'printf "%s\n" "$SHELL" > "$DOTFILES_TEST_SHELL_ENV"'
tmux -L "$SOCKET" send-keys -t "$shell_pane" Enter
for _attempt in {1..100}; do
  [[ -s "$TEST_ROOT/shell-env" ]] && break
  sleep 0.05
done
[[ -s "$TEST_ROOT/shell-env" ]] || fail 'default pane did not report its shell environment'
IFS= read -r pane_shell <"$TEST_ROOT/shell-env"
[[ "$pane_shell" == "$TEST_ROOT/home/.nix-profile/bin/fish" ]] ||
  fail 'default pane inherited a stale shell path'
tmux -L "$SOCKET" kill-window -t "$shell_pane"

# Myran configures the workspace bindings. Keep one delegation smoke check here.
[[ "$(tmux -L "$SOCKET" show-option -gqv @continuum-restore)" == off ]] || fail 'continuum restore must not replay old processes'
[[ "$(tmux -L "$SOCKET" show-option -gwv copy-mode-line-numbers)" == off ]] ||
  fail 'copy-mode line numbers reintroduce the hidden-pane redraw loop'
binding="$(tmux -L "$SOCKET" list-keys -T prefix)"
run_focus="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +r ' || true)"
[[ "$run_focus" == *'__tmux-action focus-run >/dev/null'* && "$run_focus" != *source-file* ]] ||
  fail 'prefix r no longer delegates Run focus to Myran'

# Plain application input must not be intercepted.
root_bindings="$(tmux -L "$SOCKET" list-keys -T root)"
for key in Enter q Escape; do
  [[ -z "$(printf '%s\n' "$root_bindings" | awk -v key="$key" '$4 == key')" ]] ||
    fail "plain $key still intercepts command input"
done

# Native pane navigation must target the origin and stop at the window boundary.
left="$(tmux -L "$SOCKET" new-window -d -P -F '#{pane_id}' -t smoke: -n navigation 'sleep 300')"
window="$(tmux -L "$SOCKET" display-message -p -t "$left" '#{window_id}')"
right="$(tmux -L "$SOCKET" split-window -h -P -F '#{pane_id}' -t "$left" 'sleep 300')"
tmux -L "$SOCKET" select-window -t "$window"
tmux -L "$SOCKET" select-pane -t "$right"
invoke_binding root C-h
[[ "$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')" == "$left" ]] || fail 'left navigation'
invoke_binding root C-h
[[ "$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')" == "$left" ]] || fail 'navigation wrapped'
invoke_binding root C-l
[[ "$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')" == "$right" ]] || fail 'right navigation'

# Explicit application claims and editor roles keep navigation inside the pane.
for option in @workspace_navigation @workspace_pane_role; do
  case "$option" in
  @workspace_navigation) value=application ;;
  @workspace_pane_role) value=vim ;;
  esac
  tmux -L "$SOCKET" set-option -p -t "$right" "$option" "$value"
  invoke_binding root C-h
  [[ "$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')" == "$right" ]] ||
    fail "navigation ignored $option"
  tmux -L "$SOCKET" set-option -pu -t "$right" "$option"
done

# Last-pane zoom toggles layout and focus without a shell or shared environment.
invoke_binding prefix z
zoom_state="$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id} #{window_zoomed_flag}')"
[[ "$zoom_state" == "$left 1" ]] || fail "last-pane should focus $left and zoom: $zoom_state"
invoke_binding prefix z
zoom_state="$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id} #{window_zoomed_flag}')"
[[ "$zoom_state" == "$right 0" ]] || fail "last-pane should focus $right and unzoom: $zoom_state"

# Closing tests exercise routing, confirmation and window-versus-editor scope.
tmux_test() { command tmux -L "$SOCKET" "$@"; }
wait_until() {
  local message="$1" _attempt
  shift
  for _attempt in {1..100}; do
    if "$@"; then return; fi
    sleep 0.05
  done
  fail "$message"
}
pane_is_gone() { ! tmux_test list-panes -a -F '#{pane_id}' | grep -Fxq "$1"; }
process_is_gone() { ! kill -0 "$1" 2>/dev/null; }
pane_contains() { [[ "$(tmux_test capture-pane -p -t "$1")" == *"$2"* ]]; }
editor_expr() { nvim --server "$TEST_ROOT/nvim.sock" --remote-expr "$1"; }
editor_has_one_window() { [[ "$(editor_expr 'winnr("$")')" == 1 ]]; }
run_myran() {
  HOME="$TEST_ROOT/home" XDG_STATE_HOME="$TEST_ROOT/state" \
    TMUX="$run_scope" TMUX_PANE="$run_origin" MYRAN_TMUX_SERVER_ID="$run_identity" myran "$@"
}

# Load the production mapping without plugins or a real user configuration.
printf '%s\n' \
  "local spec = dofile([[$SOURCE_ROOT/nvim/.config/nvim/lua/mitander/plugins/tmux.lua]])" \
  'for _, mapping in ipairs(spec.keys) do' \
  '  vim.keymap.set(mapping.mode or "n", mapping[1], mapping[2])' \
  'end' >"$TEST_ROOT/editor.lua"
run_origin="$(tmux_test display-message -p -t smoke: '#{pane_id}')"
run_scope="$(tmux_test display-message -p -t "$run_origin" '#{socket_path},#{pid},#{s/^.//:session_id}')"
run_identity="$(tmux_test show-environment -g MYRAN_TMUX_SERVER_ID)"
run_identity="${run_identity#MYRAN_TMUX_SERVER_ID=}"
tmux_test set-option -t smoke @workspace_root "$TEST_ROOT"
# Expand the PID and output path in the supervised process, not the driver.
# shellcheck disable=SC2016
printf '%s\n' 'printf "%s\n" "$$" >"$1"' 'exec sleep 300' >"$TEST_ROOT/run.sh"
for table in root prefix; do
  if [[ "$table" == root ]]; then
    key=C-q
    role=shell
  else
    key=q
    role=pi
  fi
  editor="$(tmux_test new-window -P -F '#{pane_id}' -t smoke: -n editor \
    nvim -u "$TEST_ROOT/editor.lua" -i NONE -n --noplugin --listen "$TEST_ROOT/nvim.sock")"
  editor_pid="$(tmux_test display-message -p -t "$editor" '#{pane_pid}')"
  tmux_test set-option -p -t "$editor" @workspace_pane_role vim
  wait_until 'editor did not start' test -S "$TEST_ROOT/nvim.sock"
  # A clean split closes only with Ctrl-Q. Prefix q quits the entire editor.
  if [[ "$table" == root ]]; then
    editor_expr "execute('split')" >/dev/null
    invoke_binding "$table" "$key"
    wait_until 'Ctrl-Q did not close just one split' editor_has_one_window
  else
    editor_expr "execute('split')" >/dev/null
  fi
  editor_expr "setline(1, 'unsaved text')" >/dev/null
  invoke_binding "$table" "$key"
  wait_until 'close did not prompt about unsaved text' pane_contains "$editor" '(C)ancel'
  tmux_test send-keys -t "$editor" c
  [[ "$(editor_expr 'getline(1)')" == 'unsaved text' ]] || fail 'cancel changed unsaved text'
  [[ "$(editor_expr '&modified')" == 1 ]] || fail 'cancel cleared unsaved changes'
  [[ "$(tmux_test display-message -p '#{pane_id}')" == "$editor" ]] || fail 'close left the editor hidden'
  invoke_binding "$table" "$key"
  wait_until 'close did not prompt again' pane_contains "$editor" '(C)ancel'
  tmux_test send-keys -t "$editor" n
  wait_until 'discard did not close editor pane' pane_is_gone "$editor"
  wait_until 'editor process survived closure' process_is_gone "$editor_pid"
  wait_until 'editor socket did not close' test ! -S "$TEST_ROOT/nvim.sock"

  # Ordinary terminals close only the focused pane, leaving its sibling alive.
  closing="$(tmux_test split-window -h -P -F '#{pane_id}' -t "$right" 'sleep 300')"
  tmux_test set-option -p -t "$closing" @workspace_pane_role "$role"
  tmux_test select-window -t "$closing"
  invoke_binding "$table" "$key"
  wait_until 'ordinary pane did not close' pane_is_gone "$closing"
  [[ "$(tmux_test list-panes -t "$right" -F '#{pane_id}' | wc -l)" -eq 2 ]] || fail 'close removed a sibling'

  # Keep Run cleanup delegated to its owner, with the invoking pane's scope.
  binding="$(tmux_test list-keys -T "$table" "$key")"
  [[ "$binding" == *'TMUX=#{q:socket_path}'*'TMUX_PANE=#{q:pane_id} myran close-run'* ]] ||
    fail 'Run closure bypasses scoped Myran cleanup'
  marker="$TEST_ROOT/run-$table.pid"
  run_myran set-default "exec bash '$TEST_ROOT/run.sh' '$marker'" >/dev/null
  run_myran run >/dev/null
  run_pane="$(tmux_test display-message -p -t smoke: '#{pane_id}')"
  wait_until 'Run did not start' test -s "$marker"
  IFS= read -r run_pid <"$marker"
  invoke_binding "$table" "$key"
  wait_until 'Run pane did not close' pane_is_gone "$run_pane"
  wait_until 'Run process survived closure' process_is_gone "$run_pid"
done

# Our session-switch fallback must work before the client has any history.
client_session_is() { [[ "$(tmux_test list-clients -F '#{session_name}')" == "$1" ]]; }
tmux_test new-session -d -s alternate 'sleep 300'
mkfifo "$TEST_ROOT/client-input"
exec 9<>"$TEST_ROOT/client-input"
tmux_test -C attach-session -t smoke <"$TEST_ROOT/client-input" >"$TEST_ROOT/client-output" 2>&1 &
client_job=$!
wait_until 'test client did not attach' client_session_is smoke
invoke_binding prefix Space
wait_until 'session switch without history failed' client_session_is alternate
invoke_binding prefix Space
wait_until 'session switch did not return' client_session_is smoke
# A previous session named "0" is not missing history.
for session in 0 1 2; do tmux_test new-session -d -s "$session" 'sleep 300'; done
tmux_test switch-client -t '=0'
tmux_test switch-client -t '=1'
invoke_binding prefix Space
wait_until 'session 0 was treated as missing history' client_session_is 0
tmux_test detach-client -t "$(tmux_test list-clients -F '#{client_name}')"
wait "$client_job"
exec 9>&-

# Reload restores managed shell defaults without duplicating the autosave hook.
tmux -L "$SOCKET" set-option -gw copy-mode-line-numbers relative
tmux -L "$SOCKET" set-option -g default-shell /bin/sh
tmux -L "$SOCKET" set-option -g default-command fish
tmux -L "$SOCKET" set-environment -g SHELL /obsolete/homebrew/bin/fish
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" source-file "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf"
[[ "$(tmux -L "$SOCKET" show-option -gwv copy-mode-line-numbers)" == off ]] ||
  fail 'reload did not disable copy-mode line numbers'
[[ "$(tmux -L "$SOCKET" show-option -gqv default-shell)" == "$TEST_ROOT/home/.nix-profile/bin/fish" ]] ||
  fail 'reload did not restore the managed shell'
[[ -z "$(tmux -L "$SOCKET" show-option -gqv default-command)" ]] ||
  fail 'reload did not clear the legacy shell command'
[[ "$(tmux -L "$SOCKET" show-environment -g SHELL)" == "SHELL=$TEST_ROOT/home/.nix-profile/bin/fish" ]] ||
  fail 'reload did not clear the stale shell environment'
status_right="$(tmux -L "$SOCKET" show-option -gqv status-right)"
[[ "$status_right" == *'#(true)'* && "$status_right" != *'#(true)'*'#(true)'* ]] || fail 'autosave hook changed'
printf 'PASS: Myran callers, navigation, editor/terminal/Run closing, session switching, safe reload\n'
