# general
alias vim="nvim"
alias so="source ~/.zshrc"
alias :q="exit"

# config
alias zshc="vim $HOME/.custom.zsh"
alias zshrc="vim $HOME/dotfiles/zsh/.zshrc"
alias vimrc="vim $HOME/dotfiles/nvim/.config/nvim/init.vim"
alias alarc="vim $HOME/dotfiles/alacritty/.config/alacritty/alacritty.yml"

# tmux
alias tn="tmux new-session -s "
alias ta="tmux attach-session -t "
alias tm="tmux attach -t coffee || tmux new -s coffee"
alias tls="tmux ls"

# git
alias lg="lazygit"
alias gs="git status"
alias gl="git log --oneline --graph --color=always --abbrev-commit --date=short |less -REX"
alias gc="git commit"
alias ga="git add"
alias gaa="git add ."
alias gp="git push"
alias gpp="git push --force"
alias gr="git rebase -i"
alias ge="git commit --amend --no-edit"
alias gx="git commit --no-verify"

# docker
alias dc="docker-compose"
alias dcd="docker-compose down"
alias dcu="docker-compose up"
alias dl= "docker logs"
alias dps="docker ps"
alias dpp="docker-compose pull --parallel"

# linux
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  alias ls="ls --color=auto"
  alias la="ls -A --color=auto"

  xset r rate 275 40

  source /usr/share/doc/fzf/examples/key-bindings.zsh
  source /usr/share/doc/fzf/examples/completion.zsh
fi

# macos
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ls="ls -G"
  alias la="ls -GA"

  bindkey "ç" fzf-cd-widget
  source ~/.fzf.zsh
  bindkey -r "^T"
fi

# fzf command
export FZF_DEFAULT_COMMAND="rg --files --no-ignore --hidden --sort-files -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'"

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

# share history between panes
setopt inc_append_history
setopt sharehistory

# fix zsh globbing expr
setopt +o nomatch

# autocomplete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# include hidden files.

# vim keys
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# settings
export EDITOR="nvim"
export TERMINAL="alacritty"
export BROWSER="firefox"
export PAGER="nvim +Man!"
export MANPAGER="$PAGER"
export MANWIDTH="999"
export KEYTIMEOUT=1

# man page color
export LESS_TERMCAP_mb=$'\e[1;34m'
export LESS_TERMCAP_md=$'\e[1;34m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;32m'

# xgd variables
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DOWNLOAD_DIR=$HOME/Downloads

# path
export PATH=$PATH:/usr/bin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:$HOME/.local/bin
export PATH=$PATH:$HOME/.bashmatic/bin

# load custom paths
[ -r ~/.custom.zsh ] && source ~/.custom.zsh

# load z
[ -f ~/.config/z/z.sh ] && source ~/.config/z/z.sh

# load bashmatic
[ -f ~/.bashmatic/init.sh ] && source ~/.bashmatic/init.sh
