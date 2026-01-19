{
  pkgs,
  inputs,
  username,
  ...
}:
{
  networking.networkmanager.enable = true;
  hardware.bluetooth.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  environment.systemPackages = with pkgs; [
    inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      programs.noctalia-shell = {
        enable = true;
        settings = {
          bar = {
            density = "compact";
            position = "top";
            showCapsule = false;
            widgets = {
              left = [
                {
                  id = "ControlCenter";
                  useDistroLogo = true;
                }
                {
                  id = "Network";
                }
                {
                  id = "Bluetooth";
                }
              ];
              right = [
                {
                  alwaysShowPercentage = false;
                  id = "Battery";
                  warningThreshold = 30;
                }
                {
                  formatHorizontal = "HH:mm";
                  formatVertical = "HH mm";
                  id = "Clock";
                  useMonospacedFont = true;
                  usePrimaryColor = true;
                }
                {
                  hideUnoccupied = false;
                  id = "Workspace";
                  labelMode = "none";
                }
              ];
            };
          };
        };
      };
    };
}
