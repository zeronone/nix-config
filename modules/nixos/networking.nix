{ hostname, ... }:
{
  networking.hostName = "${hostname}";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };
}
