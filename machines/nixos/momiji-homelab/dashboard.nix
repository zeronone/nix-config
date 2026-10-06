# Web UIs for the NAS:
#   Homepage  :8082  front page (live CPU/RAM/temp/disk usage, SMART summary, links)  LAN + tailnet
#   Cockpit   :9090  admin: storage (md/LVM, later ZFS), services, logs, terminal,     LAN + tailnet
#                    files, podman containers. Log in as arif (PAM); sudo for admin.
#   Scrutiny  :8080  SMART history + failure prediction per disk (no auth)            tailnet only
# https://momiji-homelab.<tailnet> (tailscale serve, valid cert) -> Homepage. Immich keeps its own
# node, https://immich.<tailnet> (see immich.nix). Other ports are reachable directly on the tailnet.
# On the LAN: http://momiji-homelab.local:8082 (mDNS) or http://192.168.100.3:8082.
{
  config,
  lib,
  pkgs,
  hostname,
  tailscaleNet,
  ...
}:
let
  tsHost = "${hostname}.${tailscaleNet}";
  lanHosts = [
    "${hostname}.local"
    "192.168.100.3"
  ];
  allHosts = [
    tsHost
    hostname
  ]
  ++ lanHosts;

  homepagePort = config.services.homepage-dashboard.listenPort;
  cockpitPort = config.services.cockpit.port;
  scrutinyPort = config.services.scrutiny.settings.web.listen.port;

  tailscale = lib.getExe config.services.tailscale.package;
in
{
  services.cockpit = {
    enable = true;
    openFirewall = true;
    allowed-origins = map (h: "https://${h}:${toString cockpitPort}") allHosts;
    plugins = with pkgs; [
      cockpit-files
      cockpit-podman
      # with ZFS: cockpit-zfs
    ];
    settings.WebService.LoginTo = false;
  };
  # Cockpit's Storage page talks to udisks
  services.udisks2.enable = true;

  services.scrutiny = {
    enable = true;
    # Not opened on the LAN (no auth); reachable via tailnet and through Homepage's widget
    openFirewall = false;
    settings.web.listen.port = 8080;
    collector = {
      enable = true;
      schedule = "hourly";
    };
  };

  services.homepage-dashboard = {
    enable = true;
    openFirewall = true;
    allowedHosts = builtins.concatStringsSep "," (
      # tsHost without a port: requests arriving through tailscale serve on 443
      [ tsHost ] ++ map (h: "${h}:${toString homepagePort}") (allHosts ++ [ "localhost" ])
    );
    settings = {
      title = hostname;
      theme = "dark";
      color = "slate";
      headerStyle = "clean";
      statusStyle = "dot";
    };
    widgets = [
      {
        resources = {
          label = "System";
          cpu = true;
          memory = true;
          cputemp = true;
          uptime = true;
          units = "metric";
        };
      }
      {
        resources = {
          label = "SSD";
          disk = "/";
        };
      }
      {
        resources = {
          label = "HDD pool";
          disk = "/volume3";
        };
      }
    ];
    services = [
      {
        Media = [
          {
            Immich = {
              href = "https://immich.${tailscaleNet}";
              description = "Photos & videos";
              icon = "immich.svg";
              siteMonitor = "http://127.0.0.1:${toString config.services.immich.port}";
            };
          }
        ];
      }
      {
        System = [
          {
            Cockpit = {
              href = "https://${tsHost}:${toString cockpitPort}";
              description = "Storage, services, logs, terminal";
              icon = "cockpit.svg";
            };
          }
          {
            Scrutiny = {
              href = "http://${tsHost}:${toString scrutinyPort}";
              description = "Disk SMART health";
              icon = "scrutiny.svg";
              widget = {
                type = "scrutiny";
                url = "http://127.0.0.1:${toString scrutinyPort}";
              };
            };
          }
        ];
      }
      # Later: { Home = [ { "Home Assistant" = { href = "http://${tsHost}:8123"; icon = "home-assistant.svg"; }; } ]; }
    ];
  };

  # https://momiji-homelab.<tailnet> -> Homepage. The serve config persists in tailscaled state;
  # this (re)applies it declaratively. No-op until `sudo tailscale up` has been run once.
  systemd.services.homepage-tailscale-serve = {
    description = "Expose Homepage on the tailnet via tailscale serve";
    after = [
      "tailscaled.service"
      "homepage-dashboard.service"
    ];
    wants = [ "tailscaled.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      for _ in $(seq 30); do
        ${tailscale} status >/dev/null 2>&1 && break
        sleep 2
      done
      if ! ${tailscale} status >/dev/null 2>&1; then
        echo "tailscale is not logged in yet; skipping serve setup"
        exit 0
      fi
      ${tailscale} serve --bg --https=443 http://127.0.0.1:${toString homepagePort}
    '';
  };
}
