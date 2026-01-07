{
  pkgs,
  home-manager,
  ...
}:
{
  imports = [
    home-manager.nixosModules.default
  ];

  # backup before overwritting config files
  home-manager.backupFileExtension = "bak";

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
      {
        # common programs
        programs.firefox.enable = true;
        programs.chromium.enable = true;
      }

      ../../../modules/home-manager/shell.nix
      ../../../modules/home-manager/cosmic.nix
    ];
    home.username = "arif";
    home.homeDirectory = "/home/arif";
    home.stateVersion = "25.11";
    # home.packages = with pkgs; [ awscli2 ];
  };
}
