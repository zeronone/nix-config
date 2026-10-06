{
  mylib,
  ...
}:
{
  darwinConfigurations."IT-JPN-31519" = mylib.mkDarwinHost {
    hostname = "IT-JPN-31519";
    username = "arezai";
    tailscaleIpAddr = "TODO";
  };

  darwinConfigurations."ITSO-WX6092" = mylib.mkDarwinHost {
    hostname = "ITSO-WX6092";
    username = "arezai";
    tailscaleIpAddr = "TODO";
  };

  darwinConfigurations."arif-mac" = mylib.mkDarwinHost {
    hostname = "arif-mac";
    username = "arif";
    tailscaleIpAddr = "TODO";
  };

  nixosConfigurations."asahi-nixos" = mylib.mkNixosHost {
    hostname = "asahi-nixos";
    username = "arif";
    tailscaleIpAddr = "100.91.229.87";
  };

  # UGREEN DXP4800 Plus NAS (Immich). See machines/nixos/momiji-homelab/README.md
  nixosConfigurations."momiji-homelab" = mylib.mkNixosHost {
    hostname = "momiji-homelab";
    username = "arif";
    tailscaleIpAddr = "100.88.104.85";
    system = "x86_64-linux";
    headless = true;
  };
}
