{ pkgs, ... }: {
  imports = [ ../modules/home/shell.nix ];
  home.username = "arezai";
  home.homeDirectory = "/Users/arezai";
  # Do not change
  home.stateVersion = "24.11";

  # home.packages = [ pkgs.awscli2 ];
}
