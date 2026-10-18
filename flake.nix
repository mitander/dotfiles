{
  description = "Mitander's cross-platform development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    atuin-nixpkgs.url = "github:NixOS/nixpkgs/e7e2a382e62a3b8370c376c97d78770139eeaf6c";

    ruff-nixpkgs.url = "github:NixOS/nixpkgs/422d1ae605d7fcd9896412b37dc065c456c0eefb";

    tracker-tui = {
      url = "github:mitander/ltui/37b7fc02a3898596a06b97fbe531aaff281a3830";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];

    forAllSystems = nixpkgs.lib.genAttrs systems;
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [
          (final: prev: {
            # Keep Home Manager and checks on the same tmux release across platforms.
            tmux = prev.tmux.overrideAttrs (old: {
              version = "3.8";
              buildInputs = old.buildInputs ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin [final.jemalloc];
              configureFlags = old.configureFlags ++ final.lib.optionals final.stdenv.hostPlatform.isDarwin ["--enable-jemalloc"];
              src = final.fetchFromGitHub {
                owner = "tmux";
                repo = "tmux";
                tag = "3.8";
                hash = "sha256-pv2wlr3coo+E0pfpb58giJJQn9PGgMFqtVA6nk+9JdE=";
              };
            });
          })
        ];
      };

    mkHome = {
      system,
      username,
      homeDirectory,
      dotfilesDirectory,
      platformModule,
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor system;
        extraSpecialArgs = {inherit inputs username dotfilesDirectory;};
        modules = [
          ./home/common.nix
          platformModule
          {
            home = {
              inherit username homeDirectory;
            };
          }
        ];
      };

    homes = {
      "mitander@darwin" = mkHome {
        system = "aarch64-darwin";
        username = "mitander";
        homeDirectory = "/Users/mitander";
        dotfilesDirectory = "/Users/mitander/dotfiles";
        platformModule = ./home/darwin.nix;
      };

      "mitander@linux-aarch64" = mkHome {
        system = "aarch64-linux";
        username = "mitander";
        homeDirectory = "/home/mitander";
        dotfilesDirectory = "/home/mitander/dotfiles";
        platformModule = ./home/linux.nix;
      };

      "mitander@linux-x86_64" = mkHome {
        system = "x86_64-linux";
        username = "mitander";
        homeDirectory = "/home/mitander";
        dotfilesDirectory = "/home/mitander/dotfiles";
        platformModule = ./home/linux.nix;
      };
    };

    profileForSystem = {
      aarch64-darwin = "mitander@darwin";
      aarch64-linux = "mitander@linux-aarch64";
      x86_64-linux = "mitander@linux-x86_64";
    };
  in {
    homeConfigurations = homes;

    checks = forAllSystems (
      system: let
        profile = profileForSystem.${system};
        pkgs = pkgsFor system;
        ltui =
          nixpkgs.lib.findFirst
          (package: (package.pname or "") == "ltui-linear")
          (throw "Home Manager must provide ltui-linear for tracker tests")
          homes.${profile}.config.home.packages;
        jtui =
          nixpkgs.lib.findFirst
          (package: (package.pname or "") == "jtui")
          (throw "Home Manager must provide jtui for tracker tests")
          homes.${profile}.config.home.packages;
        trackerPython = pkgs.python3.withPackages (_: ltui.propagatedBuildInputs ++ jtui.propagatedBuildInputs);
      in {
        home = homes.${profile}.activationPackage;
        formatting =
          pkgs.runCommand "formatting" {
            nativeBuildInputs = [
              inputs.ruff-nixpkgs.legacyPackages.${system}.ruff
              inputs.ruff-nixpkgs.legacyPackages.${system}.shfmt
              inputs.ruff-nixpkgs.legacyPackages.${system}.shellcheck
              inputs.ruff-nixpkgs.legacyPackages.${system}.prettier
              inputs.ruff-nixpkgs.legacyPackages.${system}.taplo
              pkgs.stylua
              pkgs.alejandra
              pkgs.fish
              pkgs.python3
              pkgs.git
            ];
          } ''
            cp -R ${./.} source
            chmod -R u+w source
            cd source
            git init -q
            export FISH_INDENT="${pkgs.fish}/bin/fish_indent"
            sh scripts/format.sh check
            python3 tests/python-format.py
            touch "$out"
          '';
        editor-shell =
          pkgs.runCommand "editor-shell-config-check" {
            nativeBuildInputs = with pkgs; [bash coreutils fd fish fzf git gnugrep neovim ripgrep tmux];
          } ''
            export HOME="$TMPDIR/home"
            export DOTFILES_TEST_ROOT="$TMPDIR/source"
            mkdir -p "$HOME" "$DOTFILES_TEST_ROOT/nvim/.config" \
              "$DOTFILES_TEST_ROOT/fish/.config/fish" "$DOTFILES_TEST_ROOT/dprint/.config" "$DOTFILES_TEST_ROOT/tests"
            cp -R ${./dprint/.config/dprint} "$DOTFILES_TEST_ROOT/dprint/.config/dprint"
            cp -R ${./nvim/.config/nvim} "$DOTFILES_TEST_ROOT/nvim/.config/nvim"
            cp ${./fish/.config/fish/config.fish} "$DOTFILES_TEST_ROOT/fish/.config/fish/config.fish"
            cp ${./tests/nvim-config.lua} "$DOTFILES_TEST_ROOT/tests/nvim-config.lua"
            cp ${./tests/nvim-formatters.lua} "$DOTFILES_TEST_ROOT/tests/nvim-formatters.lua"
            cp ${./tests/nvim-clipboard.lua} "$DOTFILES_TEST_ROOT/tests/nvim-clipboard.lua"
            nvim --clean --headless -l "$DOTFILES_TEST_ROOT/tests/nvim-config.lua"
            nvim --clean --headless -l "$DOTFILES_TEST_ROOT/tests/nvim-formatters.lua"
            nvim --clean --headless -l "$DOTFILES_TEST_ROOT/tests/nvim-clipboard.lua"
            bash ${./tests/fish-nvim.sh}
            bash ${./tests/fish-config.sh}
            touch "$out"
          '';
        tracker-source =
          pkgs.runCommand "tracker-source-check" {
            nativeBuildInputs = with pkgs; [bash coreutils gawk gnugrep];
          } ''
            bash ${./tests/tracker-source.sh} ${./scripts/dotfiles-nix.sh}
            touch "$out"
          '';
        tracker-tui =
          pkgs.runCommand "tracker-tui-check" {
            nativeBuildInputs = [trackerPython];
          } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            export FLUME_TRACKER_THEME_DIR=${ltui.flumeTrackerThemes}
            export PYTHONPATH=${ltui}/${pkgs.python3.sitePackages}:${jtui}/${pkgs.python3.sitePackages}:${ltui.src}/sctui
            python3 -m unittest discover -s ${ltui.src}/flume-theme/tests -p 'test_*.py'
            python3 -m unittest discover -s ${ltui.src}/tests -p 'test_*.py'
            python3 -m unittest discover -s ${ltui.src}/ltui/tests -p 'test_*.py'
            touch "$out"
          '';
        tmux-callers =
          pkgs.runCommand "tmux-callers-check" {
            nativeBuildInputs = with pkgs; [
              bash
              coreutils
              fish
              git
              gawk
              gnugrep
              neovim
              tmux
            ];
          } ''
            export HOME="$TMPDIR/home"
            export DOTFILES_TEST_ROOT="$TMPDIR/dotfiles"
            mkdir -p "$HOME" "$DOTFILES_TEST_ROOT/scripts" "$DOTFILES_TEST_ROOT/tmux/.tmux" \
              "$DOTFILES_TEST_ROOT/extras/tmux" "$DOTFILES_TEST_ROOT/tests" \
              "$DOTFILES_TEST_ROOT/fish/.config/fish"
            cp ${./scripts/install-myran.py} "$DOTFILES_TEST_ROOT/scripts/install-myran.py"
            cp ${./tests/install-myran.py} "$DOTFILES_TEST_ROOT/tests/install-myran.py"
            cp ${./fish/.config/fish/config.fish} "$DOTFILES_TEST_ROOT/fish/.config/fish/config.fish"
            cp ${./tmux/.tmux.conf} "$DOTFILES_TEST_ROOT/tmux/.tmux.conf"
            cp ${./tmux/.tmux/workspace-status.conf} "$DOTFILES_TEST_ROOT/tmux/.tmux/workspace-status.conf"
            cp ${./extras/tmux/colors.conf} "$DOTFILES_TEST_ROOT/extras/tmux/colors.conf"
            bash ${./tests/tmux-config.sh}
            bash ${./tests/fish-nvim.sh}
            python3 "$DOTFILES_TEST_ROOT/tests/install-myran.py"
            touch "$out"
          '';
      }
    );

    devShells = forAllSystems (
      system: let
        pkgs = pkgsFor system;
      in {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            alejandra
            deadnix
            statix
          ];
        };
      }
    );

    formatter = forAllSystems (system: (pkgsFor system).alejandra);

    apps = forAllSystems (
      system: let
        homeManager = home-manager.packages.${system}.home-manager;
      in {
        home-manager = {
          type = "app";
          program = "${homeManager}/bin/home-manager";
          meta.description = "Home Manager CLI pinned by this flake";
        };
      }
    );
  };
}
