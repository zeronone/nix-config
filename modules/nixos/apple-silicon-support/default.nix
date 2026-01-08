{ lib, ... }:
{
  imports = [
    ./modules/default.nix
  ];

  ###################
  # Customizations
  ###################

  # Binary cache for apple-silicon kernel
  nix.settings = {
    extra-substituters = [
      "https://nixos-apple-silicon.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
  };

  # Firmware is copied to /etc/nixos/firmware by bootstrap.sh (both on installer and target)
  # Using string-to-path conversion to avoid impure builtins.pathExists
  hardware.asahi.peripheralFirmwareDirectory = /etc/nixos/firmware;
}
