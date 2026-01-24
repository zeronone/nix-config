{ pkgs, ... }:
{
  # also installed by niri-flake
  # But it is added here to mix and match with other modules
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
    ];
  };
}
