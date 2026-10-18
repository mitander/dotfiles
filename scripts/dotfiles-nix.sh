#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLAKE="path:$ROOT"
TRACKER_SOURCE_ARGS=(--no-write-lock-file)

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

Tracker source:
  Uses ~/c/p/ltui when present, otherwise the locked remote input.
  DOTFILES_TRACKER_SOURCE=remote forces the remote input.
  DOTFILES_TRACKER_SOURCE=/path/to/ltui selects a different checkout.
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

checkout_for_profile() {
  case "$1" in
  mitander@darwin)
    printf '%s\n' "/Users/mitander/dotfiles"
    ;;
  mitander@linux-aarch64 | mitander@linux-x86_64)
    printf '%s\n' "/home/mitander/dotfiles"
    ;;
  *)
    printf 'Unknown profile: %s\n' "$1" >&2
    return 1
    ;;
  esac
}

verify_checkout() {
  local selected="$1" expected
  expected="$(checkout_for_profile "$selected")"

  if [[ ! -d "$expected" || ! -f "$expected/flake.nix" ]]; then
    printf 'Expected live-linked dotfiles checkout is missing: %s\n' "$expected" >&2
    return 1
  fi

  if [[ ! "$ROOT/flake.nix" -ef "$expected/flake.nix" ]]; then
    cat >&2 <<EOF
This profile live-links configuration from:
  $expected

But this command is running from:
  $ROOT

Move or clone the repository to the expected path, or define a profile for this
checkout before activating it.
EOF
    return 1
  fi
}

select_tracker_source() {
  local source="${DOTFILES_TRACKER_SOURCE:-$HOME/c/p/ltui}"
  TRACKER_SOURCE_ARGS=(--no-write-lock-file)

  if [[ "$source" == remote ]]; then
    printf 'tracker source: locked remote input\n' >&2
  elif [[ -f "$source/ltui/pyproject.toml" && -f "$source/flume-theme/pyproject.toml" ]]; then
    source="$(cd "$source" && pwd -P)"
    TRACKER_SOURCE_ARGS+=(--override-input tracker-tui "path:$source")
    printf 'tracker source: %s (including uncommitted edits)\n' "$source" >&2
  elif [[ -n "${DOTFILES_TRACKER_SOURCE:-}" || -e "$source" ]]; then
    printf 'Invalid tracker checkout: %s\n' "$source" >&2
    return 1
  else
    printf 'tracker source: locked remote input (no local checkout)\n' >&2
  fi
}

require_nix() {
  if ! command -v nix >/dev/null 2>&1; then
    cat >&2 <<'EOF'
Nix is not installed or is not on PATH.
Install Nix using an installer you have reviewed, restart the shell, and rerun
this command.
EOF
    return 1
  fi
  select_tracker_source
}

run_nix() {
  nix --extra-experimental-features "nix-command flakes" "$@"
}

home_manager() {
  run_nix run "$FLAKE#home-manager" "${TRACKER_SOURCE_ARGS[@]}" -- "$@"
}

doctor() {
  local selected
  selected="$(profile)"
  printf 'root:     %s\n' "$ROOT"
  printf 'profile:  %s\n' "$selected"
  printf 'checkout: %s\n' "$(checkout_for_profile "$selected")"
  printf 'host:     %s %s\n' "$(uname -s)" "$(uname -m)"

  verify_checkout "$selected"
  require_nix
  run_nix flake metadata "$FLAKE" "${TRACKER_SOURCE_ARGS[@]}" >/dev/null
  run_nix eval "$FLAKE#homeConfigurations.\"$selected\".activationPackage.drvPath" --raw "${TRACKER_SOURCE_ARGS[@]}" >/dev/null

  printf 'status:  selected Home Manager profile evaluates successfully\n'
}

build() {
  local selected
  require_nix
  selected="$(profile)"
  run_nix build \
    "$FLAKE#homeConfigurations.\"$selected\".activationPackage" \
    --no-link "${TRACKER_SOURCE_ARGS[@]}"
}

switch_generation() {
  local selected backup_extension
  require_nix
  selected="$(profile)"
  verify_checkout "$selected"

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
  home_manager switch --flake "$FLAKE#$selected" -b "$backup_extension" "${TRACKER_SOURCE_ARGS[@]}"
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
  run_nix flake check "$FLAKE" --all-systems --no-build "${TRACKER_SOURCE_ARGS[@]}"
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
