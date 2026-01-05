# Work machine
{ ... }:
{
  # Primary user
  system.primaryUser = "arezai";
  users.users.arezai.home = "/Users/arezai";

  # Home manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.arezai = {
    imports = [ ../../modules/home-manager/shell.nix ];
    home.username = "arezai";
    home.homeDirectory = "/Users/arezai";
    home.stateVersion = "25.11";
    # home.packages = with pkgs; [ awscli2 ];
  };

  # System config
  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
  ];
}
