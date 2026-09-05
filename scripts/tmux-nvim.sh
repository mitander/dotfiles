#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage: tmux-nvim run <server> [argfile]
       tmux-nvim alive <server>
       tmux-nvim open <server> <cwd> [-- args...]
       tmux-nvim focus <server>
       tmux-nvim find-pane <window-id>
EOF
}

run_server() {
    local server="${1:?missing nvim server socket}" argfile="${2:-}" arg args=()
    if [[ -n "$argfile" ]]; then
        while IFS= read -r -d '' arg; do
            args+=("$arg")
        done <"$argfile"
        rm -f "$argfile"
    fi

    export TMUX_EDIT_BYPASS=1
    if [[ -n "${TMUX_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
        tmux set-option -w -t "$TMUX_PANE" @workspace_vim_pane "$TMUX_PANE" >/dev/null 2>&1 || true
        tmux set-option -p -t "$TMUX_PANE" @workspace_pane_role vim >/dev/null 2>&1 || true
    fi
    if [[ -n "$argfile" ]]; then
        exec nvim --listen "$server" "${args[@]}"
    fi
    exec nvim --listen "$server"
}

server_alive() {
    local server="${1:?missing nvim server socket}"
    [[ -S "$server" ]] && env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote-expr '1' >/dev/null 2>&1
}

remote_open() {
    local server="${1:?missing nvim server socket}" cwd="${2:?missing cwd}"
    shift 2
    [[ "${1:-}" == -- ]] && shift
    cd "$cwd"
    env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote-tab-silent "$@" >/dev/null 2>&1
}

remote_focus() {
    local server="${1:?missing nvim server socket}"
    # The expression is evaluated by Neovim, not this shell.
    # shellcheck disable=SC2016
    env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote-expr \
        'system("tmux select-pane -t " . shellescape($TMUX_PANE))' >/dev/null 2>&1
}

find_vim_pane() {
    local target_window="${1:?missing window}" saved pane tty
    saved="$(tmux show-options -wqv -t "$target_window" @workspace_vim_pane || true)"
    if [[ -n "$saved" ]] && tmux display-message -p -t "$saved" '#{pane_id}' >/dev/null 2>&1; then
        printf '%s\n' "$saved"
        return 0
    fi

    while IFS=$'\t' read -r pane tty; do
        # We need terminal state and command together; pgrep is not equivalent.
        # shellcheck disable=SC2009
        if ps -o state= -o comm= -t "$tty" 2>/dev/null |
            grep -iqE '^[^TXZ ]+ +(\S+/)?g?(view|n?vim?x?)(diff)?$'; then
            printf '%s\n' "$pane"
            return 0
        fi
    done < <(tmux list-panes -t "$target_window" -F '#{pane_id}\t#{pane_tty}')
}

command_name="${1:-}"
[[ -n "$command_name" ]] || {
    usage
    exit 2
}
shift
case "$command_name" in
run) run_server "$@" ;;
alive) server_alive "$@" ;;
open) remote_open "$@" ;;
focus) remote_focus "$@" ;;
find-pane) find_vim_pane "$@" ;;
help | -h | --help) usage ;;
*)
    printf 'unknown command: %s\n' "$command_name" >&2
    usage
    exit 2
    ;;
esac
