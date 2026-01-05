# Build and apply configuration based on the host
switch:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild switch --flake .; \
    elif [ -f /etc/NIXOS ]; then \
        sudo nixos-rebuild switch --flake .; \
    else \
        home-manager switch --flake ".#$(hostname)"; \
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
