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

  # Firmware is copied in bootstrap.sh
  # Need to pass --impure to nixos-install
  hardware.asahi.peripheralFirmwareDirectory =
    lib.findFirst (path: builtins.pathExists (path + "/all_firmware.tar.gz")) null
      [
        # path when the system is operating normally
        /etc/nixos/firmware
        # path when the system is mounted in the installer
        /mnt/etc/nixos/firmware
      ];
}
