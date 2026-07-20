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
  tuxedo|tasks [cwd]
  run [cwd]
  pick-run [cwd]
  run-focused [cwd]
  run-tests [cwd]
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
        set-option -q -t "$session" @workspace_name "$name" \; \
        set-option -q -t "$session" @project_root "$root" \; \
        set-option -q -t "$session" @project_name "$name"
}

workspace_mode_label() {
    case "$1" in
    vim) printf 'edit' ;;
    pi) printf 'agent' ;;
    git) printf 'git' ;;
    tuxedo) printf 'todo' ;;
    shell) printf 'term' ;;
    shell2) printf 'term2' ;;
    run) printf 'run' ;;
    *) printf '%s' "$1" ;;
    esac
}

workspace_mode_color() {
    local role
    case "$1" in
    vim | pi | git | run | tuxedo | shell | shell2) role=accent ;;
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
        set-option -wq -t "$target" @workspace_root "$root" \; \
        set-option -wq -t "$target" @project_role "$mode" \; \
        set-option -wq -t "$target" @project_root "$root"
}

set_pane_workspace_role() {
    local target="${1:?missing pane}" role="${2:?missing role}" root="${3:?missing root}" label color
    label="$(workspace_mode_label "$role")"
    color="$(workspace_mode_color "$role")"

    tmux set-option -pq -t "$target" @workspace_pane_role "$role" \; \
        set-option -pq -t "$target" @workspace_pane_role_label "$label" \; \
        set-option -pq -t "$target" @workspace_pane_role_color "$color" \; \
        set-option -pq -t "$target" @workspace_root "$root" \; \
        set-option -pq -t "$target" @project_pane_role "$role"
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

read_run_view_completion() {
    local marker="${1:?missing marker}" bytes version status run_kind
    bytes="$(wc -c < "$marker" | tr -d ' ')"
    [[ "$bytes" =~ ^[0-9]+$ ]] && ((bytes <= 80)) || return 1
    version="$(sed -n '1p' "$marker")"
    status="$(sed -n '2p' "$marker")"
    run_kind="$(sed -n '3p' "$marker")"
    [[ "$version" == 2 && "$status" =~ ^[0-9]+$ ]] || return 1
    [[ "$run_kind" == result || "$run_kind" == application ]] || return 1
    printf '%s\t%s' "$status" "$run_kind"
}

complete_run_window() {
    local target="${1:?missing window}" marker="${2:?missing marker}" exit_code="${3:?missing exit code}" run_kind="${4:?missing run kind}" pane run_status commands condition
    condition="#{==:#{@myran_run_watch_token},$marker}"
    if [[ "$run_kind" == application ]]; then
        commands="$(quote_argv set-option -wu -t "$target" @myran_run_watch_token) ; $(quote_argv kill-window -t "$target")"
    else
        if [[ "$exit_code" == 0 ]]; then
            run_status=✓
        else
            run_status="✗ $exit_code"
        fi
        pane="$(active_pane_in_window "$target")"
        commands="$(quote_argv set-option -wu -t "$target" @myran_run_watch_token) ; $(quote_argv set-option -wq -t "$target" @myran_run_status "$run_status") ; $(quote_argv set-option -wq -t "$target" @myran_run_state completed)"
        if [[ -n "$pane" ]]; then
            commands="$commands ; $(quote_argv set-option -pq -t "$pane" @myran_run_state completed)"
        fi
    fi
    tmux if-shell -F -t "$target" "$condition" "$commands"
}

watch_run_window() {
    local root="${1:?missing root}" target="${2:?missing window}" marker="${3:?missing marker}" current_token pane pane_dead completion exit_code run_kind
    : "$root"

    while tmux display-message -p -t "$target" '#{window_id}' >/dev/null 2>&1; do
        current_token="$(tmux show-options -wqv -t "$target" @myran_run_watch_token || true)"
        if [[ "$current_token" != "$marker" ]]; then
            rm -f "$marker"
            return
        fi
        if [[ -e "$marker" ]]; then
            completion="$(read_run_view_completion "$marker" 2>/dev/null || printf '125\tresult')"
            exit_code="${completion%%$'\t'*}"
            run_kind="${completion#*$'\t'}"
            rm -f "$marker"
            complete_run_window "$target" "$marker" "$exit_code" "$run_kind"
            return
        fi
        pane="$(active_pane_in_window "$target")"
        if [[ -n "$pane" ]]; then
            pane_dead="$(tmux display-message -p -t "$pane" '#{pane_dead}' 2>/dev/null || true)"
            if [[ "$pane_dead" == 1 ]]; then
                complete_run_window "$target" "$marker" 125 result
                return
            fi
        fi
        sleep 0.025
    done
    rm -f "$marker"
}

start_run_in_pane() {
    local pane="${1:?missing pane}" target="${2:?missing window}" root="${3:?missing root}" marker pane_command watcher_command run_state cancel_error run_label
    run_state="$(tmux show-options -wqv -t "$target" @myran_run_state || true)"
    if [[ "$run_state" == active ]]; then
        tmux set-option -wq -t "$target" @myran_run_watch_token "replacing-$$-$RANDOM"
        for _ in {1..80}; do
            if cancel_error="$(cd "$root" && myr cancel 2>&1)"; then
                cancel_error=
                break
            fi
            if [[ "$cancel_error" == *"has no active instance"* ]]; then
                cancel_error=
                break
            fi
            sleep 0.025
        done
        if [[ -n "$cancel_error" ]]; then
            tmux display-message "Myran replacement failed: $cancel_error"
            return 1
        fi
        (cd "$root" && myr wait)
        sleep 0.05
    fi

    run_label="$(cd "$root" && myr __run-label)"
    marker="$(mktemp "${TMPDIR:-/tmp}/myran-run.XXXXXX")"
    rm -f "$marker"
    pane_command="exec $(quote_argv myr __run-view "$marker")"
    watcher_command="$(quote_argv "$DOTFILES_DIR/scripts/tmux-project.sh" __watch-run "$root" "$target" "$marker")"

    tmux set-option -wq -t "$target" pane-border-status bottom
    tmux set-option -wq -t "$target" pane-border-format " run · #{@myran_run_label} · #{@myran_run_status} #{R:─,#{pane_width}}"
    tmux set-option -wq -t "$target" @myran_run_label "$run_label"
    tmux set-option -wq -t "$target" @myran_run_status "…"
    tmux set-option -wq -t "$target" @myran_run_watch_token "$marker"
    tmux set-option -wq -t "$target" @myran_run_state active
    tmux set-option -pq -t "$pane" @myran_run_state active
    tmux set-option -pq -t "$pane" remain-on-exit on
    tmux set-option -pq -t "$pane" remain-on-exit-format ""
    tmux send-keys -R -t "$pane"
    tmux clear-history -t "$pane"
    tmux respawn-pane -k -t "$pane" -c "$root" "$pane_command"
    tmux run-shell -b -t "$target" "$watcher_command"
}

pick_run_modal() {
    local cwd="${1:-$PWD}" root session target popup_command client_width client_height popup_width popup_height
    root="$(workspace_root "$cwd")"
    session="$(tmux display-message -p '#S')"
    target="$(find_role_window "$session" run)"
    if [[ -n "$target" ]]; then
        close_run_window "$root" "$target" || return 1
    fi

    client_width="$(tmux display-message -p '#{client_width}')"
    client_height="$(tmux display-message -p '#{client_height}')"
    popup_width=80%
    popup_height=70%
    [[ "$client_width" =~ ^[0-9]+$ ]] && ((client_width >= 112)) && popup_width=96
    [[ "$client_height" =~ ^[0-9]+$ ]] && ((client_height >= 28)) && popup_height=20

    popup_command="$(quote_argv "$DOTFILES_DIR/scripts/tmux-project.sh" __pick-default-modal "$root")"
    tmux display-popup -E -b rounded -T " Run " -w "$popup_width" -h "$popup_height" -d "$root" "$popup_command"
}

pick_default_modal() {
    local root="${1:?missing root}" status
    if (cd "$root" && MYRAN_PICKER_INLINE=1 myr __pick-default); then
        role_window run "$root" run
        return
    else
        status=$?
    fi
    [[ "$status" -eq 130 ]] && return 0
    return "$status"
}

run_or_pick() {
    local cwd="${1:-$PWD}" root
    root="$(workspace_root "$cwd")"
    if (cd "$root" && myr run-kind >/dev/null 2>&1); then
        role_window run "$root" run
    else
        pick_run_modal "$root"
    fi
}

dismiss_run_window() {
    local target="${1:-$(tmux display-message -p '#{window_id}')}" state
    state="$(tmux show-options -wqv -t "$target" @myran_run_state || true)"
    if [[ "$state" == completed ]]; then
        tmux kill-window -t "$target" >/dev/null 2>&1 || true
    fi
}

close_run_window() {
    local cwd="${1:-$PWD}" target="${2:-$(tmux display-message -p '#{window_id}')}" root cancel_error
    root="$(workspace_root "$cwd")"
    tmux set-option -wq -t "$target" @myran_run_watch_token "closing-$$-$RANDOM"

    for _ in {1..80}; do
        if cancel_error="$(cd "$root" && myr cancel 2>&1)"; then
            tmux kill-window -t "$target" >/dev/null 2>&1 || true
            return
        fi
        if [[ "$cancel_error" == *"has no active instance"* ]]; then
            tmux kill-window -t "$target" >/dev/null 2>&1 || true
            return
        fi
        sleep 0.025
    done

    tmux display-message "Myran cancel failed: $cancel_error"
    return 1
}

role_window() {
    local role="${1:?missing role}" cwd="${2:-$PWD}" run_action="${3:-run}" root name command session target window_id pane_id
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
    run)
        role=run
        name=run
        command="myr $run_action --foreground"
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
        run) exec myr "$run_action" ;;
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
        if [[ "$role" == "run" && -n "$pane_id" ]]; then
            start_run_in_pane "$pane_id" "$target" "$root"
        fi
        return
    fi

    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root")"
    set_window_workspace_mode "$window_id" "$role" "$root"
    pane_id="$(active_pane_in_window "$window_id")"
    [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" "$role" "$root"
    tmux select-window -t "$window_id"

    if [[ "$role" == "run" && -n "$command" ]]; then
        start_run_in_pane "$pane_id" "$window_id" "$root"
    elif [[ -n "$command" ]]; then
        tmux send-keys -t "$window_id" "$command" Enter
    fi
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
    
    session="$(tmux display-message -p '#S')"
    name="ai:${task}"
    
    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root")"
    set_window_workspace_mode "$window_id" pi "$root"
    tmux set-option -w -t "$window_id" @workspace_mode_label "$name" >/dev/null
    
    pane_id="$(active_pane_in_window "$window_id")"
    [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" pi "$root"
    tmux select-window -t "$window_id"
    
    tmux send-keys -t "$window_id" "pi --name $(shell_quote "$task")" Enter
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

    # 1. Sessions: only set if root is empty/invalid
    format='#{session_id}|#{@workspace_root}|#{@project_root}'
    while IFS='|' read -r session root legacy_root; do
        [[ -n "$root" ]] || root="$legacy_root"
        if [[ -z "$root" || ! -d "$root" ]]; then
            # Find the root of the first window's active pane path
            local first_win_cwd
            first_win_cwd="$(tmux list-windows -t "$session" -F '#{pane_current_path}' 2>/dev/null | head -n 1 || true)"
            if [[ -n "$first_win_cwd" && -d "$first_win_cwd" ]]; then
                root="$(root_for_dir "$first_win_cwd")"
                set_session_workspace "$session" "$root"
            fi
        fi
    done < <(tmux list-sessions -F "$format" 2>/dev/null || true)

    # 2. Windows: restore missing metadata and refresh variant-derived colors.
    format='#{window_id}|#{@workspace_mode}|#{@project_role}|#{@workspace_root}|#{@project_root}|#{@lazygit_root}'
    while IFS='|' read -r win mode legacy_mode root legacy_root lazygit_root; do
        [[ -n "$mode" ]] || mode="$legacy_mode"
        [[ -n "$root" ]] || root="$legacy_root"
        
        if [[ -z "$mode" && -n "$lazygit_root" ]]; then
            mode=git
            root="$lazygit_root"
        fi
        
        if [[ -n "$mode" && -n "$root" ]]; then
            set_window_workspace_mode "$win" "$mode" "$root"
        fi
    done < <(tmux list-windows -a -F "$format" 2>/dev/null || true)

    # 3. Panes: restore missing roots and refresh variant-derived colors.
    format='#{pane_id}|#{@workspace_pane_role}|#{@project_pane_role}|#{@workspace_root}|#{pane_current_path}'
    while IFS='|' read -r pane pane_role legacy_pane_role pane_root pane_cwd; do
        [[ -n "$pane_role" ]] || pane_role="$legacy_pane_role"
        
        if [[ -n "$pane_role" ]]; then
            if [[ -z "$pane_root" || ! -d "$pane_root" ]]; then
                pane_root="$(root_for_dir "${pane_cwd:-$PWD}")"
            fi
            set_pane_workspace_role "$pane" "$pane_role" "$pane_root"
        fi
    done < <(tmux list-panes -a -F "$format" 2>/dev/null || true)

    return 0
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

tuxedo_window() {
    local cwd="${1:-$PWD}" root todo_file cmd tuxedo_args=() session target name window_id pane_id
    require_dir "$cwd"
    command -v tuxedo >/dev/null 2>&1 || {
        echo "tuxedo not found" >&2
        exit 127
    }
    root="$(workspace_root "$cwd")"

    if [[ -n "${TODO_FILE:-}" || -n "${TODO_DIR:-}" ]]; then
        tuxedo_args=()
    elif [[ -f "$root/todo.txt" ]]; then
        tuxedo_args=("$root/todo.txt")
    else
        todo_file="${TUXEDO_TODO_FILE:-$HOME/todo.txt}"
        mkdir -p "$(dirname "$todo_file")"
        tuxedo_args=("$todo_file")
    fi
    cmd="$(quote_argv tuxedo "${tuxedo_args[@]}")"

    if ! in_tmux; then
        cd "$root"
        exec tuxedo "${tuxedo_args[@]}"
    fi

    session="$(tmux display-message -p '#S')"
    local format='#{window_id}|#{@workspace_mode}|#{@tuxedo_root}'
    target="$(tmux list-windows -t "$session" -F "$format" |
        awk -F '|' -v root="$root" '$2 == "tuxedo" || $3 == root { print $1; exit }')"

    name="todo"

    if [[ -n "$target" ]]; then
        tmux rename-window -t "$target" "$name"
        set_window_workspace_mode "$target" tuxedo "$root"
        tmux set-option -w -t "$target" @tuxedo_root "$root" >/dev/null
        pane_id="$(active_pane_in_window "$target")"
        [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" tuxedo "$root"
        tmux select-window -t "$target"
        return
    fi

    window_id="$(tmux new-window -P -F '#{window_id}' -t "$session:" -n "$name" -c "$root" "$cmd")"
    set_window_workspace_mode "$window_id" tuxedo "$root"
    pane_id="$(active_pane_in_window "$window_id")"
    [[ -n "$pane_id" ]] && set_pane_workspace_role "$pane_id" tuxedo "$root"
    tmux set-option -w -t "$window_id" @tuxedo_root "$root" >/dev/null
    tmux select-window -t "$window_id"
}

open_todo_ref() {
    local cwd="${1:-$PWD}" session session_id tux_pane cursor_y lines=() line ref_file root full_path server
    require_dir "$cwd"
    if ! in_tmux; then
        echo "open-todo-ref requires tmux" >&2
        exit 2
    fi

    session="$(tmux display-message -p '#S')"
    session_id="$(tmux display-message -p '#{session_id}')"
    tux_pane="$(tmux list-panes -s -t "$session" -F '#{pane_id} #{@workspace_pane_role}' | awk '$2 == "tuxedo" {print $1; exit}')"
    if [[ -z "$tux_pane" ]]; then
        tmux display-message "No active todo (tuxedo) pane found"
        exit 0
    fi

    cursor_y="$(tmux display-message -t "$tux_pane" -p '#{cursor_y}')"
    while IFS= read -r line; do
        lines+=("$line")
    done < <(tmux capture-pane -t "$tux_pane" -p)

    ref_file=""
    for l in "${lines[@]}"; do
        if [[ "$l" =~ [▸›] ]] && [[ "$l" =~ ref:([a-zA-Z0-9_/.-]+) ]]; then
            ref_file="${BASH_REMATCH[1]}"
            break
        fi
    done

    if [[ -z "$ref_file" ]]; then
        line="${lines[$cursor_y]}"
        if [[ "$line" =~ ref:([a-zA-Z0-9_/.-]+) ]]; then
            ref_file="${BASH_REMATCH[1]}"
        fi
    fi

    if [[ -z "$ref_file" ]]; then
        for l in "${lines[@]}"; do
            if [[ "$l" =~ ref:([a-zA-Z0-9_/.-]+) ]]; then
                ref_file="${BASH_REMATCH[1]}"
                break
            fi
        done
    fi

    if [[ -z "$ref_file" ]]; then
        tmux display-message "No ref: path found on screen"
        exit 0
    fi

    root="$(tmux display-message -t "$tux_pane" -p '#{@workspace_root}')"
    [[ -n "$root" ]] || root="$(workspace_root "$cwd")"

    full_path="$root/$ref_file"
    if [[ ! -f "$full_path" ]]; then
        tmux display-message "File not found: $ref_file"
        exit 0
    fi

    server="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/tmux-project-${UID:-$(id -u)}/nvim-$(hash_key "${TMUX%%,*}:$session_id:$root").sock"
    if [[ -S "$server" ]]; then
        env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote "$full_path" >/dev/null 2>&1
        vim_window "$cwd"
    else
        vim_window "$cwd" "$full_path"
    fi
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
    session="$(tmux display-message -p '#S')"
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
run) run_or_pick "${1:-$PWD}" ;;
pick-run) pick_run_modal "${1:-$PWD}" ;;
agent-new | ai-new) agent_new "${1:-$PWD}" "${2:-}" ;;
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
tuxedo | tasks | task | todo) tuxedo_window "${1:-$PWD}" ;;
open-todo-ref) open_todo_ref "${1:-$PWD}" ;;
close-run) close_run_window "${1:-$PWD}" "${2:-}" ;;
dismiss-run) dismiss_run_window "${1:-}" ;;
run-focused)
    cwd="${1:-$PWD}"
    tmux split-window -h -c "$cwd" "drun; exec fish"
    ;;
run-tests)
    cwd="${1:-$PWD}"
    tmux split-window -h -c "$cwd" "dtest run; exec fish"
    ;;
__refresh-status) refresh_status_metadata ;;
__watch-run) watch_run_window "${1:?missing root}" "${2:?missing window}" "${3:?missing marker}" ;;
__pick-default-modal) pick_default_modal "${1:?missing root}" ;;
__nvim) nvim_runner "$@" ;;
help | -h | --help) usage ;;
*)
    echo "unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac

