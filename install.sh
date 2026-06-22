#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
PACKAGES=(fish tmux neovim git ripgrep fzf fd bat lsd lazygit zoxide atuin tree stylua shfmt stow)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }
link_target() { realpath "$1" 2>/dev/null || true; }

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
    sudo apt-get install -y fish tmux neovim git ripgrep fzf fd-find bat tree curl unzip build-essential nodejs npm python3 python3-pip stow || warn "Some apt packages failed; continuing"
  elif have dnf; then
    log "Installing packages with dnf"
    sudo dnf install -y fish tmux neovim git ripgrep fzf fd-find bat lsd lazygit zoxide atuin tree curl unzip gcc gcc-c++ make nodejs npm python3 stow || warn "Some dnf packages failed; continuing"
  elif have pacman; then
    log "Installing packages with pacman"
    sudo pacman -Syu --needed fish tmux neovim git ripgrep fzf fd bat lsd lazygit zoxide atuin tree curl unzip base-devel nodejs npm stow python || warn "Some pacman packages failed; continuing"
  else
    warn "No supported package manager found. Install: ${PACKAGES[*]}"
  fi
}

ensure_linux_aliases() {
  mkdir -p "$HOME/.local/bin"
  if ! have fd && have fdfind; then
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
  fi
  if ! have bat && have batcat; then
    ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
  fi
}

ensure_local_bin_path() {
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
  esac
}

nvim_is_modern() {
  have nvim || return 1
  local version major minor
  version="$(nvim --version | awk 'NR == 1 { print $2 }')"
  version="${version#v}"
  version="${version%%-*}"
  IFS=. read -r major minor _ <<<"$version"
  ((${major:-0} > 0 || ${minor:-0} >= 10))
}

install_modern_neovim() {
  [[ "$(uname -s)" == Linux ]] || return 0
  nvim_is_modern && return 0
  have curl || {
    warn "curl not found; cannot install modern Neovim release"
    return 0
  }

  local arch asset tmp opt_dir target
  case "$(uname -m)" in
    x86_64 | amd64) arch=x86_64 ;;
    aarch64 | arm64) arch=arm64 ;;
    *)
      warn "Unsupported Neovim release architecture: $(uname -m)"
      return 0
      ;;
  esac

  asset="nvim-linux-$arch.tar.gz"
  tmp="$(mktemp -d)"
  opt_dir="$HOME/.local/opt"
  mkdir -p "$opt_dir" "$HOME/.local/bin"

  log "Installing modern Neovim release to ~/.local/opt"
  if curl -fL "https://github.com/neovim/neovim/releases/latest/download/$asset" -o "$tmp/$asset"; then
    rm -rf "$opt_dir/nvim-linux-$arch"
    tar -C "$opt_dir" -xzf "$tmp/$asset"
    target="$opt_dir/nvim-linux-$arch"
    ln -sfn "$target" "$opt_dir/nvim"
    ln -sfn "$opt_dir/nvim/bin/nvim" "$HOME/.local/bin/nvim"
  else
    warn "Could not download $asset; install Neovim >= 0.10 manually"
  fi
  rm -rf "$tmp"
}

install_lazygit_release() {
  [[ "$(uname -s)" == Linux ]] || return 0
  have lazygit && return 0
  have curl || {
    warn "curl not found; cannot install lazygit release"
    return 0
  }

  local arch tmp api url
  case "$(uname -m)" in
    x86_64 | amd64) arch=x86_64 ;;
    aarch64 | arm64) arch=arm64 ;;
    armv6l | armv7l) arch=armv6 ;;
    *)
      warn "Unsupported lazygit release architecture: $(uname -m)"
      return 0
      ;;
  esac

  tmp="$(mktemp -d)"
  log "Installing latest lazygit release to ~/.local/bin"
  api="$(curl -fsSL https://api.github.com/repos/jesseduffield/lazygit/releases/latest || true)"
  url="$(printf '%s\n' "$api" | grep -o 'https://[^" ]*linux_'"$arch"'\.tar\.gz' | head -n1 || true)"
  if [[ -z "$url" ]]; then
    warn "Could not find lazygit linux_$arch release asset"
    rm -rf "$tmp"
    return 0
  fi

  if curl -fL "$url" -o "$tmp/lazygit.tar.gz"; then
    tar -C "$tmp" -xzf "$tmp/lazygit.tar.gz" lazygit
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp/lazygit" "$HOME/.local/bin/lazygit"
  else
    warn "Could not download lazygit release"
  fi
  rm -rf "$tmp"
}

