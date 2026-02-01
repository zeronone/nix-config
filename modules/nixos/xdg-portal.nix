{ pkgs, ... }:
{
  # also installed by niri-flake
  # But it is added here to mix and match with other modules
  xdg.portal = {
    enable = true;
    # xdg-open should use portal
    xdgOpenUsePortal = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
      # needed for screencasting by niri
      xdg-desktop-portal-gnome
    ];
    # Set default portal common interfaces
    config.common = {
      # Use GNOME for screencasting (Essential for Niri)
      "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
      "org.freedesktop.impl.portal.RemoteDesktop" = [ "gnome" ];

      # Use GTK for file choosing
      "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];

      default = [ "gtk" ];
    };
  };

  environment.variables = {
    # Forces Electron apps to use the XDG Portal file picker
    GTK_USE_PORTAL = "1";
  };
}
