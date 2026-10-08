# AdGuard Home: network-wide DNS ad blocking for the LAN and the tailnet.
#   DNS  :53    point the router's DHCP DNS (LAN) and the tailnet's global nameserver at this box
#   UI   :3000  login arif / adguard-password (sops; also used by the Homepage widget)
# UI changes persist (mutableSettings); the settings below are re-applied on every start.
{
  config,
  lib,
  pkgs,
  lan,
  ...
}:
{
  services.adguardhome = {
    enable = true;
    host = "0.0.0.0";
    port = 3000;
    openFirewall = true;
    settings = {
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.quad9.net/dns-query"
          # Local names (`ip host` entries on the router); the router never forwards them back
          "[/home.lan/]${lan.gateway}"
        ];
        # Used only when all upstreams fail
        fallback_dns = [ "https://dns.google/dns-query" ];
        # Reverse lookups for LAN addresses go to the router, so the query log shows names
        use_private_ptr_resolvers = true;
        local_ptr_upstreams = [ lan.gateway ];
        # Plain DNS, only to resolve the DoH hostnames above
        bootstrap_dns = [
          "1.1.1.1"
          "9.9.9.9"
          "8.8.8.8"
        ];
      };
      filters = [
        {
          enabled = true;
          id = 1;
          name = "AdGuard DNS filter";
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
        }
      ];
    };
  };

  # The UI login: inject the user after the module's preStart has written AdGuardHome.yaml.
  # AdGuard wants a bcrypt hash; it's derived from the plain password on every start, so the
  # Homepage widget (which needs the plain one) and the login can't drift apart.
  # The service has a DynamicUser, so the root-only secret comes in as a systemd credential.
  sops.secrets.adguard-password.restartUnits = [ "adguardhome.service" ];
  systemd.services.adguardhome = {
    serviceConfig.LoadCredential = [
      "password:${config.sops.secrets.adguard-password.path}"
    ];
    # Not `yq -i`: it chowns the file, which the unit's syscall filter kills
    preStart = lib.mkAfter ''
      config="$STATE_DIRECTORY/AdGuardHome.yaml"
      # Separate assignment so a failing mkpasswd stops the start (set -e)
      hash=$(${lib.getExe pkgs.mkpasswd} -m bcrypt -R 12 -s < "$CREDENTIALS_DIRECTORY/password")
      export hash
      ${lib.getExe pkgs.yq-go} '.users = [{"name": "arif", "password": strenv(hash)}]' \
        "$config" > "$config.tmp"
      mv "$config.tmp" "$config"
    '';
  };

  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };

  # Podman's container DNS (aardvark-dns) listens on 10.88.0.1:53, which would block AdGuard's
  # wildcard bind. Move it; podman redirects the containers' port-53 queries there itself.
  virtualisation.containers.containersConf.settings.network.dns_bind_port = 1153;
  # The podman module only opens 53 on the bridge; without this, container DNS times out
  networking.firewall.interfaces.podman0.allowedUDPPorts = [ 1153 ];
}
