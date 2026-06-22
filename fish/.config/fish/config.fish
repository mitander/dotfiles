# general
set -q DOTFILES_DIR; or set -gx DOTFILES_DIR "$HOME/dotfiles"

function nvim
    if test -n "$TMUX"; and test -z "$NVIM"; and test -z "$TMUX_EDIT_BYPASS"; and test -x "$DOTFILES_DIR/scripts/tmux-project.sh"
        "$DOTFILES_DIR/scripts/tmux-project.sh" vim-open -- $argv
    else
        command nvim $argv
    end
end

function vim
    nvim $argv
end

alias so "source ~/.config/fish/config.fish"
alias :q exit
command -q tree; and alias tree "tree --gitignore"

test -x ./zig/zig; and alias zig "./zig/zig"

# optional tool aliases
command -q bat; and alias cat bat
if command -q lsd
    alias ls lsd
    alias l "ls -l"
    alias la "ls -a"
    alias lla "ls -la"
    alias lt "ls --tree"
else
    alias l "ls -l"
    alias la "ls -a"
    alias lla "ls -la"
end

# tmux
function tn
    "$DOTFILES_DIR/scripts/tmux-project.sh" session $argv
end
alias ta "tmux attach-session -t "
function tm
    "$DOTFILES_DIR/scripts/tmux-session.sh" attach $argv
end
alias tls "tmux ls"

# git
function gg
    "$DOTFILES_DIR/scripts/tmux-project.sh" git $argv
end
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
alias dc docker-compose
alias dcd "docker-compose down"
alias dcu "docker-compose up"
alias dl "docker logs"
alias dps "docker ps"
alias dpp "docker-compose pull --parallel"

# linux
if test (uname) = Linux; and test -n "$DISPLAY"; and command -q xset
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

# sync history between panes
set -gx fish_history default
function fish_preexec --on-event fish_preexec
    history merge
end

function fish_postexec --on-event fish_postexec
    history save
end

# fzf command
if command -q rg
    set -gx FZF_DEFAULT_COMMAND "rg --files --no-ignore --hidden --sort-files -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'"
end

# editor and other settings
set -gx EDITOR nvim
set -gx TERMINAL ghostty
set -gx PAGER "less -RF"
set -gx MANPAGER "$PAGER"
set -gx MANWIDTH 999
set -gx KEYTIMEOUT 1

# man page
set -gx LESS_TERMCAP_mb (printf "\e[1;34m")
set -gx LESS_TERMCAP_md (printf "\e[1;34m")
set -gx LESS_TERMCAP_me (printf "\e[0m")
set -gx LESS_TERMCAP_se (printf "\e[0m")
set -gx LESS_TERMCAP_ue (printf "\e[0m")
set -gx LESS_TERMCAP_us (printf "\e[4;32m")

# xdg variables
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DOWNLOAD_DIR $HOME/Downloads

# paths
contains ~/.local/bin $PATH
or set PATH ~/.local/bin $PATH

if status is-login
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
if command -q fzf
    fzf --fish 2>/dev/null | source
end

# atuin
command -q atuin; and atuin init fish --disable-up-arrow | source

# zoxide
command -q zoxide; and zoxide init fish | source
