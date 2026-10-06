# momiji-homelab

UGREEN DXP4800 Plus class NAS: Pentium Gold 8505, 8 GB RAM, Intel UHD iGPU, NanoKVM for the console.

- LAN: `192.168.100.3`, `momiji-homelab.local`
- Tailnet: `momiji-homelab.curl-featherback.ts.net` (`100.88.104.85`)
- SSH: Tailscale SSH on the tailnet; on the LAN, key only (the work Mac's `id_homelab`)
- BIOS: `sudo systemctl reboot --firmware-setup`

## Disks

| Disk | Use |
|---|---|
| 256G KIOXIA NVMe | NixOS, Postgres (`disko.nix`) |
| 128G Phison NVMe | UGOS, unused (BIOS Boot Override) |
| 2× 4T ST4000VN006 | md RAID1 → LVM → ext4 at `/volume3`, Immich library (`storage.nix`) |

## Services

| Service | URL | Notes |
|---|---|---|
| Homepage | `http://192.168.100.3`, `https://momiji-homelab.curl-featherback.ts.net` | Caddy basic auth |
| Immich | `https://immich.curl-featherback.ts.net`, `:2283` | ML on the iGPU (`immich.nix`) |
| AdGuard Home | `:3000`, DNS on `:53` | `adguard.nix` |
| Cockpit | `:9090` | System admin |
| Scrutiny | `:8080` | SMART history |

Disk alerts: `journalctl -t nas-notify`. Immich DB backups: `/volume3/immich-library/backups`.

## Operations

- Deploy: `just deploy-homelab`
- Update Immich: `just update-immich` (read the release notes first; `just update-all` skips it)
- Secrets: `just edit-secrets momiji-homelab` (see the root README). `homepage-password-hash` is bcrypt: `nix run nixpkgs#caddy -- hash-password`
