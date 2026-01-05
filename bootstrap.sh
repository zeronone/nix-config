#!/usr/bin/env bash
set -e

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building configuration (as user)..."
    # Build DOES NOT need sudo
    nix build .#darwinConfigurations.work-mac.system

    echo "Applying configuration (may ask for sudo password)..."
    # Only the switch needs sudo permissions
    sudo ./result/sw/bin/darwin-rebuild switch --flake .#work-mac
else
    # Fedora logic remains the same
    nix run github:nix-community/home-manager -- init --flake .#personal-fedora
fi
