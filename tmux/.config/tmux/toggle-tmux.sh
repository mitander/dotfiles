#!/bin/zsh
P=$(tmux show -wqv @terminal)
if [ -n "$P" ] && tmux lsp -F'#{pane_id}'|grep -q ^$P; then
     tmux killp -t$P
     tmux set -wu @terminal
else
     P=$(tmux splitw -l 15 -PF'#{pane_id}')
     tmux set -w @terminal "$P"
fi
