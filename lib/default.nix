{
  inputs,
}:
let
  myNixModules = ../modules/nixos;
  myHmModules = ../modules/home-manager;
  myDarwinModules = ../modules/darwin;

  # --- Shared Logic & Helpers ---
  # Global packages available on all systems
  globalPackages =
    pkgs: with pkgs; [
      just
      fastfetch
      ripgrep
      wget
      jq
      lsof
      curl
      direnv
      nix-direnv
      jujutsu
      git
    ];

  # Shared home-manager modules for all hosts
  sharedHomeModules = [
    ../modules/home-manager/shell.nix
    ../modules/home-manager/development
  ];

  # Helper function to configure home-manager
  mkHomeManager =
    {
      username,
      homeDirectory,
      tailscaleIpAddr,
      pkgs-unstable,
      homeModules ? [ ],
    }:
    {
      home-manager.backupFileExtension = "bak";
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = {
        inherit
          pkgs-unstable
          tailscaleIpAddr
          myNixModules
          myHmModules
          myDarwinModules
          ;
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
      tailscaleIpAddr,
      system ? "aarch64-darwin",
    }:
    let
      machineDir = ../machines/darwin/${hostname};
      homeDirectory = "/Users/${username}";
      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.nix-vscode-extensions.overlays.default
        ];
      };
    in
    inputs.nix-darwin.lib.darwinSystem {
      specialArgs = {
        flake-inputs = inputs;
        inherit
          pkgs-unstable
          username
          homeDirectory
          tailscaleIpAddr
          hostname
          myNixModules
          myHmModules
          myDarwinModules
          ;
      };
      modules = [
        (
          { pkgs, ... }:
          {
            nixpkgs = {
              config.allowUnfree = true;
            };

            # Global packages
            environment.systemPackages = (globalPackages pkgs);
          }
        )
        inputs.home-manager.darwinModules.home-manager
        ../modules/common/nix.nix
        ../modules/darwin/bootstrap.nix
        (machineDir + /system.nix)
        {
          system.primaryUser = username;
          users.users.${username}.home = "/Users/${username}";
          networking.hostName = "${hostname}";
        }
        (mkHomeManager {
          inherit
            username
            homeDirectory
            tailscaleIpAddr
            pkgs-unstable
            ;
          homeModules = [ (machineDir + /home.nix) ];
        })
      ];
    };

  # Helper function to create NixOS hosts
  mkNixosHost =
    {
      hostname,
      username,
      tailscaleIpAddr,
      system ? "aarch64-linux",
    }:
    let
      machineDir = ../machines/nixos/${hostname};
      homeDirectory = "/home/${username}";
      pkgs-unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
        overlays = [
          inputs.nix-vscode-extensions.overlays.default
        ];
      };
    in
    inputs.nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        flake-inputs = inputs;
        inherit
          pkgs-unstable
          username
          homeDirectory
          tailscaleIpAddr
          hostname
          myNixModules
          myHmModules
          myDarwinModules
          ;
      };
      modules = [
        {
          nixpkgs.overlays = [
            inputs.dolphin-overlay.overlays.default
          ];
          nixpkgs.config.allowUnfree = true;

          # other common config
          boot.kernel.sysctl = {
            "fs.file-max" = 262144;
          };
        }
        (
          { pkgs, ... }:
          {
            # Global packages
            environment.systemPackages =
              (globalPackages pkgs)
              ++ (with pkgs; [
                wl-clipboard
                coreutils
              ]);
          }
        )
        inputs.home-manager.nixosModules.default
        ../modules/common/nix.nix
        (machineDir + /system.nix)
        (
          { pkgs, ... }:
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
        )
        (mkHomeManager {
          inherit
            username
            homeDirectory
            tailscaleIpAddr
            pkgs-unstable
            ;
          homeModules = [ (machineDir + /home.nix) ];
        })
      ];
    };
in
{
  inherit mkDarwinHost mkNixosHost mkHomeManager;
}
