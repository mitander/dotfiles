#!/usr/bin/env bash
set -euo pipefail

SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"
TMUX_NVIM_HELPER="${TMUX_NVIM_HELPER:-$DOTFILES_DIR/scripts/tmux-nvim.sh}"
TMUX_RESIDENCY_HELPER="${TMUX_RESIDENCY_HELPER:-$DOTFILES_DIR/scripts/tmux-residency.sh}"

usage() {
    cat >&2 <<'EOF'
usage: tmux-project <command> [args]

commands:
  session [cwd]
  shell [cwd]
  shell2 [cwd]
  vim [cwd]
  vim-split [cwd]
  vim-open [--] [nvim-args...]
  pi [cwd]
  pi-split [cwd]
  pane-to pi|shell|vim|git [cwd]
  promote-pane
  close-run [pane-id]
  normalize-layout [target-window]
  git [cwd]
  git-split [cwd]
  tasks [cwd] [linear|jira]
  linear-tasks [cwd]
  jira-tasks [cwd]
EOF
}

in_tmux() { [[ -n "${TMUX:-}" ]] && command -v tmux >/dev/null 2>&1; }

require_dir() {
    [[ -d "$1" ]] || {
        echo "not a directory: $1" >&2
        exit 1
    }
}

abspath() { cd "$1" && pwd -P; }

root_for_dir() {
    local cwd="${1:?missing cwd}" root
    if root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)"; then
        printf '%s\n' "$root"
    else
        abspath "$cwd"
    fi
}

workspace_name_for_root() {
    basename "$1"
}

set_session_workspace() {
    local session="${1:?missing session}" root="${2:?missing root}" name
    name="$(workspace_name_for_root "$root")"

    tmux set-option -q -t "$session" @workspace_root "$root" \; \
        set-option -q -t "$session" @workspace_name "$name"
}

workspace_mode_label() {
    case "$1" in
    vim) printf 'edit' ;;
    pi) printf 'agent' ;;
    git) printf 'git' ;;
    tasks) printf 'tasks' ;;
    shell) printf 'term' ;;
    shell2) printf 'term2' ;;
    run) printf 'run' ;;
    *) printf '%s' "$1" ;;
    esac
}

workspace_mode_color() {
    local role
    case "$1" in
    vim | pi | git | run | tasks | shell | shell2) role=accent ;;
    *) role=text ;;
    esac
    tmux show-option -gv "@flume_$role"
}

set_window_workspace_mode() {
    local target="${1:?missing window}" mode="${2:?missing mode}" root="${3:?missing root}" label color
    label="$(workspace_mode_label "$mode")"
    color="$(workspace_mode_color "$mode")"

    tmux set-option -wq -t "$target" automatic-rename off \; \
        set-option -wq -t "$target" @workspace_mode "$mode" \; \
        set-option -wq -t "$target" @workspace_mode_label "$label" \; \
        set-option -wq -t "$target" @workspace_mode_color "$color" \; \
        set-option -wq -t "$target" @workspace_root "$root"
}

set_pane_workspace_role() {
    local target="${1:?missing pane}" role="${2:?missing role}" root="${3:?missing root}" label color
    label="$(workspace_mode_label "$role")"
    color="$(workspace_mode_color "$role")"

    tmux set-option -pq -t "$target" @workspace_pane_role "$role" \; \
        set-option -pq -t "$target" @workspace_pane_role_label "$label" \; \
        set-option -pq -t "$target" @workspace_pane_role_color "$color" \; \
        set-option -pq -t "$target" @workspace_root "$root"
}

active_pane_in_window() {
    local target="${1:?missing window}"
    tmux list-panes -t "$target" -F '#{pane_active}	#{pane_id}' |
        awk -F '\t' '$1 == "1" { print $2; exit }'
}

main_pane_in_window() {
    local target="${1:?missing window}"
    tmux list-panes -t "$target" -F '#{pane_id}	#{pane_left}	#{pane_top}' |
        sort -t $'\t' -k2,2n -k3,3n |
        awk -F '\t' 'NR == 1 { print $1 }'
}

side_stack_pane_in_window() {
    local target="${1:?missing window}"
    tmux list-panes -t "$target" -F '#{pane_id}	#{pane_left}	#{pane_top}' |
        sort -t $'\t' -k2,2nr -k3,3nr |
        awk -F '\t' 'NR == 1 { print $1 }'
}

pane_count_for_window() {
    tmux list-panes -t "${1:?missing window}" 2>/dev/null | wc -l | tr -d ' '
}

normalize_role_layout() {
    local target="${1:-}" pane_count window_width main_width
    [[ -n "$target" ]] || target="$(tmux display-message -p '#{window_id}')"

    # Role splits use readable columns; raw tmux splits remain free-form.
    pane_count="$(pane_count_for_window "$target")"
    if [[ "$pane_count" -eq 2 ]]; then
        tmux select-layout -t "$target" even-horizontal >/dev/null 2>&1 || true
    elif [[ "$pane_count" -gt 2 ]]; then
        window_width="$(tmux display-message -p -t "$target" '#{window_width}' 2>/dev/null || printf 0)"
        if [[ "$window_width" =~ ^[0-9]+$ && "$window_width" -gt 0 ]]; then
            main_width=$((window_width / 2))
            tmux set-option -w -t "$target" main-pane-width "$main_width" >/dev/null 2>&1 || true
        fi
        tmux select-layout -t "$target" main-vertical >/dev/null 2>&1 || true
    fi
}

