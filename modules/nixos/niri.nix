{
  inputs,
  pkgs,
  username,
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
    mako # notification daemon
    wlr-randr # utility to manage the outputs of a wayland compositor
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
}
