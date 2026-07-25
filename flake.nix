{
  description = "Mitander's cross-platform development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      ...
    }:
    let
      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];

      forAllSystems = nixpkgs.lib.genAttrs systems;
      pkgsFor = system: import nixpkgs { inherit system; };

      mkHome =
        {
          system,
          username,
          homeDirectory,
          platformModule,
        }:
        home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          extraSpecialArgs = { inherit inputs username; };
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
          platformModule = ./home/darwin.nix;
        };

        "mitander@linux-aarch64" = mkHome {
          system = "aarch64-linux";
          username = "mitander";
          homeDirectory = "/home/mitander";
          platformModule = ./home/linux.nix;
        };

        "mitander@linux-x86_64" = mkHome {
          system = "x86_64-linux";
          username = "mitander";
          homeDirectory = "/home/mitander";
          platformModule = ./home/linux.nix;
        };
      };

      profileForSystem = {
        aarch64-darwin = "mitander@darwin";
        aarch64-linux = "mitander@linux-aarch64";
        x86_64-linux = "mitander@linux-x86_64";
      };
    in
    {
      homeConfigurations = homes;

      checks = forAllSystems (
        system:
        let
          profile = profileForSystem.${system};
        in
        {
          home = homes.${profile}.activationPackage;
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
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
        system:
        let
          homeManager = home-manager.packages.${system}.home-manager;
        in
        {
          home-manager = {
            type = "app";
            program = "${homeManager}/bin/home-manager";
            meta.description = "Home Manager CLI pinned by this flake";
          };
        }
      );
    };
}