split_role_pane() {
    local target="${1:?missing window}" root="${2:?missing root}" command="${3:-}" split_target pane_count

    normalize_role_layout "$target"
    pane_count="$(pane_count_for_window "$target")"
    if [[ "$pane_count" -le 1 ]]; then
        split_target="$target"
        if [[ -n "$command" ]]; then
            tmux split-window -h -P -F '#{pane_id}' -t "$split_target" -c "$root" "$command"
        else
            tmux split-window -h -P -F '#{pane_id}' -t "$split_target" -c "$root"
        fi
    else
        split_target="$(side_stack_pane_in_window "$target")"
        if [[ -n "$command" ]]; then
            tmux split-window -v -P -F '#{pane_id}' -t "$split_target" -c "$root" "$command"
        else
            tmux split-window -v -P -F '#{pane_id}' -t "$split_target" -c "$root"
        fi
    fi
}

workspace_root() {
    local cwd="${1:?missing cwd}" root session configured_root
    root="$(root_for_dir "$cwd")"

    if in_tmux; then
        session="$(tmux display-message -p '#{session_id}')"
        configured_root="$(tmux show-options -qv -t "$session" @workspace_root || true)"
        if [[ -n "$configured_root" && -d "$configured_root" ]]; then
            root="$configured_root"
        fi
        set_session_workspace "$session" "$root"
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

lazygit_config_files() {
    local files="" base_config theme_config tmux_config

    if [[ -n "${LAZYGIT_CONFIG_FILE:-}" ]]; then
        files="$LAZYGIT_CONFIG_FILE"
    else
        base_config="$DOTFILES_DIR/lazygit/.config/lazygit/config.yml"
        [[ -f "$base_config" ]] && files="$base_config"
    fi

    theme_config="${LAZYGIT_THEME_CONFIG_FILE:-$DOTFILES_DIR/themes/flume/extras/current/lazygit.yml}"
    if [[ -f "$theme_config" ]]; then
        [[ -n "$files" ]] && files+=","
        files+="$theme_config"
    fi

    if in_tmux; then
        tmux_config="${LAZYGIT_TMUX_CONFIG_FILE:-$DOTFILES_DIR/lazygit/.config/lazygit/tmux.yml}"
        if [[ -f "$tmux_config" ]]; then
            [[ -n "$files" ]] && files+=","
            files+="$tmux_config"
        fi
    fi

    printf '%s\n' "$files"
}

hash_key() {
    if command -v shasum >/dev/null 2>&1; then
        printf '%s' "$1" | shasum -a 256 | awk '{ print substr($1, 1, 20) }'
    else
        printf '%s' "$1" | cksum | awk '{ print $1 }'
    fi
}

nvim_server_dir() {
    local base uid="${UID:-$(id -u)}"
    base="${TMUX_PROJECT_RUNTIME_DIR:-${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/tmux-project-$uid}"
    # sockaddr_un paths are only 104 bytes on macOS. Leave room for the hashed
    # socket name instead of letting Neovim silently choose a different address.
    if ((${#base} > 70)); then
        base="/tmp/tmux-project-$uid"
    fi
    if [[ -e "$base" && ! -O "$base" ]]; then
        echo "unsafe Neovim runtime directory owner: $base" >&2
        return 1
    fi
    mkdir -p "$base"
    chmod 700 "$base"
    printf '%s\n' "$base"
}

find_role_window() {
    local session="$1" role="$2" format=$'#{window_id}\t#{@workspace_mode}'
    tmux list-windows -t "$session" -F "$format" |
        awk -F '\t' -v role="$role" '$2 == role { print $1; exit }'
}

# Ensure exactly one window owns a workspace role. Results are returned through
# globals so callers can add role-specific state without repeating lifecycle code.
ensure_role_window() {
    local session="${1:?missing session}" role="${2:?missing role}" root="${3:?missing root}"
    local name="${4:?missing name}" create_command="${5:-}"

    local owns_lock=0
    if [[ -z "${ROLE_WINDOW_LOCK:-}" ]]; then
        lock_role_window "$session" "$role"
        owns_lock=1
    fi
    ROLE_WINDOW_ID="$(find_role_window "$session" "$role")"
    ROLE_WINDOW_CREATED=0
    if [[ -z "$ROLE_WINDOW_ID" ]]; then
        if [[ -n "$create_command" ]] && declare -F "$create_command" >/dev/null; then
            create_command="$($create_command)"
        fi
        if [[ -n "$create_command" ]]; then
            ROLE_WINDOW_ID="$(tmux new-window -d -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root" "$create_command")"
        else
            ROLE_WINDOW_ID="$(tmux new-window -d -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root")"
        fi
        ROLE_WINDOW_CREATED=1
    else
        tmux rename-window -t "$ROLE_WINDOW_ID" "$name" >/dev/null
    fi

    set_window_workspace_mode "$ROLE_WINDOW_ID" "$role" "$root"
    ROLE_PANE_ID="$(active_pane_in_window "$ROLE_WINDOW_ID")"
    [[ -n "$ROLE_PANE_ID" ]] && set_pane_workspace_role "$ROLE_PANE_ID" "$role" "$root"
    if ((owns_lock)); then
        unlock_role_window
    fi
}

lock_role_window() {
    ROLE_WINDOW_LOCK="tmux-project:$(tmux display-message -p -t "$1" '#{session_id}'):$2"
    tmux wait-for -L "$ROLE_WINDOW_LOCK"
    trap 'tmux wait-for -U "$ROLE_WINDOW_LOCK" >/dev/null 2>&1 || true' EXIT
}

unlock_role_window() {
    tmux wait-for -U "$ROLE_WINDOW_LOCK"
    trap - EXIT
    ROLE_WINDOW_LOCK=
}

ensure_shell_window() {
    local session="${1:?missing session}" root="${2:?missing root}"

    set_session_workspace "$session" "$root"
    ensure_role_window "$session" shell "$root" term
    tmux select-window -t "$ROLE_WINDOW_ID" >/dev/null
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
        local format=$'#{session_id}\t#{@workspace_root}'
        existing="$(tmux list-sessions -F "$format" |
            awk -F '\t' -v root="$root" '$2 == root { print $1; exit }')"
        if [[ -n "$existing" ]]; then
            ensure_shell_window "$existing" "$root"
            attach_or_switch "$existing"
        fi
    fi

    name="$base"
    if tmux has-session -t "=$name" >/dev/null 2>&1; then
        name="$base-$(hash_key "$root" | cut -c1-8)"
    fi

    local format=$'#{session_id}\t#{window_id}'
    created="$(tmux new-session -d -P -F "$format" -s "$name" -n sh -c "$root")"
    session_id="${created%%$'\t'*}"
    window_id="${created#*$'\t'}"

    set_session_workspace "$session_id" "$root"
    set_window_workspace_mode "$window_id" shell "$root"
    ensure_shell_window "$session_id" "$root"

    attach_or_switch "$session_id"
}

role_window() {
    local role="${1:?missing role}" cwd="${2:-$PWD}" root name command session
    require_dir "$cwd"

    root="$(workspace_root "$cwd")"

    case "$role" in
    shell | sh)
        role=shell
        name=term
        command=
        ;;
    shell2 | sh2)
        role=shell2
        name=term2
        command=
        ;;
    pi | agent | ai)
        role=pi
        name=agent
        command=pi
        ;;
    *)
        echo "unknown role: $role" >&2
        exit 2
        ;;
    esac

    if ! in_tmux; then
        cd "$root"
        case "$role" in
        shell | shell2) exec "${SHELL:-fish}" ;;
        pi) exec pi ;;
        esac
    fi

    session="$(tmux display-message -p '#{session_id}')"
    ensure_role_window "$session" "$role" "$root" "$name"
    if [[ "$ROLE_WINDOW_CREATED" == 1 && -n "$command" ]]; then
        tmux send-keys -t "$ROLE_WINDOW_ID" "$command" Enter
    fi
    tmux select-window -t "$ROLE_WINDOW_ID"
    return 0
}

