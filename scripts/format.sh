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
[ "$(prettier --version)" = '3.9.6' ]
shfmt_version=$(shfmt --version)
[ "${shfmt_version#v}" = '3.14.1' ]
shellcheck --version | grep -qx 'version: 0.11.0'
fish_indent=${FISH_INDENT:-"$HOME/.nix-profile/bin/fish_indent"}
[ "$("$fish_indent" --version)" = 'fish_indent, version 4.8.1' ]
for tool in stylua alejandra taplo; do
  command -v "$tool" >/dev/null
done
ruff check --no-cache --config ruff.toml --show-settings . >/dev/null
if [ "$mode" = --check ]; then
  ruff check --no-cache --config ruff.toml .
  ruff format --no-cache --config ruff.toml --check .
else
  ruff check --no-cache --config ruff.toml --select I --fix .
  ruff format --no-cache --config ruff.toml .
fi
prettier "$mode" --ignore-path .gitignore --ignore-path .prettierignore '**/*.{md,json,jsonc,yaml,yml,ts}'
shfmt -i 2 "$shell_mode" .
"$fish_indent" "$mode" fish/.config/fish/config.fish
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
