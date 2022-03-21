# xgd variables
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DOWNLOAD_DIR=$HOME/Downloads

# path
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:/usr/local/bin"
export PATH="$PATH:/usr/bin"

# settings
export EDITOR="nvim"
export TERMINAL="alacritty"
export BROWSER="firefox"
export PAGER="nvim +Man!"
export MANPAGER="$PAGER"
export MANWIDTH="999"

# dotfiles
export DOTFILES=$HOME/dotfiles

# alias
alias zshrc="vim $HOME/.zshrc"
alias zshc="vim $HOME/.zsh.custom"
alias vimrc="vim $DOTFILES/nvim/.config/nvim/init.vim"
alias alarc="vim $DOTFILES/alacritty/.config/alacritty/alacritty.yml"
alias vim="nvim"
alias ls="ls --color=auto"
alias l="ls -A --color=auto"
alias tn="tmux new-session -s "
alias ta="tmux attach-session -t "
alias tm="tmux attach -t coffee || tmux new -s coffee"
alias tls="tmux ls"
alias gs="git status"
alias gl="git log --oneline --graph --color=always --abbrev-commit --date=short |less -REX"
alias gc="git commit"
alias ga="git add"
alias gaa="git add ."
alias gp="git push"
alias gpp="git push --force"
alias gr="git rebase -i"
alias ge="git commit --amend --no-edit"
alias so="source ~/.zshrc"

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

# fzf command
export FZF_DEFAULT_COMMAND="rg --files --no-ignore --hidden --sort-files -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'"

# linux specific
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xset r rate 275 40
fi

# macos specific
if [[ "$OSTYPE" == "darwin"* ]]; then
  alias ls="ls -G"
  bindkey "ç" fzf-cd-widget
fi

# man page color
export LESS_TERMCAP_mb=$'\e[1;34m'
export LESS_TERMCAP_md=$'\e[1;34m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;32m'

# load z autojump
[ -f ~/.config/z/z.sh ] && . ~/.config/z/z.sh

# load custom config
[ -r .zsh.custom ] && source .zsh.custom
