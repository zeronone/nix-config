#!/usr/bin/env bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Bootstrapping nix-darwin..."
    sudo nix run nix-darwin -- switch --flake .
elif [[ -f /etc/NIXOS ]]; then
    echo "Bootstrapping NixOS..."
    sudo nixos-rebuild switch --flake .
else
    echo "Bootstrapping home-manager..."
    nix run github:nix-community/home-manager -- switch --flake ".#$(hostname)"
fi
