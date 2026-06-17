#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage: tmux-project <command> [args]

commands:
  session [cwd]
  shell [cwd]
  shell2 [cwd]
  vim [cwd]
  vim-open [--] [nvim-args...]
  agent|pi|ai [cwd]
  agent-split [cwd]
  git [cwd]
EOF
}

in_tmux() { [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; }

require_dir() {
    [[ -d "$1" ]] || { echo "not a directory: $1" >&2; exit 1; }
}

abspath() { cd "$1" && pwd -P; }

root_for_dir() {
    local cwd="${1:?missing cwd}"
    if git -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1; then
        git -C "$cwd" rev-parse --show-toplevel
    else
        abspath "$cwd"
    fi
}

workspace_root() {
    local cwd="${1:?missing cwd}" root session root_opt
    root="$(root_for_dir "$cwd")"

    if in_tmux; then
        session="$(tmux display-message -p '#S')"
        root_opt="$(tmux show-options -qv -t "$session" @project_root || true)"
        if [[ -n "$root_opt" && -d "$root_opt" ]]; then
            root="$root_opt"
        else
            tmux set-option -t "$session" @project_root "$root" >/dev/null
            tmux set-option -t "$session" @project_name "$(basename "$root")" >/dev/null
        fi
    fi

    printf '%s\n' "$root"
}

shell_quote() {
    printf "'"
    printf '%s' "$1" | sed "s/'/'\\\\''/g"
    printf "'"
}

quote_argv() {
    local arg first=1
    for arg in "$@"; do
        ((first)) || printf ' '
        shell_quote "$arg"
        first=0
    done
}

hash_key() {
    if command -v shasum >/dev/null 2>&1; then
        printf '%s' "$1" | shasum -a 256 | awk '{ print substr($1, 1, 20) }'
    else
        printf '%s' "$1" | cksum | awk '{ print $1 }'
    fi
}

find_role_window() {
    local session="$1" role="$2" format=$'#{window_id}\t#{@project_role}'
    tmux list-windows -t "$session" -F "$format" \
        | awk -F '\t' -v role="$role" '$2 == role { print $1; exit }'
}

attach_or_switch() {
    local target="${1:?missing session}"
    if [[ -n "${TMUX:-}" ]]; then
        exec tmux switch-client -t "$target"
    fi
    exec tmux attach-session -t "$target"
}

new_session() {
    local cwd="${1:-$PWD}" root project base name existing created session_id window_id
    require_dir "$cwd"

    root="$(root_for_dir "$cwd")"
    project="$(basename "$root")"
    base="$(printf '%s' "$project" | tr -c '[:alnum:]_.-' '_')"
    [[ -n "$base" ]] || base=project

    if tmux list-sessions >/dev/null 2>&1; then
        local format=$'#{session_id}\t#{@project_root}'
        existing="$(tmux list-sessions -F "$format" \
            | awk -F '\t' -v root="$root" '$2 == root { print $1; exit }')"
        [[ -n "$existing" ]] && attach_or_switch "$existing"
    fi

    name="$base"
    if tmux has-session -t "=$name" >/dev/null 2>&1; then
        name="$base-$(hash_key "$root" | cut -c1-8)"
    fi

    local format=$'#{session_id}\t#{window_id}'
    created="$(tmux new-session -d -P -F "$format" -s "$name" -n sh -c "$root")"
    session_id="${created%%$'\t'*}"
    window_id="${created#*$'\t'}"

    tmux set-option -t "$session_id" @project_root "$root" >/dev/null
    tmux set-option -t "$session_id" @project_name "$project" >/dev/null
    tmux set-option -w -t "$window_id" automatic-rename off >/dev/null
    tmux set-option -w -t "$window_id" @project_role shell >/dev/null
    tmux set-option -w -t "$window_id" @project_root "$root" >/dev/null

    attach_or_switch "$session_id"
}

role_window() {
    local role="${1:?missing role}" cwd="${2:-$PWD}" root name command session target window_id
    require_dir "$cwd"

    root="$(workspace_root "$cwd")"

    case "$role" in
        shell|sh) role=shell; name=sh; command= ;;
        shell2|sh2) role=shell2; name=sh2; command= ;;
        pi|agent|ai) role=pi; name=pi; command=pi ;;
        *) echo "unknown role: $role" >&2; exit 2 ;;
    esac

    if ! in_tmux; then
        cd "$root"
        case "$role" in
            shell|shell2) exec "${SHELL:-fish}" ;;
            pi) exec pi ;;
        esac
    fi

    session="$(tmux display-message -p '#S')"
    target="$(find_role_window "$session" "$role")"
    if [[ -n "$target" ]]; then
        tmux rename-window -t "$target" "$name"
        tmux select-window -t "$target"
        return
    fi

    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root")"
    tmux set-option -w -t "$window_id" automatic-rename off >/dev/null
    tmux set-option -w -t "$window_id" @project_role "$role" >/dev/null
    tmux set-option -w -t "$window_id" @project_root "$root" >/dev/null
    tmux select-window -t "$window_id"

    [[ -n "$command" ]] && tmux send-keys -t "$window_id" "$command" Enter
    return 0
}

