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
cp "$SOURCE_ROOT/tmux/.tmux.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux.conf"
cp "$SOURCE_ROOT/tmux/.tmux/workspace-status.conf" "$TEST_ROOT/home/dotfiles/tmux/.tmux/workspace-status.conf"
cp "$SOURCE_ROOT/extras/tmux/colors.conf" "$TEST_ROOT/home/dotfiles/extras/tmux/colors.conf"
chmod +x "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh" "$TEST_ROOT/home/dotfiles/scripts/tmux-project.sh"
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
[[ "$agent_binding" == *'#{q:pane_current_path}'* ]] || fail 'Agent RoleView binding does not quote project paths'
[[ "$binding" == *'#{q:pane_current_path}'* ]] || fail 'Myran bindings do not quote project paths'
[[ "$binding" != *'tmux-project.sh run'* ]] || fail 'legacy run binding remains'
[[ "$binding" != *'tmux-project.sh agent'* ]] || fail 'legacy Agent RoleView binding remains'
[[ "$binding" != *'toggle-workspace-pin'* ]] || fail 'obsolete Workspace pin binding remains'
root_bindings="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" list-keys -T root)"
[[ "$root_bindings" == *'@workspace_navigation'* ]] || fail 'metadata navigation binding missing'
[[ "$root_bindings" == *'myr close-run'* ]] || fail 'Myran RunView close binding missing'
[[ "$root_bindings" == *'#{q:pane_current_path}'* ]] || fail 'RunView close binding does not quote project paths'
[[ "$root_bindings" == *'@myran.run.state'* ]] || fail 'Myran RunView dismissal state missing'
run_enter_binding="$(printf '%s\n' "$root_bindings" | grep -E 'bind-key +(-r )?-T root +Enter ' || true)"
[[ "$run_enter_binding" == *'myr close-run'* && "$run_enter_binding" != *'kill-window'* ]] || \
  fail 'completed RunView Enter does not close only its pane'
run_ctrl_q_binding="$(printf '%s\n' "$root_bindings" | grep -E 'bind-key +(-r )?-T root +C-q ' || true)"
[[ "$run_ctrl_q_binding" == *'TMUX_PANE=#{pane_id}'*'myr close-run'* ]] || \
  fail 'RunView Ctrl-q does not target the invoking pane'
prefix_q_binding="$(printf '%s\n' "$binding" | grep -E 'bind-key +(-r )?-T prefix +q ' || true)"
[[ "$prefix_q_binding" == *'TMUX_PANE=#{pane_id}'*'myr close-run'* ]] || \
  fail 'RunView prefix-q does not target the invoking pane'
[[ "$root_bindings" != *'ps -o state='* ]] || fail 'navigation still probes processes on keypress'
script="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -gqv @workspace_residency_script)"
[[ "$script" == "$TEST_ROOT/home/dotfiles/scripts/tmux-residency.sh" ]] || fail 'legacy residency fallback was not selected'
status_style="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -gv status-style)"
[[ "$status_style" == *'bg=#232136'* && "$status_style" == *'fg=#c9c5d9'* ]] || fail 'tracked fallback theme was not applied'

# The session-created hook is coalesced, then observes the detached session.
for _ in $(seq 1 30); do
  deadline="$(HOME="$TEST_ROOT/home" tmux -L "$SOCKET" show-option -qv -t smoke @workspace_residency_deadline 2>/dev/null || true)"
  [[ "$deadline" =~ ^[0-9]+$ ]] && break
  sleep 0.1
done
[[ "$deadline" =~ ^[0-9]+$ ]] || fail 'session-created hook did not reconcile the Workspace'

printf 'PASS: tmux residency and Myran RunView bindings\n'
