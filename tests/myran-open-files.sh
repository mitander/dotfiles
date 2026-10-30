#!/usr/bin/env bash
# shellcheck disable=SC2016 # Literal injection probes must not expand.
set -euo pipefail
ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/myran-open-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_ROOT=$(cd "$TEST_ROOT" && pwd)

# Stub client discovery and Myran execution under a disposable HOME.
export HOME="$TEST_ROOT/home" TEST_WORKSPACE="$TEST_ROOT/work space" TEST_CALLS="$TEST_ROOT/calls"
export TEST_TOKEN='v1-0123456789abcdef0123456789abcdef'
export TEST_CAPTURED="/private/tmp/test socket,123,0@$TEST_TOKEN"
TEST_CLIENTS=$(printf '10 111 %%1 %s\n20 222 %%42 %s' "$TEST_CAPTURED" "$TEST_CAPTURED")
export TEST_CLIENTS
mkdir -p "$HOME/.local/bin" "$HOME/.nix-profile/bin" "$TEST_WORKSPACE"
ln -s "$(command -v sort)" "$HOME/.nix-profile/bin/sort"
printf '#!%s\n' "$(command -v bash)" >"$HOME/.local/bin/tmux"
cat >>"$HOME/.local/bin/tmux" <<'SH'
set -eu
printf '<%s>\n' "$*" >>"$TEST_CALLS"
case "$*" in
  '-N list-clients -F #{client_activity} #{client_pid} #{pane_id} #{socket_path},#{pid},0@#{V/g:#{?#{&&:#{==:#{environ_name},_MYRAN_SERVER_ID},#{==:#{environ_hidden},1}},#{environ_value},}}') printf '%s\n' "$TEST_CLIENTS" ;;
  '-N display-message -p -t %42 #{socket_path},#{pid},0@#{V/g:#{?#{&&:#{==:#{environ_name},_MYRAN_SERVER_ID},#{==:#{environ_hidden},1}},#{environ_value},}}') printf '%s\n' "${TEST_OBSERVED_SCOPE:-$TEST_CAPTURED}" ;;
  '-N show-options -qv -t %42 @workspace_root') printf '%s\n' "$TEST_WORKSPACE" ;;
  *) exit 9 ;;
esac
SH
printf '#!%s\n' "$(command -v bash)" >"$HOME/.local/bin/myran"
cat >>"$HOME/.local/bin/myran" <<'SH'
set -eu
for name in MYRAN_TMUX_CLIENT MYRAN_TMUX_CLIENT_PID MYRAN_TMUX_PANE_PID MYRAN_TMUX_RUN_GENERATION; do
  [[ -z ${!name+x} ]] || exit 10
done
printf '<%s>\n' "$PWD" "$TMUX" "$TMUX_PANE" "$MYRAN_TMUX_SERVER_ID" "$@"
SH
chmod +x "$HOME/.local/bin/"{tmux,myran}

first="$TEST_ROOT/a b's \$(touch BAD); +42.md"
second="$TEST_ROOT/"$'line\nbreak%20.patch'
touch "$first" "$second"

# Stale inherited terminal state must not override the most recent attached client.
actual=$(TMUX=stale TMUX_PANE=%999 MYRAN_TMUX_SERVER_ID=stale \
  MYRAN_TMUX_CLIENT=stale MYRAN_TMUX_CLIENT_PID=999 MYRAN_TMUX_PANE_PID=999 \
  MYRAN_TMUX_RUN_GENERATION=stale "$ROOT/scripts/myran-open-files" "$first" "$second")
expected=$(printf '<%s>\n' "$TEST_WORKSPACE" '/private/tmp/test socket,123,0' '%42' "$TEST_TOKEN" open -- "$first" "$second")
[[ "$actual" == "$expected" ]]
[[ ! -e "$TEST_WORKSPACE/BAD" ]]
[[ $(wc -l <"$TEST_CALLS" | tr -d ' ') == 3 ]]

# Forward inclusive line ranges without changing literal path handling.
actual=$("$ROOT/scripts/myran-open-files" --at 352-596 -- "$first")
expected=$(printf '<%s>\n' "$TEST_WORKSPACE" '/private/tmp/test socket,123,0' '%42' "$TEST_TOKEN" open-at 352-596 -- "$first")
[[ "$actual" == "$expected" ]]
if "$ROOT/scripts/myran-open-files" --at '1;quit' -- "$first" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
  echo 'FAIL: accepted malformed location arguments' >&2
  exit 1
fi

# Reject invalid documents before contacting tmux.
for invalid in 'https://example.com' 'relative.md' "$TEST_ROOT/missing" "$TEST_ROOT"; do
  : >"$TEST_CALLS"
  if "$ROOT/scripts/myran-open-files" "$invalid" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
    echo 'FAIL: accepted non-file input' >&2
    exit 1
  fi
  [[ ! -s "$TEST_CALLS" && ! -s "$TEST_ROOT/out" ]]
done
if "$ROOT/scripts/myran-open-files" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
  echo 'FAIL: accepted empty input' >&2
  exit 1
fi

# Reject unusable client metadata and restarted servers before invoking Myran.
for clients in '' 'malformed' '20 222 %42 extra'; do
  if TEST_CLIENTS="$clients" "$ROOT/scripts/myran-open-files" "$first" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
    echo 'FAIL: accepted missing or malformed client' >&2
    exit 1
  fi
  [[ ! -s "$TEST_ROOT/out" ]]
done
# Missing, malformed or Session-only identity cannot be replaced with inherited authority.
for token in '' 'v1-short' 'v1-0123456789ABCDEF0123456789ABCDEF'; do
  : >"$TEST_CALLS"
  if TEST_CLIENTS="20 222 %42 /private/tmp/test socket,123,0@$token" \
    MYRAN_TMUX_SERVER_ID="$TEST_TOKEN" "$ROOT/scripts/myran-open-files" "$first" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
    echo 'FAIL: adopted inherited authority for a missing or invalid server identity' >&2
    exit 1
  fi
  [[ ! -s "$TEST_ROOT/out" ]]
  [[ $(wc -l <"$TEST_CALLS" | tr -d ' ') == 1 ]]
done

# A changed capability rejects even if the server PID and socket are unchanged.
for observed in "/private/tmp/test socket,999,0@$TEST_TOKEN" \
  '/private/tmp/test socket,123,0@v1-fedcba9876543210fedcba9876543210'; do
  : >"$TEST_CALLS"
  if TEST_OBSERVED_SCOPE="$observed" "$ROOT/scripts/myran-open-files" "$first" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
    echo 'FAIL: accepted a replaced tmux server or capability' >&2
    exit 1
  fi
  [[ ! -s "$TEST_ROOT/out" ]]
  [[ $(wc -l <"$TEST_CALLS" | tr -d ' ') == 2 ]]
  grep -q 'server changed' "$TEST_ROOT/error"
done

# A pinned client still needs an existing Myran workspace.
if TEST_WORKSPACE="$TEST_ROOT/missing" "$ROOT/scripts/myran-open-files" "$first" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
  echo 'FAIL: accepted missing workspace' >&2
  exit 1
fi
[[ ! -s "$TEST_ROOT/out" ]]
printf 'PASS: Myran document routing, literal paths, captured server identity and missing workspace failures\n'
