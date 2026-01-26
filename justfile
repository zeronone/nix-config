# Build and apply configuration based on the host
switch:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild switch --flake .; \
    elif [ -f /etc/NIXOS ]; then \
        sudo nixos-rebuild switch --flake .; \
        niri validate -c ./config/niri/config.kdl; \
    else \
        home-manager switch --flake ".#$(hostname)"; \
    fi

# Build and apply on next boot
boot:
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "Not supported"; \
    elif [ -f /etc/NIXOS ]; then \
        sudo nixos-rebuild boot --flake .; \
    else \
        echo "Not supported"; \
    fi

watch-store:
    cachix watch-store zeronone

check:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild check --flake .; \
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
clean:
    nix-collect-garbage -d

# Update the flake.lock file to get latest package versions
update:
    nix flake update
