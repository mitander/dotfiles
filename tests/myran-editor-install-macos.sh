#!/usr/bin/env bash
# Exercise real installation in disposable HOME without registering apps or selecting defaults.
set -euo pipefail
ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/myran-editor-install.XXXXXX")
trap 'rm -rf "$TEST_ROOT"' EXIT
TEST_ROOT=$(cd "$TEST_ROOT" && pwd -P)
export HOME="$TEST_ROOT/home"
mkdir -p "$HOME"
app="$HOME/Applications/Myran Editor.app"
binary="$app/Contents/MacOS/myran-editor"

install_app() {
  "$ROOT/scripts/install-myran-editor" --no-register >"$TEST_ROOT/output" 2>"$TEST_ROOT/error"
}

checksum() {
  shasum -a 256 "$1" | cut -d ' ' -f 1
}

# Install without registration and keep the resource launcher live-linked.
install_app
[[ -x "$binary" ]]
[[ $(readlink "$app/Contents/Resources/myran-open-files") == "$ROOT/scripts/myran-open-files" ]]

# An update replaces the executable while existing readers retain the old bytes.
old_inode=$(/usr/bin/stat -f '%i' "$binary")
old_hash=$(checksum "$binary")
exec 3<"$binary"
install_app
[[ $(/usr/bin/stat -f '%i' "$binary") != "$old_inode" ]]
[[ $(checksum /dev/fd/3) == "$old_hash" ]]
exec 3<&-
installed_hash=$(checksum "$binary")

# Reject symlink destinations without altering the installed executable.
for path in "$HOME" "$HOME/Applications" "$app" "$app/Contents" \
  "$app/Contents/MacOS" "$app/Contents/Resources" "$binary" "$app/Contents/Info.plist"; do
  mv "$path" "$path.saved"
  ln -s "$path.saved" "$path"
  if install_app; then
    echo "FAIL: accepted symlink destination $path" >&2
    exit 1
  fi
  grep -q 'symlink installation path' "$TEST_ROOT/error"
  rm "$path"
  mv "$path.saved" "$path"
  [[ $(checksum "$binary") == "$installed_hash" ]]
done

# Failed compilation and unrelated app identities must preserve installed bytes.
if DEVELOPER_DIR="$TEST_ROOT/no-sdk" install_app; then
  echo 'FAIL: compilation unexpectedly succeeded with no SDK' >&2
  exit 1
fi
[[ $(checksum "$binary") == "$installed_hash" ]]
/usr/bin/plutil -replace CFBundleIdentifier -string test.unrelated "$app/Contents/Info.plist"
if install_app; then
  echo 'FAIL: replaced an unrelated app' >&2
  exit 1
fi
[[ $(checksum "$binary") == "$installed_hash" ]]
grep -q 'unrelated app' "$TEST_ROOT/error"
printf 'PASS: isolated native install/update, atomic executable replacement, symlink rejection, failure preservation\n'
