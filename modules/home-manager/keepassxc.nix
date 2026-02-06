{ config, lib, ... }:
{
  programs.keepassxc = {
    enable = true;
    settings = {
      Browser.Enabled = true;
      autostart = lib.mkIf config.xdg.autostart.enable true;

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
}
