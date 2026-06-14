#!/usr/bin/env bash
set -euo pipefail

cwd="${1:-$PWD}"
window_prefix="${LAZYGIT_TMUX_WINDOW_PREFIX:-git}"
config_file="${LAZYGIT_CONFIG_FILE:-$HOME/dotfiles/lazygit/.config/lazygit/config.yml}"
lazygit_cmd=(lazygit)

if ! command -v lazygit >/dev/null 2>&1; then
    echo "lazygit not found" >&2
    exit 127
fi

if [[ -n "${TMUX:-}" && -f "$config_file" ]]; then
    lazygit_cmd+=(--use-config-file "$config_file")
fi

if git -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1; then
    cwd="$(git -C "$cwd" rev-parse --show-toplevel)"
fi

if [[ -z "${TMUX:-}" ]] || ! command -v tmux >/dev/null 2>&1; then
    cd "$cwd"
    exec "${lazygit_cmd[@]}"
fi

session="$(tmux display-message -p '#S')"
target="$(tmux list-windows -t "$session" -F '#{window_id}	#{@lazygit_root}' \
    | awk -F '\t' -v root="$cwd" '$2 == root { print $1; exit }')"

if [[ -n "$target" ]]; then
    tmux select-window -t "$target"
    exit 0
fi

window_name="$window_prefix:$(basename "$cwd")"
command="$(printf "%q " "${lazygit_cmd[@]}")"
window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$window_name" -c "$cwd" "$command")"
tmux set-option -w -t "$window_id" @lazygit_root "$cwd" >/dev/null
tmux select-window -t "$window_id"
