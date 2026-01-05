{ pkgs, globalPackages, ... }:
{
  imports = [ ../../modules/home-manager/shell.nix ];
  home.username = "arif";
  home.homeDirectory = "/home/arif";
  home.stateVersion = "25.11";

  # Global packages + machine-specific packages
  home.packages =
    (globalPackages pkgs)
    ++ (with pkgs; [
      vlc
      discord
      firefox
    ]);
}
