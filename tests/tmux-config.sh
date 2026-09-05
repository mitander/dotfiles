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
  "$TEST_ROOT/home/dotfiles/extras/tmux" \
  "$TEST_ROOT/home/dotfiles/tmux/.tmux" \
  "$TEST_ROOT/home/.tmux/plugins/tpm" \
  "$TEST_ROOT/state"
cp "$SOURCE_ROOT/scripts/tmux-residency.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh"
cp "$SOURCE_ROOT/scripts/tmux-project.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh"
cp "$SOURCE_ROOT/scripts/tmux-nvim.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-nvim.sh"
cp "$SOURCE_ROOT/tmux/.tmux.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf"
cp "$SOURCE_ROOT/tmux/.tmux/workspace-status.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux/workspace-status.conf"
cp "$SOURCE_ROOT/extras/tmux/colors.conf" "$TEST_ROOT/home/dotfiles/extras/tmux/colors.conf"
chmod +x "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" \
  "$TEST_ROOT/home/dotfiles/scripts/tmux-nvim.sh"
printf '#!/bin/sh\nexit 0\n' >"$TEST_ROOT/home/.tmux/plugins/tpm/tpm"
chmod +x "$TEST_ROOT/home/.tmux/plugins/tpm/tpm"

HOME="$TEST_ROOT/home" XDG_STATE_HOME="$TEST_ROOT/state" \
  tmux -L "$SOCKET" -f "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf" new-session -d -s smoke

hook="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-hooks -g client-detached)"
[[ "$hook" == *'request-reconcile'* ]] || fail 'client-detached hook missing asynchronous reconciliation'
exit_hook="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-hooks -g pane-died)"
[[ "$exit_hook" != *'tmux-project.sh'* ]] || fail 'legacy run completion hook remains'
binding="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-keys -T prefix)"
[[ "$binding" == *workspace_residency_script*sleep* ]] || fail 'Workspace sleep binding missing'
reload_binding="$(printf '%s\n' "$binding" | grep -F 'T prefix +' || true)"
[[ "$reload_binding" == *'source-file'*'.tmux.conf'* ]] || fail 'reload is not bound to prefix +'
run_focus_binding="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +r ' || true)"
[[ "$run_focus_binding" == *'select-window -t :run'* ]] || fail 'prefix r does not focus the Myran run window'
[[ "$run_focus_binding" != *'source-file'* ]] || fail 'prefix r still reloads tmux'
[[ "$binding" == *'myr run'* && "$binding" == *'myr pick-run'* ]] || fail 'direct Myran run bindings missing'
[[ "$binding" == *'myr run >/dev/null 2>&1'* && "$binding" == *'myr pick-run >/dev/null 2>&1'* ]] || \
  fail 'Myran run output can force the selected pane into view mode'
agent_binding="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +a ' || true)"
[[ "$agent_binding" == *'myr role open agent'* ]] || fail 'direct Myran Agent RoleView binding missing'
tasks_binding="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +t ' || true)"
[[ "$tasks_binding" == *'@workspace_project_script'*tasks* ]] || fail 'tracker task window binding missing'
actions_binding="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +p ' || true)"
[[ "$actions_binding" == *'new-window'*'actions'*'gh observer --repo'* ]] || fail 'GitHub Actions watcher binding missing'
[[ "$binding" != *tuxedo* ]] || fail 'legacy Tuxedo prefix binding remains'
[[ "$agent_binding" == *'#{q:pane_current_path}'* ]] || fail 'Agent RoleView binding does not quote project paths'
[[ "$binding" == *'#{q:pane_current_path}'* ]] || fail 'Myran bindings do not quote project paths'
[[ "$binding" != *'tmux-project.sh run'* ]] || fail 'legacy run binding remains'
[[ "$binding" != *'tmux-project.sh agent'* ]] || fail 'legacy Agent RoleView binding remains'
[[ "$binding" != *'toggle-workspace-pin'* ]] || fail 'obsolete Workspace pin binding remains'
root_bindings="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-keys -T root)"
[[ "$root_bindings" != *tuxedo* ]] || fail 'legacy Tuxedo root binding remains'
[[ "$root_bindings" == *'@workspace_navigation'* ]] || fail 'metadata navigation binding missing'
[[ "$root_bindings" == *'@workspace_project_script'*close-run* ]] || fail 'central RunView close binding missing'
[[ "$root_bindings" == *'@myran.run.state'* ]] || fail 'Myran RunView dismissal state missing'
run_enter_binding="$(printf '%s\n' "$root_bindings" | grep -E 'bind-key +(-r )?-T root +Enter ' || true)"
[[ "$run_enter_binding" == *'@workspace_project_script'*close-run* && "$run_enter_binding" != *'kill-window'* ]] || \
  fail 'completed RunView Enter does not close only its pane'
