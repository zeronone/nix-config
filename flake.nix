{
  description = "Multi-machine Dotfiles";

  inputs = {
    # Package sets
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs: {
    # 1. WORK MACBOOK (nix-darwin + home-manager)
    darwinConfigurations."work-mac" = nix-darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      modules = [
        ./hosts/work-mac/configuration.nix
        home-manager.darwinModules.home-manager {
          # Using Determinate Systems nix insallation, which conflicts with nix-darwin
          nix.enable = false;

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.arezai = {
            imports = [ ./users/work-user.nix ];
          };
        }
      ];
    };

    # 2. PERSONAL FEDORA (Home Manager Standalone)
    homeConfigurations."personal-fedora" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [ ./users/personal-user.nix ];
    };
  };
}
