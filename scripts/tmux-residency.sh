#!/usr/bin/env bash
set -euo pipefail

umask 077

usage() {
  cat >&2 <<'EOF'
usage: tmux-residency <command> [args]

commands:
  reconcile                         reconcile every workspace session
  timer-fired <session-id> <due>    handle one delayed residency timer
  sleep [session-id]                cool restartable tools immediately
  wake-pane <pane-id>               resume one cooled tool pane
  wake-window <window-id>           resume every cooled tool pane in a window
  status [session-id]               print internal residency metadata
  benchmark [iterations]            measure read-only tmux query latency
EOF
}

TMUX_RESIDENCY_LOCKED=0
TMUX_RESIDENCY_LOCK="workspace-residency"

tmux_cmd() {
  if [[ -n "${TMUX_RESIDENCY_SOCKET:-}" ]]; then
    command tmux -L "$TMUX_RESIDENCY_SOCKET" "$@"
  else
    command tmux "$@"
  fi
}

now_epoch() {
  if [[ -n "${TMUX_RESIDENCY_NOW:-}" ]]; then
    printf '%s\n' "$TMUX_RESIDENCY_NOW"
  else
    date +%s
  fi
}

is_uint() {
  [[ "$1" =~ ^[0-9]+$ ]]
}

shell_quote() {
  printf "'"
  printf '%s' "$1" | sed "s/'/'\\\\''/g"
  printf "'"
}

