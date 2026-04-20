{ myHmModules, username, ... }:
{
  imports = [
    myHmModules.apple-us-iso-fcitx5
    myHmModules.fontconfig
    myHmModules.node
    myHmModules.keepassxc
  ];

  systemd.user.services.midori-harness = {
    Unit = {
      Description = "Midori Harness - midori-labs";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
    Service = {
      WorkingDirectory = "/home/arif/midori-labs";
      ExecStart = "/home/arif/.local/bin/midori-harness run";
      Restart = "always";
      RestartSec = "3";
    };
  };
}
