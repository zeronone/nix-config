{
  inputs,
}:
let
  lib = inputs.nixpkgs.lib;
  mapModules =
    dir:
    lib.mapAttrs' (
      name: type:
      let
        baseName = lib.removeSuffix ".nix" name;
      in
      lib.nameValuePair baseName (dir + "/${name}")
    ) (builtins.readDir dir);

  myNixModules = mapModules ../modules/nixos;
  myHmModules = mapModules ../modules/home-manager;
  myDarwinModules = mapModules ../modules/darwin;

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
      jujutsu
      git
      nix-tree
      unzip
      devenv
      gh
      # cachix
    ];

  # Shared home-manager modules for all hosts
  sharedHomeModules = [
    ../modules/home-manager/shell.nix
    ../modules/home-manager/development
  ];

  tailscaleNet = "curl-featherback.ts.net";

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
          tailscaleNet
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
          inputs.claude-code-nix.overlays.default
          inputs.antigravity-nix.overlays.default
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
          tailscaleNet
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
              overlays = [
                inputs.claude-code-nix.overlays.default
                inputs.antigravity-nix.overlays.default
              ];
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
          inputs.claude-code-nix.overlays.default
          inputs.antigravity-nix.overlays.default
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
          tailscaleNet
          hostname
          myNixModules
          myHmModules
          myDarwinModules
          ;
      };
      modules = [
        {
          nixpkgs = {
            config.allowUnfree = true;
            overlays = [
              # TODO: Revert to `inputs.dolphin-overlay.overlays.default` once upstream dolphin-overlay supports Plasma 6/NixOS 26.05
              (final: prev: {
                kdePackages = prev.kdePackages.overrideScope (
                  kfinal: kprev: {
                    dolphin = prev.symlinkJoin {
                      name = "dolphin-wrapped";
                      paths = [ kprev.dolphin ];
                      nativeBuildInputs = [ prev.makeWrapper ];
                      postBuild = ''
                        rm $out/bin/dolphin
                        makeWrapper ${kprev.dolphin}/bin/dolphin $out/bin/dolphin \
                          --set XDG_CONFIG_DIRS "${prev.kdePackages.plasma-workspace}/etc/xdg:$XDG_CONFIG_DIRS" \
                          --set XDG_MENU_PREFIX "plasma-" \
                          --run "${kprev.kservice}/bin/kbuildsycoca6 --noincremental"
                      '';
                    };
                  }
                );
              })
              inputs.claude-code-nix.overlays.default
              inputs.antigravity-nix.overlays.default
            ];
          };

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
              linger = true;
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
