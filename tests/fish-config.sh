#!/usr/bin/env bash
# shellcheck disable=SC2016 # Fish snippets must retain their literal variables.
set -euo pipefail
ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/fish-config-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
FISH="$(command -v fish)"
FZF_BINARY="$(command -v fzf)"
mkdir -p "$TEST_ROOT/home/.nix-profile/bin" "$TEST_ROOT/home/.dprint/bin" "$TEST_ROOT/home/.config/fish" "$TEST_ROOT/bin" "$TEST_ROOT/project/target"
printf '#!/bin/sh\nexit 0\n' >"$TEST_ROOT/home/.dprint/bin/dprint"
chmod +x "$TEST_ROOT/home/.dprint/bin/dprint"
ln -s "$ROOT/fish/.config/fish/config.fish" "$TEST_ROOT/home/.config/fish/config.fish"
for tool in fzf atuin zoxide; do
  printf '#!/bin/sh\nprintf "%%s\\n" "%s" >> "$DOTFILES_TEST_CALLS"\n' "$tool" >"$TEST_ROOT/bin/$tool"
  chmod +x "$TEST_ROOT/bin/$tool"
done
export HOME="$TEST_ROOT/home" XDG_CONFIG_HOME="$TEST_ROOT/home/.config"
export XDG_DATA_HOME="$TEST_ROOT/home/.local/share" XDG_CACHE_HOME="$TEST_ROOT/home/.cache"
export DOTFILES_TEST_CALLS="$TEST_ROOT/calls" DOTFILES_TEST_CONFIG="$ROOT/fish/.config/fish/config.fish"
export DOTFILES_DIR="$ROOT" PATH="$TEST_ROOT/bin:$PATH" TMUX='' TMUX_PANE='' DISPLAY=''
# The word inside a quoted preview is not an input-delimiter option.
export FZF_CTRL_T_OPTS=' --preview "echo --read0 preview"'
# Prevent an installed macOS Homebrew from changing this isolated test environment.
export HOMEBREW_PREFIX=/opt/homebrew
export PATH="$PATH:/opt/homebrew/bin"

# Repeated sourcing must not grow PATH or initialize interactive tools.
"$FISH" --no-config -c 'source "$DOTFILES_TEST_CONFIG";
    set -l initial_path_count (count $PATH)
    source "$DOTFILES_TEST_CONFIG"
    test (count $PATH) -eq $initial_path_count; or exit 1
    set -l nix_index (contains -i -- "$HOME/.nix-profile/bin" $PATH)
    set -l brew_index (contains -i -- /opt/homebrew/bin $PATH)
    test $nix_index -lt $brew_index; or exit 1
    command -q dprint; or exit 1
    not functions -q fzf; or exit 1'
[[ ! -e "$DOTFILES_TEST_CALLS" ]] || {
  echo 'FAIL: noninteractive shell initialized UI tools' >&2
  exit 1
}

# Personal configuration must preserve Flume-owned colors and native tool settings.
"$FISH" --no-config -c 'set -gx FZF_DEFAULT_OPTS_FILE /provided/fzf.opts
    set -gx LG_CONFIG_FILE /provided/lazygit.yml
    set -gx LS_COLORS "di=34:ow=0;35"
    set -g fish_color_error 123456
    set -g fish_color_autosuggestion abcdef
    source "$DOTFILES_TEST_CONFIG"
    test "$FZF_DEFAULT_OPTS_FILE" = /provided/fzf.opts; or exit 1
    test "$LG_CONFIG_FILE" = /provided/lazygit.yml; or exit 1
    test "$LS_COLORS" = "di=34:ow=0;35"; or exit 1
    test "$fish_color_error" = 123456; or exit 1
    test "$fish_color_autosuggestion" = abcdef; or exit 1
    not functions -q lazygit; or exit 1'

# Only explicit successful reload/apply refresh installed Flume fragments in this shell.
mkdir -p "$XDG_CONFIG_HOME/fish/conf.d"
printf 'set -g fish_color_error abcdef\n' >"$XDG_CONFIG_HOME/fish/conf.d/flume.fish"
printf 'set -gx FLUME_TEST_TOOLS refreshed\n' >"$XDG_CONFIG_HOME/fish/conf.d/flume-tools.fish"
printf 'exit 99\n' >"$XDG_CONFIG_HOME/fish/conf.d/unrelated.fish"
printf '#!/bin/sh\nexit "${DOTFILES_TEST_STATUS:-0}"\n' >"$TEST_ROOT/bin/dotfiles"
chmod +x "$TEST_ROOT/bin/dotfiles"
"$FISH" --no-config -c 'source "$DOTFILES_TEST_CONFIG"
    set -g fish_color_error 123456
    dotfiles
    test "$fish_color_error" = 123456; or exit 1
    dotfiles help
    test "$fish_color_error" = 123456; or exit 1
    dotfiles reload
    test "$fish_color_error" = abcdef; or exit 1
    test "$FLUME_TEST_TOOLS" = refreshed; or exit 1
    set -g fish_color_error 654321
    set -gx DOTFILES_TEST_STATUS 42
    dotfiles reload
    test $status -eq 42; or exit 1
    test "$fish_color_error" = 654321; or exit 1
    set -e DOTFILES_TEST_STATUS
    dotfiles apply
    test "$fish_color_error" = abcdef; or exit 1'
rm "$XDG_CONFIG_HOME/fish/conf.d/"*.fish

