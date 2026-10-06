# UGREEN DXP4800 Plus class NAS (Pentium Gold 8505, 8G RAM). A NanoKVM is attached via USB/HDMI
# for console/BIOS access.
#   - 256G KIOXIA NVMe : NixOS                          -> ./disko.nix
#   - 128G Phison NVMe : UGOS (unused; BIOS Boot Override)
#   - 2x 4T HDD RAID1  : data incl. Immich library      -> ./storage.nix
{
  pkgs,
  flake-inputs,
  myNixModules,
  username,
  hostname,
  ...
}:
{
  imports = [
    flake-inputs.disko.nixosModules.disko
    ./disko.nix
    ./hardware-configuration.nix
    ./storage.nix
    ./immich.nix
    ./dashboard.nix
    myNixModules.tailscale
    myNixModules.ssh-lan
    myNixModules.podman
    myNixModules.disk-health
    myNixModules.intel-gpu
    myNixModules.mdns
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;

  hardware.enableRedistributableFirmware = true;

  networking.hostName = hostname;
  # Required by ZFS (planned)
  networking.hostId = "b60f83bd";

  # Static 192.168.100.3 on the 10GbE port (AQC113, atlantic), matched by MAC so interface
  # renames don't matter. The 2.5GbE port (I226-V, igc) falls back to DHCP if ever cabled.
  # Gateway/DNS = router. Keep .3 outside the router's DHCP pool (or reserved).
  networking.networkmanager = {
    enable = true;
    # No auto-created "Wired connection N" DHCP profiles; only the ones below
    settings.main.no-auto-default = "*";
    ensureProfiles.profiles = {
      lan-10g = {
        connection = {
          id = "lan-10g";
          type = "ethernet";
          autoconnect-priority = 10;
        };
        ethernet.mac-address = "6c:1f:f7:a5:6b:c8";
        ipv4 = {
          method = "manual";
          address1 = "192.168.100.3/24,192.168.100.1";
          dns = "192.168.100.1;";
        };
        ipv6.method = "auto";
      };
      lan-2g5 = {
        connection = {
          id = "lan-2g5";
          type = "ethernet";
        };
        ethernet.mac-address = "6c:1f:f7:a5:6b:c9";
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };

  users.users.${username}.openssh.authorizedKeys.keys = [
    # ~/.ssh/id_github.pub
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM50iMhN9wacVqvVuT0UvP/KLRsHtQBbmHga6zpvGgZ+ arif.matsuda@gmail.com"
  ];

  zramSwap.enable = true;

  environment.systemPackages = with pkgs; [
    mdadm
    lvm2
    pciutils
    usbutils
    btop
  ];

  time.timeZone = "Asia/Tokyo";

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  system.stateVersion = "26.05";
}
