{
  config,
  lib,
  pkgs,
  username,
  dotfilesDirectory,
  ...
}: let
  live = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDirectory}/${path}";
in {
  home = {
    # This value defines the first Home Manager release used by this
    # configuration. Do not change it during routine upgrades.
    stateVersion = "26.05";

    packages = with pkgs; [
      atuin
      bat
      curl
      delta
      fd
      fish
      fzf
      git
      jq
      lazygit
      lsd
      neovim
      ripgrep
      shfmt
      stylua
      tmux
      tree
      unzip
      zoxide
    ];
  };

  programs.home-manager.enable = true;

  home.activation.checkDotfilesCheckout = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    dotfiles_expected_checkout=${lib.escapeShellArg dotfilesDirectory}
    if [[ ! -d "$dotfiles_expected_checkout" || ! -f "$dotfiles_expected_checkout/flake.nix" ]]; then
      echo "Expected live-linked dotfiles checkout is missing: $dotfiles_expected_checkout" >&2
      echo "Clone this repository there or activate a profile with the correct path." >&2
      exit 1
    fi
    flume_expected_checkout="$dotfiles_expected_checkout/themes/flume"
    for schema in dusk opal mira mesa; do
      if [[ ! -f "$flume_expected_checkout/extras/tuxedo/flume-$schema.toml" ]]; then
        echo "Expected Flume checkout or generated Tuxedo palette is missing: $flume_expected_checkout" >&2
        echo "Clone mitander/flume.nvim at ~/c/p/flume.nvim and generate its theme extras." >&2
        exit 1
      fi
    done
    unset flume_expected_checkout dotfiles_expected_checkout
  '';

  home.activation.removeLegacyTuxedoTheme = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    legacy_tuxedo_theme="$HOME/.config/tuxedo/themes/flume.toml"
    if [[ -L "$legacy_tuxedo_theme" ]]; then
      legacy_tuxedo_target="$(readlink -f "$legacy_tuxedo_theme")"
      if [[ "$legacy_tuxedo_target" == ${lib.escapeShellArg "${dotfilesDirectory}/themes/flume/extras/current/tuxedo.toml"} ||
            "$legacy_tuxedo_target" == ${lib.escapeShellArg "${dotfilesDirectory}/tuxedo/.config/tuxedo/themes/flume.toml"} ]]; then
        rm -f "$legacy_tuxedo_theme"
      fi
      unset legacy_tuxedo_target
    fi
    unset legacy_tuxedo_theme
  '';

  xdg.configFile = {
    ".lldbinit".source = live "lldb/.config/.lldbinit";
    "fish/config.fish".source = live "fish/.config/fish/config.fish";
    "ghostty/config".source = live "ghostty/.config/ghostty/config";
    "lazygit/config.yml".source = live "lazygit/.config/lazygit/config.yml";
    "lsd/config.yaml".source = live "lsd/.config/lsd/config.yaml";
    "nvim".source = live "nvim/.config/nvim";
    "stylua/.luarc.json".source = live "stylua/.config/stylua/.luarc.json";
    "stylua/.stylua.toml".source = live "stylua/.config/stylua/.stylua.toml";
    "tuxedo/themes/flume-dusk.toml".source = live "tuxedo/.config/tuxedo/themes/flume-dusk.toml";
    "tuxedo/themes/flume-mesa.toml".source = live "tuxedo/.config/tuxedo/themes/flume-mesa.toml";
    "tuxedo/themes/flume-mira.toml".source = live "tuxedo/.config/tuxedo/themes/flume-mira.toml";
    "tuxedo/themes/flume-opal.toml".source = live "tuxedo/.config/tuxedo/themes/flume-opal.toml";
  };

  home.file = {
    ".gitconfig".source = live "git/.gitconfig";
    ".pi/agent/extensions/flume-ui/index.ts".source = live "pi/.pi/agent/extensions/flume-ui/index.ts";
    ".tmux.conf".source = live "tmux/.tmux.conf";
    ".tmux/workspace-status.conf".source = live "tmux/.tmux/workspace-status.conf";
    ".local/bin/tmux-residency".source = live "scripts/tmux-residency.sh";
  };

  # LazyGit's tmux.yml is loaded directly from the repository by
  # scripts/tmux-project.sh; it is not a user configuration destination.
  # Pi's active theme link remains Flume-managed. Home Manager installs every
  # immutable Tuxedo palette so Flume can switch Tuxedo through its mutable,
  # unmanaged config without replacing theme contents at runtime. Pi credentials,
  # sessions, extensions from other sources, and other mutable agent state stay unmanaged.
  # LSD's colors.yaml remains Flume-managed so changing the active theme keeps
  # updating it without requiring a Home Manager activation.

  # Keep activation builds focused on the environment. The online Home Manager
  # manual remains available, while disabling local manpage generation avoids a
  # large documentation build on every supported architecture.
  manual.manpages.enable = false;

  assertions = [
    {
      assertion = username == "mitander";
      message = "This initial migration scaffold only defines the mitander account.";
    }
  ];
}
