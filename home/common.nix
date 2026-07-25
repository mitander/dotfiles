{
  config,
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
      stow
      stylua
      tmux
      tree
      unzip
      zoxide
    ];
  };

  programs.home-manager.enable = true;

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
    ".local/bin/tmux-residency".source = live "scripts/tmux-residency.sh";
  };

  # LazyGit's tmux.yml is loaded directly from the repository by
  # scripts/tmux-project.sh; it is not a user configuration destination.
  # Pi and Tuxedo theme links remain Flume-managed; Pi credentials, sessions,
  # extensions from other sources, and other mutable agent state stay unmanaged.
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
