{ pkgs, username, ... }:
let
  hammerSpoonRepoCommit = "cbb1ce1";
in
{
  # System Settings
  system.defaults = {
    CustomUserPreferences = {
      "org.hammerspoon.Hammerspoon" = {
        MJConfigFile = "~/.config/hammerspoon/init.lua";
      };
    };
  };

  # some default settings needed by the spoons below
  system.defaults.dock.mru-spaces = false;
  system.defaults.spaces.spans-displays = false;

  homebrew.casks = [ "hammerspoon" ];
  home-manager.users.${username} = {
    # ensure directory exists
    home.file.".config/hammerspoon/Spoons/.keep".text = "";
    home.file.".config/hammerspoon/init.lua".source = ../../config/hammerspoon/init.lua;

    home.file.".config/hammerspoon/Spoons/SpoonInstall.spoon" = {
      source = pkgs.fetchzip {
        url = "https://github.com/Hammerspoon/Spoons/raw/${hammerSpoonRepoCommit}/Spoons/SpoonInstall.spoon.zip";
        hash = "sha256-3f0d4znNuwZPyqKHbZZDlZ3gsuaiobhHPsefGIcpCSE=";
      };
    };

    home.file.".config/hammerspoon/Spoons/MouseFollowsFocus.spoon" = {
      source = pkgs.fetchzip {
        url = " https://github.com/Hammerspoon/Spoons/raw/${hammerSpoonRepoCommit}/Spoons/MouseFollowsFocus.spoon.zip";
        hash = "sha256-TI3LxurbBohvR9xI+HvrorGZl5QyPB1+uSX0uMC2RiQ=";
      };
    };

    home.file.".config/hammerspoon/Spoons/ActiveSpace.spoon/init.lua" = {
      source = pkgs.fetchurl {
        url = "https://github.com/mogenson/ActiveSpace.spoon/raw/a246cb5/init.lua";
        hash = "sha256-17lyE3yOn6417SxrbLGlFPMQE5nWtXLw2l73f3riwRA=";
      };
    };
  };
}
