# sops-nix: secrets are decrypted at activation into /run/secrets with the host's SSH key.
# The host's age recipient (`ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`) goes in .sops.yaml.
# Hosts set `sops.defaultSopsFile`.
{ flake-inputs, ... }:
{
  imports = [ flake-inputs.sops-nix.nixosModules.sops ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
