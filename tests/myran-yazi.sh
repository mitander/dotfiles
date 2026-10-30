#!/usr/bin/env bash
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/myran-yazi.XXXXXX")
TEST_ROOT=$(cd "$TEST_ROOT" && pwd)
trap 'rm -rf "$TEST_ROOT"' EXIT
export TEST_ROOT
mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/project" "$TEST_ROOT/elsewhere"
export PATH="$TEST_ROOT/bin:$PATH" MYRAN_YAZI_SCRIPT="$ROOT/scripts/myran-yazi"
export TMUX='/private/tmp/test socket,123,0' TMUX_PANE=%7 MYRAN_TMUX_SERVER_ID=retained
export TEST_WORKSPACE="$TEST_ROOT/project"

cat >"$TEST_ROOT/bin/tmux" <<'SH'
#!/usr/bin/env bash
set -eu
[[ $# == 5 && $1 == show-options && $2 == -qv && $3 == -t && $4 == %7 && $5 == @workspace_root ]]
printf '%s\n' "$TEST_WORKSPACE"
SH
cat >"$TEST_ROOT/bin/yazi" <<'SH'
#!/usr/bin/env bash
set -eu
printf '%s\0' "$PWD" "$MYRAN_YAZI_ROOT" >"$TEST_ROOT/launched"
cd "$TEST_ROOT/elsewhere"
exec "$MYRAN_YAZI_SCRIPT" --open 'sp ace-λ;$(touch INJECTED)*.rs' '-leading.rs' "$TEST_ROOT/outside.rs"
SH
cat >"$TEST_ROOT/bin/myran" <<'SH'
#!/usr/bin/env bash
set -eu
printf '%s\0' "$PWD" "$TMUX" "$TMUX_PANE" "$MYRAN_TMUX_SERVER_ID" "$@" >"$TEST_ROOT/opened"
exit "${TEST_MYRAN_STATUS:-0}"
SH
chmod +x "$TEST_ROOT/bin/"*

# Browsing cwd must never become Project identity. Preserve argv and retained terminal identity.
"$MYRAN_YAZI_SCRIPT"
printf '%s\0' "$TEST_WORKSPACE" "$TEST_WORKSPACE" >"$TEST_ROOT/expected-launch"
cmp "$TEST_ROOT/expected-launch" "$TEST_ROOT/launched"
printf '%s\0' "$TEST_WORKSPACE" "$TMUX" "$TMUX_PANE" retained open -- \
  "$TEST_ROOT/elsewhere/sp ace-λ;\$(touch INJECTED)*.rs" \
  "$TEST_ROOT/elsewhere/-leading.rs" "$TEST_ROOT/outside.rs" >"$TEST_ROOT/expected-open"
cmp "$TEST_ROOT/expected-open" "$TEST_ROOT/opened"
[[ ! -e "$TEST_ROOT/elsewhere/INJECTED" ]]

# A second launching Workspace and newline-bearing roots remain distinct.
export TEST_WORKSPACE="$TEST_ROOT/second"$'\n'
mkdir -p "$TEST_WORKSPACE"
"$MYRAN_YAZI_SCRIPT"
printf '%s\0' "$TEST_WORKSPACE" "$TEST_WORKSPACE" >"$TEST_ROOT/expected-launch"
cmp "$TEST_ROOT/expected-launch" "$TEST_ROOT/launched"

# Myran owns stale-identity rejection. Forward its failure, never retry via desktop routing.
if TEST_MYRAN_STATUS=23 "$MYRAN_YAZI_SCRIPT"; then exit 1; else [[ $? == 23 ]]; fi
for variable in TMUX TMUX_PANE MYRAN_TMUX_SERVER_ID; do
  if env -u "$variable" "$MYRAN_YAZI_SCRIPT" >"$TEST_ROOT/out" 2>&1; then exit 1; fi
done
if "$MYRAN_YAZI_SCRIPT" --open >"$TEST_ROOT/out" 2>&1; then exit 1; fi
if TEST_WORKSPACE='' "$MYRAN_YAZI_SCRIPT" >"$TEST_ROOT/out" 2>&1; then exit 1; fi
printf '%s\n' 'myran-yazi: passed'
