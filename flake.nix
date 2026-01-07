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

    in
    {
      # work macbook
      darwinConfigurations."IT-JPN-31519" = nix-darwin.lib.darwinSystem {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        specialArgs = { inherit inputs globalPackages; };
        modules = [
          # common config
          ./modules/nix-darwin/bootstrap.nix

          # customized config
          ./machines/nix-darwin/IT-JPN-31519.nix
        ];
      };

      # personal macbook
      darwinConfigurations."arif-mac" = nix-darwin.lib.darwinSystem {
        pkgs = import nixpkgs {
          system = "aarch64-darwin";
          config.allowUnfree = true;
        };
        specialArgs = { inherit inputs globalPackages; };
        modules = [
          home-manager.darwinModules.home-manager
          # common config
          ./modules/nix-darwin/bootstrap.nix

          # customized config
          ./machines/nix-darwin/arif-mac.nix
        ];
      };

      # 3. NixOS (for NixOS based machines)
      nixosConfigurations."asahi-nixos" = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = { inherit inputs globalPackages; };
        modules = [
          ./modules/nixos/cosmic.nix

          # customized config
          ./machines/nixos/asahi-nixos
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
