{ ... }:
{
  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  networking.wireless.iwd = {
    enable = true;
    settings.General.EnableNetworkConfiguration = true;
  };
}
