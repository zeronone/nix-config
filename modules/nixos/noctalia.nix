{
  pkgs,
  flake-inputs,
  username,
  ...
}:
{
  # Pre-requisites
  networking.networkmanager.enable = true;
  services.power-profiles-daemon.enable = true;
  services.upower.enable = true;

  environment.systemPackages = [
    flake-inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  users.users."${username}" = {
    extraGroups = [ "bluetooth" ];
  };

  home-manager.users.${username} =
    { flake-inputs, ... }:
    {
      imports = [
        flake-inputs.noctalia.homeModules.default
      ];

      programs.noctalia = {
        enable = true;
        settings = {
          wallpaper = {
            enabled = false;
          };
          bar = {
            main = {
              position = "top";
              capsule = true;
              margin_edge = 8;
              start = [
                "workspaces"
                "launcher"
                "sysmon"
                "active-window"
                "media"
              ];
              center = [ ];
              end = [
                "network"
                "bluetooth"
                "volume"
                "brightness"
                "battery"
                "clock"
                "notifications"
                "control-center"
              ];
            };
          };
          widget = {
            clock = {
              format = "{:%H:%M}";
            };
          };
        };
      };
    };
}
