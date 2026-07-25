#!/usr/bin/env bash
set -euo pipefail

umask 077

usage() {
  cat >&2 <<'EOF'
usage: tmux-residency <command> [args]

commands:
  reconcile                         reconcile every workspace session
  timer-fired <session-id> <due>    handle one delayed residency timer
  sleep [session-id]                observe an immediate cooling decision
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
    off | observe) printf '%s\n' "$mode" ;;
    *) printf 'off\n' ;;
  esac
}

disable_runtime_locked() {
  local session format='#{session_id}'
  tmux_cmd set-option -gqu @workspace_residency_reconcile_pending >/dev/null 2>&1 || true
  while IFS= read -r session; do
    [[ -n "$session" ]] || continue
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
  local session="$1" attached="$2" now deadline grace
  session_exists "$session" || return 0
  now="$(now_epoch)"

  if is_uint "$attached" && ((attached > 0)); then
    unset_session_option "$session" @workspace_residency_deadline
    unset_session_option "$session" @workspace_residency_result
    return
  fi

  deadline="$(session_option "$session" @workspace_residency_deadline)"
  if [[ -z "$deadline" && "$(session_option "$session" @workspace_residency_result)" == observe:would-cool ]]; then
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
  if [[ "$(residency_mode)" != observe ]]; then
    disable_runtime_locked
    return 0
  fi
  reconcile_all_locked
}

request_reconcile() {
  local pending path command
  acquire_lock
  if [[ "$(residency_mode)" != observe ]]; then
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
  if [[ "$(residency_mode)" != observe ]]; then
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
  local session="$1" scheduled_due="$2" timer_due attached deadline now
  is_uint "$scheduled_due" || return 2
  acquire_lock
  session_exists "$session" || return 0

  timer_due="$(session_option "$session" @workspace_residency_timer_due)"
  [[ "$timer_due" == "$scheduled_due" ]] || return 0
  unset_session_option "$session" @workspace_residency_timer_due
  if [[ "$(residency_mode)" != observe ]]; then
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

  observe_cooling "$session"
}

resolve_session() {
  if [[ -n "${1:-}" ]]; then
    printf '%s\n' "$1"
  else
    current_session
  fi
}

sleep_workspace() {
  local session="$1"
  acquire_lock
  session_exists "$session" || { printf 'workspace session not found: %s\n' "$session" >&2; return 1; }
  if [[ "$(residency_mode)" != observe ]]; then
    tmux_cmd display-message -t "$session" 'Workspace Residency is off' 2>/dev/null || true
    return 0
  fi
  observe_cooling "$session"
  tmux_cmd display-message -t "$session" 'Workspace cooling observed (no tools stopped)' 2>/dev/null || true
}

print_status() {
  local session="$1" name attached deadline result root project_root now state remaining=0 format
  session_exists "$session" || { printf 'workspace session not found: %s\n' "$session" >&2; return 1; }
  format='#{session_name}|#{session_attached}|#{@workspace_residency_deadline}|#{@workspace_residency_result}|#{@workspace_root}|#{@project_root}'
  IFS='|' read -r name attached deadline result root project_root < <(
    tmux_cmd display-message -p -t "$session" "$format"
  )
  [[ -n "$root" ]] || root="$project_root"
  now="$(now_epoch)"
  if [[ "$(residency_mode)" == off ]]; then
    state=off
  elif is_uint "$attached" && ((attached > 0)); then
    state=attached
  elif is_uint "$deadline" && ((deadline > now)); then
    state=grace
    remaining=$((deadline - now))
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
  status) print_status "$(resolve_session "${1:-}")" ;;
  benchmark) benchmark "${1:-100}" ;;
  help | -h | --help | '') usage ;;
  *) printf 'unknown command: %s\n' "$command_name" >&2; usage; exit 2 ;;
esac
