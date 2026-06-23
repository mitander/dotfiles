#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

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
  normalize-layout [target-window]
  git [cwd]
  git-split [cwd]
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
    local cwd="${1:?missing cwd}"
    if git -C "$cwd" rev-parse --show-toplevel >/dev/null 2>&1; then
        git -C "$cwd" rev-parse --show-toplevel
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

    tmux set-option -t "$session" @workspace_root "$root" >/dev/null
    tmux set-option -t "$session" @workspace_name "$name" >/dev/null

    # Backward-compatible aliases for already-restored sessions/configs.
    tmux set-option -t "$session" @project_root "$root" >/dev/null
    tmux set-option -t "$session" @project_name "$name" >/dev/null
}

workspace_mode_label() {
    case "$1" in
    vim) printf 'edit' ;;
    pi) printf 'agent' ;;
    git) printf 'git' ;;
    shell) printf 'term' ;;
    shell2) printf 'term2' ;;
    *) printf '%s' "$1" ;;
    esac
}

workspace_mode_color() {
    case "$1" in
    vim) printf '#6aa6bc' ;;    # accent
    pi) printf '#b99add' ;;     # magenta
    git) printf '#d8b574' ;;    # yellow
    shell) printf '#a3be8c' ;;  # green
    shell2) printf '#8fc9d2' ;; # cyan
    *) printf '#d6d2e8' ;;      # text
    esac
}

set_window_workspace_mode() {
    local target="${1:?missing window}" mode="${2:?missing mode}" root="${3:?missing root}" label color
    label="$(workspace_mode_label "$mode")"
    color="$(workspace_mode_color "$mode")"

    tmux set-option -w -t "$target" automatic-rename off >/dev/null
    tmux set-option -w -t "$target" @workspace_mode "$mode" >/dev/null
    tmux set-option -w -t "$target" @workspace_mode_label "$label" >/dev/null
    tmux set-option -w -t "$target" @workspace_mode_color "$color" >/dev/null
    tmux set-option -w -t "$target" @workspace_root "$root" >/dev/null

    # Backward-compatible aliases for scripts that still look for project roles.
    tmux set-option -w -t "$target" @project_role "$mode" >/dev/null
    tmux set-option -w -t "$target" @project_root "$root" >/dev/null
}

