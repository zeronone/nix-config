{ ... }:
{
  services.openssh = {
    enable = true;
    openFirewall = false;
  };

  # Only allow from tailscale
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 22 ];
  };
}
