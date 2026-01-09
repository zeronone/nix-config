## Overview

- Machine configs

## Dependencies

- MacOSX

```
# Lix (only used for nix-darwin)
# nix-darwin will manager another Nix installation that defaults to upstream Nix
curl -sSf -L https://install.lix.systems/lix | sh -s -- install
```

- Linux (non NixOS)

```
sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon

mkdir -p ~/.config/nix
cat <<EOF > ~/.config/nix/nix.conf
experimental-features = nix-command flakes
EOF
```

## Initial setup

```bash
./bootstrap.sh
```

## Updates

```
just switch
```

## Apple Silicon (Asahi Linux) Setup

Apple Silicon Macs require non-distributable firmware files for Wi-Fi and other peripherals.
These are stored in a private git repository and referenced as a flake input.

### Initial firmware setup (on the Asahi Linux machine)

1. Create a private git repository (e.g., `github.com/zeronone/asahi-firmware`)

1. Push firmware to the repository:

   ```bash
   ./scripts/push-asahi-firmware.sh --dir m1pro
   ```

   Use a different `--dir` for each machine type (e.g., `m1pro`, `m2max`, `m3`).

1. Update the flake lock file:

   ```bash
   nix flake lock --update-input asahi-firmware
   ```

1. Proceed with normal installation:

   ```bash
   ./bootstrap.sh
   ```

### Updating firmware

If firmware is updated (e.g., after macOS update), re-run:

```bash
./scripts/push-asahi-firmware.sh --dir m1pro
nix flake lock --update-input asahi-firmware
just switch
```
