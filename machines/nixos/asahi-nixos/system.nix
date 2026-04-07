# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  flake-inputs,
  myNixModules,
  ...
}:
{
  imports = [
    # Apple Silicon support from flake input
    flake-inputs.nixos-apple-silicon.nixosModules.apple-silicon-support
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    myNixModules.networking
    # myNixModules.x86_64-emulation
    # myNixModules.muvm-fex
    myNixModules.niri
    myNixModules.noctalia
    myNixModules.fonts
    myNixModules.macbook-notch
    myNixModules.macbook-us-ansi
    myNixModules.podman
    myNixModules.rust
    myNixModules.gui-apps
    myNixModules.tailscale
  ];

  # Binary cache for apple-silicon kernel
  nix.settings = {
    extra-substituters = [ "https://nixos-apple-silicon.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
  };

  hardware.asahi = {
    enable = true;
    # Firmware from private git repo (see scripts/push-asahi-firmware.sh)
    peripheralFirmwareDirectory = flake-inputs.asahi-firmware;
  };

  # Activation script to ensure the boot binary is at the path expected by this Mac
  # NixOS defaults to /boot/asahi/boot.bin, but this machine uses /boot/m1n1/boot.bin
  system.activationScripts.sync-m1n1 = {
    text = ''
      if [ -f /boot/asahi/boot.bin ]; then
        mkdir -p /boot/m1n1
        cp /boot/asahi/boot.bin /boot/m1n1/boot.bin
      fi
    '';
    deps = [ ];
  };

  # Use the patched fairydust kernel as default
  boot.kernelPackages = lib.mkForce (
    pkgs.linuxPackagesFor (
      (pkgs.buildLinux {
        inherit (pkgs) stdenv lib;
        version = "6.19.11";
        modDirVersion = "6.19.11";
        pname = "linux-fairydust";

        src = pkgs.fetchFromGitHub {
          owner = "AsahiLinux";
          repo = "linux";
          rev = "4e84610e5722c34e48fef3f33f7bd8faedb13348";
          hash = "sha256-G32SzJW1paAUaBCnw5cou20WwpuVR8OZSDRpV58IUJU=";
        };

        kernelPatches = [
          {
            name = "Asahi config";
            patch = null;
            structuredExtraConfig = with lib.kernel; {
              # Apple Silicon Specifics
              ARM64_16K_PAGES = yes;
              ARM64_MEMORY_MODEL_CONTROL = yes;
              ARM64_ACTLR_STATE = yes;
              APPLE_WATCHDOG = yes;
              APPLE_M1_CPU_PMU = yes;
              HID_APPLE = module;
              APPLE_PMGR_MISC = yes;
              APPLE_PMGR_PWRSTATE = yes;
              # DP Alt Mode support
              DRM_APPLE = module;
              PHY_APPLE_ATC = module;
              PHY_APPLE_DPTX = module;
              TYPEC_DP_ALTMODE = module;
              TYPEC_TPS6598X = module;
            };
            features.rust = true;
          }
          {
            name = "M1 Pro/Max/Ultra DP support";
            patch = ./0001-add-m1-pro-max-ultra-support.patch;
          }
        ];
      })
    )
  );

  # Bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  # should be set to false for asahi
  boot.loader.efi.canTouchEfiVariables = false;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?
}