pi_split() {
    local cwd="${1:-$PWD}" root session target pane_id
    require_dir "$cwd"

    if ! in_tmux; then
        cd "$cwd"
        exec pi
    fi

    root="$(workspace_root "$cwd")"
    session="$(tmux display-message -p '#{session_id}')"
    target="$(find_role_window "$session" pi)"

    if [[ -z "$target" ]]; then
        role_window pi "$root"
        return
    fi

    tmux select-window -t "$target"
    pane_id="$(split_role_pane "$target" "$root")"
    set_pane_workspace_role "$pane_id" pi "$root"
    normalize_role_layout "$target"
    tmux select-window -t "$target"
    tmux select-pane -t "$pane_id"
    tmux send-keys -t "$pane_id" pi Enter
}

agent_new() {
    local cwd="${1:-$PWD}" task="${2:-}" root session window_id pane_id name
    require_dir "$cwd"
    root="$(workspace_root "$cwd")"
    
    if [[ -z "$task" ]]; then
        task="run"
    fi
    
    if ! in_tmux; then
        cd "$root"
        exec pi --name "$task"
    fi
    
    session="$(tmux display-message -p '#{session_id}')"
    name="ai:${task}"
    
    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root")"
    set_window_workspace_mode "$window_id" pi "$root"
    tmux set-option -w -t "$window_id" @workspace_mode_label "$name" >/dev/null
    
    pane_id="$(active_pane_in_window "$window_id")"
    [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" pi "$root"
    tmux select-window -t "$window_id"
    
    tmux send-keys -t "$window_id" "pi --name $(shell_quote "$task")" Enter
}

vim_window() {
    local cwd="$1"
    shift
    local arg_count=$# args=("$@")
    local root name start_cwd session session_id server target saved_server vim_pane new_pane
    require_dir "$cwd"

    root="$(workspace_root "$cwd")"
    name=edit
    start_cwd="$root"
    ((arg_count)) && start_cwd="$(abspath "$cwd")"

    if ! in_tmux; then
        cd "$start_cwd"
        ((arg_count)) && exec nvim "${args[@]}"
        exec nvim
    fi

    session="$(tmux display-message -p '#{session_id}')"
    session_id="$session"
    server="$(nvim_server_dir)/nvim-$(hash_key "${TMUX%%,*}:$session_id:$root").sock"

    make_argfile() {
        local argfile
        argfile="$(mktemp "${TMPDIR:-/tmp}/tmux-project.XXXXXX")"
        printf '%s\0' "${args[@]}" >"$argfile"
        printf '%s' "$argfile"
    }

    start_command() {
        local cmd
        cmd="$(shell_quote "$TMUX_NVIM_HELPER") run $(shell_quote "$server")"
        ((arg_count)) && cmd="$cmd $(shell_quote "$(make_argfile)")"
        printf '%s' "$cmd"
    }

    server_alive() {
        "$TMUX_NVIM_HELPER" alive "$server"
    }

    fresh_server() {
        printf '%s/nvim-%s.sock\n' "$(nvim_server_dir)" \
            "$(hash_key "${TMUX%%,*}:$session_id:$root:recovery:$RANDOM:$$")"
    }

    remote_open() {
        "$TMUX_NVIM_HELPER" open "$server" "$start_cwd" -- "${args[@]}"
    }

    remote_focus() {
        "$TMUX_NVIM_HELPER" focus "$server"
    }

    find_vim_pane() {
        "$TMUX_NVIM_HELPER" find-pane "$1"
    }

    lock_role_window "$session" vim
    # Never unlink a socket after a failed health probe. An address collision is
    # cheap; orphaning an editor with unsaved state is not.
    [[ -e "$server" ]] && server="$(fresh_server)"
    ensure_role_window "$session" vim "$start_cwd" "$name" start_command
    target="$ROLE_WINDOW_ID"
    if [[ "$ROLE_WINDOW_CREATED" == 1 ]]; then
        tmux set-option -w -t "$target" @workspace_root "$root" \; \
            set-option -w -t "$target" @workspace_vim_server "$server" >/dev/null
        [[ -n "$ROLE_PANE_ID" ]] && set_pane_workspace_role "$ROLE_PANE_ID" vim "$root"
        unlock_role_window
        tmux select-window -t "$target"
        return
    fi

    saved_server="$(tmux show-options -wqv -t "$target" @workspace_vim_server || true)"
    [[ -n "$saved_server" ]] && server="$saved_server"
    tmux set-option -w -t "$target" @workspace_vim_server "$server" >/dev/null
    unlock_role_window
    tmux select-window -t "$target"

    if ((arg_count)); then
        if [[ -S "$server" ]]; then
            vim_pane="$(find_vim_pane "$target")"
            [[ -n "$vim_pane" ]] && tmux select-pane -t "$vim_pane"
            (
                remote_focus || true
                if remote_open; then
                    remote_focus || true
                else
                    lock_role_window "$session" vim
                    # Another caller may have repaired the role while we waited.
                    saved_server="$(tmux show-options -wqv -t "$target" @workspace_vim_server || true)"
                    [[ -n "$saved_server" ]] && server="$saved_server"
                    if ! server_alive || ! remote_open; then
                        server="$(fresh_server)"
                        new_pane="$(tmux split-window -h -P -F '#{pane_id}' -t "$target" -c "$start_cwd" "$(start_command)")"
                        set_pane_workspace_role "$new_pane" vim "$root"
                        tmux set-option -wq -t "$target" @workspace_vim_server "$server"
                        normalize_role_layout "$target"
                        tmux select-pane -t "$new_pane"
                    fi
                    unlock_role_window
                fi
            ) >/dev/null 2>&1 &
        else
            lock_role_window "$session" vim
            saved_server="$(tmux show-options -wqv -t "$target" @workspace_vim_server || true)"
            [[ -n "$saved_server" ]] && server="$saved_server"
            if ! server_alive; then
                server="$(fresh_server)"
                new_pane="$(tmux split-window -h -P -F '#{pane_id}' -t "$target" -c "$start_cwd" "$(start_command)")"
                set_pane_workspace_role "$new_pane" vim "$root"
                tmux set-option -wq -t "$target" @workspace_vim_server "$server"
                normalize_role_layout "$target"
                tmux select-pane -t "$new_pane"
            fi
            unlock_role_window
        fi
    else
        vim_pane="$(find_vim_pane "$target")"
        [[ -n "$vim_pane" ]] && tmux select-pane -t "$vim_pane"
    fi
}

vim_split() {
    local cwd="${1:-$PWD}" root session session_id target server_dir server cmd pane_id
    require_dir "$cwd"

    if ! in_tmux; then
        cd "$cwd"
        exec nvim
    fi

    root="$(workspace_root "$cwd")"
    session="$(tmux display-message -p '#{session_id}')"
    session_id="$session"
    target="$(find_role_window "$session" vim)"

    if [[ -z "$target" ]]; then
        vim_window "$root"
        return
    fi

    server_dir="$(nvim_server_dir)"
    server="$server_dir/nvim-$(hash_key "${TMUX%%,*}:$session_id:$root:split:$RANDOM:$$").sock"
    cmd="$(shell_quote "$TMUX_NVIM_HELPER") run $(shell_quote "$server")"

    tmux rename-window -t "$target" edit >/dev/null
    set_window_workspace_mode "$target" vim "$root"
    tmux select-window -t "$target"
    pane_id="$(split_role_pane "$target" "$root" "$cmd")"
    set_pane_workspace_role "$pane_id" vim "$root"
    normalize_role_layout "$target"
    tmux select-window -t "$target"
    tmux select-pane -t "$pane_id"
}

edit_window() {
    local cwd="${1:-$PWD}" mode
    require_dir "$cwd"

    if in_tmux; then
        mode="$(tmux show-options -wqv @workspace_mode || true)"
        if [[ "$mode" == vim ]]; then
            vim_split "$cwd"
            return
        fi
    fi

    vim_window "$cwd"
}

pane_to_role() {
    local role="${1:?missing role}" cwd="${2:-$PWD}" root session current_pane current_window current_role current_mode target name pane_count join_target
    require_dir "$cwd"
    in_tmux || { echo "pane-to requires tmux" >&2; exit 2; }

    case "$role" in
    agent | pi | ai) role=pi; name=agent ;;
    vim | nvim | editor | edit) role=vim; name=edit ;;
    git | lazygit) role=git; name=git ;;
    shell | term | sh) role=shell; name=term ;;
    *) echo "unknown pane role: $role" >&2; exit 2 ;;
    esac

    root="$(workspace_root "$cwd")"
    session="$(tmux display-message -p '#{session_id}')"
    current_pane="${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}"
    current_window="$(tmux display-message -p -t "$current_pane" '#{window_id}')"
    current_role="$(tmux show-options -pqv -t "$current_pane" @workspace_pane_role || true)"
    current_mode="$(tmux show-options -wqv -t "$current_window" @workspace_mode || true)"

    # Mode keys are idempotent: if this pane is already in the requested mode,
    # do nothing. For old windows without pane tags, tag the pane and stop.
    if [[ "$current_role" == "$role" ]]; then
        return
    fi
    if [[ -z "$current_role" && "$current_mode" == "$role" ]]; then
        set_pane_workspace_role "$current_pane" "$role" "$root"
        return
    fi

    target="$(find_role_window "$session" "$role")"

    if [[ -z "$target" ]]; then
        target="$(tmux break-pane -d -P -F '#{window_id}' -s "$current_pane" -n "$name")"
        set_window_workspace_mode "$target" "$role" "$root"
        set_pane_workspace_role "$current_pane" "$role" "$root"
        tmux select-window -t "$target"
        tmux select-pane -t "$current_pane"
        return
    fi

    tmux rename-window -t "$target" "$name" >/dev/null
    set_window_workspace_mode "$target" "$role" "$root"

    if [[ "$target" == "$current_window" ]]; then
        set_pane_workspace_role "$current_pane" "$role" "$root"
        normalize_role_layout "$target"
        tmux select-pane -t "$current_pane"
        return
    fi

    normalize_role_layout "$target"
    pane_count="$(tmux list-panes -t "$target" | wc -l | tr -d ' ')"
    if [[ "$pane_count" -le 1 ]]; then
        join_target="$(active_pane_in_window "$target")"
        tmux join-pane -h -s "$current_pane" -t "$join_target"
    else
        join_target="$(side_stack_pane_in_window "$target")"
        tmux join-pane -v -s "$current_pane" -t "$join_target"
    fi
    set_pane_workspace_role "$current_pane" "$role" "$root"
    normalize_role_layout "$target"
    tmux select-window -t "$target"
    tmux select-pane -t "$current_pane"
}

