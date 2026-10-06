# nix-config

Nix flake for my macOS (nix-darwin) and NixOS machines.

- `hosts.nix`: host list
- `machines/{darwin,nixos}/<host>/`: per-host config
- `modules/`: shared modules (`common`, `darwin`, `nixos`, `home-manager`)
- `lib/`: host builders

## Install

macOS:

```sh
curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install | sh
```

Linux (non-NixOS):

```sh
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" > ~/.config/nix/nix.conf
```

Then:

```sh
./bootstrap.sh
echo "access-tokens = github.com=$(gh auth token)" > ~/.secrets/nix-github-token.conf
sudo tailscale set --operator=$USER
sudo tailscale up
cachix authtoken XXXX   # https://app.cachix.org/cache/zeronone/settings/authtokens
```

## Usage

`just --list` for all recipes. Common ones:

- `just switch`: build and apply this machine's config
- `just update-all`: update flake inputs
- `just push-to-cachix <package>`: push a build to the `zeronone` cache

## Secrets

[sops-nix](https://github.com/Mic92/sops-nix). Each host that uses secrets has its own `machines/<os>/<host>/secrets.yaml`, encrypted to that host and to my age key, so a host can only read its own secrets. Recipients per file are in `.sops.yaml`.

- My key: `~/.config/sops/age/keys.txt.age` (passphrase-protected), backup in KeePassXC
- Hosts decrypt at activation with their SSH host key (`modules/nixos/sops.nix`); the age recipient is `ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub`
- Edit: `just edit-secrets`, or `just sops <file>` for any file
- After changing recipients in `.sops.yaml`: `just sops updatekeys <file>`. If a key leaked, change the secrets themselves too; old versions stay in git history.
- In Nix, pass secrets as paths (`config.sops.secrets.<name>.path`) or `sops.templates`, never as values

## Asahi firmware

Apple Silicon needs non-distributable firmware, kept in the private `asahi-firmware` repo (flake input). On the Asahi machine, after a macOS update or for a new machine type:

```sh
./scripts/push-asahi-firmware.sh --dir m1pro
nix flake update asahi-firmware
just switch
```
