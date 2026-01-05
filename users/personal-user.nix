{ pkgs, ... }: {
  imports = [ ../modules/home/shell.nix ];
  home.username = "arif";
  home.homeDirectory = "/home/arif";
  # Do not change
  home.stateVersion = "24.11";

  home.packages = [ pkgs.vlc pkgs.discord pkgs.firefox ];
}
