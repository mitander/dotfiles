#!/usr/bin/env bash
# shellcheck disable=SC2016 # Fish code and injection probes need literal dollar signs.
set -euo pipefail
ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/fish-nvim-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"
for tool in myran nvim lazygit; do
  printf '#!/bin/sh\nprintf "<%%s>\\n" "%s" "$@"\n' "$tool" >"$TEST_ROOT/bin/$tool"
  chmod +x "$TEST_ROOT/bin/$tool"
done
# Extract only the caller functions, never source live init/integrations.
for name in nvim vim tn tm lazygit gg; do
  awk "/^function $name\$/,/^end\$/" "$ROOT/fish/.config/fish/config.fish" >>"$TEST_ROOT/callers.fish"
done
export HOME="$TEST_ROOT/home" DOTFILES_DIR="$TEST_ROOT" PATH="$TEST_ROOT/bin:$PATH"
export TMUX=test NVIM='' TMUX_EDIT_BYPASS=''
call() { fish --no-config -c 'source "$argv[1]"; $argv[2..]' -- "$TEST_ROOT/callers.fish" "$@"; }
[[ "$(call nvim 'file with spaces' '$(touch BAD)' 'a;b')" == $'<myran>\n<open>\n<-->\n<file with spaces>\n<$(touch BAD)>\n<a;b>' ]]
[[ "$(call vim -- '-literal' '+literal')" == $'<myran>\n<open>\n<-->\n<-literal>\n<+literal>' ]]
[[ "$(call nvim)" == $'<myran>\n<open>\n<-->' ]]
for option in -u +42 --headless; do
  if call nvim "$option" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
    echo 'FAIL: startup flag accepted' >&2
    exit 1
  fi
  grep -q 'command nvim' "$TEST_ROOT/error"
  [[ ! -s "$TEST_ROOT/out" ]]
done
[[ "$(TMUX='' call nvim -u NONE)" == $'<nvim>\n<-u>\n<NONE>' ]]
[[ "$(NVIM=socket call vim +42)" == $'<nvim>\n<+42>' ]]
[[ "$(TMUX_EDIT_BYPASS=1 call nvim --headless)" == $'<nvim>\n<--headless>' ]]
[[ "$(call tn 'a b')" == $'<myran>\n<workspace>\n<open>\n<a b>' ]]
[[ "$(call tm)" == $'<myran>\n<workspace>\n<switch>' ]]
[[ "$(call gg)" == $'<myran>\n<role>\n<open>\n<git>' ]]
[[ "$(TMUX='' call gg)" == "$(printf '<lazygit>\n<--use-config-file>\n<%s/lazygit/.config/lazygit/config.yml,%s/themes/flume/extras/current/lazygit.yml>' "$TEST_ROOT" "$TEST_ROOT")" ]]
[[ "$(TMUX='' call gg --debug)" == "$(printf '<lazygit>\n<--use-config-file>\n<%s/lazygit/.config/lazygit/config.yml,%s/themes/flume/extras/current/lazygit.yml>\n<--debug>' "$TEST_ROOT" "$TEST_ROOT")" ]]
printf 'PASS: Fish Myran callers, literal paths, rejected startup flags, native branches\n'
