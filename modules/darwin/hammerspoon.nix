{ pkgs, username, ... }:
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
        url = "https://github.com/Hammerspoon/Spoons/raw/cbb1ce1/Spoons/SpoonInstall.spoon.zip";
        hash = "sha256-3f0d4znNuwZPyqKHbZZDlZ3gsuaiobhHPsefGIcpCSE=";
      };
    };

    home.file.".config/hammerspoon/Spoons/ActiveSpace.spoon/init.lua" = {
      source = pkgs.fetchurl {
        url = "https://github.com/mogenson/ActiveSpace.spoon/raw/a246cb5/init.lua";
        hash = "sha256-17lyE3yOn6417SxrbLGlFPMQE5nWtXLw2l73f3riwRA=";
      };
    };

    # This relies on Karabiner to have a mapping for F19
    # https://evantravers.com/articles/2020/06/08/hammerspoon-a-better-better-hyper-key/
    # HammerSpoon intercepts F19+<key>, and if there is no key-binding, it instead emits
    # the typical <hyper>+<key> (⌘⇧⌥⌃+<key>). This is useful for keybindings in other apps
    # that don't support a fake key, such as F19
    home.file.".config/hammerspoon/Spoons/Hyper.spoon" = {
      source = pkgs.fetchzip {
        url = "https://github.com/evantravers/Hyper.spoon/releases/download/2.1.1/Hyper.spoon.zip";
        hash = "sha256-P9qL14iqfgt9B4NtBX/Ii0wwejcrl0f1AowMPYe5Xrk=";
        stripRoot = false;
      };
    };
  };
}
