{
  inputs,
  mylib,
  ...
}:
{
  darwinConfigurations."IT-JPN-31519" = mylib.mkDarwinHost {
    hostname = "IT-JPN-31519";
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
}