agent_split() {
    local cwd="${1:-$PWD}" root session target pane_id
    require_dir "$cwd"

    if ! in_tmux; then
        cd "$cwd"
        exec pi
    fi

    root="$(workspace_root "$cwd")"
    session="$(tmux display-message -p '#S')"
    target="$(find_role_window "$session" pi)"

    if [[ -z "$target" ]]; then
        role_window pi "$root"
        return
    fi

    pane_id="$(tmux split-window -h -P -F '#{pane_id}' -t "$target" -c "$root")"
    tmux select-window -t "$target"
    tmux select-pane -t "$pane_id"
    tmux send-keys -t "$pane_id" pi Enter
}

nvim_runner() {
    local server="${1:?missing nvim server socket}" argfile="${2:-}" arg args=()
    if [[ -n "$argfile" ]]; then
        while IFS= read -r -d '' arg; do
            args+=("$arg")
        done <"$argfile"
        rm -f "$argfile"
    fi

    export TMUX_EDIT_BYPASS=1
    if [[ -n "${TMUX_PANE:-}" ]] && command -v tmux >/dev/null 2>&1; then
        tmux set-option -w -t "$TMUX_PANE" @project_vim_pane "$TMUX_PANE" >/dev/null 2>&1 || true
    fi
    exec nvim --listen "$server" "${args[@]}"
}

