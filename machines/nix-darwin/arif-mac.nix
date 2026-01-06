# Work machine
{ ... }:
{
  # Primary user
  system.primaryUser = "arif";
  users.users.arif.home = /Users/arif;

  # Home manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.arif = {
    imports = [ ../../modules/home-manager/shell.nix ];
    home.username = "arif";
    home.homeDirectory = /Users/arif;
    home.stateVersion = "25.11";
    # home.packages = with pkgs; [ awscli2 ];
  };

  # System config
  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
  ];
}
