alias zshrc="vim $HOME/.zshrc"
alias vimrc="vim ${XDG_CONFIG_HOME:-$HOME/.config}/nvim/init.vim"
alias vim="nvim"
alias tm="tmux attach || tmux new"
alias tn="tmux new-session -s"
alias ta="tmux attach -t"
alias tls="tmux ls"
#alias ls="ls -G"
alias ls="ls --color=auto"
alias la="ls -A --color=auto"
alias gl="git log --oneline --graph"

# prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' [%b]'
setopt PROMPT_SUBST
setopt autocd
autoload -U colors && colors
PROMPT='%Bcarlos: %{$fg[green]%}${PWD/#$HOME/~}%{$fg[magenta]%}${vcs_info_msg_0_}%{$reset_color%} $ %b'
stty stop undef

# settings
HISTSIZE=10000
SAVEHIST=10000
bindkey -v
bindkey '^R' history-incremental-search-backward

# auto/tab complete
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
compinit
_comp_options+=(globdots)		# include hidden files.

# vim keys
export KEYTIMEOUT=1
bindkey -v
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# autojump
[ -f ~/.config/z/z.sh ] && . ~/.config/z/z.sh

# paths
export PATH="/usr/local/sbin:$PATH"
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOOGLE_APPLICATION_CREDENTIALS="/home/carl/code/afry/gae_sa_staging.json"
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export PATH=$PATH:$JAVA_HOME/bin

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/carl/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/home/carl/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/carl/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/home/carl/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
