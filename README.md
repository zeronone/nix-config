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
