{
  pkgs,
  pkgs-unstable,
  username,
  homeDirectory,
  ...
}:
{
  # JP IME on mac
  homebrew.casks = [
    # Karabiner Driver is necessary on Mac for Kanata to run
    "karabiner-elements"
  ];

  home-manager.users.${username} =
    { pkgs, ... }:
    {
      home.file.".config/karabiner/karabiner.json".source = ../../config/karabiner/karabiner.json;
    };

  # Kanata didn't work well
  # Need to permit it in "Accessibility", and daemon needs "Full Disk Access"

  # homebrew.brews = [
  #   "kanata"
  # ];

  # Install Kanata
  # environment.systemPackages = [ pkgs-unstable.kanata ];

  # # Doing it in home-manager didn't work, how to do it user-specific
  # launchd = {
  #   daemons = {
  #     kanata = {
  #       command = "${pkgs-unstable.kanata}/bin/kanata -c ${homeDirectory}/.config/kanata/osx-kanata.kbd";
  #       serviceConfig = {
  #         KeepAlive = true;
  #         RunAtLoad = true;
  #         StandardOutPath = "/tmp/kanata.out.log";
  #         StandardErrorPath = "/tmp/kanata.err.log";
  #       };
  #     };
  #   };
  # };

  # Confiure kanata daemon
  # home-manager.users.${username} =
  #   { pkgs, config, ... }:
  #   {
  #     # Kanata Configuration
  #     home.file.".config/kanata/osx-kanata.kbd".source = ../../config/kanata/osx-kanata.kbd;
  #   };
}
