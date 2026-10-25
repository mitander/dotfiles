#!/usr/bin/env sh
set -eu
cd "$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

case "${1:-write}" in
write)
  mode=--write
  shell_mode=-w
  ;;
check | --check)
  mode=--check
  shell_mode=-d
  ;;
*)
  printf '%s\n' "usage: $0 [write|check]" >&2
  exit 2
  ;;
esac

# Nix pins tool versions. Check availability before any formatter can write.
fish_indent=${FISH_INDENT:-"$HOME/.nix-profile/bin/fish_indent"}
for tool in prettier shfmt "$fish_indent" stylua alejandra taplo ruff; do
  command -v "$tool" >/dev/null
done
if [ "$mode" = --check ]; then
  command -v shellcheck >/dev/null
fi

# The Python write path sorts imports and formats without applying other lint fixes.
if [ "$mode" = --check ]; then
  ruff check --no-cache --config ruff.toml .
  ruff format --no-cache --config ruff.toml --check .
else
  ruff check --no-cache --config ruff.toml --select I --fix .
  ruff format --no-cache --config ruff.toml .
fi

prettier "$mode" --ignore-path .gitignore --ignore-path .prettierignore '**/*.{md,json,jsonc,yaml,yml,ts,mjs}'
shfmt -i 2 "$shell_mode" .
"$fish_indent" "$mode" fish/.config/fish/config.fish

# Run shell diagnostics only in check mode.
if [ "$mode" = --check ]; then
  shfmt -f=0 . | xargs -0 shellcheck -x
  stylua --check nvim tests
  alejandra --check flake.nix home
  git ls-files -z --cached --others --exclude-standard '*.toml' | xargs -0 taplo fmt --check
else
  stylua nvim tests
  alejandra flake.nix home
  git ls-files -z --cached --others --exclude-standard '*.toml' | xargs -0 taplo fmt
fi