vim_window() {
    local cwd="$1"; shift
    local args=("$@")
    local root name start_cwd session session_id server target saved_server window_id vim_pane new_pane
    require_dir "$cwd"

    root="$(workspace_root "$cwd")"
    name=vim
    start_cwd="$root"
    ((${#args[@]})) && start_cwd="$(abspath "$cwd")"

    if ! in_tmux; then
        cd "$start_cwd"
        exec nvim "${args[@]}"
    fi

    session="$(tmux display-message -p '#S')"
    session_id="$(tmux display-message -p '#{session_id}')"
    server="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/tmux-project-${UID:-$(id -u)}/nvim-$(hash_key "${TMUX%%,*}:$session_id:$root").sock"
    mkdir -p "$(dirname "$server")"

    make_argfile() {
        local argfile
        argfile="$(mktemp "${TMPDIR:-/tmp}/tmux-project.XXXXXX")"
        printf '%s\0' "${args[@]}" >"$argfile"
        printf '%s' "$argfile"
    }

    start_command() {
        local cmd
        cmd="$(shell_quote "$HOME/dotfiles/scripts/tmux-project.sh") __nvim $(shell_quote "$server")"
        ((${#args[@]})) && cmd="$cmd $(shell_quote "$(make_argfile)")"
        printf '%s' "$cmd"
    }

    server_alive() {
        [[ -S "$server" ]] && env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote-expr '1' >/dev/null 2>&1
    }

    clean_server() {
        if [[ -e "$server" ]] && ! server_alive; then
            rm -f "$server"
        fi
    }

    remote_open() {
        (cd "$start_cwd" && env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote-tab-silent "${args[@]}") >/dev/null 2>&1
    }

    remote_focus() {
        env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote-expr \
            'system("tmux select-pane -t " . shellescape($TMUX_PANE))' >/dev/null 2>&1
    }

    find_vim_pane() {
        local target_window="$1" saved pane tty

        saved="$(tmux show-options -wqv -t "$target_window" @project_vim_pane || true)"
        if [[ -n "$saved" ]] && tmux display-message -p -t "$saved" '#{pane_id}' >/dev/null 2>&1; then
            printf '%s\n' "$saved"
            return 0
        fi

        while IFS=$'\t' read -r pane tty; do
            if ps -o state= -o comm= -t "$tty" 2>/dev/null \
                | grep -iqE '^[^TXZ ]+ +(\S+/)?g?(view|n?vim?x?)(diff)?$'; then
                printf '%s\n' "$pane"
                return 0
            fi
        done < <(tmux list-panes -t "$target_window" -F '#{pane_id}\t#{pane_tty}')
    }

    target="$(find_role_window "$session" vim)"
    if [[ -n "$target" ]]; then
        tmux rename-window -t "$target" "$name"
        saved_server="$(tmux show-options -wqv -t "$target" @project_vim_server || true)"
        [[ -n "$saved_server" ]] && server="$saved_server"
    fi

    if [[ -z "$target" ]]; then
        clean_server
        window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$start_cwd" "$(start_command)")"
        tmux set-option -w -t "$window_id" automatic-rename off >/dev/null
        tmux set-option -w -t "$window_id" @project_role vim >/dev/null
        tmux set-option -w -t "$window_id" @project_root "$root" >/dev/null
        tmux set-option -w -t "$window_id" @project_vim_server "$server" >/dev/null
        tmux select-window -t "$window_id"
        return
    fi

    tmux set-option -w -t "$target" @project_vim_server "$server" >/dev/null
    tmux select-window -t "$target"

    if ((${#args[@]})); then
        if [[ -S "$server" ]]; then
            vim_pane="$(find_vim_pane "$target")"
            [[ -n "$vim_pane" ]] && tmux select-pane -t "$vim_pane"
            (
                remote_focus || true
                if remote_open; then
                    remote_focus || true
                else
                    rm -f "$server"
                    new_pane="$(tmux split-window -h -P -F '#{pane_id}' -t "$target" -c "$start_cwd" "$(start_command)")"
                    tmux select-pane -t "$new_pane"
                fi
            ) >/dev/null 2>&1 &
        else
            rm -f "$server"
            new_pane="$(tmux split-window -h -P -F '#{pane_id}' -t "$target" -c "$start_cwd" "$(start_command)")"
            tmux select-pane -t "$new_pane"
        fi
    else
        vim_pane="$(find_vim_pane "$target")"
        [[ -n "$vim_pane" ]] && tmux select-pane -t "$vim_pane"
    fi
}

git_window() {
    local cwd="${1:-$PWD}" root config_file session target name cmd window_id lazygit_cmd
    require_dir "$cwd"
    command -v lazygit >/dev/null 2>&1 || { echo "lazygit not found" >&2; exit 127; }

    root="$(root_for_dir "$cwd")"
    config_file="${LAZYGIT_CONFIG_FILE:-$HOME/dotfiles/lazygit/.config/lazygit/config.yml}"
    lazygit_cmd=(lazygit)
    if in_tmux && [[ -f "$config_file" ]]; then
        lazygit_cmd+=(--use-config-file "$config_file")
    fi

    if ! in_tmux; then
        cd "$root"
        exec "${lazygit_cmd[@]}"
    fi

    session="$(tmux display-message -p '#S')"
    local format=$'#{window_id}\t#{@lazygit_root}'
    target="$(tmux list-windows -t "$session" -F "$format" \
        | awk -F '\t' -v root="$root" '$2 == root { print $1; exit }')"

    if [[ -n "$target" ]]; then
        name="${LAZYGIT_TMUX_WINDOW_PREFIX:-git}"
        tmux rename-window -t "$target" "$name"
        tmux select-window -t "$target"
        return
    fi

    name="${LAZYGIT_TMUX_WINDOW_PREFIX:-git}"
    cmd="$(quote_argv "${lazygit_cmd[@]}")"
    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root" "$cmd")"
    tmux set-option -w -t "$window_id" automatic-rename off >/dev/null
    tmux set-option -w -t "$window_id" @lazygit_root "$root" >/dev/null
    tmux select-window -t "$window_id"
}

cmd="${1:-}"
[[ -n "$cmd" ]] || { usage; exit 2; }
shift || true

case "$cmd" in
    session|new-session) new_session "${1:-$PWD}" ;;
    shell|sh) role_window shell "${1:-$PWD}" ;;
    shell2|sh2) role_window shell2 "${1:-$PWD}" ;;
    agent|pi|ai) role_window pi "${1:-$PWD}" ;;
    agent-split|pi-split) agent_split "${1:-$PWD}" ;;
    vim) vim_window "${1:-$PWD}" ;;
    vim-open)
        [[ "${1:-}" == -- ]] && shift
        vim_window "$PWD" "$@"
        ;;
    git|lazygit) git_window "${1:-$PWD}" ;;
    __nvim) nvim_runner "$@" ;;
    help|-h|--help) usage ;;
    *) echo "unknown command: $cmd" >&2; usage; exit 2 ;;
esac
