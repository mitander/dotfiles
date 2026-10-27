#!/usr/bin/env bash
# shellcheck disable=SC2016 # Fish code and injection probes need literal dollar signs.
set -euo pipefail
ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/fish-nvim-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT

# Record argv without launching an editor or touching a workspace.
mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/bin"
for tool in myran nvim lazygit; do
  printf '#!/bin/sh\nprintf "<%%s>\\n" "%s" "$@"\n' "$tool" >"$TEST_ROOT/bin/$tool"
  chmod +x "$TEST_ROOT/bin/$tool"
done

cat >"$TEST_ROOT/bin/tmux" <<'SH'
#!/bin/sh
case "$1" in
  display-message) printf '%s\n' '$7' ;;
  show-options)
    if [ "${TEST_TMUX_FAILURE:-0}" != 0 ]; then
      exit 1
    fi
    case "$5" in
      @workspace_root) printf '%s\n' "${TEST_WORKSPACE_ROOT:-}" ;;
      @project_root) printf '%s\n' "${TEST_PROJECT_ROOT:-}" ;;
      *) exit 2 ;;
    esac
    ;;
  *) exit 2 ;;
esac
SH
chmod +x "$TEST_ROOT/bin/tmux"
mkdir -p "$TEST_ROOT/project/.git" "$TEST_ROOT/project/subdir" "$TEST_ROOT/unmanaged"
cd -P "$TEST_ROOT/project"
TEST_ROOT="$(cd "$TEST_ROOT" && pwd -P)"
export TEST_WORKSPACE_ROOT="$PWD" TEST_PROJECT_ROOT=''

# Extract only the caller functions, never source live init/integrations.
for name in nvim vim tn tm lazygit gg; do
  awk "/^function $name\$/,/^end\$/" "$ROOT/fish/.config/fish/config.fish" >>"$TEST_ROOT/callers.fish"
done
export HOME="$TEST_ROOT/home" DOTFILES_DIR="$TEST_ROOT" PATH="$TEST_ROOT/bin:$PATH"
HOME="$(cd "$HOME" && pwd)"
export HOME
export LG_CONFIG_FILE="$DOTFILES_DIR/lazygit/.config/lazygit/config.yml,$HOME/.config/lazygit/flume.yml"
export TMUX=test NVIM='' TMUX_EDIT_BYPASS=''

call() {
  fish --no-config -c 'source "$argv[1]"; $argv[2..]' -- "$TEST_ROOT/callers.fish" "$@"
}

# Forward filenames literally, but reject editor startup flags inside tmux.
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

# Keep native editor startup available outside Myran routing.
[[ "$(TMUX='' call nvim -u NONE)" == $'<nvim>\n<-u>\n<NONE>' ]]
[[ "$(NVIM=socket call vim +42)" == $'<nvim>\n<+42>' ]]
[[ "$(TMUX_EDIT_BYPASS=1 call nvim --headless)" == $'<nvim>\n<--headless>' ]]

# No matching Workspace means ordinary editing, including native startup flags.
[[ "$(TEST_WORKSPACE_ROOT='' call vim 'file with spaces')" == $'<nvim>\n<file with spaces>' ]]
[[ "$(TEST_WORKSPACE_ROOT='' call nvim -u NONE +42)" == $'<nvim>\n<-u>\n<NONE>\n<+42>' ]]
[[ "$(TEST_WORKSPACE_ROOT=/another/project call nvim -- '-literal')" == $'<nvim>\n<-->\n<-literal>' ]]
[[ "$(TEST_WORKSPACE_ROOT='' TEST_PROJECT_ROOT="$PWD" call vim)" == $'<myran>\n<open>\n<-->' ]]
[[ "$(cd subdir && call vim file.rs)" == $'<myran>\n<open>\n<-->\n<file.rs>' ]]
[[ "$(cd "$TEST_ROOT/unmanaged" && call vim file.rs)" == $'<nvim>\n<file.rs>' ]]
[[ "$(cd "$TEST_ROOT/unmanaged" && TEST_WORKSPACE_ROOT="$TEST_ROOT/unmanaged" call vim)" == $'<myran>\n<open>\n<-->' ]]

# Operational failures are not evidence that a Workspace is absent.
if TEST_TMUX_FAILURE=1 call vim >"$TEST_ROOT/out"; then
  echo 'FAIL: tmux failure was hidden' >&2
  exit 1
fi
[[ ! -s "$TEST_ROOT/out" ]]
printf '#!/bin/sh\nexit 9\n' >"$TEST_ROOT/bin/myran"
set +e
call vim >"$TEST_ROOT/out"
status=$?
set -e
[[ "$status" == 9 && ! -s "$TEST_ROOT/out" ]]
printf '#!/bin/sh\nprintf "<%%s>\\n" "%s" "$@"\n' myran >"$TEST_ROOT/bin/myran"

# Workspace shortcuts use Myran. Git retains its standalone fallback.
[[ "$(call tn 'a b')" == $'<myran>\n<workspace>\n<open>\n<a b>' ]]
[[ "$(call tm)" == $'<myran>\n<workspace>\n<switch>' ]]
[[ "$(call gg)" == $'<myran>\n<role>\n<open>\n<git>' ]]
[[ "$(TMUX='' call gg)" == "$(printf '<lazygit>\n<--use-config-file>\n<%s/lazygit/.config/lazygit/config.yml,%s/.config/lazygit/flume.yml>' "$TEST_ROOT" "$HOME")" ]]
[[ "$(TMUX='' call gg --debug)" == "$(printf '<lazygit>\n<--use-config-file>\n<%s/lazygit/.config/lazygit/config.yml,%s/.config/lazygit/flume.yml>\n<--debug>' "$TEST_ROOT" "$HOME")" ]]
printf 'PASS: Fish Myran callers, Workspace-aware editor routing, literal paths, native branches\n'
