{
  pkgs,
  home-manager,
  ...
}:
{
  imports = [
    home-manager.nixosModules.default
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  # Users
  users.users.arif = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  # home-manager
  home-manager.users.arif = {
    imports = [
      ../../../modules/home-manager/shell.nix
      {
        # common programs
        programs.firefox.enable = true;
        programs.chromium.enable = true;
      }
    ];
    home.username = "arif";
    home.homeDirectory = "/home/arif";
    home.stateVersion = "25.11";
    # home.packages = with pkgs; [ awscli2 ];
  };
}