resume_cooled_window() {
    local target="${1:-}"
    [[ -n "$target" ]] || return 0
    if tmux list-panes -t "$target" -F '#{@workspace_residency_cooled}' 2>/dev/null | grep -qx 1; then
        "$TMUX_RESIDENCY_HELPER" wake-window "$target"
    fi
}

close_run_pane() {
    local pane="${1:-${TMUX_PANE:-}}" cwd
    in_tmux || { echo "close-run requires tmux" >&2; return 2; }
    [[ -n "$pane" ]] || { echo "close-run requires a pane" >&2; return 2; }
    cwd="$(tmux display-message -p -t "$pane" '#{pane_current_path}')"
    if ! (cd "$cwd" && env TMUX_PANE="$pane" myr close-run >/dev/null 2>&1); then
        tmux display-message -t "$pane" "Myran close failed"
        return 1
    fi
}

promote_pane() {
    local target current_pane main_pane
    in_tmux || { echo "promote-pane requires tmux" >&2; exit 2; }
    current_pane="${TMUX_PANE:-$(tmux display-message -p '#{pane_id}')}"
    target="${1:-$(tmux display-message -p -t "$current_pane" '#{window_id}')}"
    main_pane="$(main_pane_in_window "$target")"
    if [[ -n "$main_pane" && "$main_pane" != "$current_pane" ]]; then
        tmux swap-pane -s "$current_pane" -t "$main_pane"
    fi
    normalize_role_layout "$target"
    tmux select-pane -t "$current_pane"
}

