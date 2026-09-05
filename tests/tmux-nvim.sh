#!/usr/bin/env bash
set -euo pipefail

ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HELPER="$ROOT/scripts/tmux-nvim.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmux-nvim-test.XXXXXX")"
SOCKET="tmux-nvim-test-$$"

cleanup() {
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/work"
cat >"$TEST_ROOT/bin/nvim" <<'EOF'
#!/usr/bin/env bash
{
  printf 'cwd=<%s>\n' "$PWD"
  for arg in "$@"; do printf 'arg=<%s>\n' "$arg"; done
} >>"$NVIM_TEST_LOG"
EOF
chmod +x "$TEST_ROOT/bin/nvim"
export PATH="$TEST_ROOT/bin:$PATH"
export NVIM_TEST_LOG="$TEST_ROOT/nvim.log"

argfile="$TEST_ROOT/args"
printf '%s\0' 'one two.txt' '-leading-dash' >"$argfile"
env -u TMUX -u TMUX_PANE "$HELPER" run "$TEST_ROOT/server.sock" "$argfile"
[[ ! -e "$argfile" ]] || fail 'run helper did not remove its argument file'
grep -Fq 'arg=<--listen>' "$NVIM_TEST_LOG" || fail 'run helper omitted --listen'
grep -Fq 'arg=<one two.txt>' "$NVIM_TEST_LOG" || fail 'run helper split a spaced argument'
grep -Fq 'arg=<-leading-dash>' "$NVIM_TEST_LOG" || fail 'run helper lost a leading-dash argument'

: >"$NVIM_TEST_LOG"
env -u TMUX -u TMUX_PANE "$HELPER" open "$TEST_ROOT/server.sock" "$TEST_ROOT/work" -- 'another file.txt'
work_dir="$(cd "$TEST_ROOT/work" && pwd -L)"
grep -Fq "cwd=<$work_dir>" "$NVIM_TEST_LOG" || fail 'open helper used the wrong working directory'
grep -Fq 'arg=<--remote-tab-silent>' "$NVIM_TEST_LOG" || fail 'open helper omitted remote-tab mode'
grep -Fq 'arg=<another file.txt>' "$NVIM_TEST_LOG" || fail 'open helper split a spaced path'

# Prefer explicit pane metadata over process inspection.
tmux -L "$SOCKET" -f /dev/null new-session -d -s smoke -c "$TEST_ROOT/work"
window="$(tmux -L "$SOCKET" display-message -p -t smoke '#{window_id}')"
pane="$(tmux -L "$SOCKET" display-message -p -t smoke '#{pane_id}')"
tmux -L "$SOCKET" set-option -wq -t "$window" @workspace_vim_pane "$pane"
socket_path="$(tmux -L "$SOCKET" display-message -p -t smoke '#{socket_path}')"
server_pid="$(tmux -L "$SOCKET" display-message -p -t smoke '#{pid}')"
found="$(TMUX="$socket_path,$server_pid,0" TMUX_PANE="$pane" "$HELPER" find-pane "$window")"
[[ "$found" == "$pane" ]] || fail 'find-pane ignored workspace metadata'

printf 'PASS: tmux Neovim helper boundaries\n'
