{
  inputs,
  pkgs,
  username,
  lib,
  ...
}:
{
  imports = [
    inputs.niri.nixosModules.niri
  ];
  # It is recommended to use this overlay over directly accessing the outputs.
  # This is because the overlay ensures that the dependencies match your system's nixpkgs version,
  # which is most important for mesa. If mesa doesn't match, niri will be unable to run in a TTY.
  nixpkgs.overlays = [ inputs.niri.overlays.niri ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-stable;
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

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        ../../modules/home-manager/fuzzel.nix
      ];

      # we configure our own config manually
      programs.niri.config = null;
      xdg.configFile = {
        "niri/config.kdl".source = ../../config/niri/config.kdl;
      };
    };
}