migrate_legacy_metadata() {
    local session root name legacy_root legacy_name win mode legacy_mode legacy_window_root
    local pane role legacy_role pane_cwd pane_window

    # IDs are newline-safe, so query values separately instead of packing user
    # paths into a delimiter-based format. Remove an old option only after its
    # value has a valid home in the @workspace_* namespace.
    while IFS= read -r session; do
        [[ -n "$session" ]] || continue
        root="$(tmux show-option -qv -t "$session" @workspace_root || true)"
        name="$(tmux show-option -qv -t "$session" @workspace_name || true)"
        legacy_root="$(tmux show-option -qv -t "$session" @project_root || true)"
        legacy_name="$(tmux show-option -qv -t "$session" @project_name || true)"
        if [[ ( -z "$root" || ! -d "$root" ) && -n "$legacy_root" && -d "$legacy_root" ]]; then
            set_session_workspace "$session" "$legacy_root"
            root="$legacy_root"
        fi
        if [[ -z "$name" && -n "$legacy_name" ]]; then
            tmux set-option -q -t "$session" @workspace_name "$legacy_name"
        fi
        name="$(tmux show-option -qv -t "$session" @workspace_name || true)"
        [[ -n "$root" && -d "$root" ]] && tmux set-option -qu -t "$session" @project_root >/dev/null 2>&1 || true
        [[ -n "$name" ]] && tmux set-option -qu -t "$session" @project_name >/dev/null 2>&1 || true
    done < <(tmux list-sessions -F '#{session_id}' 2>/dev/null || true)

    while IFS= read -r win; do
        [[ -n "$win" ]] || continue
        mode="$(tmux show-option -wqv -t "$win" @workspace_mode || true)"
        root="$(tmux show-option -wqv -t "$win" @workspace_root || true)"
        legacy_mode="$(tmux show-option -wqv -t "$win" @project_role || true)"
        legacy_window_root="$(tmux show-option -wqv -t "$win" @project_root || true)"
        [[ -n "$mode" ]] || mode="$legacy_mode"
        [[ -n "$root" ]] || root="$legacy_window_root"
        if [[ -z "$root" ]]; then
            session="$(tmux display-message -p -t "$win" '#{session_id}')"
            root="$(tmux show-option -qv -t "$session" @workspace_root || true)"
        fi
        if [[ -n "$mode" && -n "$root" && -d "$root" ]]; then
            set_window_workspace_mode "$win" "$mode" "$root"
            tmux set-option -wqu -t "$win" @project_role >/dev/null 2>&1 || true
            tmux set-option -wqu -t "$win" @project_root >/dev/null 2>&1 || true
        fi
    done < <(tmux list-windows -a -F '#{window_id}' 2>/dev/null || true)

    while IFS= read -r pane; do
        [[ -n "$pane" ]] || continue
        role="$(tmux show-option -pqv -t "$pane" @workspace_pane_role || true)"
        legacy_role="$(tmux show-option -pqv -t "$pane" @project_pane_role || true)"
        [[ -n "$role" ]] || role="$legacy_role"
        if [[ -n "$role" ]]; then
            root="$(tmux show-option -pqv -t "$pane" @workspace_root || true)"
            if [[ -z "$root" || ! -d "$root" ]]; then
                pane_window="$(tmux display-message -p -t "$pane" '#{window_id}')"
                root="$(tmux show-option -wqv -t "$pane_window" @workspace_root || true)"
            fi
            if [[ -z "$root" || ! -d "$root" ]]; then
                pane_cwd="$(tmux display-message -p -t "$pane" '#{pane_current_path}')"
                root="$(root_for_dir "${pane_cwd:-$PWD}")"
            fi
            set_pane_workspace_role "$pane" "$role" "$root"
            tmux set-option -pqu -t "$pane" @project_pane_role >/dev/null 2>&1 || true
        fi
    done < <(tmux list-panes -a -F '#{pane_id}' 2>/dev/null || true)
}

