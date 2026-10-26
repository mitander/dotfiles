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

# Leaving Edit returns to the previous window without closing Neovim or changing its text.
editor="$(tmux -L "$SOCKET" new-window -d -P -F '#{pane_id}' -t smoke: -n editor nvim -u NONE -i NONE -n --noplugin)"
editor_pid="$(tmux -L "$SOCKET" display-message -p -t "$editor" '#{pane_pid}')"
tmux -L "$SOCKET" set-option -p -t "$editor" @workspace_pane_role vim
tmux -L "$SOCKET" select-window -t "$editor"
for _attempt in {1..100}; do
  [[ "$(tmux -L "$SOCKET" display-message -p -t "$editor" '#{pane_current_command}')" == nvim ]] && break
  sleep 0.02
done
tmux -L "$SOCKET" send-keys -t "$editor" -l 'ikeep this editor warm'
for _attempt in {1..100}; do
  [[ "$(tmux -L "$SOCKET" capture-pane -p -t "$editor")" == *'keep this editor warm'* ]] && break
  sleep 0.02
done
invoke_binding root C-q
[[ "$(tmux -L "$SOCKET" display-message -p '#{window_id}')" == "$window" ]] || fail 'Ctrl-Q did not return to the previous window'
[[ "$(tmux -L "$SOCKET" display-message -p -t "$editor" '#{pane_pid}')" == "$editor_pid" ]] || fail 'Ctrl-Q replaced the editor process'
[[ "$(tmux -L "$SOCKET" capture-pane -p -t "$editor")" == *'keep this editor warm'* ]] || fail 'Ctrl-Q changed editor text'

# Outside Edit, observe the original Ctrl-Q byte reaching an application.
ready="$TEST_ROOT/receiver-ready"
received="$TEST_ROOT/received"
# Expand $byte in the receiving pane, not in this test driver.
# shellcheck disable=SC2016
printf -v receiver 'stty raw -echo; touch %q; IFS= read -r -n 1 byte; printf "%%s" "$byte" > %q; exec sleep 300' "$ready" "$received"
receiver_pane="$(tmux -L "$SOCKET" new-window -P -F '#{pane_id}' -t smoke: -n receiver bash --noprofile --norc -c "$receiver")"
for _attempt in {1..100}; do
  [[ -f "$ready" ]] && break
  sleep 0.02
done
[[ -f "$ready" ]] || fail 'Ctrl-Q receiver did not start'
invoke_binding root C-q
for _attempt in {1..100}; do
  [[ -s "$received" ]] && break
  sleep 0.02
done
[[ -s "$received" ]] || fail 'Ctrl-Q was swallowed outside Edit'
IFS= read -r -n 1 received_byte <"$received"
[[ "$received_byte" == $'\x11' ]] || fail 'Ctrl-Q was changed outside Edit'
tmux -L "$SOCKET" kill-window -t "$receiver_pane"
tmux -L "$SOCKET" kill-window -t "$editor"

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
printf 'PASS: Myran callers, native navigation/splits/zoom, warm editor, Ctrl-Q forwarding, safe reload\n'