run_ctrl_q_binding="$(printf '%s\n' "$root_bindings" | grep -E 'bind-key +(-r )?-T root +C-q ' || true)"
[[ "$run_ctrl_q_binding" == *'close-run'*'#{pane_id}'* ]] || \
  fail 'RunView Ctrl-q does not target the invoking pane'
prefix_q_binding="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +q ' || true)"
[[ "$prefix_q_binding" == *'close-run'*'#{pane_id}'* ]] || \
  fail 'RunView prefix-q does not target the invoking pane'
[[ "$root_bindings" != *'ps -o state='* ]] || fail 'navigation still probes processes on keypress'
status_mouse_binding="$(printf '%s\n' "$root_bindings" | grep -F 'MouseDown1StatusLeft' || true)"
[[ "$status_mouse_binding" == *'@workspace_session_script'* && "$status_mouse_binding" != *'~/dotfiles'* ]] || fail 'status workspace picker bypasses the configured command path'
script="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -gqv @workspace_residency_script)"
[[ "$script" == "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh" ]] || fail 'legacy residency fallback was not selected'
status_style="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -gv status-style)"
[[ "$status_style" == *'bg=#232136'* && "$status_style" == *'fg=#c9c5d9'* ]] || fail 'tracked fallback theme was not applied'

# Concurrent background mode switches still create only one role window.
mkdir -p "$TEST_ROOT/bin"
printf '#!/bin/sh\nsleep 5\n' >"$TEST_ROOT/bin/lazygit"
# Variables below belong to the generated scripts.
# shellcheck disable=SC2016
printf '#!/bin/sh\nprintf "linear:%%s:%%s\\n" "$TRACKER_SCOPE" "$TRACKER_REPOSITORY"\n' >"$TEST_ROOT/bin/ltui"
# shellcheck disable=SC2016
printf '#!/bin/sh\nprintf "jira:%%s:%%s\\n" "$TRACKER_SCOPE" "$TRACKER_REPOSITORY"\n' >"$TEST_ROOT/bin/jtui"
chmod +x "$TEST_ROOT/bin/lazygit" "$TEST_ROOT/bin/ltui" "$TEST_ROOT/bin/jtui"

tracker="$(env -u TMUX -u TMUX_PANE HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:$PATH" TRACKER_TUI=jira \
  "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" tasks "$TEST_ROOT")"
[[ "$tracker" == "jira::$(basename "$TEST_ROOT")" ]] || fail 'TRACKER_TUI did not select Jira'
tracker="$(env -u TMUX -u TMUX_PANE HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:$PATH" \
  "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" tasks "$TEST_ROOT" linear)"
[[ "$tracker" == "linear::$(basename "$TEST_ROOT")" ]] || fail 'explicit tracker did not select Linear'
mkdir -p "$TEST_ROOT/project"
git -C "$TEST_ROOT/project" init -q
git -C "$TEST_ROOT/project" config workspace.tracker jira
git -C "$TEST_ROOT/project" config workspace.tracker-team KAP
tracker="$(env -u TMUX -u TMUX_PANE HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:$PATH" \
  "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" tasks "$TEST_ROOT/project")"
[[ "$tracker" == "jira:KAP:project" ]] || fail 'repository config did not select Jira team'
git -C "$TEST_ROOT/project" config --unset workspace.tracker-team
git -C "$TEST_ROOT/project" checkout -q -b feature/OPS-42-test
tracker="$(env -u TMUX -u TMUX_PANE HOME="$TEST_ROOT/home" PATH="$TEST_ROOT/bin:$PATH" \
  "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" tasks "$TEST_ROOT/project")"
[[ "$tracker" == "jira:OPS:project" ]] || fail 'issue branch did not select tracker team'