set_pane_workspace_role() {
    local target="${1:?missing pane}" role="${2:?missing role}" root="${3:?missing root}" label color
    label="$(workspace_mode_label "$role")"
    color="$(workspace_mode_color "$role")"

    tmux set-option -p -t "$target" @workspace_pane_role "$role" >/dev/null
    tmux set-option -p -t "$target" @workspace_pane_role_label "$label" >/dev/null
    tmux set-option -p -t "$target" @workspace_pane_role_color "$color" >/dev/null
    tmux set-option -p -t "$target" @workspace_root "$root" >/dev/null

    # Backward-compatible alias naming.
    tmux set-option -p -t "$target" @project_pane_role "$role" >/dev/null
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
    local cwd="${1:?missing cwd}" root session root_opt legacy_root_opt
    root="$(root_for_dir "$cwd")"

    if in_tmux; then
        session="$(tmux display-message -p '#S')"
        root_opt="$(tmux show-options -qv -t "$session" @workspace_root || true)"
        legacy_root_opt="$(tmux show-options -qv -t "$session" @project_root || true)"
        if [[ -n "$root_opt" && -d "$root_opt" ]]; then
            root="$root_opt"
        elif [[ -n "$legacy_root_opt" && -d "$legacy_root_opt" ]]; then
            root="$legacy_root_opt"
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

hash_key() {
    if command -v shasum >/dev/null 2>&1; then
        printf '%s' "$1" | shasum -a 256 | awk '{ print substr($1, 1, 20) }'
    else
        printf '%s' "$1" | cksum | awk '{ print $1 }'
    fi
}

find_role_window() {
    local session="$1" role="$2" format=$'#{window_id}\t#{@workspace_mode}\t#{@project_role}'
    tmux list-windows -t "$session" -F "$format" |
        awk -F '\t' -v role="$role" '$2 == role || $3 == role { print $1; exit }'
}

ensure_shell_window() {
    local session="${1:?missing session}" root="${2:?missing root}" target format pane_id

    set_session_workspace "$session" "$root"

    target="$(find_role_window "$session" shell)"
    if [[ -z "$target" ]]; then
        format=$'#{window_id}\t#{@workspace_mode}\t#{@project_role}\t#{pane_current_command}'
        target="$(tmux list-windows -t "$session" -F "$format" |
            awk -F '\t' '$2 == "" && $3 == "" && $4 ~ /^(fish|zsh|bash|sh)$/ { print $1; exit }')"
    fi
    if [[ -z "$target" ]]; then
        target="$(tmux new-window -d -P -F '#{window_id}' -t "$session:" -n sh -c "$root")"
    fi

    tmux rename-window -t "$target" term >/dev/null
    set_window_workspace_mode "$target" shell "$root"
    pane_id="$(active_pane_in_window "$target")"
    [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" shell "$root"
    tmux select-window -t "$target" >/dev/null
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
        local format=$'#{session_id}\t#{@workspace_root}\t#{@project_root}'
        existing="$(tmux list-sessions -F "$format" |
            awk -F '\t' -v root="$root" '$2 == root || $3 == root { print $1; exit }')"
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
    local role="${1:?missing role}" cwd="${2:-$PWD}" root name command session target window_id pane_id
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

    session="$(tmux display-message -p '#S')"
    target="$(find_role_window "$session" "$role")"
    if [[ -n "$target" ]]; then
        tmux rename-window -t "$target" "$name"
        set_window_workspace_mode "$target" "$role" "$root"
        pane_id="$(active_pane_in_window "$target")"
        [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" "$role" "$root"
        tmux select-window -t "$target"
        return
    fi

    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root")"
    set_window_workspace_mode "$window_id" "$role" "$root"
    pane_id="$(active_pane_in_window "$window_id")"
    [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" "$role" "$root"
    tmux select-window -t "$window_id"

    [[ -n "$command" ]] && tmux send-keys -t "$window_id" "$command" Enter
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
    session="$(tmux display-message -p '#S')"
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
        tmux set-option -w -t "$TMUX_PANE" @workspace_vim_pane "$TMUX_PANE" >/dev/null 2>&1 || true
        tmux set-option -w -t "$TMUX_PANE" @project_vim_pane "$TMUX_PANE" >/dev/null 2>&1 || true
        tmux set-option -p -t "$TMUX_PANE" @workspace_pane_role vim >/dev/null 2>&1 || true
        tmux set-option -p -t "$TMUX_PANE" @project_pane_role vim >/dev/null 2>&1 || true
    fi
    exec nvim --listen "$server" "${args[@]}"
}

vim_window() {
    local cwd="$1"
    shift
    local args=("$@")
    local root name start_cwd session session_id server target saved_server window_id vim_pane new_pane
    require_dir "$cwd"

    root="$(workspace_root "$cwd")"
    name=edit
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
        cmd="$(shell_quote "$DOTFILES_DIR/scripts/tmux-project.sh") __nvim $(shell_quote "$server")"
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

        saved="$(tmux show-options -wqv -t "$target_window" @workspace_vim_pane || true)"
        [[ -n "$saved" ]] || saved="$(tmux show-options -wqv -t "$target_window" @project_vim_pane || true)"
        if [[ -n "$saved" ]] && tmux display-message -p -t "$saved" '#{pane_id}' >/dev/null 2>&1; then
            printf '%s\n' "$saved"
            return 0
        fi

        while IFS=$'\t' read -r pane tty; do
            if ps -o state= -o comm= -t "$tty" 2>/dev/null |
                grep -iqE '^[^TXZ ]+ +(\S+/)?g?(view|n?vim?x?)(diff)?$'; then
                printf '%s\n' "$pane"
                return 0
            fi
        done < <(tmux list-panes -t "$target_window" -F '#{pane_id}\t#{pane_tty}')
    }

    target="$(find_role_window "$session" vim)"
    if [[ -n "$target" ]]; then
        tmux rename-window -t "$target" "$name"
        set_window_workspace_mode "$target" vim "$root"
        saved_server="$(tmux show-options -wqv -t "$target" @workspace_vim_server || true)"
        [[ -n "$saved_server" ]] || saved_server="$(tmux show-options -wqv -t "$target" @project_vim_server || true)"
        [[ -n "$saved_server" ]] && server="$saved_server"
    fi

    if [[ -z "$target" ]]; then
        clean_server
        window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$start_cwd" "$(start_command)")"
        set_window_workspace_mode "$window_id" vim "$root"
        tmux set-option -w -t "$window_id" @workspace_vim_server "$server" >/dev/null
        tmux set-option -w -t "$window_id" @project_vim_server "$server" >/dev/null
        vim_pane="$(active_pane_in_window "$window_id")"
        [[ -n "$vim_pane" ]] && set_pane_workspace_role "$vim_pane" vim "$root"
        tmux select-window -t "$window_id"
        return
    fi

    tmux set-option -w -t "$target" @workspace_vim_server "$server" >/dev/null
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
                    set_pane_workspace_role "$new_pane" vim "$root"
                    normalize_role_layout "$target"
                    tmux select-pane -t "$new_pane"
                fi
            ) >/dev/null 2>&1 &
        else
            rm -f "$server"
            new_pane="$(tmux split-window -h -P -F '#{pane_id}' -t "$target" -c "$start_cwd" "$(start_command)")"
            set_pane_workspace_role "$new_pane" vim "$root"
            normalize_role_layout "$target"
            tmux select-pane -t "$new_pane"
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
    session="$(tmux display-message -p '#S')"
    session_id="$(tmux display-message -p '#{session_id}')"
    target="$(find_role_window "$session" vim)"

    if [[ -z "$target" ]]; then
        vim_window "$root"
        return
    fi

    server_dir="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/tmux-project-${UID:-$(id -u)}"
    mkdir -p "$server_dir"
    server="$server_dir/nvim-$(hash_key "${TMUX%%,*}:$session_id:$root:split:$RANDOM:$$").sock"
    cmd="$(shell_quote "$DOTFILES_DIR/scripts/tmux-project.sh") __nvim $(shell_quote "$server")"

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
    local cwd="${1:-$PWD}" mode legacy_mode
    require_dir "$cwd"

    if in_tmux; then
        mode="$(tmux show-options -wqv @workspace_mode || true)"
        legacy_mode="$(tmux show-options -wqv @project_role || true)"
        if [[ "$mode" == vim || "$legacy_mode" == vim ]]; then
            vim_split "$cwd"
            return
        fi
    fi

    vim_window "$cwd"
}