refresh_status_metadata() {
    local session root first_win_cwd win mode lazygit_root pane pane_role pane_root pane_cwd pane_window

    in_tmux || return 0
    migrate_legacy_metadata

    while IFS= read -r session; do
        [[ -n "$session" ]] || continue
        root="$(tmux show-option -qv -t "$session" @workspace_root || true)"
        if [[ -z "$root" || ! -d "$root" ]]; then
            first_win_cwd="$(tmux list-windows -t "$session" -F '#{pane_current_path}' 2>/dev/null | head -n 1 || true)"
            if [[ -n "$first_win_cwd" && -d "$first_win_cwd" ]]; then
                set_session_workspace "$session" "$(root_for_dir "$first_win_cwd")"
            fi
        fi
    done < <(tmux list-sessions -F '#{session_id}' 2>/dev/null || true)

    while IFS= read -r win; do
        [[ -n "$win" ]] || continue
        mode="$(tmux show-option -wqv -t "$win" @workspace_mode || true)"
        root="$(tmux show-option -wqv -t "$win" @workspace_root || true)"
        lazygit_root="$(tmux show-option -wqv -t "$win" @lazygit_root || true)"
        if [[ -z "$mode" && -n "$lazygit_root" ]]; then
            mode=git
            root="$lazygit_root"
        fi
        if [[ -n "$mode" && -n "$root" ]]; then
            set_window_workspace_mode "$win" "$mode" "$root"
        fi
    done < <(tmux list-windows -a -F '#{window_id}' 2>/dev/null || true)

    while IFS= read -r pane; do
        [[ -n "$pane" ]] || continue
        pane_role="$(tmux show-option -pqv -t "$pane" @workspace_pane_role || true)"
        pane_root="$(tmux show-option -pqv -t "$pane" @workspace_root || true)"
        pane_cwd="$(tmux display-message -p -t "$pane" '#{pane_current_path}')"
        if [[ -n "$pane_role" ]]; then
            if [[ -z "$pane_root" || ! -d "$pane_root" ]]; then
                pane_window="$(tmux display-message -p -t "$pane" '#{window_id}')"
                pane_root="$(tmux show-option -wqv -t "$pane_window" @workspace_root || true)"
            fi
            if [[ -z "$pane_root" || ! -d "$pane_root" ]]; then
                pane_root="$(root_for_dir "${pane_cwd:-$PWD}")"
            fi
            set_pane_workspace_role "$pane" "$pane_role" "$pane_root"
        fi
    done < <(tmux list-panes -a -F '#{pane_id}' 2>/dev/null || true)
}

