{
  description = "Nix config for my machines, copied from all over the internet.";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles to optimize settings for different hardware
    # No support for: MacBookPro18,2 yet
    # hardware.url = "github:nixos/nixos-hardware";

    # Nix Darwin (for MacOS machines)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # treefmt
    treefmt-nix.url = "github:numtide/treefmt-nix";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nix-darwin,
      nixvim,
      treefmt-nix,
      systems,
      ...
    }@inputs:
    let
      # Small tool to iterate over each systems
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});

      # Global packages available on all systems
      globalPackages =
        pkgs: with pkgs; [
          just
          fastfetch
          ripgrep
        ];

      # Eval the treefmt modules from ./treefmt.nix
      treefmtEval = eachSystem (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);

      # Shared home-manager modules for all hosts
      sharedHomeModules = [
        ./modules/home-manager/shell.nix
        ./modules/home-manager/nixvim.nix
      ];

      # Helper function to configure home-manager
      mkHomeManager =
        {
          username,
          homeDirectory,
          homeModules ? [ ],
        }:
        {
          home-manager.backupFileExtension = "bak";
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.sharedModules = sharedHomeModules;
          home-manager.users.${username} = {
            imports = homeModules;
            home.username = username;
            home.homeDirectory = homeDirectory;
            home.stateVersion = "25.11";
          };
        };

      # Helper function to create Darwin hosts
      mkDarwinHost =
        {
          hostname,
          username,
          system ? "aarch64-darwin",
          modules ? [ ],
          homeModules ? [ ],
        }:
        nix-darwin.lib.darwinSystem {
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          specialArgs = { inherit inputs globalPackages; };
          modules = [
            home-manager.darwinModules.home-manager
            ./modules/common/nix.nix
            ./modules/nix-darwin/bootstrap.nix
            {
              system.primaryUser = username;
              users.users.${username}.home = "/Users/${username}";
            }
            (mkHomeManager {
              inherit username homeModules;
              homeDirectory = "/Users/${username}";
            })
          ]
          ++ modules;
        };

      # Helper function to create NixOS hosts
      mkNixosHost =
        {
          hostname,
          username,
          system ? "aarch64-linux",
          modules ? [ ],
          homeModules ? [ ],
        }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs globalPackages; };
          modules = [
            home-manager.nixosModules.default
            ./modules/common/nix.nix
            {
              users.users.${username} = {
                isNormalUser = true;
                extraGroups = [ "wheel" ];
              };
            }
            (mkHomeManager {
              inherit username homeModules;
              homeDirectory = "/home/${username}";
            })
          ]
          ++ modules;
        };

    in
    {
      # work macbook
      darwinConfigurations."IT-JPN-31519" = mkDarwinHost {
        hostname = "IT-JPN-31519";
        username = "arezai";
        modules = [
          ./machines/nix-darwin/IT-JPN-31519.nix
        ];
      };

      # personal macbook
      darwinConfigurations."arif-mac" = mkDarwinHost {
        hostname = "arif-mac";
        username = "arif";
        modules = [
          ./machines/nix-darwin/arif-mac.nix
        ];
      };

      # NixOS (for NixOS based machines)
      nixosConfigurations."asahi-nixos" = mkNixosHost {
        hostname = "asahi-nixos";
        username = "arif";
        modules = [
          ./modules/nixos/cosmic.nix
          ./machines/nixos/asahi-nixos
        ];
        homeModules = [
          ./modules/home-manager/cosmic.nix
          {
            programs.firefox.enable = true;
            programs.chromium.enable = true;
          }
        ];
      };

      # for `nix fmt`
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      # for `nix flake check`
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });
    };
}
