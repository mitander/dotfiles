#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLAKE="path:$ROOT"

usage() {
  cat <<'EOF'
Usage: scripts/dotfiles-nix.sh <command>

Commands:
  profile      Print the automatically selected Home Manager profile
  doctor       Check prerequisites and evaluate the selected profile
  check        Evaluate every flake output without building it
  build        Build the selected Home Manager generation without activating it
  switch       Activate the selected generation (requires DOTFILES_ALLOW_ACTIVATE=1)
  generations  List Home Manager generations
EOF
}

profile() {
  case "$(uname -s):$(uname -m)" in
    Darwin:arm64 | Darwin:aarch64)
      printf '%s\n' "mitander@darwin"
      ;;
    Linux:x86_64 | Linux:amd64)
      printf '%s\n' "mitander@linux-x86_64"
      ;;
    Linux:arm64 | Linux:aarch64)
      printf '%s\n' "mitander@linux-aarch64"
      ;;
    *)
      printf 'Unsupported host: %s %s\n' "$(uname -s)" "$(uname -m)" >&2
      return 1
      ;;
  esac
}

require_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    cat >&2 <<'EOF'
Nix is not installed or is not on PATH.
Install Nix using an installer you have reviewed, restart the shell, and rerun
this command. The legacy ./install.sh remains available in the meantime.
EOF
    return 1
  fi
}

run_nix() {
  nix --extra-experimental-features "nix-command flakes" "$@"
}

home_manager() {
  run_nix run "$FLAKE#home-manager" -- "$@"
}

doctor() {
  local selected
  selected="$(profile)"
  printf 'root:    %s\n' "$ROOT"
  printf 'profile: %s\n' "$selected"
  printf 'host:    %s %s\n' "$(uname -s)" "$(uname -m)"

  require_nix
  run_nix flake metadata "$FLAKE" --no-write-lock-file >/dev/null
  run_nix eval "$FLAKE#homeConfigurations.\"$selected\".activationPackage.drvPath" --raw >/dev/null

  if command -v stow >/dev/null 2>&1; then
    printf 'legacy:  GNU Stow is present; existing links remain untouched\n'
  fi

  printf 'status:  selected Home Manager profile evaluates successfully\n'
}

build() {
  local selected
  require_nix
  selected="$(profile)"
  run_nix build \
    "$FLAKE#homeConfigurations.\"$selected\".activationPackage" \
    --no-link
}

switch_generation() {
  local selected backup_extension
  require_nix
  selected="$(profile)"

  if [[ "${DOTFILES_ALLOW_ACTIVATE:-}" != 1 ]]; then
    cat >&2 <<EOF
Refusing to modify your home directory.
First run:
  $0 doctor
  $0 build

Then activate explicitly with:
  DOTFILES_ALLOW_ACTIVATE=1 $0 switch
EOF
    return 1
  fi

  backup_extension="pre-nix-$(date +%Y%m%d-%H%M%S)"
  home_manager switch --flake "$FLAKE#$selected" -b "$backup_extension"
  printf 'Activation complete. Home Manager conflict backups use .%s\n' "$backup_extension"
}

command="${1:-}"
case "$command" in
  profile)
    profile
    ;;
  doctor)
    doctor
    ;;
  check)
    require_nix
    run_nix flake check "$FLAKE" --all-systems --no-build
    ;;
  build)
    build
    ;;
  switch)
    switch_generation
    ;;
  generations)
    require_nix
    home_manager generations
    ;;
  -h | --help | help | "")
    usage
    ;;
  *)
    printf 'Unknown command: %s\n\n' "$command" >&2
    usage >&2
    exit 2
    ;;
esac
