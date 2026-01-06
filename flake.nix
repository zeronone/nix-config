{
  description = "Nix config for my machines, copied from all over the internet.";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS profiles to optimize settings for different hardware
    # No support for: MacBookPro18,2 yet
    # hardware.url = "github:nixos/nixos-hardware";

    # Declarative kde plasma manager (plasma 6)
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Nix Darwin (for MacOS machines)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin";
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
      nix-darwin,
      home-manager,
      plasma-manager,
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
          vim
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
        specialArgs = { inherit home-manager globalPackages; };
        modules = [
          home-manager.darwinModules.home-manager
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
        specialArgs = { inherit home-manager globalPackages; };
        modules = [
          home-manager.darwinModules.home-manager
          # common config
          ./modules/nix-darwin/bootstrap.nix

          # customized config
          ./machines/nix-darwin/arif-mac.nix
        ];
      };

      # 2. asahi-fedora (Linux machines managed by Home Manager Standalone)
      homeConfigurations."asahi-fedora" = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "aarch64-linux";
          config.allowUnfree = true;
        };
        extraSpecialArgs = {
          inherit globalPackages;
          inherit inputs;
        };
        modules = [
          plasma-manager.homeModules.plasma-manager
          # customized config
          ./machines/home-manager/asahi-fedora.nix
        ];
      };

      # 3. NixOS (for NixOS based machines)
      # nixosConfigurations."asahi-nixos" = nixpkgs.lib.nixosSystem {
      #   system = "aarch64-linux";
      #   modules = [
      #     ./machines/nixos/asahi-nixos.nix
      #   ];
      # };

      # for `nix fmt`
      formatter = eachSystem (pkgs: treefmtEval.${pkgs.system}.config.build.wrapper);
      # for `nix flake check`
      checks = eachSystem (pkgs: {
        formatting = treefmtEval.${pkgs.system}.config.build.check self;
      });
    };
}
