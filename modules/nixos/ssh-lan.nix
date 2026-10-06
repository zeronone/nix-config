# Server variant of ./ssh.nix: SSH also reachable on the LAN (not just tailscale0), key-only.
# Authorized keys stay per host.
{ lib, ... }:
{
  imports = [ ./ssh.nix ];

  services.openssh.openFirewall = lib.mkForce true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    PermitRootLogin = "no";
  };
}
