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
    myNixModules.desktop
    myNixModules.tailscale
    myNixModules.ssh
    myNixModules.fhs
  ];

  # Binary cache for apple-silicon kernel
  nix.settings = {
    extra-substituters = [ "https://nixos-apple-silicon.cachix.org" ];
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
  };

  nixpkgs.overlays = [
    (final: prev: {
      libva-v4l2_request-sofus13 = final.callPackage "${flake-inputs.nixos-apple-silicon}/apple-silicon-support/packages/libva-v4l2_request-sofus13" { };
      avd-fw = prev.runCommand "avd-fw" { } "mkdir -p $out/lib/firmware";
    })
  ];

  hardware.asahi = {
    enable = true;
    peripheralFirmwareDirectory = flake-inputs.asahi-firmware;
    avd = {
      enable = true;
      vaapi-support = true;
    };
  };

  # Use the fairydust branch: the asahi-x.y.z release that nixos-apple-silicon
  # ships, plus the DP alt mode hacks that make the left-front USB-C port a
  # DisplayPort output on the 14/16" MacBook Pro (see t600x-j314-j316.dtsi).
  # The old 0001-add-m1-pro-max-ultra-support.patch is no longer needed: t600x
  # atcphy nodes fall back to "apple,t8103-atcphy", and M1 Pro has no dptx-phy.
  # Keep version in sync with the branch's Makefile, and the Asahi config in
  # sync with nixos-apple-silicon's packages/linux-asahi/default.nix.
  boot.kernelPackages = lib.mkForce (
    pkgs.linuxPackagesFor (
      pkgs.buildLinux {
        inherit (pkgs) stdenv lib;
        version = "7.1.13";
        modDirVersion = "7.1.13";
        pname = "linux-fairydust";

        src = pkgs.fetchFromGitHub {
          owner = "AsahiLinux";
          repo = "linux";
          rev = "ce9f2eba72c061a50b2d790450e90af3439d8c24"; # fairydust, 2026-09-08
          hash = "sha256-W3yMSUe6xa+M/X0k86kbCS4g3d7jJmO3WV9L/5rQRhI=";
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
              # Prevents bluetooth stuttering (defaults to 'n')
              BT_BRCMEXT = yes;
              # DP Alt Mode support
              DRM_APPLE = module;
              PHY_APPLE_ATC = module;
              PHY_APPLE_DPTX = module;
              TYPEC_DP_ALTMODE = module;
              TYPEC_TPS6598X = module;
            };
            features.rust = true;
          }
        ];
      }
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

  # Sound (https://github.com/nix-community/nixos-apple-silicon/issues/352)
  hardware.asahi.setupAsahiSound = true;
  services.pipewire.configPackages = lib.mkForce [ ];
  services.pipewire.wireplumber.configPackages = lib.mkForce [ ];
  # Fix Bluetooth audio disconnections on Apple Silicon / Asahi Linux:
  # 1. Disable HFP/HSP headset profiles ("bluez5.roles") so apps (like Chromium input)
  #    requesting mic access don't trigger a profile switch. Switching between A2DP
  #    and HSP/HFP often fails under Broadcom firmware/driver and crashes the transport.
  #    This forces the use of the high-quality internal MacBook microphones instead.
  # 2. Increase idle suspend timeout to 30 seconds to prevent audio dropouts during
  #    momentary pauses or network buffering, while still preserving power in long runs.
  services.pipewire.wireplumber.extraConfig = {
    "10-bluez" = {
      "monitor.bluez.properties" = {
        "bluez5.roles" = [
          "a2dp_sink"
          "a2dp_source"
          "bap_sink"
          "bap_source"
        ];
      };
      "monitor.bluez.rules" = [
        {
          matches = [
            { "node.name" = "~bluez_output.*"; }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 30;
            };
          };
        }
      ];
    };
  };
  environment.systemPackages = [ pkgs.asahi-audio ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 3;
  # should be set to false for asahi
  boot.loader.efi.canTouchEfiVariables = false;

  # Set your time zone.
  time.timeZone = "Asia/Tokyo";

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  system.stateVersion = "25.11";
}
