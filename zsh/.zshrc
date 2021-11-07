# alias
alias zshrc="vim $HOME/.zshrc"
alias vimrc="vim $XDG_CONFIG_HOME/nvim/init.vim"
alias vim="nvim"
alias ls="ls --color=auto"
alias la="ls -A --color=auto"
alias gl="git log --oneline --graph"
alias tn="tmux new-session -s "
alias ta="tmux attach-session -t "
alias tm="tmux attach -t coffee || tmux new -s coffee"
alias tls="tmux ls"

# prompt
autoload -Uz vcs_info
autoload -U colors && colors
setopt PROMPT_SUBST
setopt autocd
zstyle ':vcs_info:git:*' formats ' [%b]'
precmd() { vcs_info }
PROMPT='%B[$(hostname -f)] %{$fg[green]%}${PWD/#$HOME/~}%{$fg[magenta]%}${vcs_info_msg_0_}%{$reset_color%} $ %b'
stty stop undef

# history
HISTSIZE=999999999
SAVEHIST=$HISTSIZE
HISTFILE=$HOME/.zsh_history

# autocomplete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# include hidden files.

# vim keys
export KEYTIMEOUT=1
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# backwards search
bindkey -v '^R' history-incremental-search-backward

# z autojump
[ -f ~/.config/z/z.sh ] && . ~/.config/z/z.sh

# keyboard repeat settings
xset r rate 250 40

# fzf variables
export FZF_DEFAULT_COMMAND="rg --files --no-ignore --hidden --sort-files -g '!{.git,vendor,.vscode,.gitlab}/*'"
export BAT_THEME="base16"

# go variables
export GOPATH=$HOME/go
export GOPRIVATE=gitlab.com/SensysGatso
export GONOSUMDB=gitlab.com/SensysGatso

# XGD variables
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DOWNLOAD_DIR=$HOME/Downloads

# paths
export PATH=$PATH:/snap/bin
export PATH=$PATH:/usr/local/sbin
export PATH=$PATH:/usr/local/zig/bin
export PATH=$PATH:/usr/local/zls/bin
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:$HOME/go/bin
