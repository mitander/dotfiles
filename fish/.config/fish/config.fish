# Environment and shell paths
set -q DOTFILES_DIR; or set -gx DOTFILES_DIR "$HOME/dotfiles"

if test -x /opt/homebrew/bin/brew
    if not set -q HOMEBREW_PREFIX; or not contains -- /opt/homebrew/bin $PATH
        # Initialize Homebrew before applying Nix PATH priority.
        eval (/opt/homebrew/bin/brew shellenv fish)
    end
end

# Keep the Home Manager profile ahead of host packages.
for nix_bin in /nix/var/nix/profiles/default/bin $HOME/.nix-profile/bin
    if test -d $nix_bin
        while set -l path_index (contains -i -- $nix_bin $PATH)
            set -e PATH[$path_index]
        end
        set -p PATH $nix_bin
    end
end
set -gx PATH $PATH

# Editor routing
function nvim
    if test -n "$TMUX"; and test -z "$NVIM"; and test -z "$TMUX_EDIT_BYPASS"
        set -l paths
        set -l literal 0

        for arg in $argv
            if test $literal = 0; and test "$arg" = --
                set literal 1
                continue
            end
            if test $literal = 0; and string match -qr '^[+-]' -- "$arg"
                echo 'Use command nvim for startup flags or +commands (myran open accepts paths only).' >&2
                return 2
            end
            set -a paths "$arg"
        end

        myran open -- $paths
    else
        command nvim $argv
    end
end

function vim
    nvim $argv
end

# Configuration reload
alias so "source ~/.config/fish/config.fish"

function dotfiles
    command dotfiles $argv
    set -l dotfiles_status $status

    if test $dotfiles_status = 0; and test (count $argv) -eq 0
        source ~/.config/fish/config.fish
    else if test $dotfiles_status = 0; and contains -- $argv[1] reload apply
        source ~/.config/fish/config.fish
    end
    return $dotfiles_status
end

# Command aliases
alias :q exit
if command -q tree
    alias tree "tree --gitignore"
    alias lt tree
end

test -x ./zig/zig; and alias zig "./zig/zig"

command -q bat; and alias cat bat
command -q lsd; and alias ls lsd
alias l "ls -l"
alias la "ls -a"
alias lla "ls -la"

# Workspaces
function tn
    myran workspace open $argv
end
alias ta "tmux attach-session -t "
function tm
    myran workspace switch $argv
end
alias tls "tmux ls"

# Git
set -gx LG_CONFIG_FILE "$DOTFILES_DIR/lazygit/.config/lazygit/config.yml,$HOME/.config/lazygit/flume.yml"

function lazygit
    command lazygit --use-config-file "$LG_CONFIG_FILE" $argv
end

function gg
    if test -n "$TMUX"
        myran role open git $argv
    else
        lazygit $argv
    end
end

function gs
    git status $argv
    git diff --stat

    for file in (git ls-files --others --exclude-standard)
        git diff --no-index --stat /dev/null "$file"; or true
    end
end

alias gl "git log --oneline --graph --color=always --abbrev-commit --date=short | less -REX"
alias gc "git commit"
alias ga "git add"
alias gaa "git add ."
alias gp "git push"
alias gpp "git push --force"
alias gr "git rebase -i"
alias ge "git commit --amend --no-edit"
alias gx "git commit --no-verify"

# Docker
alias dc docker-compose
alias dcd "docker-compose down"
alias dcu "docker-compose up"
alias dl "docker logs"
alias dps "docker ps"
alias dpp "docker-compose pull --parallel"

# Interactive behavior
# Set the X11 keyboard repeat rate on Linux.
if status is-interactive; and test -n "$DISPLAY"; and command -q xset; and test (uname) = Linux
    xset r rate 275 40
end

set fish_greeting

if status is-interactive
    fish_vi_key_bindings
end

function fish_mode_prompt
    # The prompt already shows the editing context. Hide the extra mode indicator.
end

# ANSI roles follow the terminal's active theme palette.
set -g fish_color_error red
set -g fish_color_autosuggestion brblack

