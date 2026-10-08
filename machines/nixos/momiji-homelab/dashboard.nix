# Web UIs for the NAS (plain HTTP; only reachable on the LAN and the tailnet):
#   Homepage  :80    front page (live CPU/RAM/temp/disk usage, SMART summary, links)  LAN + tailnet
#                    Caddy with basic auth in front of :8082: arif / homepage-password-hash
#                    (sops, bcrypt from `nix run nixpkgs#caddy -- hash-password`).
#   Cockpit   :9090  admin: storage (md/LVM, later ZFS), services, logs, terminal,     LAN + tailnet
#                    files, podman containers. Log in as arif (PAM); sudo for admin.
#   Scrutiny  :8080  SMART history + failure prediction per disk (no auth)            LAN + tailnet
#   AdGuard   :3000  DNS ad blocking (adguard.nix)                                     LAN + tailnet
# Homepage: http://192.168.100.3, http://momiji-homelab.home.lan, http://momiji-homelab.local (mDNS), http://<tailnet IP or name>,
# and https://momiji-homelab.<tailnet> (tailscale serve, valid cert). Immich keeps its own node,
# https://immich.<tailnet> (see immich.nix), so does ntfy (ntfy.nix). Other ports are reachable directly on the tailnet.
{
  config,
  lib,
  pkgs,
  hostname,
  tailscaleNet,
  tailscaleIpAddr,
  lan,
  ...
}:
let
  tsHost = "${hostname}.${tailscaleNet}";
  allHosts = [
    tsHost
    hostname
    tailscaleIpAddr
    "${hostname}.local"
    "${hostname}.${lan.domain}"
    lan.address
  ];

  homepagePort = config.services.homepage-dashboard.listenPort;
  cockpitPort = config.services.cockpit.port;
  scrutinyPort = config.services.scrutiny.settings.web.listen.port;
  adguardPort = config.services.adguardhome.port;

  tailscale = lib.getExe config.services.tailscale.package;
in
{
  services.cockpit = {
    enable = true;
    openFirewall = true;
    allowed-origins = map (h: "http://${h}:${toString cockpitPort}") allHosts;
    plugins = with pkgs; [
      cockpit-files
      cockpit-podman
      # with ZFS: cockpit-zfs
    ];
    settings.WebService = {
      LoginTo = false;
      # Serve plain HTTP instead of redirecting to the self-signed HTTPS
      AllowUnencrypted = true;
    };
  };
  # cockpit-ws reads cockpit.conf only at start; restart it on deploys that change it (e.g. Origins)
  systemd.services.cockpit.restartTriggers = [ config.environment.etc."cockpit/cockpit.conf".source ];
  systemd.services.cockpit-wsinstance-http.restartTriggers = [
    config.environment.etc."cockpit/cockpit.conf".source
  ];
  # Cockpit's Storage page talks to udisks
  services.udisks2.enable = true;

  services.scrutiny = {
    enable = true;
    # No auth, but read-only SMART data; fine on the home LAN
    openFirewall = true;
    settings.web.listen.port = 8080;
    collector = {
      enable = true;
      schedule = "hourly";
    };
  };

  # The login in front of Homepage, which has no auth of its own
  sops.secrets.homepage-password-hash = { };
  sops.templates."caddy.env" = {
    # Single quotes: systemd must not touch the $s in the bcrypt hash
    content = "HOMEPAGE_PASSWORD_HASH='${config.sops.placeholder.homepage-password-hash}'";
    restartUnits = [ "caddy.service" ];
  };
  services.caddy = {
    enable = true;
    globalConfig = "auto_https off";
    environmentFile = config.sops.templates."caddy.env".path;
    virtualHosts.":80".extraConfig = ''
      basic_auth {
        arif {$HOMEPAGE_PASSWORD_HASH}
      }
      reverse_proxy 127.0.0.1:${toString homepagePort}
    '';
  };
  networking.firewall.allowedTCPPorts = [ 80 ];

  # AdGuard API password for the widget (the secret is declared in adguard.nix)
  sops.templates."homepage.env" = {
    content = "HOMEPAGE_VAR_ADGUARD_PASSWORD='${config.sops.placeholder.adguard-password}'";
    restartUnits = [ "homepage-dashboard.service" ];
  };

  services.homepage-dashboard = {
    enable = true;
    # Only reachable through Caddy
    listenPort = 8082;
    openFirewall = false;
    environmentFiles = [ config.sops.templates."homepage.env".path ];
    # Caddy passes the Host header through: no port, as clients use :80 (or tailscale serve's 443)
    allowedHosts = builtins.concatStringsSep "," (
      allHosts
      ++ [
        "localhost"
        "127.0.0.1"
      ]
    );
    # Links point at tailnet names. When the page is opened by any other address (e.g. the LAN IP
    # from a machine without Tailscale), rewrite them to that address so they keep working.
    customJS = ''
      (() => {
        const here = location.hostname;
        if (here === "${tsHost}") return;
        // tailnet host in a link -> port on this machine ("" keeps the link's port)
        const ports = ${
          builtins.toJSON {
            ${tsHost} = "";
            "immich.${tailscaleNet}" = toString config.services.immich.port;
            "ntfy.${tailscaleNet}" = toString config.tailscaleNodes.ntfy;
          }
        };
        const rewrite = () => {
          for (const a of document.querySelectorAll("a[href]")) {
            const url = new URL(a.href, location.href);
            if (!(url.hostname in ports)) continue;
            const port = ports[url.hostname];
            url.protocol = "http:";
            url.hostname = here;
            if (port) url.port = port;
            a.href = url.href;
          }
        };
        rewrite();
        new MutationObserver(rewrite).observe(document.body, { childList: true, subtree: true });
      })();
    '';
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
              href = "http://${tsHost}:${toString cockpitPort}";
              description = "Storage, services, logs, terminal";
              icon = "cockpit.svg";
            };
          }
          {
            "AdGuard Home" = {
              href = "http://${tsHost}:${toString adguardPort}";
              description = "DNS ad blocking";
              icon = "adguard-home.svg";
              widget = {
                type = "adguard";
                url = "http://127.0.0.1:${toString adguardPort}";
                username = "arif";
                password = "{{HOMEPAGE_VAR_ADGUARD_PASSWORD}}";
              };
            };
          }
          {
            ntfy = {
              href = "https://ntfy.${tailscaleNet}";
              description = "Push notifications";
              icon = "ntfy.svg";
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

  # The Next.js server binds all interfaces unless told otherwise
  systemd.services.homepage-dashboard.environment.HOSTNAME = "127.0.0.1";

  # https://momiji-homelab.<tailnet> -> Caddy -> Homepage. The serve config persists in tailscaled state;
  # this (re)applies it declaratively. No-op until `sudo tailscale up` has been run once.
  systemd.services.homepage-tailscale-serve = {
    description = "Expose Homepage on the tailnet via tailscale serve";
    after = [
      "tailscaled.service"
      "caddy.service"
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
      ${tailscale} serve --bg --https=443 http://127.0.0.1:80
    '';
  };
}
