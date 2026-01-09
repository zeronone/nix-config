{ ... }:
{
  # https://wiki.nixos.org/wiki/Fcitx5
  i18n.inputMethod.fcitx5.settings.inputMethod = {
    GroupOrder."0" = "Default";
    "Groups/0" = {
      Name = "Default";
      "Default Layout" = "us-mac-iso";
      DefaultIM = "mozc";
    };
    "Groups/0/Items/0".Name = "keyboard-us-mac-iso";
    "Groups/0/Items/0".Layout = "";
    "Groups/0/Items/1".Name = "mozc";
    "Groups/0/Items/1".Layout = "us-mac-iso";
  };
}
