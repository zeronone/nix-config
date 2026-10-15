# Home Assistant: native service, state in /var/lib/hass (NVMe).
#   https://home-assistant.<tailnet> (own tailnet node, tailscale-nodes.nix) and http://192.168.100.3:8123
#   Host network, so LAN discovery (mDNS/SSDP) and Matter work.
# Nix decides which integrations are installed; their setup (ntfy, AdGuard, ...) happens in the
# UI. Automations, scenes and scripts are UI-editable (the *.yaml files below).
# Matter: the Matter server on localhost:5580 (add the Matter integration with
# ws://localhost:5580/ws). Thread devices need a border router on the LAN (e.g. Apple TV 4K /
# HomePod) and the NAS to accept its IPv6 routes; none is set up here.
{ config, ... }:
let
  port = config.services.home-assistant.config.http.server_port;
  uiFiles = [
    "automations.yaml"
    "scenes.yaml"
    "scripts.yaml"
  ];
in
{
  services.home-assistant = {
    enable = true;
    openFirewall = true;
    extraComponents = [
      # Onboarding
      "met"
      "radio_browser"
      "google_translate"
      "isal"
      # Integrations set up in the UI
      "ntfy"
      "mobile_app"
      "adguard"
      "systemmonitor"
      "homekit_controller"
      "matter"
      "thread"
    ];
    config = {
      # Location, units, time zone: set during onboarding (UI), not here
      default_config = { };
      http = {
        server_port = 8123;
        # The tailnet sidecar reaches HA over the podman bridge
        use_x_forwarded_for = true;
        trusted_proxies = [ "10.88.0.0/16" ];
      };
      "automation ui" = "!include automations.yaml";
      "scene ui" = "!include scenes.yaml";
      "script ui" = "!include scripts.yaml";
    };
  };

  # HA refuses to start if an !include target is missing
  systemd.tmpfiles.rules = map (
    f: "f ${config.services.home-assistant.configDir}/${f} 0644 hass hass -"
  ) uiFiles;

  # Port stays closed in the firewall; HA on this host is its only client
  services.matter-server.enable = true;

  tailscaleNodes.home-assistant = port;
}
