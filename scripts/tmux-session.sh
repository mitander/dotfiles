#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: tmux-session.sh switch|attach" >&2
}

command -v tmux >/dev/null 2>&1 || { echo "tmux not found" >&2; exit 127; }

if [[ -n "${TMUX:-}" ]] && command -v fzf-tmux >/dev/null 2>&1; then
  picker=(fzf-tmux -p 80%,70% --header='Select a tmux session. Click a session to switch, or click outside to cancel.' --bind 'left-click:accept')
elif command -v fzf >/dev/null 2>&1; then
  picker=(fzf --header='Select a tmux session. Click a session to switch.' --bind 'left-click:accept')
else
  echo "fzf not found" >&2
  exit 127
fi

sessions="$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)"
current_session="$(tmux display-message -p '#S' 2>/dev/null || true)"

case "${1:-}" in
  switch)
    command_name=switch-client
    sessions="$(printf '%s\n' "$sessions" | grep -vxF "$current_session" || true)"
    ;;
  attach)
    command_name=attach-session
    ;;
  help|-h|--help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

set +e
selection="$(printf '%s\n[cancel]\n' "$sessions" | "${picker[@]}")"
picker_status=$?
set -e

# fzf exits 130 on Escape/Ctrl-C and 1 on no match. Treat picker cancellation as
# a clean no-op so tmux does not show an error.
[[ $picker_status -ne 0 || "$selection" == "[cancel]" || -z "$selection" ]] && exit 0
exec tmux "$command_name" -t "$selection"
