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

MYRAN_BINARY="${MYRAN_TEST_BINARY:-$(command -v myran)}"
mkdir -p "$TEST_ROOT/bin"
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
HOME="$TEST_ROOT/home" XDG_STATE_HOME="$TEST_ROOT/state" \
  tmux -L "$SOCKET" -f "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf" new-session -d -s smoke 'sleep 300'

for _attempt in {1..100}; do
  [[ -n "$(tmux -L "$SOCKET" show-option -gqv @myran.integration.bindings)" ]] && break
  sleep 0.05
done
[[ -n "$(tmux -L "$SOCKET" show-option -gqv @myran.integration.bindings)" ]] ||
  fail "Myran setup failed: $(tmux -L "$SOCKET" show-messages)"

hooks="$(tmux -L "$SOCKET" show-hooks -g)"
[[ "$hooks" != *request-reconcile* ]] || fail 'cooling hook remains'
[[ -z "$(tmux -L "$SOCKET" show-option -gqv @workspace_residency_mode)" ]] || fail 'cooling option remains'
[[ "$(tmux -L "$SOCKET" show-option -gqv @continuum-restore)" == on ]] || fail 'continuum restore is disabled'
binding="$(tmux -L "$SOCKET" list-keys -T prefix)"
[[ -z "$(printf '%s\n' "$binding" | awk '$4 == "I"')" ]] || fail 'retired cooling chord rebound by TPM'
[[ "$binding" != *workspace_residency_script*sleep* ]] || fail 'Workspace sleep binding remains'
reload_binding="$(printf '%s\n' "$binding" | grep -F 'T prefix ,' || true)"
[[ "$reload_binding" == *source-file*'.tmux.conf'* ]] || fail 'reload is not prefix ,'
run_focus="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +r ' || true)"
[[ "$run_focus" == *'select-window -t :run'* && "$run_focus" != *source-file* ]] || fail 'prefix r changed'
[[ "$binding" == *'__tmux-action run >/dev/null'* && "$binding" == *'__tmux-action pick-run >/dev/null'* ]] ||
  fail 'Myran-owned Run bindings missing'
for role in term edit agent git tracker actions; do
  [[ "$binding" == *"__tmux-action $role"* ]] || fail "missing role: $role"
done
[[ "$binding" != *tuxedo* && "$binding" != *toggle-workspace-pin* ]] || fail 'obsolete binding remains'
[[ "$binding" == *'#{q:pane_current_path}'* ]] || fail 'caller paths are not quoted'
agent="$(printf '%s\n' "$binding" | awk '$4 == "A"')"
[[ "$agent" == *'__tmux-action new-agent'* ]] || fail 'Agent popup is not Myran-owned'
[[ "$agent" != *command-prompt* ]] || fail 'Agent name interpolates through a prompt template'
for raw in s v S '|' '-'; do
  [[ "$(printf '%s\n' "$binding" | awk -v key="$raw" '$4 == key')" == *split-window* ]] ||
    fail "native split changed: $raw"
done

root_bindings="$(tmux -L "$SOCKET" list-keys -T root)"
[[ "$root_bindings" != *tuxedo* ]] || fail 'obsolete root binding remains'
[[ "$root_bindings" == *'@workspace_navigation'* && "$root_bindings" != *'ps -o state='* ]] ||
  fail 'navigation no longer uses metadata'
for key in Enter q Escape; do
  [[ -z "$(printf '%s\n' "$root_bindings" | awk -v key="$key" '$4 == key')" ]] ||
    fail "plain $key still intercepts command input"
done
ctrl_q="$(printf '%s\n' "$root_bindings" | grep -E 'bind-key +(-r )?-T root +C-q ' || true)"
prefix_q="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +q ' || true)"
for close in "$ctrl_q" "$prefix_q"; do
  [[ "$close" == *'TMUX_PANE=#{q:pane_id}'*'__tmux-action close-run'* ]] || fail 'Run close loses invoking pane'
done
mouse="$(printf '%s\n' "$root_bindings" | grep -F MouseDown1StatusLeft || true)"
[[ "$mouse" == *'__tmux-action workspace'* ]] || fail 'status picker bypasses Myran'
[[ -z "$(tmux -L "$SOCKET" show-option -gqv @workspace_residency_script)" ]] || fail 'callback helper remains'
style="$(tmux -L "$SOCKET" show-option -gv status-style)"
[[ "$style" == *'bg=#232136'* && "$style" == *'fg=#c9c5d9'* ]] || fail 'fallback theme changed'
status_right="$(tmux -L "$SOCKET" show-option -gqv status-right)"
[[ "$status_right" == *'#(true)'* && "$status_right" == *zoom* ]] || fail 'autosave/status styling lost'

# Native pane navigation must target the origin and stop at the window boundary.
left="$(tmux -L "$SOCKET" new-window -d -P -F '#{pane_id}' -t smoke: -n navigation 'sleep 300')"
window="$(tmux -L "$SOCKET" display-message -p -t "$left" '#{window_id}')"
right="$(tmux -L "$SOCKET" split-window -h -P -F '#{pane_id}' -t "$left" 'sleep 300')"
tmux -L "$SOCKET" if-shell -F -t "$right" '#{pane_at_left}' '' "select-pane -t $right -L"
[[ "$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')" == "$left" ]] || fail 'left navigation'
tmux -L "$SOCKET" if-shell -F -t "$left" '#{pane_at_left}' '' "select-pane -t $left -L"
[[ "$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')" == "$left" ]] || fail 'navigation wrapped'
tmux -L "$SOCKET" if-shell -F -t "$left" '#{pane_at_right}' '' "select-pane -t $left -R"
[[ "$(tmux -L "$SOCKET" display-message -p -t "$window" '#{pane_id}')" == "$right" ]] || fail 'right navigation'

# Reload neither adopts roots nor schedules cooling. It clears obsolete helper options.
tmux -L "$SOCKET" new-session -d -s unclassified -c "$TEST_ROOT" 'sleep 300'
unclassified="$(tmux -L "$SOCKET" display-message -p -t unclassified '#{session_id}')"
tmux -L "$SOCKET" set-option -g @workspace_project_script /obsolete/project
tmux -L "$SOCKET" set-option -g @workspace_session_script /obsolete/session
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" source-file "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf"
[[ -z "$(tmux -L "$SOCKET" show-option -qv -t "$unclassified" @workspace_root)" ]] || fail 'reload adopted root'
[[ -z "$(tmux -L "$SOCKET" show-option -qv -t "$unclassified" @workspace_residency_deadline)" ]] || fail 'reload scheduled cooling'
[[ -z "$(tmux -L "$SOCKET" show-option -gqv @workspace_project_script)" ]] || fail 'obsolete project option'
[[ -z "$(tmux -L "$SOCKET" show-option -gqv @workspace_session_script)" ]] || fail 'obsolete session option'
status_right="$(tmux -L "$SOCKET" show-option -gqv status-right)"
[[ "$status_right" == *'#(true)'* && "$status_right" != *'#(true)'*'#(true)'* ]] || fail 'autosave hook changed'
printf 'PASS: Myran callers, native navigation/splits, restore enabled, safe reload\n'
