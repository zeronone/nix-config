{
  description = "Nix config for my machines, copied from all over the internet.";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Flake Utils
    flake-utils.url = "github:numtide/flake-utils";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Nix Darwin (for MacOS machines)
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim/nixos-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apple Silicon support for NixOS
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Private repo for Apple Silicon firmware (non-distributable)
    asahi-firmware = {
      url = "git+ssh://git@github.com/zeronone/asahi-firmware.git?dir=m1pro";
      flake = false;
    };

    # treefmt
    treefmt-nix.url = "github:numtide/treefmt-nix";

    # vscode
    nix-vscode-extensions.url = "github:nix-community/nix-vscode-extensions";

    # niri+noctalia
    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dolphin-overlay.url = "github:rumboon/dolphin-overlay";

    # latest stable release
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      home-manager,
      nix-darwin,
      nixvim,
      nixos-apple-silicon,
      asahi-firmware,
      treefmt-nix,
      nix-vscode-extensions,
      dolphin-overlay,
      ...
    }@inputs:
    let
      # --- Shared Logic & Helpers ---

      # Global packages available on all systems
      globalPackages =
        pkgs: with pkgs; [
          just
          fastfetch
          ripgrep
          wget
          jq
          curl
          direnv
          nix-direnv
        ];

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
          home-manager.extraSpecialArgs = {
            flake-inputs = inputs;
          };
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
        let
          machineDir = ./machines/nix-darwin/${hostname};
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          homeDirectory = "/Users/${username}";
        in
        nix-darwin.lib.darwinSystem {
          specialArgs = {
            flake-inputs = inputs;
            inherit
              pkgs-unstable
              username
              homeDirectory
              hostname
              ;
          };
          modules = [
            {
              # Global packages
              environment.systemPackages = (globalPackages pkgs);
            }
            home-manager.darwinModules.home-manager
            ./modules/common/nix.nix
            ./modules/darwin/bootstrap.nix
            (machineDir + /system.nix)
            {
              system.primaryUser = username;
              users.users.${username}.home = "/Users/${username}";
              networking.hostName = "${hostname}";
            }
            (mkHomeManager {
              inherit username homeDirectory homeModules;
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
        let
          machineDir = ./machines/nixos/${hostname};
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
          };
          nixGlobalPackages = (globalPackages pkgs) ++ (with pkgs; [ wl-clipboard ]);
          homeDirectory = "/home/${username}";
        in
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            flake-inputs = inputs;
            inherit
              pkgs-unstable
              username
              homeDirectory
              hostname
              ;
          };
          modules = [
            {
              nixpkgs.overlays = [
                nix-vscode-extensions.overlays.default
                dolphin-overlay.overlays.default
              ];
              nixpkgs.config.allowUnfree = true;

              # other common config
              boot.kernel.sysctl = {
                "fs.file-max" = 262144;
              };
            }
            {
              # Global packages
              environment.systemPackages = nixGlobalPackages;
            }
            home-manager.nixosModules.default
            ./modules/common/nix.nix
            (machineDir + /system.nix)
            {
              programs.zsh.enable = true;
              users.users.${username} = {
                isNormalUser = true;
                initialPassword = "password";
                extraGroups = [
                  "wheel"
                  "networkmanager"
                ];
                shell = pkgs.zsh;
              };
            }
            (mkHomeManager {
              inherit username homeDirectory homeModules;
            })
          ]
          ++ modules;
        };

    in
    # --- System Specific Outputs (formatter, checks) ---
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        # Eval the treefmt modules from ./treefmt.nix
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        # for `nix fmt`
        formatter = treefmtEval.config.build.wrapper;
        # for `nix flake check`
        checks = {
          formatting = treefmtEval.config.build.check self;
        };
      }
    )
    //
      # --- System Agnostic Outputs (NixOS/Darwin Configurations) ---
      {
        # work macbook
        darwinConfigurations."IT-JPN-31519" = mkDarwinHost {
          hostname = "IT-JPN-31519";
          username = "arezai";
          homeModules = [ ];
          modules = [
            ./modules/darwin/nix-homebrew.nix
            (
              { lib, ... }:
              {
                # Don't delete other brews installed on this machine
                homebrew.onActivation.cleanup = lib.mkForce "none";
                homebrew.brews = [
                  "openssl"
                  "readline"
                  "coreutils"
                  "ed"
                  "findutils"
                  "gnu-indent"
                  "gnu-sed"
                  "gnu-tar"
                  "gettext"
                  "gnu-which"
                  "gnutls"
                  "grep"
                ];
              }
            )
            ./modules/darwin/macbook-us-ansi.nix
            ./modules/darwin/hammerspoon.nix
          ];
        };

        # personal macbook
        darwinConfigurations."arif-mac" = mkDarwinHost {
          hostname = "arif-mac";
          username = "arif";
          modules = [
            ./modules/darwin/nix-homebrew.nix
            ./modules/darwin/macbook-us-ansi.nix
          ];
          homeModules = [ ];
        };

        # NixOS (for NixOS based machines)
        nixosConfigurations."asahi-nixos" = mkNixosHost {
          hostname = "asahi-nixos";
          username = "arif";
          modules = [
            #./modules/nixos/x86_64-emulation.nix
            ./modules/nixos/muvm-fex.nix
            ./modules/nixos/niri.nix
            ./modules/nixos/noctalia.nix
            ./modules/nixos/fonts.nix
            ./modules/nixos/macbook-notch.nix
            ./modules/nixos/macbook-us-ansi.nix
            ./modules/nixos/podman.nix
            ./modules/nixos/rust.nix
            ./modules/nixos/gui-apps.nix
          ];
          homeModules = [
            ./modules/home-manager/apple-us-iso-fcitx5.nix
            ./modules/home-manager/fontconfig.nix
            ./modules/home-manager/node.nix
          ];
        };
      };
}
