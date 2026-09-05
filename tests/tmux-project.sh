#!/usr/bin/env bash
set -euo pipefail

ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PROJECT_SCRIPT="$ROOT/scripts/tmux-project.sh"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tmux-project-test.XXXXXX")"
SOCKET="tmux-project-test-$$"

cleanup() {
  tmux -L "$SOCKET" kill-server >/dev/null 2>&1 || true
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT INT TERM

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$TEST_ROOT/home" "$TEST_ROOT/project" "$TEST_ROOT/runtime" "$TEST_ROOT/bin"
printf '#!/bin/sh\nexec sleep 300\n' >"$TEST_ROOT/bin/lazygit"
chmod +x "$TEST_ROOT/bin/lazygit"
project_root="$(cd "$TEST_ROOT/project" && pwd -P)"
tmux -L "$SOCKET" -f /dev/null new-session -d -s smoke -c "$project_root"
session="$(tmux -L "$SOCKET" display-message -p -t smoke '#{session_id}')"
pane="$(tmux -L "$SOCKET" display-message -p -t smoke '#{pane_id}')"
socket_path="$(tmux -L "$SOCKET" display-message -p -t smoke '#{socket_path}')"
server_pid="$(tmux -L "$SOCKET" display-message -p -t smoke '#{pid}')"
tmux_env="$socket_path,$server_pid,0"
tmux -L "$SOCKET" set-option -q -t "$session" @workspace_root "$project_root"
tmux -L "$SOCKET" set-option -gq @flume_accent '#ffffff'
tmux -L "$SOCKET" set-option -gq @flume_text '#aaaaaa'

run_project() {
  HOME="$TEST_ROOT/home" XDG_RUNTIME_DIR="$TEST_ROOT/runtime" TMUX="$tmux_env" TMUX_PANE="$pane" \
    PATH="$TEST_ROOT/bin:$PATH" DOTFILES_DIR="$ROOT" "$PROJECT_SCRIPT" "$@"
}

# A conflicting deterministic server path is preserved. Neovim uses a fresh
# address, and later opens reuse that server instead of creating another window.
key="$socket_path:$session:$project_root"
if command -v shasum >/dev/null 2>&1; then
  hash="$(printf '%s' "$key" | shasum -a 256 | awk '{ print substr($1, 1, 20) }')"
else
  hash="$(printf '%s' "$key" | cksum | awk '{ print $1 }')"
fi
server_dir="$TEST_ROOT/runtime/tmux-project-${UID:-$(id -u)}"
((${#server_dir} > 70)) && server_dir="/tmp/tmux-project-${UID:-$(id -u)}"
stale_server="$server_dir/nvim-$hash.sock"
mkdir -p "$(dirname "$stale_server")"
printf stale >"$stale_server"
run_project vim "$project_root"
vim_window="$(tmux -L "$SOCKET" list-windows -t "$session" -F '#{window_id}|#{@workspace_mode}' | awk -F '|' '$2 == "vim" { print $1; exit }')"
server="$(tmux -L "$SOCKET" show-option -wqv -t "$vim_window" @workspace_vim_server 2>/dev/null || true)"
[[ -n "$server" && "$server" != "$stale_server" ]] || fail 'Neovim reused a conflicting socket address'
[[ -f "$stale_server" ]] || fail 'Neovim cleanup unlinked an unconfirmed socket owner'
for _ in $(seq 1 100); do
  [[ -S "$server" ]] && break
  sleep 0.05
done
if [[ ! -S "$server" ]]; then
  vim_root_pid="$(tmux -L "$SOCKET" display-message -p -t "$vim_window" '#{pane_pid}')"
  ps -axo pid=,ppid=,command= | awk -v root="$vim_root_pid" '$1 == root || $2 == root' >&2 || true
  tmux -L "$SOCKET" display-message -p -t "$vim_window" '#{pane_start_command}' >&2 || true
  tmux -L "$SOCKET" capture-pane -p -t "$vim_window" >&2 || true
  ls -la "$(dirname "$server")" >&2 || true
  fail 'Neovim server did not replace the stale socket path'
fi
vim_windows="$(tmux -L "$SOCKET" list-windows -t "$session" -F '#{@workspace_mode}' | grep -cx vim)"
[[ "$vim_windows" == 1 ]] || fail "expected one Neovim role window, got $vim_windows"

file="$project_root/file with spaces.txt"
printf 'hello\n' >"$file"
(
  cd "$project_root"
  run_project vim-open -- "$file"
)
for _ in $(seq 1 100); do
  opened="$(env TMUX_EDIT_BYPASS=1 nvim --server "$server" --remote-expr "bufexists('$file')" 2>/dev/null || true)"
  [[ "$opened" == 1 ]] && break
  sleep 0.05
done
[[ "$opened" == 1 ]] || fail 'remote open did not preserve the spaced file path'
vim_windows="$(tmux -L "$SOCKET" list-windows -t "$session" -F '#{@workspace_mode}' | grep -cx vim)"
[[ "$vim_windows" == 1 ]] || fail 'remote open created a duplicate Neovim window'

# Selecting a cooled restartable role wakes it immediately.
run_project git "$project_root"
git_window="$(tmux -L "$SOCKET" list-windows -t "$session" -F '#{window_id}|#{@workspace_mode}' | awk -F '|' '$2 == "git" { print $1; exit }')"
run_project git-split "$project_root"
git_panes=()
while IFS= read -r git_pane; do
  git_panes+=("$git_pane")
done < <(tmux -L "$SOCKET" list-panes -t "$git_window" -F '#{pane_id}')
[[ ${#git_panes[@]} == 2 ]] || fail 'Git split did not create a second pane'
tmux -L "$SOCKET" set-option -gq @workspace_residency_mode cool
TMUX_RESIDENCY_SOCKET="$SOCKET" "$ROOT/scripts/tmux-residency.sh" sleep "$session"
for git_pane in "${git_panes[@]}"; do
  [[ "$(tmux -L "$SOCKET" show-option -pqv -t "$git_pane" @workspace_residency_cooled)" == 1 ]] || fail 'Git pane was not cooled'
done
run_project git "$project_root"
for git_pane in "${git_panes[@]}"; do
  [[ -z "$(tmux -L "$SOCKET" show-option -pqv -t "$git_pane" @workspace_residency_cooled 2>/dev/null || true)" ]] || fail 'selecting Git did not wake every cooled pane'
done

# Managed layouts form two columns, then stack additional panes on the right.
layout_window="$(tmux -L "$SOCKET" new-window -d -P -F '#{window_id}' -t "$session:" -n layout -c "$project_root")"
left="$(tmux -L "$SOCKET" display-message -p -t "$layout_window" '#{pane_id}')"
right="$(tmux -L "$SOCKET" split-window -h -d -P -F '#{pane_id}' -t "$layout_window" -c "$project_root")"
pane="$left"
run_project normalize-layout "$layout_window"
read -r first_left first_top first_width <<<"$(tmux -L "$SOCKET" display-message -p -t "$left" '#{pane_left} #{pane_top} #{pane_width}')"
read -r second_left second_top second_width <<<"$(tmux -L "$SOCKET" display-message -p -t "$right" '#{pane_left} #{pane_top} #{pane_width}')"
[[ "$first_top" == "$second_top" && "$first_left" -lt "$second_left" ]] || fail 'two-pane role layout is not side-by-side'
width_delta=$((first_width - second_width))
((width_delta < 0)) && width_delta=$((-width_delta))
((width_delta <= 1)) || fail 'two-pane role layout is not even'

bottom_right="$(tmux -L "$SOCKET" split-window -v -d -P -F '#{pane_id}' -t "$right" -c "$project_root")"
run_project normalize-layout "$layout_window"
right_count="$(tmux -L "$SOCKET" list-panes -t "$layout_window" -F '#{pane_left}' | sort -n | uniq -c | tail -n 1 | awk '{print $1}')"
[[ "$right_count" == 2 ]] || fail 'third role pane was not stacked in the side column'
pane="$bottom_right"
tmux -L "$SOCKET" select-pane -t "$bottom_right"
promoted_pid="$(tmux -L "$SOCKET" display-message -p -t "$bottom_right" '#{pane_pid}')"
run_project promote-pane "$layout_window"
active_position="$(tmux -L "$SOCKET" display-message -p -t "$layout_window" '#{pane_left},#{pane_top}')"
active_pid="$(tmux -L "$SOCKET" display-message -p -t "$layout_window" '#{pane_pid}')"
[[ "$active_position" == 0,0 ]] || fail 'promote-pane did not focus the main position'
[[ "$active_pid" == "$promoted_pid" ]] || fail 'promote-pane focus did not follow the promoted process'

printf 'PASS: tmux project Neovim and layout scenarios\n'
