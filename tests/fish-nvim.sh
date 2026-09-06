#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/fish-nvim-test.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/scripts"
printf '#!/usr/bin/env bash\nprintf "<%%s>\\n" "$@"\n' >"$TEST_ROOT/scripts/tmux-project.sh"
chmod +x "$TEST_ROOT/scripts/tmux-project.sh"

# Load the real wrapper without running unrelated shell integrations.
awk '/^function nvim$/,/^end$/' "$ROOT/fish/.config/fish/config.fish" >"$TEST_ROOT/nvim.fish"
for separator in '' '--'; do
  actual="$(HOME="$TEST_ROOT/home" DOTFILES_DIR="$TEST_ROOT" TMUX=test NVIM= TMUX_EDIT_BYPASS= \
    fish --no-config -c 'source "$argv[1]"; nvim $argv[2..]' -- \
    "$TEST_ROOT/nvim.fish" ${separator:+"$separator"} 'file with spaces.txt')"
  expected=$'<vim-open>\n'
  [[ -z "$separator" ]] || expected+=$'<-->\n'
  expected+='<file with spaces.txt>'
  [[ "$actual" == "$expected" ]] || {
    printf 'FAIL: fish wrapper changed editor arguments:\n%s\n' "$actual" >&2
    exit 1
  }
done
printf 'fish nvim wrapper tests passed\n'
