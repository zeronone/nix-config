{
  flake-inputs,
  pkgs,
  username,
  lib,
  ...
}:
{
  imports = [
    flake-inputs.niri.nixosModules.niri
    # Although already installed by niri-flake
    # Added here for completion
    ./xdg-portal.nix
  ];
  # It is recommended to use this overlay over directly accessing the outputs.
  # This is because the overlay ensures that the dependencies match your system's nixpkgs version,
  # which is most important for mesa. If mesa doesn't match, niri will be unable to run in a TTY.
  # 2026-01: Not using it, as we use niri directly for nixos-stable, instead of niri-stable
  # nixpkgs.overlays = [ flake-inputs.niri.overlays.niri ];

  programs.niri = {
    enable = true;
    package = pkgs.niri;
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

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.systemPackages = with pkgs; [
    swaybg
    mako

    # Dolphin
    kdePackages.qtsvg
    kdePackages.dolphin
  ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      # we configure our own config manually
      programs.niri.config = null;
      home.file."wallpaper.png" = {
        source = ../../nix-dark.png;
        force = true;
      };
      xdg.configFile = {
        "niri/config.kdl".source = ../../config/niri/config.kdl;
      };
    };
}