fzf_has_shell_integration() {
  have fzf || return 1
  fzf --bash >/dev/null 2>&1 && fzf --fish >/dev/null 2>&1
}

install_fzf_release_if_needed() {
  [[ "$(uname -s)" == Linux ]] || return 0
  fzf_has_shell_integration && return 0
  have curl || {
    warn "curl not found; cannot install modern fzf release"
    return 0
  }

  local arch tmp api url
  case "$(uname -m)" in
    x86_64 | amd64) arch=amd64 ;;
    aarch64 | arm64) arch=arm64 ;;
    armv5*) arch=armv5 ;;
    armv6*) arch=armv6 ;;
    armv7*) arch=armv7 ;;
    ppc64le) arch=ppc64le ;;
    riscv64) arch=riscv64 ;;
    s390x) arch=s390x ;;
    loongarch64) arch=loong64 ;;
    *)
      warn "Unsupported fzf release architecture: $(uname -m)"
      return 0
      ;;
  esac

  tmp="$(mktemp -d)"
  log "Installing latest fzf release to ~/.local/bin"
  api="$(curl -fsSL https://api.github.com/repos/junegunn/fzf/releases/latest || true)"
  url="$(printf '%s\n' "$api" | grep -o 'https://[^" ]*linux_'"$arch"'\.tar\.gz' | head -n1 || true)"
  if [[ -z "$url" ]]; then
    warn "Could not find fzf linux_$arch release asset"
    rm -rf "$tmp"
    return 0
  fi

  if curl -fL "$url" -o "$tmp/fzf.tar.gz"; then
    tar -C "$tmp" -xzf "$tmp/fzf.tar.gz" fzf
    mkdir -p "$HOME/.local/bin"
    install -m 0755 "$tmp/fzf" "$HOME/.local/bin/fzf"
  else
    warn "Could not download fzf release"
  fi
  rm -rf "$tmp"
}

backup_target() {
  local target="$1"
  mkdir -p "$BACKUP_DIR$(dirname "$target")"
  mv "$target" "$BACKUP_DIR$target"
  log "Backed up $target -> $BACKUP_DIR$target"
}

require_stow() {
  if ! have stow; then
    warn "GNU stow is required for linking configs. Install stow or rerun without DOTFILES_SKIP_PACKAGES."
    exit 1
  fi
}

remove_stowed_ancestor() {
  local package="$1" rel="$2" path="$HOME" part target
  IFS=/ read -r -a parts <<<"$rel"
  for part in "${parts[@]:0:${#parts[@]}-1}"; do
    path="$path/$part"
    if [[ -L "$path" ]]; then
      target="$(link_target "$path")"
      if [[ "$target" == "$DOTFILES_DIR/$package"* ]]; then
        rm -f "$path"
      else
        backup_target "$path"
      fi
    fi
    if [[ -e "$path" && ! -d "$path" ]]; then
      backup_target "$path"
    fi
    mkdir -p "$path"
  done
}

prepare_stow_package() {
  local package="$1"
  [[ -d "$DOTFILES_DIR/$package" ]] || return 0

  # First let stow remove any links it already owns. Then clean conflicts that
  # the old hand-rolled linker or existing dotfiles may have left behind.
  stow -D -d "$DOTFILES_DIR" -t "$HOME" --no-folding "$package" >/dev/null 2>&1 || true

  while IFS= read -r -d '' src; do
    local rel dst current
    rel="${src#"$DOTFILES_DIR/$package/"}"
    dst="$HOME/$rel"

    remove_stowed_ancestor "$package" "$rel"

    if [[ -L "$dst" ]]; then
      current="$(link_target "$dst")"
      if [[ "$current" == "$src" ]]; then
        rm -f "$dst"
      else
        backup_target "$dst"
      fi
    elif [[ -e "$dst" ]]; then
      if cmp -s "$src" "$dst"; then
        rm -f "$dst"
      else
        backup_target "$dst"
      fi
    fi
  done < <(find "$DOTFILES_DIR/$package" \( -type f -o -type l \) -print0 | sort -z)
}