git_window() {
    local cwd="${1:-$PWD}" root config_files session target name cmd window_id pane_id lazygit_cmd
    require_dir "$cwd"
    command -v lazygit >/dev/null 2>&1 || {
        echo "lazygit not found" >&2
        exit 127
    }

    root="$(workspace_root "$cwd")"
    lazygit_cmd=(lazygit)
    config_files="$(lazygit_config_files)"
    [[ -n "$config_files" ]] && lazygit_cmd+=(--use-config-file "$config_files")

    if ! in_tmux; then
        cd "$root"
        exec "${lazygit_cmd[@]}"
    fi

    session="$(tmux display-message -p '#{session_id}')"
    name="${LAZYGIT_TMUX_WINDOW_PREFIX:-git}"
    cmd="$(quote_argv "${lazygit_cmd[@]}")"
    lock_role_window "$session" git
    ensure_role_window "$session" git "$root" "$name" "$cmd"
    tmux set-option -w -t "$ROLE_WINDOW_ID" @lazygit_root "$root" >/dev/null
    if [[ -n "$ROLE_PANE_ID" ]]; then
        tmux set-option -pq -t "$ROLE_PANE_ID" @workspace_resume_command "$cmd"
    fi
    resume_cooled_window "$ROLE_WINDOW_ID"
    unlock_role_window
    tmux select-window -t "$ROLE_WINDOW_ID"
}

tracker_window() {
    local cwd="${1:-$PWD}" tracker="${2:-}" root command_name task_cmd session current_tracker current_scope
    local tracker_scope tracker_repository branch
    require_dir "$cwd"
    root="$(workspace_root "$cwd")"

    if [[ -z "$tracker" ]]; then
        tracker="${TRACKER_TUI:-$(git -C "$root" config --get workspace.tracker 2>/dev/null || true)}"
    fi
    case "${tracker:-linear}" in
    linear | ltui)
        tracker=linear
        command_name=ltui
        ;;
    jira | jtui)
        tracker=jira
        command_name=jtui
        ;;
    *)
        echo "unsupported tracker: $tracker (expected linear or jira)" >&2
        exit 2
        ;;
    esac

    command -v "$command_name" >/dev/null 2>&1 || {
        echo "$command_name not found" >&2
        exit 127
    }

    tracker_repository="$(basename "$root")"
    tracker_scope="${TRACKER_SCOPE:-$(git -C "$root" config --get workspace.tracker-team 2>/dev/null || true)}"
    if [[ -z "$tracker_scope" ]]; then
        branch="$(git -C "$root" branch --show-current 2>/dev/null || true)"
        if [[ "$branch" =~ (^|/)([[:alpha:]][[:alnum:]]*)-[[:digit:]]+ ]]; then
            tracker_scope="${BASH_REMATCH[2]}"
        fi
    fi
    task_cmd="$(quote_argv env "TRACKER_REPOSITORY=$tracker_repository" "TRACKER_SCOPE=$tracker_scope" "$command_name")"

    if ! in_tmux; then
        cd "$root"
        exec env TRACKER_REPOSITORY="$tracker_repository" TRACKER_SCOPE="$tracker_scope" "$command_name"
    fi

    session="$(tmux display-message -p '#{session_id}')"
    lock_role_window "$session" tasks
    ensure_role_window "$session" tasks "$root" "$tracker" "$task_cmd"
    current_tracker="$(tmux show-option -wv -t "$ROLE_WINDOW_ID" @tracker_tui 2>/dev/null || true)"
    current_scope="$(tmux show-option -wv -t "$ROLE_WINDOW_ID" @tracker_scope 2>/dev/null || true)"
    if [[ "$ROLE_WINDOW_CREATED" == 0 && ("$current_tracker" != "$tracker" || "$current_scope" != "$tracker_scope") ]]; then
        tmux respawn-pane -k -t "$ROLE_PANE_ID" -c "$root" "$task_cmd"
    fi
    tmux set-option -w -t "$ROLE_WINDOW_ID" @tasks_root "$root" \; \
        set-option -w -t "$ROLE_WINDOW_ID" @tracker_tui "$tracker" \; \
        set-option -w -t "$ROLE_WINDOW_ID" @tracker_scope "$tracker_scope"
    if [[ -n "$ROLE_PANE_ID" ]]; then
        tmux set-option -pq -t "$ROLE_PANE_ID" @workspace_resume_command "$task_cmd"
    fi
    resume_cooled_window "$ROLE_WINDOW_ID"
    unlock_role_window
    tmux select-window -t "$ROLE_WINDOW_ID"
}

