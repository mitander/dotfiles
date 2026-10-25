#!/usr/bin/env bash
# shellcheck disable=SC2016 # Literal injection probes must not expand.
set -euo pipefail
ROOT="${DOTFILES_TEST_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/myran-open-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_ROOT=$(cd "$TEST_ROOT" && pwd)

# Stub client discovery and Myran execution under a disposable HOME.
export HOME="$TEST_ROOT/home" TEST_WORKSPACE="$TEST_ROOT/work space" TEST_CALLS="$TEST_ROOT/calls"
export TEST_CLIENTS=$'10 111 %1 /private/tmp/test socket,123,0\n20 222 %42 /private/tmp/test socket,123,0'
mkdir -p "$HOME/.local/bin" "$HOME/.nix-profile/bin" "$TEST_WORKSPACE"
ln -s "$(command -v sort)" "$HOME/.nix-profile/bin/sort"
printf '#!%s\n' "$(command -v bash)" >"$HOME/.local/bin/tmux"
cat >>"$HOME/.local/bin/tmux" <<'SH'
set -eu
printf '<%s>\n' "$*" >>"$TEST_CALLS"
case "$*" in
  'list-clients -F #{client_activity} #{client_pid} #{pane_id} #{socket_path},#{pid},0') printf '%s\n' "$TEST_CLIENTS" ;;
  'display-message -p -t %42 #{socket_path},#{pid},0') printf '%s\n' "${TEST_OBSERVED_SCOPE:-/private/tmp/test socket,123,0}" ;;
  'show-options -qv -t %42 @workspace_root') printf '%s\n' "$TEST_WORKSPACE" ;;
  *) exit 9 ;;
esac
SH
printf '#!%s\n' "$(command -v bash)" >"$HOME/.local/bin/myran"
cat >>"$HOME/.local/bin/myran" <<'SH'
set -eu
printf '<%s>\n' "$PWD" "$TMUX" "$TMUX_PANE" "$@"
SH
chmod +x "$HOME/.local/bin/"{tmux,myran}

first="$TEST_ROOT/a b's \$(touch BAD); +42.md"
second="$TEST_ROOT/"$'line\nbreak%20.patch'
touch "$first" "$second"

# Stale inherited terminal state must not override the most recent attached client.
actual=$(TMUX=stale TMUX_PANE=%999 "$ROOT/scripts/myran-open-files" "$first" "$second")
expected=$(printf '<%s>\n' "$TEST_WORKSPACE" '/private/tmp/test socket,123,0' '%42' open -- "$first" "$second")
[[ "$actual" == "$expected" ]]
[[ ! -e "$TEST_WORKSPACE/BAD" ]]
[[ $(wc -l <"$TEST_CALLS" | tr -d ' ') == 3 ]]

# Forward inclusive line ranges without changing literal path handling.
actual=$("$ROOT/scripts/myran-open-files" --at 352-596 -- "$first")
expected=$(printf '<%s>\n' "$TEST_WORKSPACE" '/private/tmp/test socket,123,0' '%42' open-at 352-596 -- "$first")
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
: >"$TEST_CALLS"
if TEST_OBSERVED_SCOPE='/private/tmp/test socket,999,0' "$ROOT/scripts/myran-open-files" "$first" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
  echo 'FAIL: accepted a replaced tmux server' >&2
  exit 1
fi
[[ ! -s "$TEST_ROOT/out" ]]
[[ $(wc -l <"$TEST_CALLS" | tr -d ' ') == 2 ]]
grep -q 'server changed' "$TEST_ROOT/error"

# A pinned client still needs an existing Myran workspace.
if TEST_WORKSPACE="$TEST_ROOT/missing" "$ROOT/scripts/myran-open-files" "$first" >"$TEST_ROOT/out" 2>"$TEST_ROOT/error"; then
  echo 'FAIL: accepted missing workspace' >&2
  exit 1
fi
[[ ! -s "$TEST_ROOT/out" ]]
printf 'PASS: Myran document routing, literal paths, pinned client, missing workspace failures\n'
