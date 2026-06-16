#!/usr/bin/env bash
set -euo pipefail

usage() {
    echo "usage: $(basename "$0") <edit|shell|pi> [cwd]" >&2
}

role="${1:-}"
cwd="${2:-$PWD}"

if [[ -z "$role" ]]; then
    usage
    exit 2
fi

if [[ ! -d "$cwd" ]]; then
    echo "not a directory: $cwd" >&2
    exit 1
fi

if git -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1; then
    root="$(git -C "$cwd" rev-parse --show-toplevel)"
else
    root="$(cd "$cwd" && pwd -P)"
fi

project="$(basename "$root")"

case "$role" in
    edit)
        window_name="edit:$project"
        command="nvim ."
        ;;
    shell|sh)
        role="shell"
        window_name="sh:$project"
        command=""
        ;;
    pi|agent|ai)
        role="pi"
        window_name="pi:$project"
        command="pi"
        ;;
    *)
        echo "unknown role: $role" >&2
        usage
        exit 2
        ;;
esac

if [[ -z "${TMUX:-}" ]] || ! command -v tmux >/dev/null 2>&1; then
    cd "$root"
    case "$role" in
        edit) exec nvim . ;;
        shell) exec "${SHELL:-fish}" ;;
        pi) exec pi ;;
    esac
fi

session="$(tmux display-message -p '#S')"
target="$(tmux list-windows -t "$session" -F '#{window_id}	#{@project_role}	#{@project_root}' \
    | awk -F '\t' -v role="$role" -v root="$root" '$2 == role && $3 == root { print $1; exit }')"

if [[ -n "$target" ]]; then
    tmux select-window -t "$target"
    exit 0
fi

if [[ "$role" == "pi" ]]; then
    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$window_name" -c "$root")"
elif [[ -n "$command" ]]; then
    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$window_name" -c "$root" "$command")"
else
    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$window_name" -c "$root")"
fi

tmux set-option -w -t "$window_id" automatic-rename off >/dev/null
tmux set-option -w -t "$window_id" @project_role "$role" >/dev/null
tmux set-option -w -t "$window_id" @project_root "$root" >/dev/null
tmux select-window -t "$window_id"

if [[ "$role" == "pi" ]]; then
    tmux send-keys -t "$window_id" "$command" Enter
fi
