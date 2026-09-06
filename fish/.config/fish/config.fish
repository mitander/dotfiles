# general
set -q DOTFILES_DIR; or set -gx DOTFILES_DIR "$HOME/dotfiles"

# Prefer the Home Manager package profile while keeping the host login shell
# unchanged. Move existing Nix entries as well as adding missing ones: GUI apps
# can inherit a PATH where Homebrew appears before the Nix profile.
for nix_bin in /nix/var/nix/profiles/default/bin $HOME/.nix-profile/bin
    if test -d $nix_bin
        while set -l path_index (contains -i -- $nix_bin $PATH)
            set -e PATH[$path_index]
        end
        set -p PATH $nix_bin
    end
end
set -gx PATH $PATH

function nvim
    if test -n "$TMUX"; and test -z "$NVIM"; and test -z "$TMUX_EDIT_BYPASS"; and test -x "$DOTFILES_DIR/scripts/tmux-project.sh"
        # vim-open handles the editor's own optional -- separator.
        "$DOTFILES_DIR/scripts/tmux-project.sh" vim-open $argv
    else
        command nvim $argv
    end
end

function vim
    nvim $argv
end

alias so "source ~/.config/fish/config.fish"
alias :q exit
command -q tree; and alias tree "ls --tree"

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
function lazygit
    set -l configs "$DOTFILES_DIR/lazygit/.config/lazygit/config.yml,$DOTFILES_DIR/themes/flume/extras/current/lazygit.yml"
    command lazygit --use-config-file $configs $argv
end

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

# Terminal applications claim Ctrl-h/j/k/l once at process start rather than
# making tmux probe the tty process tree on every navigation keypress.
function __workspace_navigation_set
    test -n "$TMUX_PANE"; or return
    command -q tmux; or return
    command tmux set-option -pq -t "$TMUX_PANE" @workspace_navigation application
end

function __workspace_navigation_clear
    test -n "$TMUX_PANE"; or return
    command -q tmux; or return
    command tmux set-option -pu -t "$TMUX_PANE" @workspace_navigation >/dev/null 2>&1
end

# Clear claims left by nested applications after the top-level shell command.
function __workspace_navigation_postexec --on-event fish_postexec
    __workspace_navigation_clear
end

# Initial FZF value; the function below refreshes it for every invocation.
set -l flume_fzf_opts "$DOTFILES_DIR/themes/flume/extras/current/fzf.opts"
test -r "$flume_fzf_opts"; and set -gx FZF_DEFAULT_OPTS (string trim <"$flume_fzf_opts")

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

    function fzf
        set -l opts_file "$DOTFILES_DIR/themes/flume/extras/current/fzf.opts"
        if test -r "$opts_file"
            set -lx FZF_DEFAULT_OPTS (string trim <"$opts_file")
        end
        __workspace_navigation_set
        command fzf $argv
        set -l fzf_status $status
        __workspace_navigation_clear
        return $fzf_status
    end
end

if command -q hx
    function hx
        __workspace_navigation_set
        command hx $argv
        set -l hx_status $status
        __workspace_navigation_clear
        return $hx_status
    end
end

# atuin
command -q atuin; and atuin init fish --disable-up-arrow | source

# zoxide
command -q zoxide; and zoxide init fish | source

# depthbound developer DX helpers
function drun
    if test -f scripts/db-run.sh
        ./scripts/db-run.sh $argv
    else if test -f build.zig
        if test -f ./zig/zig
            ./zig/zig build run $argv
        else
            zig build run $argv
        end
    else
        echo "No scripts/db-run.sh or build.zig found in the current directory."
    end
end

function dtest
    if test -f scripts/db-test.py
        ./scripts/db-test.py $argv
    else if test -f build.zig
        if test -f ./zig/zig
            ./zig/zig build test $argv
        else
            zig build test $argv
        end
    else
        echo "No scripts/db-test.py or build.zig found in the current directory."
    end
end

abbr -a dr drun
abbr -a dt dtest
