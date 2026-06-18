#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
PACKAGES=(fish tmux neovim git ripgrep fzf fd bat lsd lazygit zoxide atuin tree stylua shfmt)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

install_packages() {
  [[ "${DOTFILES_SKIP_PACKAGES:-}" == 1 ]] && return 0

  if have brew; then
    log "Installing CLI packages with Homebrew"
    brew install "${PACKAGES[@]}" || warn "Some Homebrew packages failed; continuing"
    if [[ "$(uname -s)" == Darwin ]] && ! brew list --cask ghostty >/dev/null 2>&1; then
      brew install --cask ghostty || warn "Ghostty cask install failed; install it manually"
    fi
    return 0
  fi

  if [[ "$(uname -s)" == Darwin ]]; then
    warn "Homebrew not found. Install from https://brew.sh, then rerun this script."
    return 0
  fi

  if have apt-get; then
    log "Installing packages with apt"
    sudo apt-get update
    sudo apt-get install -y fish tmux neovim git ripgrep fzf fd-find bat tree curl unzip build-essential nodejs npm python3 python3-pip || warn "Some apt packages failed; continuing"
  elif have dnf; then
    log "Installing packages with dnf"
    sudo dnf install -y fish tmux neovim git ripgrep fzf fd-find bat lsd lazygit zoxide atuin tree curl unzip gcc gcc-c++ make nodejs npm python3 || warn "Some dnf packages failed; continuing"
  elif have pacman; then
    log "Installing packages with pacman"
    sudo pacman -Syu --needed fish tmux neovim git ripgrep fzf fd bat lsd lazygit zoxide atuin tree curl unzip base-devel nodejs npm python || warn "Some pacman packages failed; continuing"
  else
    warn "No supported package manager found. Install: ${PACKAGES[*]}"
  fi
}

ensure_linux_aliases() {
  mkdir -p "$HOME/.local/bin"
  if ! have fd && have fdfind; then ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"; fi
  if ! have bat && have batcat; then ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"; fi
}

backup_target() {
  local target="$1"
  mkdir -p "$BACKUP_DIR$(dirname "$target")"
  mv "$target" "$BACKUP_DIR$target"
  log "Backed up $target -> $BACKUP_DIR$target"
}

link_file() {
  local src="$1" rel="$2" dst="$HOME/$rel"
  mkdir -p "$(dirname "$dst")"

  if [[ -L "$dst" ]]; then
    local current
    current="$(readlink "$dst")"
    if [[ "$current" == "$src" ]]; then
      return 0
    fi
    backup_target "$dst"
  elif [[ -e "$dst" ]]; then
    if cmp -s "$src" "$dst"; then
      rm -f "$dst"
    else
      backup_target "$dst"
    fi
  fi

  ln -s "$src" "$dst"
}

link_package() {
  local package="$1"
  [[ -d "$DOTFILES_DIR/$package" ]] || return 0
  while IFS= read -r -d '' src; do
    local rel="${src#"$DOTFILES_DIR/$package/"}"
    link_file "$src" "$rel"
  done < <(find "$DOTFILES_DIR/$package" \( -type f -o -type l \) -print0 | sort -z)
}

ensure_dotfiles_alias() {
  local canonical="$HOME/dotfiles"
  [[ "$DOTFILES_DIR" == "$canonical" ]] && return 0
  if [[ -e "$canonical" && ! -L "$canonical" ]]; then
    warn "$canonical exists and is not a symlink; DOTFILES_DIR-dependent integrations will use shell env when available"
    return 0
  fi
  ln -sfn "$DOTFILES_DIR" "$canonical"
}

ensure_theme_repo() {
  local theme_dir="$HOME/c/p/flume"
  mkdir -p "$(dirname "$theme_dir")"

  if [[ -d "$theme_dir/.git" ]]; then
    return 0
  fi

  if [[ -e "$theme_dir" ]]; then
    warn "$theme_dir exists but is not a git repo; leaving theme setup untouched"
    return 0
  fi

  log "Cloning flume theme repo"
  git clone https://github.com/mitander/flume.git "$theme_dir"
}

install_tpm() {
  [[ "${DOTFILES_SKIP_TPM:-}" == 1 ]] && return 0
  local tpm="$HOME/.tmux/plugins/tpm"
  if [[ ! -d "$tpm/.git" ]]; then
    log "Installing tmux plugin manager"
    git clone https://github.com/tmux-plugins/tpm "$tpm"
  fi
}

warm_neovim() {
  [[ "${DOTFILES_SKIP_NVIM_SYNC:-}" == 1 ]] && return 0
  if have nvim; then
    log "Syncing Neovim plugins"
    nvim --headless '+Lazy! sync' +qa || warn "Neovim plugin sync failed; run :Lazy sync inside nvim"
  fi
}

set_login_shell_hint() {
  local fish_bin
  fish_bin="$(command -v fish || true)"
  [[ -n "$fish_bin" ]] || return 0
  if [[ "${SHELL:-}" != "$fish_bin" ]]; then
    warn "To make fish your login shell: chsh -s $fish_bin"
  fi
}

main() {
  log "Bootstrapping dotfiles from $DOTFILES_DIR"
  install_packages
  ensure_linux_aliases
  ensure_dotfiles_alias
  ensure_theme_repo

  log "Linking config"
  for package in fish ghostty nvim tmux git lazygit stylua lsd lldb; do
    link_package "$package"
  done

  install_tpm
  warm_neovim
  set_login_shell_hint
  log "Done. Open Ghostty or run: tmux new -A -s dev"
}

main "$@"
