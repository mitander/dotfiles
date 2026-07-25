#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: tmux-session.sh switch|attach|list" >&2
}

command -v tmux >/dev/null 2>&1 || { echo "tmux not found" >&2; exit 127; }

tmux_cmd() {
  if [[ -n "${TMUX_SESSION_SOCKET:-}" ]]; then
    command tmux -L "$TMUX_SESSION_SOCKET" "$@"
  else
    command tmux "$@"
  fi
}

list_sessions() {
  local exclude_id="${1:-}" format
  format='#{session_id}|#{session_name}|#{@workspace_root}|#{@project_root}'
  tmux_cmd list-sessions -F "$format" 2>/dev/null |
    awk -F '|' -v exclude="$exclude_id" '
      $1 == exclude { next }
      {
        count += 1
        ids[count] = $1
        names[count] = $2
        roots[count] = $3 == "" ? $4 : $3
        roots[count] = roots[count] == "" ? "—" : roots[count]
        if (length(names[count]) > name_width) {
          name_width = length(names[count])
        }
      }
      END {
        format = "%-" name_width "s  %s"
        for (row = 1; row <= count; row += 1) {
          printf "%s\t", ids[row]
          printf format "\n", names[row], roots[row]
        }
      }
    '
}

command_name="${1:-}"
case "$command_name" in
  list)
    list_sessions
    exit 0
    ;;
  switch | attach) ;;
  help | -h | --help)
    usage
    exit 0
    ;;
  *)
    usage
    exit 2
    ;;
esac

fzf_opts_file="${DOTFILES_DIR:-$HOME/dotfiles}/themes/flume/extras/current/fzf.opts"
[[ -r "$fzf_opts_file" ]] && FZF_DEFAULT_OPTS="$(<"$fzf_opts_file")" && export FZF_DEFAULT_OPTS

if [[ -n "${TMUX:-}" ]] && command -v fzf-tmux >/dev/null 2>&1; then
  picker=(fzf-tmux -p '80%,70%')
elif command -v fzf >/dev/null 2>&1; then
  picker=(fzf)
else
  echo "fzf not found" >&2
  exit 127
fi
picker+=(--delimiter=$'\t' --with-nth=2 --header='workspace  root  ·  [Cancel]' --bind 'left-click:accept,click-header:abort')

current_session_id="$(tmux_cmd display-message -p '#{session_id}' 2>/dev/null || true)"
if [[ "$command_name" == switch ]]; then
  tmux_command=switch-client
  sessions="$(list_sessions "$current_session_id")"
else
  tmux_command=attach-session
  sessions="$(list_sessions)"
fi

set +e
selection="$(printf '%s\n[cancel]\t[cancel]\t\n' "$sessions" | "${picker[@]}")"
picker_status=$?
set -e
selection_id="${selection%%$'\t'*}"

# fzf exits 130 on Escape/Ctrl-C and 1 on no match. Treat picker cancellation as
# a clean no-op so tmux does not show an error.
[[ $picker_status -ne 0 || "$selection_id" == "[cancel]" || -z "$selection_id" ]] && exit 0
if [[ -n "${TMUX_SESSION_SOCKET:-}" ]]; then
  exec tmux -L "$TMUX_SESSION_SOCKET" "$tmux_command" -t "$selection_id"
fi
exec tmux "$tmux_command" -t "$selection_id"
