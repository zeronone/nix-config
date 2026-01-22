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
          wallpaper = {
            enabled = false;
          };
          bar = {
            density = "compact";
            position = "top";
            showOutline = false;
            showCapsule = true;
            widgets = {
              left = [
                {
                  hideUnoccupied = false;
                  id = "Workspace";
                  labelMode = "none";
                }
                {
                  id = "Launcher";
                }
                {
                  id = "ControlCenter";
                }
                {
                  id = "SystemMonitor";
                }
                {
                  id = "ActiveWindow";
                }
                {
                  id = "MediaMini";
                }
              ];
              center = [ ];
              right = [
                {
                  id = "Network";
                }
                {
                  id = "Bluetooth";
                }
                {
                  id = "Volume";
                }
                {
                  id = "Brightness";
                }
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
                  id = "NotificationHistory";
                }
              ];
            };
          };
        };
      };
    };
}
