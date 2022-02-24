# xgd variables
export XDG_CONFIG_HOME=$HOME/.config
export XDG_CACHE_HOME=$HOME/.cache
export XDG_DOWNLOAD_DIR=$HOME/Downloads

# alias
alias zshrc="vim $HOME/.zshrc"
alias vimrc="vim $XDG_CONFIG_HOME/nvim/init.vim"
alias alarc="vim $XDG_CONFIG_HOME/alacritty/alacritty.yml"
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

# fzf variables
export FZF_DEFAULT_COMMAND="rg --files --no-ignore --hidden --sort-files -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'"

# linux/macos
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  xset r rate 275 40
  export GOROOT="/usr/local/go"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  export ZIG=/usr/local/zig
  export ZLS=/usr/local/zls
  export GOROOT=/opt/homebrew/opt/go/libexec
fi

# variables
export ZIG=/usr/local/zig
export ZLS=/usr/local/zls
export GOPATH=$HOME/go

export EDITOR="nvim"
export TERMINAL="alacritty"
export BROWSER="firefox"
export PAGER="nvim +Man!"
export MANPAGER="$PAGER"
export MANWIDTH="999"

# path
export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$ZIG/bin"
export PATH="$PATH:$ZLS/bin"
export PATH="$PATH:$GOPATH/bin"
export PATH="$PATH:$GOROOT/bin"
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:$HOME/.cargo/bin"

# man page color
export LESS_TERMCAP_mb=$'\e[1;34m'
export LESS_TERMCAP_md=$'\e[1;34m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_ue=$'\e[0m'
export LESS_TERMCAP_us=$'\e[4;32m'

# # allow vim to open files from terminal buffer with "vim [filename]"
# # if nvr is installed, set listen address
# if type -f nvr > /dev/null; then
#   alias vim="NVIM_LISTEN_ADDRESS=/tmp/nvimsocket nvim"
#   if [ -n "${NVIM_LISTEN_ADDRESS}" ]; then
#     function nvim() {nvr $1}
#   fi
# fi

[ -r .zsh.custom ] && source .zsh.custom