pane_to_role() {
    local role="${1:?missing role}" cwd="${2:-$PWD}" root session current_pane current_window current_role legacy_current_role current_mode legacy_current_mode target name pane_count join_target
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
    session="$(tmux display-message -p '#S')"
    current_pane="$(tmux display-message -p '#{pane_id}')"
    current_window="$(tmux display-message -p '#{window_id}')"
    current_role="$(tmux show-options -pqv -t "$current_pane" @workspace_pane_role || true)"
    legacy_current_role="$(tmux show-options -pqv -t "$current_pane" @project_pane_role || true)"
    [[ -n "$current_role" ]] || current_role="$legacy_current_role"
    current_mode="$(tmux show-options -wqv -t "$current_window" @workspace_mode || true)"
    legacy_current_mode="$(tmux show-options -wqv -t "$current_window" @project_role || true)"
    [[ -n "$current_mode" ]] || current_mode="$legacy_current_mode"

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

promote_pane() {
    local target current_pane main_pane
    in_tmux || { echo "promote-pane requires tmux" >&2; exit 2; }
    target="${1:-$(tmux display-message -p '#{window_id}')}"
    current_pane="$(tmux display-message -p '#{pane_id}')"
    main_pane="$(main_pane_in_window "$target")"
    if [[ -n "$main_pane" && "$main_pane" != "$current_pane" ]]; then
        tmux swap-pane -s "$current_pane" -t "$main_pane"
    fi
    normalize_role_layout "$target"
    tmux select-pane -t "$current_pane"
}

refresh_status_metadata() {
    local format session root legacy_root win mode legacy_mode lazygit_root pane pane_role legacy_pane_role pane_root pane_cwd

    in_tmux || return 0

    format=$'#{session_id}\t#{@workspace_root}\t#{@project_root}'
    while IFS=$'\t' read -r session root legacy_root; do
        [[ -n "$root" ]] || root="$legacy_root"
        if [[ -n "$root" && -d "$root" ]]; then
            set_session_workspace "$session" "$root"
        fi
    done < <(tmux list-sessions -F "$format" 2>/dev/null || true)

    format=$'#{window_id}\t#{@workspace_mode}\t#{@project_role}\t#{@workspace_root}\t#{@project_root}\t#{@lazygit_root}'
    while IFS=$'\t' read -r win mode legacy_mode root legacy_root lazygit_root; do
        [[ -n "$mode" ]] || mode="$legacy_mode"
        if [[ -z "$mode" && -n "$lazygit_root" ]]; then
            mode=git
        fi
        [[ -n "$root" ]] || root="$legacy_root"
        [[ -n "$root" ]] || root="$lazygit_root"
        [[ -n "$mode" && -n "$root" ]] || continue

        set_window_workspace_mode "$win" "$mode" "$root"
        if [[ "$mode" == git ]]; then
            tmux set-option -w -t "$win" @lazygit_root "$root" >/dev/null
        fi
    done < <(tmux list-windows -a -F "$format" 2>/dev/null || true)

    format=$'#{pane_id}\t#{@workspace_pane_role}\t#{@project_pane_role}\t#{@workspace_root}\t#{pane_current_path}'
    while IFS=$'\t' read -r pane pane_role legacy_pane_role pane_root pane_cwd; do
        [[ -n "$pane_role" ]] || pane_role="$legacy_pane_role"
        [[ -n "$pane_role" ]] || continue
        [[ -n "$pane_root" && -d "$pane_root" ]] || pane_root="$pane_cwd"
        [[ -n "$pane_root" && -d "$pane_root" ]] || continue
        set_pane_workspace_role "$pane" "$pane_role" "$(root_for_dir "$pane_root")"
    done < <(tmux list-panes -a -F "$format" 2>/dev/null || true)

    return 0
}

git_window() {
    local cwd="${1:-$PWD}" root config_file session target name cmd window_id pane_id lazygit_cmd
    require_dir "$cwd"
    command -v lazygit >/dev/null 2>&1 || {
        echo "lazygit not found" >&2
        exit 127
    }

    root="$(workspace_root "$cwd")"
    config_file="${LAZYGIT_CONFIG_FILE:-$DOTFILES_DIR/lazygit/.config/lazygit/config.yml}"
    lazygit_cmd=(lazygit)
    if in_tmux && [[ -f "$config_file" ]]; then
        lazygit_cmd+=(--use-config-file "$config_file")
    fi

    if ! in_tmux; then
        cd "$root"
        exec "${lazygit_cmd[@]}"
    fi

    session="$(tmux display-message -p '#S')"
    local format=$'#{window_id}\t#{@workspace_mode}\t#{@lazygit_root}'
    target="$(tmux list-windows -t "$session" -F "$format" |
        awk -F '\t' -v root="$root" '$2 == "git" || $3 == root { print $1; exit }')"

    if [[ -n "$target" ]]; then
        name="${LAZYGIT_TMUX_WINDOW_PREFIX:-git}"
        tmux rename-window -t "$target" "$name"
        set_window_workspace_mode "$target" git "$root"
        tmux set-option -w -t "$target" @lazygit_root "$root" >/dev/null
        pane_id="$(active_pane_in_window "$target")"
        [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" git "$root"
        tmux select-window -t "$target"
        return
    fi

    name="${LAZYGIT_TMUX_WINDOW_PREFIX:-git}"
    cmd="$(quote_argv "${lazygit_cmd[@]}")"
    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root" "$cmd")"
    set_window_workspace_mode "$window_id" git "$root"
    pane_id="$(active_pane_in_window "$window_id")"
    [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" git "$root"
    tmux set-option -w -t "$window_id" @lazygit_root "$root" >/dev/null
    tmux select-window -t "$window_id"
}

git_split() {
    local cwd="${1:-$PWD}" root config_file session target name cmd pane_id lazygit_cmd
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
    session="$(tmux display-message -p '#S')"
    config_file="${LAZYGIT_CONFIG_FILE:-$DOTFILES_DIR/lazygit/.config/lazygit/config.yml}"
    lazygit_cmd=(lazygit)
    if [[ -f "$config_file" ]]; then
        lazygit_cmd+=(--use-config-file "$config_file")
    fi
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
pi-split | agent-split) pi_split "${1:-$PWD}" ;;
pane-to) pane_to_role "${1:?missing role}" "${2:-$PWD}" ;;
promote-pane) promote_pane ;;
normalize-layout) normalize_role_layout "${1:-}" ;;
edit) edit_window "${1:-$PWD}" ;;
vim) vim_window "${1:-$PWD}" ;;
vim-split) vim_split "${1:-$PWD}" ;;
vim-open)
    # Some callers, notably lazygit, invoke editors as `nvim -- file`.
    # That separator is useful for regular nvim startup, but Neovim remote
    # treats it as another file when using --remote-tab-silent.
    args=()
    for arg in "$@"; do
        [[ "$arg" == -- ]] && continue
        args+=("$arg")
    done
    vim_window "$PWD" "${args[@]}"
    ;;
git | lazygit) git_window "${1:-$PWD}" ;;
git-split | lazygit-split) git_split "${1:-$PWD}" ;;
__refresh-status) refresh_status_metadata ;;
__nvim) nvim_runner "$@" ;;
help | -h | --help) usage ;;
*)
    echo "unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac
