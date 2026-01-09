{ pkgs, ... }:
{
  # https://wiki.nixos.org/wiki/Fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      waylandFrontend = true;
      addons = with pkgs; [
        fcitx5-mozc
        qt6Packages.fcitx5-configtool
      ];
    };
  };
}
