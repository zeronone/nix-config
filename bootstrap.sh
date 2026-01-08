#!/usr/bin/env bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Bootstrapping nix-darwin..."
    sudo nix run nix-darwin -- switch --flake .
elif [[ -f /etc/NIXOS ]]; then
    echo "Bootstrapping NixOS..."
    # Copy firmware to both installer and target system for pure flake evaluation
    mkdir -p /etc/nixos/firmware
    cp -R -u -p /mnt/boot/asahi/{all_firmware.tar.gz,kernelcache*} /etc/nixos/firmware
    mkdir -p /mnt/etc/nixos/firmware
    cp -R -u -p /mnt/boot/asahi/{all_firmware.tar.gz,kernelcache*} /mnt/etc/nixos/firmware
    nixos-install --flake .
else
    echo "Bootstrapping home-manager..."
    nix run home-manager/master -- switch --flake ".#$(hostname)"
fi
