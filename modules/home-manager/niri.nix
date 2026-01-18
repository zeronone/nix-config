{
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./fuzzel.nix ];

  gtk = {
    enable = true;

    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };

    iconTheme = {
      name = "Adawaita";
      package = pkgs.adwaita-icon-theme;
    };
  };

  xdg.configFile = {
    "niri/config.kdl".source = ../../config/niri/config.kdl;
  };
}