git_split() {
    local cwd="${1:-$PWD}" root config_files session target name cmd pane_id lazygit_cmd
    require_dir "$cwd"
    command -v lazygit >/dev/null 2>&1 || {
        echo "lazygit not found" >&2
        exit 127
    }

    if ! in_tmux; then
        git_window "$cwd"
        return
    fi

    root="$(workspace_root "$cwd")"
    session="$(tmux display-message -p '#{session_id}')"
    lazygit_cmd=(lazygit)
    config_files="$(lazygit_config_files)"
    [[ -n "$config_files" ]] && lazygit_cmd+=(--use-config-file "$config_files")
    cmd="$(quote_argv "${lazygit_cmd[@]}")"

    local format=$'#{window_id}\t#{@workspace_mode}\t#{@lazygit_root}'
    target="$(tmux list-windows -t "$session" -F "$format" |
        awk -F '\t' -v root="$root" '$2 == "git" || $3 == root { print $1; exit }')"

    if [[ -z "$target" ]]; then
        git_window "$root"
        return
    fi

    name="${LAZYGIT_TMUX_WINDOW_PREFIX:-git}"
    tmux rename-window -t "$target" "$name" >/dev/null
    set_window_workspace_mode "$target" git "$root"
    tmux set-option -w -t "$target" @lazygit_root "$root" >/dev/null
    tmux select-window -t "$target"
    pane_id="$(split_role_pane "$target" "$root" "$cmd")"
    set_pane_workspace_role "$pane_id" git "$root"
    tmux set-option -pq -t "$pane_id" @workspace_resume_command "$cmd"
    normalize_role_layout "$target"
    tmux select-window -t "$target"
    tmux select-pane -t "$pane_id"
}

cmd="${1:-}"
[[ -n "$cmd" ]] || {
    usage
    exit 2
}
shift || true

case "$cmd" in
session | new-session) new_session "${1:-$PWD}" ;;
shell | sh) role_window shell "${1:-$PWD}" ;;
shell2 | sh2) role_window shell2 "${1:-$PWD}" ;;
agent | pi | ai) role_window pi "${1:-$PWD}" ;;
agent-new | ai-new) agent_new "${1:-$PWD}" "${2:-}" ;;
pi-split | agent-split) pi_split "${1:-$PWD}" ;;
pane-to) pane_to_role "${1:?missing role}" "${2:-$PWD}" ;;
promote-pane) promote_pane ;;
close-run) close_run_pane "${1:-}" ;;
normalize-layout) normalize_role_layout "${1:-}" ;;
edit) edit_window "${1:-$PWD}" ;;
vim) vim_window "${1:-$PWD}" ;;
vim-split) vim_split "${1:-$PWD}" ;;
vim-open)
    # Some callers, notably lazygit, invoke editors as `nvim -- file`.
    # That separator is useful for regular nvim startup, but Neovim remote
    # treats it as another file when using --remote-tab-silent.
    [[ "${1:-}" == -- ]] && shift
    vim_window "$PWD" "$@"
    ;;
git | lazygit) git_window "${1:-$PWD}" ;;
git-split | lazygit-split) git_split "${1:-$PWD}" ;;
tasks | task | todo) tracker_window "${1:-$PWD}" "${2:-}" ;;
linear-tasks) tracker_window "${1:-$PWD}" linear ;;
jira-tasks) tracker_window "${1:-$PWD}" jira ;;
__refresh-status) refresh_status_metadata ;;
help | -h | --help) usage ;;
*)
    echo "unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac

