{ pkgs, username, ... }:
{
  environment.systemPackages = [
    pkgs.arion
    pkgs.docker-client
  ];

  virtualisation = {
    docker.enable = false;
    podman = {
      enable = true;
      dockerCompat = true;
      # allow containers under podman-compose to talk to each other
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  users.users."${username}" = {
    extraGroups = [ "podman" ];
  };
}
