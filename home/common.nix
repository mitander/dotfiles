{
  config,
  inputs,
  lib,
  pkgs,
  dotfilesDirectory,
  ...
}: let
  toolingPkgs = inputs.ruff-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};

  # Keep one format per face so macOS does not register duplicate font identities.
  jetbrainsMono =
    pkgs.runCommand "jetbrains-mono-static-${pkgs.jetbrains-mono.version}" {
      inherit (pkgs.jetbrains-mono) pname version;
    } ''
      mkdir -p "$out/share/fonts/truetype"
      for font in ${pkgs.jetbrains-mono}/share/fonts/truetype/*.ttf; do
        case "$font" in
          *'['*) continue ;;
        esac
        ln -s "$font" "$out/share/fonts/truetype/"
      done
    '';

  live = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDirectory}/${path}";
in {
  home = {
    # Do not change during routine upgrades.
    stateVersion = "26.05";

    packages = with pkgs; [
      # Shell and navigation
      inputs.atuin-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.atuin
      bat
      direnv
      fd
      fish
      fzf
      lsd
      ripgrep
      tmux
      tree
      tokei
      yazi
      python3
      zoxide

      # Image conversion for Neovim's Snacks image viewer
      imagemagick

      # Development tools
      clang-tools
      curl
      delta
      gh
      git
      jq
      lazygit
      neovim
      unzip
      uv
      zig

      # Language servers. Rust stays with rustup; ZLS follows the project Zig toolchain.
      gopls
      lua-language-server
      typescript-language-server
      vscode-langservers-extracted

      # Formatters and diagnostics
      alejandra
      toolingPkgs.dprint
      toolingPkgs.prettier
      toolingPkgs.prettierd
      toolingPkgs.pyright
      toolingPkgs.ruff
      toolingPkgs.shellcheck
      toolingPkgs.shfmt
      toolingPkgs.taplo
      toolingPkgs.typescript
      stylua

      # Fonts
      jetbrainsMono
      maple-mono.truetype
    ];
  };

  # Platform integration
  fonts.fontconfig.enable = pkgs.stdenv.hostPlatform.isLinux;

  programs.home-manager.enable = true;

  # Checkout validation
  home.activation.checkDotfilesCheckout = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    dotfiles_expected_checkout=${lib.escapeShellArg dotfilesDirectory}
    if [[ ! -d "$dotfiles_expected_checkout" || ! -f "$dotfiles_expected_checkout/flake.nix" ]]; then
      echo "Expected live-linked dotfiles checkout is missing: $dotfiles_expected_checkout" >&2
      echo "Clone this repository there or activate a profile with the correct path." >&2
      exit 1
    fi
    unset dotfiles_expected_checkout
  '';

  # Live configuration links
  xdg.configFile =
    {
      ".lldbinit".source = live "lldb/.config/.lldbinit";
      "bronson/flume".source = live "themes/flume/extras";
      "dprint".source = live "dprint/.config/dprint";
      "fish/config.fish".source = live "fish/.config/fish/config.fish";
      "ghostty/config".source = live "ghostty/.config/ghostty/config";
      "lazygit/config.yml".source = live "lazygit/.config/lazygit/config.yml";
      "lazygit/flume.yml".source = live "themes/flume/extras/current/lazygit.yml";
      "lsd/config.yaml".source = live "lsd/.config/lsd/config.yaml";
      "nvim".source = live "nvim/.config/nvim";
      "yazi/yazi.toml".source = live "yazi/.config/yazi/yazi.toml";
      "yazi/keymap.toml".source = live "yazi/.config/yazi/keymap.toml";
      "yazi/theme.toml".source = live "yazi/.config/yazi/theme.toml";
      "stylua/.stylua.toml".source = live "stylua/.config/stylua/.stylua.toml";
    }
    // lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      "ghostty/linux".source = live "ghostty/.config/ghostty/linux";
    };

  # Command and tmux links
  home.file = {
    ".gitconfig".source = live "git/.gitconfig";
    ".local/bin/dotfiles".source = live "scripts/dotfiles";
    ".local/bin/myran-yazi".source = live "scripts/myran-yazi";
    ".local/bin/dotfiles-format".source = live "scripts/format.sh";
    ".local/bin/ltui".source = live "tracker-tui/launch";
    ".local/bin/bronson".source = live "scripts/bronson";
    ".tmux.conf".source = live "tmux/.tmux.conf";
    ".tmux/workspace-status.conf".source = live "tmux/.tmux/workspace-status.conf";
  };

  # Mutable agent state stays unmanaged. The Flume-managed lsd colors file
  # remains linked so theme changes apply without a Home Manager activation.

  # Keep activation builds focused on the environment.
  manual.manpages.enable = false;
}