script_path() {
  local path="$0"
  if [[ "$path" != */* ]]; then
    path="$(command -v "$path")"
  fi
  case "$path" in
  /*) printf '%s\n' "$path" ;;
  *) printf '%s/%s\n' "$PWD" "$path" ;;
  esac
}

acquire_lock() {
  tmux_cmd wait-for -L "$TMUX_RESIDENCY_LOCK"
  TMUX_RESIDENCY_LOCKED=1
}

release_lock() {
  if [[ "$TMUX_RESIDENCY_LOCKED" == 1 ]]; then
    tmux_cmd wait-for -U "$TMUX_RESIDENCY_LOCK" >/dev/null 2>&1 || true
    TMUX_RESIDENCY_LOCKED=0
  fi
}
trap release_lock EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

session_option() {
  tmux_cmd show-options -qv -t "$1" "$2" 2>/dev/null || true
}

set_session_option() {
  tmux_cmd set-option -q -t "$1" "$2" "$3"
}

unset_session_option() {
  tmux_cmd set-option -qu -t "$1" "$2" >/dev/null 2>&1 || true
}

session_exists() {
  tmux_cmd has-session -t "$1" >/dev/null 2>&1
}

current_session() {
  tmux_cmd display-message -p '#{session_id}'
}

residency_mode() {
  local mode
  mode="$(tmux_cmd show-option -gqv @workspace_residency_mode 2>/dev/null || true)"
  case "$mode" in
  off | observe | cool) printf '%s\n' "$mode" ;;
  *) printf 'off\n' ;;
  esac
}

pane_option() {
  tmux_cmd show-options -pqv -t "$1" "$2" 2>/dev/null || true
}

unset_pane_option() {
  tmux_cmd set-option -pqu -t "$1" "$2" >/dev/null 2>&1 || true
}

role_can_cool() {
  case "$1" in
  git | tasks) return 0 ;;
  *) return 1 ;;
  esac
}

resume_pane() {
  local pane="$1" command root
  command="$(pane_option "$pane" @workspace_resume_command)"
  root="$(pane_option "$pane" @workspace_root)"
  if [[ -n "$command" && -n "$root" && -d "$root" ]]; then
    tmux_cmd respawn-pane -k -t "$pane" -c "$root" "$command"
  fi
  unset_pane_option "$pane" @workspace_residency_cooled
  unset_pane_option "$pane" @workspace_residency_cooled_role
}

resume_session() {
  local session="$1" pane_session pane cooled format
  format='#{session_id}|#{pane_id}|#{@workspace_residency_cooled}'
  while IFS='|' read -r pane_session pane cooled; do
    [[ "$pane_session" == "$session" && -n "$pane" && "$cooled" == 1 ]] || continue
    resume_pane "$pane"
  done < <(tmux_cmd list-panes -a -F "$format" 2>/dev/null || true)
}

cool_pane() {
  local pane="$1" role="$2" command root placeholder
  role_can_cool "$role" || return 1
  [[ -z "$(pane_option "$pane" @workspace_residency_cooled)" ]] || return 1
  command="$(pane_option "$pane" @workspace_resume_command)"
  root="$(pane_option "$pane" @workspace_root)"
  [[ -n "$command" && -n "$root" && -d "$root" ]] || return 1

  # Git and task views are restartable projections of repository state. Kill
  # them and leave a tiny placeholder instead of trying to SIGSTOP a tmux
  # foreground process group, which tmux deliberately resumes.
  placeholder="printf '\\n[workspace cooled: $role]\\n'; exec sleep 2147483647"
  tmux_cmd set-option -pq -t "$pane" @workspace_residency_cooled 1
  tmux_cmd set-option -pq -t "$pane" @workspace_residency_cooled_role "$role"
  if ! tmux_cmd respawn-pane -k -t "$pane" -c "$root" "$placeholder"; then
    unset_pane_option "$pane" @workspace_residency_cooled
    unset_pane_option "$pane" @workspace_residency_cooled_role
    return 1
  fi
}

cool_session() {
  local session="$1" pane_session pane role count=0 format
  format='#{session_id}|#{pane_id}|#{@workspace_pane_role}'
  while IFS='|' read -r pane_session pane role; do
    [[ "$pane_session" == "$session" && -n "$pane" ]] || continue
    if cool_pane "$pane" "$role"; then
      count=$((count + 1))
    fi
  done < <(tmux_cmd list-panes -a -F "$format" 2>/dev/null || true)
  printf '%s\n' "$count"
}

disable_runtime_locked() {
  local session format='#{session_id}'
  tmux_cmd set-option -gqu @workspace_residency_reconcile_pending >/dev/null 2>&1 || true
  while IFS= read -r session; do
    [[ -n "$session" ]] || continue
    resume_session "$session"
    unset_session_option "$session" @workspace_residency_deadline
    unset_session_option "$session" @workspace_residency_timer_due
    unset_session_option "$session" @workspace_residency_result
  done < <(tmux_cmd list-sessions -F "$format" 2>/dev/null || true)
}

grace_seconds() {
  local configured
  if [[ -n "${TMUX_RESIDENCY_GRACE_SECONDS:-}" ]]; then
    configured="$TMUX_RESIDENCY_GRACE_SECONDS"
  else
    configured="$(tmux_cmd show-option -gqv @workspace_residency_grace_seconds 2>/dev/null || true)"
  fi
  is_uint "$configured" || configured=900
  printf '%s\n' "$configured"
}

schedule_timer() {
  local session="$1" due="$2" now delay command path log
  now="$(now_epoch)"
  delay=$((due - now))
  ((delay > 0)) || delay=0
  path="$(script_path)"

  command="$(shell_quote "$path") timer-fired $(shell_quote "$session") $(shell_quote "$due")"
  if [[ -n "${TMUX_RESIDENCY_SOCKET:-}" ]]; then
    command="TMUX_RESIDENCY_SOCKET=$(shell_quote "$TMUX_RESIDENCY_SOCKET") $command"
  fi

  if [[ -n "${TMUX_RESIDENCY_SCHEDULER_LOG:-}" ]]; then
    log="$TMUX_RESIDENCY_SCHEDULER_LOG"
    printf '%s\t%s\t%s\n' "$session" "$due" "$delay" >>"$log"
  fi

  if [[ "${TMUX_RESIDENCY_DISABLE_SCHEDULE:-0}" != 1 ]]; then
    if ((delay > 0)); then
      tmux_cmd run-shell -b -d "$delay" "$command"
    else
      tmux_cmd run-shell -b "$command"
    fi
  fi
  set_session_option "$session" @workspace_residency_timer_due "$due"
}

ensure_timer() {
  local session="$1" deadline="$2" timer_due
  timer_due="$(session_option "$session" @workspace_residency_timer_due)"
  if is_uint "$timer_due"; then
    return
  fi
  schedule_timer "$session" "$deadline"
}

reconcile_session() {
  local session="$1" attached="$2" now deadline grace result mode
  session_exists "$session" || return 0
  now="$(now_epoch)"
  mode="$(residency_mode)"

  result="$(session_option "$session" @workspace_residency_result)"
  if [[ "$mode" == observe && "$result" == cool:* ]]; then
    resume_session "$session"
    unset_session_option "$session" @workspace_residency_result
    result=
  elif [[ "$mode" == cool && "$result" == observe:would-cool ]]; then
    # An observation is not a completed cooling operation. Start a fresh grace
    # period when enabling cooling, rather than skipping this detached session.
    unset_session_option "$session" @workspace_residency_result
    result=
  fi

  if is_uint "$attached" && ((attached > 0)); then
    resume_session "$session"
    unset_session_option "$session" @workspace_residency_deadline
    unset_session_option "$session" @workspace_residency_result
    return
  fi

  deadline="$(session_option "$session" @workspace_residency_deadline)"
  if [[ -z "$deadline" && -n "$result" ]]; then
    return
  fi
  if ! is_uint "$deadline"; then
    grace="$(grace_seconds)"
    deadline=$((now + grace))
    set_session_option "$session" @workspace_residency_deadline "$deadline"
  fi
  ensure_timer "$session" "$deadline"
}

reconcile_all_locked() {
  local session attached format
  format='#{session_id}|#{session_attached}'
  while IFS='|' read -r session attached; do
    [[ -n "$session" ]] || continue
    reconcile_session "$session" "$attached"
  done < <(tmux_cmd list-sessions -F "$format" 2>/dev/null || true)
}

reconcile_all() {
  acquire_lock
  tmux_cmd set-option -gqu @workspace_residency_reconcile_pending >/dev/null 2>&1 || true
  if [[ "$(residency_mode)" == off ]]; then
    disable_runtime_locked
    return 0
  fi
  reconcile_all_locked
}

request_reconcile() {
  local pending path command
  acquire_lock
  if [[ "$(residency_mode)" == off ]]; then
    disable_runtime_locked
    return 0
  fi
  pending="$(tmux_cmd show-option -gqv @workspace_residency_reconcile_pending 2>/dev/null || true)"
  [[ "$pending" == 1 ]] && return 0
  tmux_cmd set-option -gq @workspace_residency_reconcile_pending 1
  path="$(script_path)"
  command="$(shell_quote "$path") reconcile-requested"
  if [[ -n "${TMUX_RESIDENCY_SOCKET:-}" ]]; then
    command="TMUX_RESIDENCY_SOCKET=$(shell_quote "$TMUX_RESIDENCY_SOCKET") $command"
  fi
  tmux_cmd run-shell -b -d 0.1 "$command"
}

reconcile_requested() {
  local pending
  acquire_lock
  pending="$(tmux_cmd show-option -gqv @workspace_residency_reconcile_pending 2>/dev/null || true)"
  [[ "$pending" == 1 ]] || return 0
  tmux_cmd set-option -gqu @workspace_residency_reconcile_pending >/dev/null 2>&1 || true
  if [[ "$(residency_mode)" == off ]]; then
    disable_runtime_locked
    return 0
  fi
  reconcile_all_locked
}

observe_cooling() {
  local session="$1" now
  now="$(now_epoch)"
  set_session_option "$session" @workspace_residency_result 'observe:would-cool'
  set_session_option "$session" @workspace_residency_last_observed_at "$now"
  unset_session_option "$session" @workspace_residency_deadline
}

timer_fired() {
  local session="$1" scheduled_due="$2" timer_due attached deadline now mode cooled
  is_uint "$scheduled_due" || return 2
  acquire_lock
  session_exists "$session" || return 0

  timer_due="$(session_option "$session" @workspace_residency_timer_due)"
  [[ "$timer_due" == "$scheduled_due" ]] || return 0
  unset_session_option "$session" @workspace_residency_timer_due
  mode="$(residency_mode)"
  if [[ "$mode" == off ]]; then
    resume_session "$session"
    unset_session_option "$session" @workspace_residency_deadline
    unset_session_option "$session" @workspace_residency_result
    return 0
  fi

  attached="$(tmux_cmd display-message -p -t "$session" '#{session_attached}' 2>/dev/null || printf 0)"
  if is_uint "$attached" && ((attached > 0)); then
    unset_session_option "$session" @workspace_residency_deadline
    return 0
  fi

  deadline="$(session_option "$session" @workspace_residency_deadline)"
  is_uint "$deadline" || return 0
  now="$(now_epoch)"
  if ((now < deadline)); then
    schedule_timer "$session" "$deadline"
    return 0
  fi

  if [[ "$mode" == cool ]]; then
    cooled="$(cool_session "$session")"
    set_session_option "$session" @workspace_residency_result "cool:$cooled"
    set_session_option "$session" @workspace_residency_last_observed_at "$now"
    unset_session_option "$session" @workspace_residency_deadline
  else
    observe_cooling "$session"
  fi
}

resolve_session() {
  if [[ -n "${1:-}" ]]; then
    printf '%s\n' "$1"
  else
    current_session
  fi
}

wake_pane() {
  local pane="$1"
  acquire_lock
  tmux_cmd display-message -p -t "$pane" '#{pane_id}' >/dev/null 2>&1 || return 0
  resume_pane "$pane"
}

wake_window() {
  local window="$1" pane
  acquire_lock
  while IFS= read -r pane; do
    [[ -n "$pane" ]] && resume_pane "$pane"
  done < <(tmux_cmd list-panes -t "$window" -F '#{pane_id}' 2>/dev/null || true)
}

sleep_workspace() {
  local session="$1" mode cooled
  acquire_lock
  session_exists "$session" || {
    printf 'workspace session not found: %s\n' "$session" >&2
    return 1
  }
  mode="$(residency_mode)"
  if [[ "$mode" == off ]]; then
    tmux_cmd display-message -t "$session" 'Workspace Residency is off' 2>/dev/null || true
    return 0
  fi
  if [[ "$mode" == cool ]]; then
    cooled="$(cool_session "$session")"
    set_session_option "$session" @workspace_residency_result "cool:$cooled"
    unset_session_option "$session" @workspace_residency_deadline
    tmux_cmd display-message -t "$session" "Cooled $cooled idle workspace tool pane(s)" 2>/dev/null || true
  else
    observe_cooling "$session"
    tmux_cmd display-message -t "$session" 'Workspace cooling observed (no tools stopped)' 2>/dev/null || true
  fi
}

print_status() {
  local session="$1" name attached deadline result root now state remaining=0 format
  session_exists "$session" || {
    printf 'workspace session not found: %s\n' "$session" >&2
    return 1
  }
  format='#{session_name}|#{session_attached}|#{@workspace_residency_deadline}|#{@workspace_residency_result}|#{@workspace_root}'
  IFS='|' read -r name attached deadline result root < <(
    tmux_cmd display-message -p -t "$session" "$format"
  )
  now="$(now_epoch)"
  if [[ "$(residency_mode)" == off ]]; then
    state=off
  elif is_uint "$attached" && ((attached > 0)); then
    state=attached
  elif is_uint "$deadline" && ((deadline > now)); then
    state=grace
    remaining=$((deadline - now))
  elif [[ "$result" == cool:* ]]; then
    state=cooled
  elif [[ "$result" == observe:would-cool ]]; then
    state=observed
  else
    state=detached
  fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$session" "$name" "$state" "$remaining" "$result" "$root"
}

benchmark() {
  local iterations="${1:-100}" elapsed
  if ! is_uint "$iterations" || ((iterations <= 0)); then
    printf 'iterations must be a positive integer\n' >&2
    return 2
  fi
  printf 'sessions=%s panes=%s iterations=%s\n' \
    "$(tmux_cmd list-sessions 2>/dev/null | wc -l | tr -d ' ')" \
    "$(tmux_cmd list-panes -a 2>/dev/null | wc -l | tr -d ' ')" \
    "$iterations"
  TIMEFORMAT='%3R'
  elapsed="$({ time for _ in $(seq 1 "$iterations"); do tmux_cmd list-sessions -F '#{session_id}\t#{session_attached}\t#{@workspace_root}' >/dev/null; done; } 2>&1)"
  awk -v total="$elapsed" -v count="$iterations" 'BEGIN { printf "list-sessions avg-ms=%.3f\n", (total * 1000) / count }'
  elapsed="$({ time for _ in $(seq 1 "$iterations"); do tmux_cmd list-panes -a -F '#{pane_id}\t#{@workspace_pane_role}' >/dev/null; done; } 2>&1)"
  awk -v total="$elapsed" -v count="$iterations" 'BEGIN { printf "list-panes avg-ms=%.3f\n", (total * 1000) / count }'
}

command_name="${1:-}"
shift || true
case "$command_name" in
reconcile) reconcile_all ;;
request-reconcile) request_reconcile ;;
reconcile-requested) reconcile_requested ;;
timer-fired) timer_fired "${1:?missing session id}" "${2:?missing scheduled due}" ;;
sleep) sleep_workspace "$(resolve_session "${1:-}")" ;;
wake-pane) wake_pane "${1:?missing pane id}" ;;
wake-window) wake_window "${1:?missing window id}" ;;
status) print_status "$(resolve_session "${1:-}")" ;;
benchmark) benchmark "${1:-100}" ;;
help | -h | --help | '') usage ;;
*)
  printf 'unknown command: %s\n' "$command_name" >&2
  usage
  exit 2
  ;;
esac
