{ config, lib, ... }:
{
  programs.keepassxc = {
    enable = true;
    autostart = lib.mkIf config.xdg.autostart.enable true;
    settings = {
      Browser.Enabled = true;

      # https://wiki.nixos.org/wiki/Secret_Service
      FdoSecrets.Enabled = true;

      GUI = {
        AdvancedSettings = true;
        CompactMode = true;
        HidePasswords = true;
      };
    };
  };

  # Sync directory at ~/Sync
  # Access UI at: http://127.0.0.1:8384/
  services.syncthing = {
    enable = true;
  };

  # Enable creation of XDG autostart entries.
  xdg.autostart.enable = true;
}
