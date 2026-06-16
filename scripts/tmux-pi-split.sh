#!/usr/bin/env bash
set -euo pipefail

cwd="${1:-$PWD}"

if [[ ! -d "$cwd" ]]; then
    echo "not a directory: $cwd" >&2
    exit 1
fi

if [[ -z "${TMUX:-}" ]] || ! command -v tmux >/dev/null 2>&1; then
    cd "$cwd"
    exec pi
fi

if git -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1; then
    root="$(git -C "$cwd" rev-parse --show-toplevel)"
else
    root="$(cd "$cwd" && pwd -P)"
fi

session="$(tmux display-message -p '#S')"
target="$(tmux list-windows -t "$session" -F '#{window_id}	#{@project_role}	#{@project_root}' \
    | awk -F '\t' -v root="$root" '$2 == "pi" && $3 == root { print $1; exit }')"

if [[ -z "$target" ]]; then
    exec "$HOME/dotfiles/scripts/tmux-role-window.sh" pi "$root"
fi

pane_id="$(tmux split-window -h -P -F '#{pane_id}' -t "$target" -c "$root")"
tmux select-window -t "$target"
tmux select-pane -t "$pane_id"
tmux send-keys -t "$pane_id" pi Enter
