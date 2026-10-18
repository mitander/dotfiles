{
  description = "Mitander's cross-platform development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    atuin-nixpkgs.url = "github:NixOS/nixpkgs/e7e2a382e62a3b8370c376c97d78770139eeaf6c";

    ruff-nixpkgs.url = "github:NixOS/nixpkgs/422d1ae605d7fcd9896412b37dc065c456c0eefb";

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
    }:
      home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsFor system;
        extraSpecialArgs = {inherit inputs username dotfilesDirectory;};
        modules = [
          ./home/common.nix
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
      };

      "mitander@linux-aarch64" = mkHome {
        system = "aarch64-linux";
        username = "mitander";
        homeDirectory = "/home/mitander";
        dotfilesDirectory = "/home/mitander/dotfiles";
      };

      "mitander@linux-x86_64" = mkHome {
        system = "x86_64-linux";
        username = "mitander";
        homeDirectory = "/home/mitander";
        dotfilesDirectory = "/home/mitander/dotfiles";
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
        formatPkgs = inputs.ruff-nixpkgs.legacyPackages.${system};
      in {
        home = homes.${profile}.activationPackage;
        default =
          pkgs.runCommand "dotfiles-check" {
            nativeBuildInputs = [
              formatPkgs.ruff
              formatPkgs.shfmt
              formatPkgs.shellcheck
              formatPkgs.prettier
              formatPkgs.taplo
              pkgs.stylua
              pkgs.alejandra
              pkgs.fish
              pkgs.python3
              pkgs.git
              pkgs.bash
              pkgs.fd
              pkgs.fzf
              pkgs.neovim
              pkgs.ripgrep
              pkgs.tmux
            ];
          } ''
            export HOME="$TMPDIR/home"
            mkdir -p "$HOME"
            cp -R ${./.} source
            chmod -R u+w source
            patchShebangs source
            cd source
            git init -q
            export FISH_INDENT="${pkgs.fish}/bin/fish_indent"
            bash scripts/check
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
