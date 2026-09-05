{
  config,
  lib,
  pkgs,
  username,
  dotfilesDirectory,
  ...
}: let
  live = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDirectory}/${path}";

  trackerTuiSource = pkgs.fetchFromGitHub {
    owner = "runpantheon";
    repo = "ltui";
    rev = "598c4039999e07b3dc03f4f199ccab8d63648dc5";
    hash = "sha256-tbf2rxNsHmtrUPJTXoGvzTjPhONBTxCK0xnkR9tWhWI=";
  };

  flumeTrackerTheme = pkgs.python3Packages.buildPythonPackage {
    pname = "flume-tracker-theme";
    version = "0.1.0";
    src = ../tracker-tui;
    format = "other";

    dependencies = with pkgs.python3Packages; [
      textual
      watchfiles
    ];

    installPhase = ''
      runHook preInstall
      install -Dm644 flume_tracker_theme.py \
        "$out/${pkgs.python3.sitePackages}/flume_tracker_theme.py"
      runHook postInstall
    '';
  };

  mkTrackerTui = {
    pname,
    subdirectory,
  }:
    pkgs.python3Packages.buildPythonApplication {
      inherit pname;
      version = "unstable-2026-09-03";
      src = trackerTuiSource;
      sourceRoot = "${trackerTuiSource.name}/${subdirectory}";
      pyproject = true;

      postPatch = ''
        ${pkgs.python3}/bin/python ${../tracker-tui/patch_upstream.py} ${subdirectory} ${subdirectory}.py
      '';

      build-system = with pkgs.python3Packages; [setuptools];
      dependencies = with pkgs.python3Packages; [
        flumeTrackerTheme
        httpx
        textual
      ];

      makeWrapperArgs = [
        "--set-default"
        "FLUME_TRACKER_THEME_DIR"
        "${dotfilesDirectory}/themes/flume/extras/tracker-tui"
        "--set-default"
        "FLUME_SCHEMA_FILE"
        "${dotfilesDirectory}/themes/flume/extras/current/schema"
      ];

      doCheck = false;
    };
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
      (mkTrackerTui {
        pname = "ltui-linear";
        subdirectory = "ltui";
      })
      (mkTrackerTui {
        pname = "jtui";
        subdirectory = "jtui";
      })
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
    unset dotfiles_expected_checkout
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
  };

  home.file = {
    ".gitconfig".source = live "git/.gitconfig";
    ".pi/agent/extensions/flume-ui/index.ts".source = live "pi/.pi/agent/extensions/flume-ui/index.ts";
    ".tmux.conf".source = live "tmux/.tmux.conf";
    ".tmux/workspace-status.conf".source = live "tmux/.tmux/workspace-status.conf";
    ".local/bin/tmux-nvim".source = live "scripts/tmux-nvim.sh";
    ".local/bin/tmux-project".source = live "scripts/tmux-project.sh";
    ".local/bin/tmux-residency".source = live "scripts/tmux-residency.sh";
    ".local/bin/tmux-session".source = live "scripts/tmux-session.sh";
  };

  # LazyGit's tmux.yml is loaded directly from the repository by
  # scripts/tmux-project.sh; it is not a user configuration destination.
  # Pi credentials, sessions, extensions from other sources, and other mutable
  # agent state stay unmanaged. LSD's colors.yaml remains Flume-managed so
  # changing the active theme keeps updating it without a Home Manager activation.

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
