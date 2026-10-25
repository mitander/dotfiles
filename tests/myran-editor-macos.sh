#!/usr/bin/env bash
# Exercises Launch Services delivery without changing document or browser defaults.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/myran-editor-test.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_ROOT=$(cd "$TEST_ROOT" && pwd -P)
app="$TEST_ROOT/Myran Editor Test.app"
resources="$app/Contents/Resources"
mkdir -p "$app/Contents/MacOS" "$resources"

# Check URL parsing and helper lifecycle before exercising native delivery.
/usr/bin/swiftc -target "$(uname -m)-apple-macosx13.0" \
  "$ROOT/extras/myran-editor/FileLinks.swift" \
  "$ROOT/tests/myran-editor-links.swift" \
  -o "$TEST_ROOT/links"
"$TEST_ROOT/links"
/usr/bin/swiftc -target "$(uname -m)-apple-macosx13.0" \
  "$ROOT/extras/myran-editor/FileLinks.swift" \
  "$ROOT/extras/myran-editor/Launcher.swift" \
  "$ROOT/tests/myran-editor-launcher.swift" \
  -o "$TEST_ROOT/launcher"
"$TEST_ROOT/launcher"

# Build a disposable app with a recording launcher instead of Myran.
/usr/bin/swiftc -target "$(uname -m)-apple-macosx13.0" \
  "$ROOT/extras/myran-editor/FileLinks.swift" \
  "$ROOT/extras/myran-editor/Launcher.swift" \
  "$ROOT/extras/myran-editor/main.swift" \
  -o "$app/Contents/MacOS/myran-editor"
cp "$ROOT/extras/myran-editor/Info.plist" "$app/Contents/Info.plist"
# Never register a temporary app under the production bundle identity.
plutil -replace CFBundleIdentifier -string "io.github.mitander.myran-editor.test.$$" "$app/Contents/Info.plist"
plutil -remove UTImportedTypeDeclarations "$app/Contents/Info.plist"
plutil -remove CFBundleURLTypes "$app/Contents/Info.plist"
cat >"$resources/myran-open-files" <<'SH'
#!/bin/bash
set -eu
printf '%s\0' "$@" >"$(dirname "$0")/received"
SH
chmod +x "$resources/myran-open-files"

# Observe decoded filenames at the helper boundary, including literal punctuation.
file="$TEST_ROOT/file with space %20 # ; \$(touch BAD).md"
touch "$file"
url="file://$TEST_ROOT/file%20with%20space%20%2520%20%23%20%3B%20%24%28touch%20BAD%29.md"
/usr/bin/open -W -n -a "$app" "$url"
printf '%s\0' "$file" >"$TEST_ROOT/expected"
cmp "$TEST_ROOT/expected" "$resources/received"

# File URL fragments are stripped by Launch Services. A custom navigation URL preserves location.
encoded_path="${url#file://}"
/usr/bin/open -W -n -a "$app" "myran://open?path=$encoded_path&line=352&end=596"
printf '%s\0' --at 352-596 -- "$file" >"$TEST_ROOT/expected"
cmp "$TEST_ROOT/expected" "$resources/received"

# Check that the app and installer contain no document-default setters.
if grep -RE 'LSSetDefault|setDefaultApplication' "$ROOT/extras/myran-editor" "$ROOT/scripts/install-myran-editor"; then
  echo 'FAIL: native app or installer can change defaults' >&2
  exit 1
fi
printf 'PASS: native macOS URL decoding and line-range delivery, no default setters\n'