socket_path="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" display-message -p -t smoke '#{socket_path}')"
server_pid="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" display-message -p -t smoke '#{pid}')"

# Legacy metadata, including delimiter characters, is migrated once. Windows
# without their own root inherit the migrated session root.
legacy_root="$TEST_ROOT/project|legacy"
mkdir -p "$legacy_root"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" new-session -d -s legacy -c "$legacy_root"
legacy_session="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" display-message -p -t legacy '#{session_id}')"
legacy_window="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" display-message -p -t legacy '#{window_id}')"
legacy_pane="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" display-message -p -t legacy '#{pane_id}')"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -q -t "$legacy_session" @workspace_root "$TEST_ROOT/missing-root"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -q -t "$legacy_session" @project_root "$legacy_root"
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -q -t "$legacy_session" @project_name 'legacy|name'
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -wq -t "$legacy_window" @project_role git
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" set-option -pq -t "$legacy_pane" @project_pane_role git
HOME="$TEST_ROOT/home" TMUX="$socket_path,$server_pid,0" TMUX_PANE="$legacy_pane" PATH="$TEST_ROOT/bin:$PATH" \
  DOTFILES_DIR="$TEST_ROOT/home/dotfiles" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" __refresh-status
[[ "$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -qv -t "$legacy_session" @workspace_root)" == "$legacy_root" ]] || fail 'legacy session root was not migrated safely'
[[ "$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -qv -t "$legacy_session" @workspace_name)" == 'legacy|name' ]] || fail 'legacy session name was not migrated safely'
[[ "$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -wqv -t "$legacy_window" @workspace_mode)" == git ]] || fail 'legacy window role did not inherit the session root'
[[ "$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -wqv -t "$legacy_window" @workspace_root)" == "$legacy_root" ]] || fail 'legacy window root was corrupted'
[[ "$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -pqv -t "$legacy_pane" @workspace_pane_role)" == git ]] || fail 'legacy pane role was not migrated'
[[ "$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -pqv -t "$legacy_pane" @workspace_root)" == "$legacy_root" ]] || fail 'legacy pane root was corrupted'
[[ -z "$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -wqv -t "$legacy_window" @project_role 2>/dev/null || true)" ]] || fail 'legacy window metadata remains'

# Session names containing tmux target punctuation must be addressed by ID.
HOME="$TEST_ROOT/home" tmux -L "$SOCKET" new-session -d -s smoke.test -c "$TEST_ROOT"
dotted_session_id="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-sessions -F '#{session_name}|#{session_id}' |
  awk -F '|' '$1 == "smoke.test" { print $2 }')"
dotted_pane="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-panes -t "$dotted_session_id" -F '#{pane_id}' | head -n 1)"
HOME="$TEST_ROOT/home" TMUX="$socket_path,$server_pid,0" TMUX_PANE="$dotted_pane" PATH="$TEST_ROOT/bin:$PATH" \
  DOTFILES_DIR="$TEST_ROOT/home/dotfiles" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" git "$TEST_ROOT"
dotted_role_windows="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-windows -t "$dotted_session_id" -F '#{@workspace_mode}' | grep -cx git)"
[[ "$dotted_role_windows" == 1 ]] || fail 'git mode failed in a dotted session name'

smoke_pane="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-panes -t smoke -F '#{pane_id}' | head -n 1)"
for _ in 1 2 3 4 5; do
  HOME="$TEST_ROOT/home" TMUX="$socket_path,$server_pid,0" TMUX_PANE="$smoke_pane" PATH="$TEST_ROOT/bin:$PATH" \
    DOTFILES_DIR="$TEST_ROOT/home/dotfiles" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh" git "$TEST_ROOT" &
done
wait
role_windows="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-windows -t smoke -F '#{@workspace_mode}' | grep -cx git)"
[[ "$role_windows" == 1 ]] || fail "concurrent mode switches created $role_windows git windows"

# The session-created hook is coalesced, then schedules the detached session.
for _ in $(seq 1 30); do
  deadline="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -qv -t smoke @workspace_residency_deadline 2>/dev/null || true)"
  [[ "$deadline" =~ ^[0-9]+$ ]] && break
  sleep 0.1
done
[[ "$deadline" =~ ^[0-9]+$ ]] || fail 'session-created hook did not reconcile the Workspace'

printf 'PASS: tmux residency and Myran RunView bindings\n'
