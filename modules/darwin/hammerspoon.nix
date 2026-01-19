{ pkgs, ... }:
{
  # System Settings
  system.defaults = {
    CustomUserPreferences = {
      "org.hammerspoon.Hammerspoon" = {
        MJConfigFile = "~/.config/hammerspoon/init.lua";
      };
    };
  };

  homebrew.casks = [ "hammerspoon" ];
}
