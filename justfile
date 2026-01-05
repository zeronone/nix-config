# Build and apply configuration based on the host
switch:
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo darwin-rebuild switch --flake .#work-mac; \
    else \
        home-manager switch --flake .#personal-fedora; \
    fi

# Clean up old generations to free up disk space
clean:
    nix-collect-garbage -d

# Update the flake.lock file to get latest package versions
update:
    nix flake update
