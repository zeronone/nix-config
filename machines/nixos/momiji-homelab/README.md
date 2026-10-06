# momiji-homelab

UGREEN DXP4800 Plus class NAS. Pentium Gold 8505, 8 GB RAM, Intel UHD iGPU. NanoKVM attached for the console.

- LAN: `192.168.100.3` (static, 10GbE `enp2s0`), `momiji-homelab.local`
- Tailnet: `momiji-homelab.curl-featherback.ts.net` (`100.88.104.85`)
- SSH: `arif@` with key auth only. sudo and Cockpit use your password.

## Disks

| Disk | Use |
|---|---|
| 256G KIOXIA NVMe | NixOS: ESP + ext4 root, Postgres (`disko.nix`) |
| 128G Phison NVMe | UGOS, unused. Bootable via BIOS Boot Override (`NVME:debian`) |
| 2× 4T ST4000VN006 | md RAID1 → LVM → ext4 at `/volume3`, Immich library (`storage.nix`) |

To get into the BIOS: `sudo systemctl reboot --firmware-setup`. The NanoKVM is too slow to catch the hotkey.

## Services

| Service | URL | Notes |
|---|---|---|
| Immich | `https://immich.curl-featherback.ts.net`, `http://192.168.100.3:2283` | Server from the `nixpkgs-immich` pin, ML in the OpenVINO container on the iGPU. The tailnet URL comes from the `tailscale-immich` sidecar, a separate tailnet node with its state in `/var/lib/tailscale-immich` (`immich.nix`) |
| Homepage | `https://momiji-homelab.curl-featherback.ts.net`, `:8082` on the LAN | Front page |
| Cockpit | `https://…:9090` | Storage, services, logs, terminal, files, Podman |
| Scrutiny | `:8080`, tailnet only | SMART history |

Disk alerts (smartd, mdadm, monthly RAID check) go to the journal: `journalctl -t nas-notify`.

## Operations

- Deploy: `just deploy-homelab` (or `just deploy-homelab boot`)
- Update Immich: `just update-immich`, read the release notes first. `just update-all` skips it on purpose.
- Immich DB backups: `/volume3/immich-library/backups`

## Later

- ZFS: add 2 HDDs, create a mirror, copy, then add the old pair as a second mirror. `networking.hostId` is already set; add `cockpit-zfs` when it happens.
- Home Assistant, sops-nix.
