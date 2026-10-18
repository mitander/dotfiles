#!/usr/bin/env bash
# Launch routing is tested with recording executables, never tracker services.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/tracker-local.XXXXXX")"
trap 'rm -rf "$TEST_ROOT"' EXIT
export HOME="$TEST_ROOT/home" CALLS="$TEST_ROOT/calls" DOTFILES_DIR="$ROOT"
export LTUI_CHECKOUT="$HOME/c/p/checkout with spaces"
mkdir -p "$TEST_ROOT/bin" "$LTUI_CHECKOUT"/{ltui,jtui,flume-theme}
for package in ltui jtui flume-theme; do
  touch "$LTUI_CHECKOUT/$package/pyproject.toml"
done
for app in ltui jtui; do
  ln -s "$ROOT/tracker-tui/launch" "$TEST_ROOT/bin/$app"
done
if "$TEST_ROOT/bin/ltui" 2>"$TEST_ROOT/error"; then
  echo 'FAIL: a missing environment must not launch or install anything' >&2
  exit 1
fi
grep -q setup-trackers "$TEST_ROOT/error"
[[ ! -e "$LTUI_CHECKOUT/.venv" ]]

cat >"$TEST_ROOT/bin/python" <<'EOF'
#!/usr/bin/env bash
printf '<%s>\n' "$@" >>"$CALLS"
if [[ "$1 $2" == '-m venv' ]]; then
  mkdir -p "$3/bin"
  cp "$0" "$3/bin/python"
fi
EOF
chmod +x "$TEST_ROOT/bin/python"
PYTHON="$TEST_ROOT/bin/python" bash "$ROOT/scripts/setup-trackers" >/dev/null
grep -qx '<venv>' "$CALLS"
[[ "$(grep -cx '<--editable>' "$CALLS")" == 3 ]]
for package in ltui jtui flume-theme; do
  grep -Fqx "<$LTUI_CHECKOUT/$package>" "$CALLS"
done

cat >"$LTUI_CHECKOUT/.venv/bin/ltui" <<'EOF'
#!/usr/bin/env bash
printf 'scope=%s\nthemes=%s\nschema=%s\n' "${TRACKER_SCOPE:-unset}" "$FLUME_TRACKER_THEME_DIR" "$FLUME_SCHEMA_FILE"
printf '<%s>\n' "$@"
EOF
chmod +x "$LTUI_CHECKOUT/.venv/bin/ltui"
cp "$LTUI_CHECKOUT/.venv/bin/ltui" "$LTUI_CHECKOUT/.venv/bin/jtui"
: >"$CALLS"
unset TRACKER_SCOPE FLUME_TRACKER_THEME_DIR FLUME_SCHEMA_FILE
literal="literal \$(touch '$TEST_ROOT/BAD');"
"$TEST_ROOT/bin/ltui" "$literal" >"$TEST_ROOT/out"
grep -qx scope=dev "$TEST_ROOT/out"
grep -Fqx "themes=$ROOT/themes/flume/extras/palette" "$TEST_ROOT/out"
grep -Fqx "schema=$ROOT/themes/flume/extras/current/schema" "$TEST_ROOT/out"
grep -Fqx "<$literal>" "$TEST_ROOT/out"
[[ ! -e "$TEST_ROOT/BAD" && ! -s "$CALLS" ]]
TRACKER_SCOPE=custom FLUME_TRACKER_THEME_DIR=/custom/themes FLUME_SCHEMA_FILE=/custom/schema \
  "$TEST_ROOT/bin/ltui" >"$TEST_ROOT/out"
grep -qx scope=custom "$TEST_ROOT/out"
grep -qx themes=/custom/themes "$TEST_ROOT/out"
grep -qx schema=/custom/schema "$TEST_ROOT/out"
"$TEST_ROOT/bin/jtui" >"$TEST_ROOT/out"
grep -qx scope=unset "$TEST_ROOT/out"
printf 'PASS: editable setup is explicit; local launch preserves literal arguments and overrides without installing\n'
