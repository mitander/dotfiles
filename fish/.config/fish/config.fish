# general
alias vim "nvim"
alias so "source ~/.config/fish/config.fish"
alias :q "exit"

# bat
alias cat "bat"

# lsd
alias ls "lsd"
alias l "ls -l"
alias la "ls -a"
alias lla "ls -la"
alias lt "ls --tree"

# tmux
alias tn "tmuxinator start session -n (basename (pwd))"
alias ta "tmux attach-session -t "
alias tm "~/dotfiles/scripts/tmux-session.sh attach"
alias tls "tmux ls"

# git
alias gg "lazygit"
alias gs "git status"
alias gl "git log --oneline --graph --color=always --abbrev-commit --date=short | less -REX"
alias gc "git commit"
alias ga "git add"
alias gaa "git add ."
alias gp "git push"
alias gpp "git push --force"
alias gr "git rebase -i"
alias ge "git commit --amend --no-edit"
alias gx "git commit --no-verify"

# docker
alias dc "docker-compose"
alias dcd "docker-compose down"
alias dcu "docker-compose up"
alias dl "docker logs"
alias dps "docker ps"
alias dpp "docker-compose pull --parallel"

# linux
if test (uname) = "Linux"
    xset r rate 275 40
end

# disable greeting
set fish_greeting

# vi bindings
fish_vi_key_bindings
function fish_mode_prompt
    # disable mode indicator
end

# prompt
function fish_prompt
    set_color --bold white
    echo -n "[$(hostname)] "
    set_color --bold blue
    echo -n (prompt_pwd)
    set_color --bold green
    set branch_output (fish_git_prompt)
    set branch_output (string replace -r '\(' '[' -- $branch_output)
    set branch_output (string replace -r '\)' ']' -- $branch_output)
    echo -n $branch_output
    set_color normal
    echo -n " \$ "
end

function fish_right_prompt
    set_color --bold blue
    echo -n $(date +%H:%M:%S)
end

#sync history between panes
set -Ux fish_history default
function fish_preexec --on-event fish_preexec
    history merge
end

function fish_postexec --on-event fish_postexec
    history save
end

# fzf command
set -Ux FZF_DEFAULT_COMMAND "rg --files --no-ignore --hidden --sort-files -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'"

# editor and other settings
set -Ux EDITOR "nvim"
set -Ux TERMINAL "alacritty"
set -Ux BROWSER "firefox"
set -Ux PAGER "less -RF"
set -Ux MANPAGER "$PAGER"
set -Ux MANWIDTH "999"
set -Ux KEYTIMEOUT 1

# man page
set -Ux LESS_TERMCAP_mb (printf "\e[1;34m")
set -Ux LESS_TERMCAP_md (printf "\e[1;34m")
set -Ux LESS_TERMCAP_me (printf "\e[0m")
set -Ux LESS_TERMCAP_se (printf "\e[0m")
set -Ux LESS_TERMCAP_ue (printf "\e[0m")
set -Ux LESS_TERMCAP_us (printf "\e[4;32m")

# xgd variables
set -Ux XDG_DATA_HOME $HOME/.local/share
set -Ux XDG_CONFIG_HOME $HOME/.config
set -Ux XDG_CACHE_HOME $HOME/.cache
set -Ux XDG_DOWNLOAD_DIR $HOME/Downloads

# paths
if status is-login
    contains ~/.local/bin $PATH
    or set PATH ~/.local/bin $PATH

    contains /usr/bin $PATH
    or set PATH /usr/bin $PATH

    contains /usr/local/bin $PATH
    or set PATH /usr/local/bin $PATH
end

# custom paths
test -r $HOME/.custom.fish; and source $HOME/.custom.fish

# fish-autosuggestions
test -f ~/.config/fish/scripts/fish-autosuggestions.fish; and source ~/.config/fish/scripts/fish-autosuggestions.fish

# fzf
fzf --fish | source

# atuin
atuin init fish --disable-up-arrow | source

# zoxide
zoxide init fish | source
