{
  config,
  lib,
  tailscaleIpAddr,
  ...
}:
{
  programs.keepassxc = {
    enable = true;
    autostart = lib.mkIf config.xdg.autostart.enable true;
    # problematic
    # settings = {
    #   Browser = {
    #     Enabled = true;
    #   };

    #   # https://wiki.nixos.org/wiki/Secret_Service
    #   FdoSecrets.Enabled = true;

    #   GUI = {
    #     AdvancedSettings = true;
    #     CompactMode = true;
    #     HidePasswords = true;
    #   };
    # };
  };

  # Enable creation of XDG autostart entries.
  xdg.autostart.enable = true;
}