link_package() {
  local package="$1"
  [[ -d "$DOTFILES_DIR/$package" ]] || return 0

  prepare_stow_package "$package"
  stow -d "$DOTFILES_DIR" -t "$HOME" --no-folding "$package"
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
  local theme_dir="$HOME/c/p/flume.nvim"
  mkdir -p "$(dirname "$theme_dir")" "$DOTFILES_DIR/themes"

  if [[ ! -d "$theme_dir/.git" ]]; then
    if [[ -e "$theme_dir" ]]; then
      warn "$theme_dir exists but is not a git repo; leaving theme setup untouched"
    else
      log "Cloning flume theme repo"
      git clone https://github.com/mitander/flume.nvim.git "$theme_dir"
    fi
  fi

  if [[ ! -L "$DOTFILES_DIR/themes/flume" ]]; then
    if [[ -e "$DOTFILES_DIR/themes/flume" ]]; then
      warn "$DOTFILES_DIR/themes/flume exists and is not a symlink; leaving it untouched"
    else
      ln -s ../../c/p/flume.nvim "$DOTFILES_DIR/themes/flume"
    fi
  fi

  [[ -f "$DOTFILES_DIR/themes/flume/extras/ghostty/flume" ]] || warn "Flume Ghostty theme missing: $DOTFILES_DIR/themes/flume/ghostty/flume"
  [[ -f "$DOTFILES_DIR/themes/flume/extras/tmux/colors.conf" ]] || warn "Flume tmux colors missing: $DOTFILES_DIR/themes/flume/tmux/colors.conf"
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
    if ! nvim_is_modern; then
      warn "Neovim is too old for this config; install Neovim >= 0.10, then run :Lazy sync"
      return 0
    fi
    log "Syncing Neovim plugins"
    nvim --headless '+lua require("lazy").sync({ wait = true })' +qa || warn "Neovim plugin sync failed; open nvim and run :Lazy sync"
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

verify_link() {
  local path="$1" expected="$2" actual
  actual="$(link_target "$path")"
  if [[ "$actual" != "$expected" ]]; then
    warn "$path is not linked correctly (got: ${actual:-missing}, expected: $expected)"
  fi
}

verify_config_links() {
  verify_link "$HOME/.config/nvim/init.lua" "$DOTFILES_DIR/nvim/.config/nvim/init.lua"
  verify_link "$HOME/.tmux.conf" "$DOTFILES_DIR/tmux/.tmux.conf"
  verify_link "$HOME/.config/fish/config.fish" "$DOTFILES_DIR/fish/.config/fish/config.fish"
  verify_link "$HOME/.config/ghostty/config" "$DOTFILES_DIR/ghostty/.config/ghostty/config"
  verify_link "$HOME/.config/lsd/config.yaml" "$DOTFILES_DIR/lsd/.config/lsd/config.yaml"
  verify_link "$HOME/.pi/agent/themes/flume.json" "$DOTFILES_DIR/pi/.pi/agent/themes/flume.json"
  verify_link "$HOME/.pi/agent/extensions/flume-ui/index.ts" "$DOTFILES_DIR/pi/.pi/agent/extensions/flume-ui/index.ts"
}

main() {
  log "Bootstrapping dotfiles from $DOTFILES_DIR"
  install_packages
  ensure_linux_aliases
  ensure_local_bin_path
  install_modern_neovim
  install_fzf_release_if_needed
  install_lazygit_release
  ensure_dotfiles_alias
  ensure_theme_repo

  log "Linking config"
  require_stow
  for package in fish ghostty nvim tmux git lazygit stylua lsd lldb pi; do
    link_package "$package"
  done
  verify_config_links

  install_tpm
  warm_neovim
  set_login_shell_hint
  log "Done. Restart Ghostty and tmux for config changes: tmux kill-server; tmux new -A -s dev"
}

main "$@"
