#!/usr/bin/env bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Bootstrapping nix-darwin..."
    sudo nix run nix-darwin -- switch --flake .
elif [[ -f /etc/NIXOS ]]; then
    echo "Bootstrapping NixOS..."
    mkdir -p /mnt/etc/nixos/firmware
    cp -R -u -p /mnt/boot/asahi/{all_firmware.tar.gz,kernelcache*} /mnt/etc/nixos/firmware
    # Requires impure due to firmeware
    nixos-install --flake . --impure
else
    echo "Bootstrapping home-manager..."
    nix run home-manager/master -- switch --flake ".#$(hostname)"
fi
