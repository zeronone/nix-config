# Agent notes

Nix flake for all my machines (nix-darwin, NixOS, home-manager).

## Layout

- `hosts.nix`: host list (flake name = hostname); `lib/default.nix`: `mkDarwinHost` / `mkNixosHost`
- `machines/<darwin|nixos>/<host>/{system,home}.nix`: per-host config
- `modules/{common,darwin,nixos,home-manager}/`: shared modules
- `secrets.yaml` (sops) next to the host or router that uses it

## Hosts

| Host | Kind | System | User |
|---|---|---|---|
| `IT-JPN-31519` | darwin | aarch64-darwin | arezai |
| `ITSO-WX6092` | darwin | aarch64-darwin | arezai |
| `arif-mac` | darwin | aarch64-darwin | arif |
| `asahi-nixos` | nixos | aarch64-linux | arif |
| `momiji-homelab` | nixos (NAS) | x86_64-linux | arif |

## Validating changes

- `nix fmt`: format (treefmt)
- `nix flake check --all-systems` (`just lint`): formatting, evaluates every host (`eval-hosts`), and builds the full closures of the hosts native to this machine (`host-<name>`)
- Evaluation only, any platform: `nix build --no-link .#checks.<system>.eval-hosts`
- One host: `nix build --no-link .#checks.<system>.host-<name>`

## Inspecting config

Use `nixosConfigurations` or `darwinConfigurations` according to the table above.

```sh
nix eval .#nixosConfigurations.momiji-homelab.config.services.immich.enable
nix eval .#darwinConfigurations.arif-mac.config.home-manager.users.arif.programs.git.enable
nix eval --json .#nixosConfigurations.momiji-homelab.config.networking.firewall.allowedTCPPorts
nix eval --inputs-from . --raw nixpkgs#sops.version          # package in the pinned nixpkgs
nix eval --inputs-from . --raw nixpkgs-unstable#sops.version
```

## Tools

`nix develop -c <cmd>` provides sops (with `SOPS_AGE_KEY_FILE` set), age, just, nom, nvd, nixd, nixos-rebuild, nixos-anywhere, jq.

## Rules

- Don't run `sudo`, `switch`/`deploy`, or anything decrypting secrets: give the command to the user.
- `nixpkgs-immich` is bumped only via `just update-immich` (Immich DB migrations are one-way).
- The HDD pool on `momiji-homelab` holds irreplaceable data: never touch its disks/filesystems config without asking.
