{
  config,
  inputs,
  lib,
  pkgs,
  username,
  dotfilesDirectory,
  ...
}: let
  live = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDirectory}/${path}";

  # Private agent configuration lives in ~/.agents.
  agentLive = path: config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.agents/${path}";

  # Personal fork; see tracker-tui/README.md before updating the pin.
  trackerTuiSource = pkgs.fetchFromGitHub {
    owner = "mitander";
    repo = "ltui";
    rev = "37b7fc02a3898596a06b97fbe531aaff281a3830";
    name = "ltui-personal-source";
    hash = "sha256-v9BAYjfPHr+1eyPIfG7yq19Qe+fkmVnBTW8ToEMNw50=";
  };

  # Build-time palettes are pinned; runtime schema selection remains live-linked.
  flumeSource = pkgs.fetchFromGitHub {
    owner = "mitander";
    repo = "flume.nvim";
    rev = "b767a86b02d3a936a8609f2fa4ff50bb4b468cb4";
    hash = "sha256-+FkqFM/yVXJCL4abZgYp4Qp7AO5lc9uxa4CkFou14dQ=";
  };

  flumeTrackerThemes =
    pkgs.runCommand "flume-tracker-themes" {
      nativeBuildInputs = [pkgs.neovim];
      paletteSource = "${flumeSource}/lua/flume/palette.lua";
    } ''
      mkdir -p runtime/lua/flume
      cp "$paletteSource" runtime/lua/flume/palette.lua
      export HOME="$TMPDIR" FLUME_RUNTIME="$PWD/runtime" FLUME_TRACKER_OUTPUT="$out"
      nvim --headless --clean -l ${trackerTuiSource}/flume-theme/generate.lua
    '';

  flumeTrackerTheme = pkgs.python3Packages.buildPythonPackage {
    pname = "flume-tracker-theme";
    version = "0.1.0";
    src = trackerTuiSource;
    sourceRoot = "ltui-personal-source/flume-theme";
    pyproject = true;
    build-system = [pkgs.python3Packages.setuptools];
    pythonImportsCheck = ["flume_tracker_theme"];

    dependencies = with pkgs.python3Packages; [
      textual
      watchfiles
    ];

    postInstall = ''
      install -Dm644 ../LICENSE "$out/share/doc/flume-tracker-theme/LICENSE"
      install -Dm644 ../NOTICE "$out/share/doc/flume-tracker-theme/NOTICE"
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
      sourceRoot = "ltui-personal-source/${subdirectory}";
      pyproject = true;

      build-system = with pkgs.python3Packages; [setuptools];
      dependencies = with pkgs.python3Packages; [
        flumeTrackerTheme
        httpx
        textual
      ];

      makeWrapperArgs = [
        "--set-default"
        "FLUME_TRACKER_THEME_DIR"
        "${flumeTrackerThemes}"
        "--set-default"
        "FLUME_SCHEMA_FILE"
        "${dotfilesDirectory}/themes/flume/extras/current/schema"
      ];

      pythonImportsCheck = [subdirectory];
      passthru.flumeTrackerThemes = flumeTrackerThemes;
      postInstall = ''
        install -Dm644 ../LICENSE "$out/share/doc/${pname}/LICENSE"
        install -Dm644 ../NOTICE "$out/share/doc/${pname}/NOTICE"
      '';
    };
in {
  home = {
    # Do not change during routine upgrades.
    stateVersion = "26.05";

    packages = with pkgs; [
      inputs.atuin-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.atuin
      bat
      alejandra
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
      inputs.ruff-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.prettier
      inputs.ruff-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.taplo
      ripgrep
      inputs.ruff-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ruff
      inputs.ruff-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.shfmt
      inputs.ruff-nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system}.shellcheck
      stylua
      tmux
      tree
      unzip
      zoxide
    ];
  };

  programs.home-manager.enable = true;

  home.activation.checkAgentConfigCheckout = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
    agents_expected_checkout="$HOME/.agents"
    if [[ ! -d "$agents_expected_checkout/skills" || ! -d "$agents_expected_checkout/.git" ]]; then
      echo "Expected live-linked agent-config checkout is missing: $agents_expected_checkout" >&2
      echo "Run: mkdir -p ~/.agents && gh repo clone mitander/agent-config ~/.agents" >&2
      exit 1
    fi
  '';

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
    "bronson/flume".source = live "themes/flume/extras";
    "bronson/flume-themes".source = flumeTrackerThemes;
    "fish/config.fish".source = live "fish/.config/fish/config.fish";
    "ghostty/config".source = live "ghostty/.config/ghostty/config";
    "lazygit/config.yml".source = live "lazygit/.config/lazygit/config.yml";
    "lsd/config.yaml".source = live "lsd/.config/lsd/config.yaml";
    "nvim".source = live "nvim/.config/nvim";
    "git/work.gitconfig".source = live "git/work.gitconfig";
    "git/personal.gitconfig".source = live "git/personal.gitconfig";
    "stylua/.luarc.json".source = live "stylua/.config/stylua/.luarc.json";
    "stylua/.stylua.toml".source = live "stylua/.config/stylua/.stylua.toml";
  };

  home.file = {
    ".gitconfig".source = live "git/.gitconfig";
    ".pi/agent/AGENTS.md".source = agentLive "pi/AGENTS.md";
    ".pi/agent/settings.json".source = agentLive "pi/settings.json";
    ".pi/agent/extensions/context-watch".source = agentLive "pi/extensions/context-watch";
    ".pi/agent/extensions/myran".source = agentLive "pi/extensions/myran";
    ".pi/agent/extensions/herdr-agent-state.ts".source = agentLive "pi/extensions/herdr-agent-state.ts";
    ".pi/agent/extensions/flume-ui/index.ts".source = live "pi/.pi/agent/extensions/flume-ui/index.ts";
    ".claude/CLAUDE.md".source = agentLive "pi/AGENTS.md";
    ".codex/AGENTS.md".source = agentLive "pi/AGENTS.md";
    ".copilot/AGENTS.md".source = agentLive "pi/AGENTS.md";
    ".local/bin/agents-skills-link".source = live "scripts/agents-skills-link.sh";
    ".local/bin/dotfiles".source = live "scripts/dotfiles";
    ".local/bin/dotfiles-format".source = live "scripts/format.sh";
    ".tmux.conf".source = live "tmux/.tmux.conf";
    ".tmux/workspace-status.conf".source = live "tmux/.tmux/workspace-status.conf";
  };

  # Mutable agent state stays unmanaged. The Flume-managed lsd colors file
  # remains linked so theme changes apply without a Home Manager activation.

  # Keep activation builds focused on the environment.
  manual.manpages.enable = false;

  assertions = [
    {
      assertion = username == "mitander";
      message = "This initial migration scaffold only defines the mitander account.";
    }
  ];
}