# Prompt
function fish_prompt
    set -l last_status $status

    set_color --bold white
    echo -n "[$hostname] "
    set_color --bold blue
    echo -n (prompt_pwd)

    set_color --bold green
    set -l branch_output (fish_git_prompt)
    set branch_output (string replace -r '\(' '[' -- $branch_output)
    set branch_output (string replace -r '\)' ']' -- $branch_output)
    echo -n $branch_output
    set_color normal
    echo -n " "

    if test $last_status -ne 0
        set_color red
    end
    echo -n '$'
    set_color normal
    echo -n " "
end

function fish_right_prompt
    set_color brblack
    echo -n $(date +%H:%M:%S)
    set_color normal
end

# Shared history
# Keep commands available across panes.
set -gx fish_history default
function fish_preexec --on-event fish_preexec
    history merge
end

function fish_postexec --on-event fish_postexec
    history save
end

# Pane navigation
# Let terminal applications claim pane navigation keys.
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

# Clear claims after each command.
function __workspace_navigation_postexec --on-event fish_postexec
    __workspace_navigation_clear
end

# File discovery
# fzf reads the active theme on each invocation. Keep personal options separate.
set -gx FZF_DEFAULT_OPTS_FILE "$DOTFILES_DIR/themes/flume/extras/current/fzf.opts"

if command -q rg
    set -gx FZF_DEFAULT_COMMAND "rg --files --hidden -g '!{.git,vendor,.vscode,.gitlab,*cache*}/*'"
end

# Ctrl-T uses a separate command with directory-prefix and ignore support.
function __dotfiles_fzf_files
    set -l root .
    if set -q dir; and test -n "$dir"
        # Keep directory newlines inside one record, including at the end of its name.
        set root (string unescape -- "$dir/" | string collect)
    end

    if command -q fd
        command fd --print0 --color=never --type f --type d --hidden --follow --exclude .git -- . "$root"
    else
        command rg --files --null --hidden -g '!.git' -- "$root"
    end
end

set -gx FZF_CTRL_T_COMMAND 'fish -c __dotfiles_fzf_files'
set -gx FZF_CTRL_T_OPTS "$FZF_CTRL_T_OPTS --read0"

# Editors and pagers
set -gx EDITOR nvim
set -gx TERMINAL ghostty
set -gx PAGER "less -RF"
set -gx MANPAGER "$PAGER"
set -gx MANWIDTH 999
set -gx KEYTIMEOUT 1

# Manual-page colors
set -gx LESS_TERMCAP_mb (printf "\e[1;34m")
set -gx LESS_TERMCAP_md (printf "\e[1;34m")
set -gx LESS_TERMCAP_me (printf "\e[0m")
set -gx LESS_TERMCAP_se (printf "\e[0m")
set -gx LESS_TERMCAP_ue (printf "\e[0m")
set -gx LESS_TERMCAP_us (printf "\e[4;32m")

# XDG directories
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DOWNLOAD_DIR $HOME/Downloads

# Extra paths
contains ~/.local/bin $PATH
or set PATH ~/.local/bin $PATH

if test -d "$HOME/.dprint/bin"
    fish_add_path --global --append --path "$HOME/.dprint/bin"
end

if status is-login
    contains /usr/bin $PATH
    or set PATH /usr/bin $PATH

    contains /usr/local/bin $PATH
    or set PATH /usr/local/bin $PATH
end

# Local overrides and integrations
test -r $HOME/.custom.fish; and source $HOME/.custom.fish

test -f ~/.config/fish/scripts/fish-autosuggestions.fish; and source ~/.config/fish/scripts/fish-autosuggestions.fish

if status is-interactive; and command -q fzf
    fzf --fish 2>/dev/null | source

    function fzf
        __workspace_navigation_set
        command fzf $argv
        set -l fzf_status $status
        __workspace_navigation_clear
        return $fzf_status
    end
end

status is-interactive; and command -q atuin; and atuin init fish --disable-up-arrow | source
status is-interactive; and command -q zoxide; and zoxide init fish | source
