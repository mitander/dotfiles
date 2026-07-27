#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NIX_SCRIPT="$ROOT/scripts/dotfiles-nix.sh"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--activate] [--check]

Safely prepare the Nix/Home Manager environment without invoking a host package
manager.

Options:
  --activate  Build and activate explicitly after validation
  --check     Evaluate every supported system before building
  -h, --help  Show this help

Without --activate, the script runs doctor and build, then prints the guarded
activation command.
EOF
}

activate=0
check_all=0

while (($# > 0)); do
  case "$1" in
    --activate)
      activate=1
      ;;
    --check)
      check_all=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown option: %s\n\n' "$1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

if ! command -v nix >/dev/null 2>&1 && [[ -x /nix/var/nix/profiles/default/bin/nix ]]; then
  export PATH="/nix/var/nix/profiles/default/bin:$PATH"
fi

if ! command -v nix >/dev/null 2>&1; then
  cat >&2 <<'EOF'
Nix is not installed or is not on PATH.
Install Nix using an installer you have reviewed, start a fresh shell, and rerun
./install.sh. This script intentionally does not install Nix automatically.
EOF
  exit 1
fi

"$NIX_SCRIPT" doctor
if ((check_all)); then
  "$NIX_SCRIPT" check
fi
"$NIX_SCRIPT" build

if ((activate)); then
  DOTFILES_ALLOW_ACTIVATE=1 "$NIX_SCRIPT" switch
else
  cat <<EOF

Build complete; no home-directory changes were made.
Activate explicitly with:
  DOTFILES_ALLOW_ACTIVATE=1 $NIX_SCRIPT switch

Ordinary dotfile edits are live-linked and do not require activation.
EOF
fi
