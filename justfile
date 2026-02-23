set shell := ["zsh", "-cu"]

# Build and apply configuration based on the host
switch:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo -v; sudo darwin-rebuild switch --flake . |& nom; \
    elif [ -f /etc/NIXOS ]; then \
        sudo -v; nixos-rebuild --sudo switch --flake . |& nom; \
        niri validate -c ./config/niri/config.kdl; \
    else \
        home-manager switch --flake ".#$(hostname)" |& nom; \
    fi

# Build and apply on next boot
boot:
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "Not supported"; \
    elif [ -f /etc/NIXOS ]; then \
        sudo -v; nixos-rebuild --sudo boot --flake . |& nom; \
    else \
        echo "Not supported"; \
    fi

watch-store:
    cachix watch-store zeronone

check:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo -v; sudo darwin-rebuild check --flake .; \
    elif [ -f /etc/NIXOS ]; then \
        niri validate -c ./config/niri/config.kdl || exit 1; \
        nixos-rebuild dry-run --flake .; \
    else \
        echo "TODO"; \
    fi

fmt:
    nix fmt

lint:
    nix flake check --all-systems

# Clean up old generations to free up disk space
gc:
    @if [ -f /etc/NIXOS ]; then \
        sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d; \
    fi
    nix-collect-garbage -d

clean-store:
    nix-store --gc --option keep-outputs false --option keep-derivations false

# Update the flake.lock file to get latest package versions
update:
    nix flake update
