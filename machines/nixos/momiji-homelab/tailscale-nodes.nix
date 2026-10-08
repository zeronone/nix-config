# One tailnet node per service: https://<name>.<tailnet> with a Tailscale cert (TLS ends in the
# sidecar; the service itself speaks plain HTTP). Each node is a Tailscale container in userspace
# mode (no tun, so it can't clash with the host's tailscaled) that reaches the service on the host
# via the podman bridge, so the service must listen beyond 127.0.0.1.
# Node identity lives in /var/lib/tailscale-<name>. A new node logs in once: the login URL is in
# `sudo podman logs tailscale-<name>`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  serveConfig =
    name: port:
    pkgs.writeText "${name}-serve.json" (
      builtins.toJSON {
        TCP."443".HTTPS = true;
        # containerboot substitutes ${TS_CERT_DOMAIN}
        Web."\${TS_CERT_DOMAIN}:443".Handlers."/".Proxy =
          "http://host.containers.internal:${toString port}";
      }
    );
in
{
  options.tailscaleNodes = lib.mkOption {
    type = lib.types.attrsOf lib.types.port;
    default = { };
    description = "Tailnet node name -> host port of the HTTP service it serves";
  };

  config = {
    virtualisation.oci-containers.containers = lib.mapAttrs' (
      name: port:
      lib.nameValuePair "tailscale-${name}" {
        image = "docker.io/tailscale/tailscale:stable";
        hostname = name;
        environment = {
          TS_STATE_DIR = "/var/lib/tailscale";
          TS_USERSPACE = "true";
          TS_SERVE_CONFIG = "/config/serve.json";
        };
        volumes = [
          "/var/lib/tailscale-${name}:/var/lib/tailscale"
          "${serveConfig name port}:/config/serve.json:ro"
        ];
      }
    ) config.tailscaleNodes;

    systemd.tmpfiles.rules = lib.mapAttrsToList (
      name: _: "d /var/lib/tailscale-${name} 0700 root root -"
    ) config.tailscaleNodes;
  };
}
