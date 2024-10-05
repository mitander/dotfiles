#!/usr/bin/env bash
source "$HOME/.tmux/plugins/tmux-fzf/scripts/.envs"

FZF_DEFAULT_OPTS="$FZF_DEFAULT_OPTS --header='Select an action.'"

sessions=$(tmux list-sessions)
current_session=$(tmux display-message -p | sed -e 's/^\[//' -e 's/\].*//')

if [[ "$1" == "switch" ]]; then
    command="switch-client"
    sessions=$(echo "$sessions" | grep -v "^$current_session: ")
    selection=$(printf "%s\n[cancel]" "$sessions" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS")
elif [[ "$1" == "attach" ]]; then
    command="attach-session"
    selection=$(printf "%s\n[cancel]" "$sessions" | eval "$TMUX_FZF_BIN $TMUX_FZF_OPTIONS")
else
    echo "Invalid action: $1"
fi

[[ "$selection" == "[cancel]" || -z "$selection" ]] && exit
target=$(echo "$selection" | sed -e 's/:.*$//')
tmux "$command" -t "$target"
