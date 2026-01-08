#!/usr/bin/env bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Bootstrapping nix-darwin..."
    sudo nix run nix-darwin -- switch --flake .
elif [[ -f /etc/NIXOS ]]; then
    echo "Bootstrapping NixOS..."
    echo "Note: Ensure firmware is pushed to private repo first (see scripts/push-asahi-firmware.sh)"
    echo "      Then run: nix flake lock --update-input asahi-firmware"
    nixos-install --flake .
else
    echo "Bootstrapping home-manager..."
    nix run home-manager/master -- switch --flake ".#$(hostname)"
fi
