{
  inputs,
  pkgs,
  username,
  lib,
  ...
}:
{
  programs.niri = {
    enable = true;
  };
  programs.yazi = {
    enable = true;
    plugins = {
      starship = pkgs.yaziPlugins.starship;
      wl-clipboard = pkgs.yaziPlugins.wl-clipboard;
      git = pkgs.yaziPlugins.git;
      chmod = pkgs.yaziPlugins.chmod;
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    xwayland-satellite
    tokyonight-gtk-theme
    swaylock
    swayidle
    swaybg
    mako
    wlr-randr
    swayimg
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri";
        user = "greeter";
      };
    };
  };

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [ ../home-manager/fuzzel.nix ];

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
    };
}
