# `ssh momiji-homelab` (and `just deploy momiji-homelab`) from any machine, same config everywhere.
# The bare name is canonicalized to the first domain that resolves:
#   - on the tailnet: momiji-homelab.<tailnet> (MagicDNS) -> Tailscale SSH, no key needed
#   - otherwise: momiji-homelab.home.lan (router DNS) -> LAN sshd, key only; the machine's
#     ~/.ssh/id_homelab must be in the LAN-only list in machines/nixos/momiji-homelab/system.nix
# System-wide ssh_config, so user ~/.ssh/config files (Ansible-managed on the work Mac) stay untouched.
{ tailscaleNet, ... }:
{
  programs.ssh.extraConfig = ''
    Host momiji-homelab
      CanonicalizeHostname yes
      CanonicalDomains ${tailscaleNet} home.lan
    Host momiji-homelab momiji-homelab.*
      User arif
      IdentityFile ~/.ssh/id_homelab
      IdentitiesOnly yes
      AddKeysToAgent yes
      # macOS: key passphrase from the Keychain; Linux ssh doesn't know the option
      IgnoreUnknown UseKeychain
      UseKeychain yes
  '';
}
