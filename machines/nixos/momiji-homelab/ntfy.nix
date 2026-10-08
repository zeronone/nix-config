# ntfy: push notifications to the phone (ntfy app) from the NAS and anything on the LAN.
#   https://ntfy.<tailnet> (own tailnet node, Tailscale cert; tailscale-nodes.nix) and http://192.168.100.3:2586
#   Subscribe to topic `homelab`, logged in as arif / ntfy-password-hash (sops, from
#   `nix run nixpkgs#ntfy-sh -- user hash`).
#   Publish: `notify` (modules/nixos/notify.nix) on the NAS; elsewhere
#     curl -H "Authorization: Bearer <ntfy-publish-token>" -d message http://192.168.100.3:2586/homelab
#   The token (`nix run nixpkgs#ntfy-sh -- token generate`) belongs to `publisher`, which can only
#   publish; its password is unknown on purpose (random, discarded).
{
  config,
  tailscaleNet,
  ...
}:
let
  port = 2586;
in
{
  sops.secrets.ntfy-password-hash = { };
  sops.templates."ntfy.env" = {
    # Single quotes: systemd must not touch the $s in the bcrypt hashes
    content = ''
      NTFY_AUTH_USERS='arif:${config.sops.placeholder.ntfy-password-hash}:admin,publisher:$2y$10$lvd6v1kXxuyONWUuTjUUkevXTZpBBJ2NKPg9ICy3dUzQYxVGTJcH2:user'
      NTFY_AUTH_TOKENS='publisher:${config.sops.placeholder.ntfy-publish-token}:notify'
    '';
    restartUnits = [ "ntfy-sh.service" ];
  };

  services.ntfy-sh = {
    enable = true;
    environmentFile = config.sops.templates."ntfy.env".path;
    settings = {
      base-url = "https://ntfy.${tailscaleNet}";
      # Plain HTTP only; TLS is Tailscale's. All interfaces: the LAN and the sidecar (podman bridge)
      listen-http = ":${toString port}";
      auth-default-access = "deny-all";
      auth-access = [ "publisher:*:wo" ];
      # `notify` can burst, e.g. during a router reboot
      visitor-request-limit-exempt-hosts = "127.0.0.1,::1";
    };
  };

  tailscaleNodes.ntfy = port;

  networking.firewall.allowedTCPPorts = [ port ];
}