# Interactive shells initialize each UI integration once.
"$FISH" --no-config -i -c 'source "$DOTFILES_TEST_CONFIG"; functions -q fzf' >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
for tool in fzf atuin zoxide; do
  [[ "$(grep -cx "$tool" "$DOTFILES_TEST_CALLS")" == 1 ]]
done

# Completion bindings survive reloads without changing Enter, Escape or Ctrl-J/K.
"$FISH" --no-config -i -c 'source "$DOTFILES_TEST_CONFIG"
    source "$DOTFILES_TEST_CONFIG"
    for key in tab ctrl-i
        bind -M insert $key | string match -q "*complete-and-search*"; or exit 1
        bind --user -M insert $key | string unescape | string match -q "*commandline --search-field*"; or exit 1
    end
    test (bind --user -M insert ctrl-n) = "bind -M insert ctrl-n down-or-search"; or exit 1
    test (bind -M insert ctrl-p) = "bind -M insert ctrl-p up-or-search"; or exit 1
    for key in enter ctrl-j
        bind -M insert $key | string match -q "* $key execute"; or exit 1
    end
    bind -M insert ctrl-k | string match -q "* ctrl-k kill-line"; or exit 1
    bind -M insert escape | string unescape | string match -q "*commandline -f cancel*"; or exit 1
' >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"

# File discovery must respect Git ignores, including through shell aliases.
git -C "$TEST_ROOT/project" init -q
printf 'target/\n' >"$TEST_ROOT/project/.gitignore"
printf 'source\n' >"$TEST_ROOT/project/name with spaces.rs"
printf 'hidden\n' >"$TEST_ROOT/project/.hidden"
printf 'ignored\n' >"$TEST_ROOT/project/target/artifact"
cd "$TEST_ROOT/project"
# Keep filename display stable across tree versions while testing ignore behavior.
for listing in tree lt; do
  "$FISH" --no-config -c 'source "$DOTFILES_TEST_CONFIG"; $argv[1] --noreport -N' -- "$listing" >"$TEST_ROOT/tree"
  grep -q 'name with spaces.rs' "$TEST_ROOT/tree"
  if grep -q 'target\|artifact' "$TEST_ROOT/tree"; then
    echo "FAIL: $listing included gitignored files" >&2
    exit 1
  fi
done
"$FISH" --no-config -c 'source "$DOTFILES_TEST_CONFIG"; eval $FZF_DEFAULT_COMMAND' >"$TEST_ROOT/files"
grep -qx 'name with spaces.rs' "$TEST_ROOT/files"
grep -qx '.hidden' "$TEST_ROOT/files"
if grep -q 'target/artifact\|^\.git/' "$TEST_ROOT/files"; then
  echo 'FAIL: default discovery included ignored files' >&2
  exit 1
fi

# Ctrl-T must preserve literal roots and NUL-delimited filenames.
prefix='source dir;$(touch BAD)'
mkdir -p "$prefix/target"
printf 'source\n' >"$prefix/inner.rs"
printf 'ignored\n' >"$prefix/target/artifact"
"$FISH" --no-config -c 'source "$DOTFILES_TEST_CONFIG";
    set -gx dir (string escape -n -- "$argv[1]"); eval $FZF_CTRL_T_COMMAND' -- "$prefix" >"$TEST_ROOT/widget-files"
grep -aFq "$prefix/inner.rs" "$TEST_ROOT/widget-files"
if grep -aq 'target/artifact' "$TEST_ROOT/widget-files" || [[ -e BAD ]]; then
  echo 'FAIL: Ctrl-T ignored its root/ignore rules or interpreted a path as commands' >&2
  exit 1
fi
newline_file="$prefix/name"$'\n''newline.rs'
printf 'source\n' >"$newline_file"
"$FISH" --no-config -c 'source "$DOTFILES_TEST_CONFIG";
    set -gx dir (string escape -n -- "$argv[1]")
    set -gx FZF_DEFAULT_OPTS "$FZF_CTRL_T_OPTS"; set -e FZF_DEFAULT_OPTS_FILE
    eval $FZF_CTRL_T_COMMAND | "$argv[2]" --print0 --filter=newline.rs' -- "$prefix" "$FZF_BINARY" >"$TEST_ROOT/selection"
printf '%s\0' "$newline_file" >"$TEST_ROOT/expected"
cmp "$TEST_ROOT/expected" "$TEST_ROOT/selection"
newline_dir="$prefix/directory"$'\n'
mkdir "$newline_dir"
printf 'source\n' >"$newline_dir/nested.rs"
"$FISH" --no-config -c 'source "$DOTFILES_TEST_CONFIG";
    set -gx dir (string escape -n -- "$argv[1]")
    set -gx FZF_DEFAULT_OPTS "$FZF_CTRL_T_OPTS"; set -e FZF_DEFAULT_OPTS_FILE
    eval $FZF_CTRL_T_COMMAND | "$argv[2]" --print0 --filter=nested.rs' -- "$newline_dir" "$FZF_BINARY" >"$TEST_ROOT/selection"
printf '%s\0' "$newline_dir/nested.rs" >"$TEST_ROOT/expected"
cmp "$TEST_ROOT/expected" "$TEST_ROOT/selection"
printf 'PASS: Fish UI initialization, completion bindings, PATH priority, ignored files, Ctrl-T literal/NUL paths\n'
