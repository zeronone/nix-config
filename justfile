set shell := ["zsh", "-cu"]

# Certain inputs are updated daily (i.e: claude-code)
# Run an update ONLY if flake.lock is older than 24 hours
update-bleeding-edge:
    #!/usr/bin/env bash
    FILE="flake.lock"
    LAST_MOD=$(date -r "$FILE" +%s)
    NOW=$(date +%s)
    AGE=$((NOW - LAST_MOD))

    if [ "$AGE" -gt 86400 ]; then
        echo "Updating bleeding-edge deps flake (lockfile is $((AGE / 3600))h old)..."
        nix flake update claude-code-nix
    else
        echo "Skipping beleeding-edge deps update (lockfile only $((AGE / 3600))h old)."
    fi

# Build and apply configuration based on the host
switch: update-bleeding-edge
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo -v; sudo darwin-rebuild switch --flake . |& nom; \
    elif [ -f /etc/NIXOS ]; then \
        sudo -v; nixos-rebuild --sudo switch --flake . |& nom; \
        niri validate -c ./config/niri/config.kdl; \
    else \
        home-manager switch --flake ".#$(hostname)" |& nom; \
    fi

# Build and apply on next boot
boot: update-bleeding-edge
    @if [ "$(uname)" = "Darwin" ]; then \
        echo "Not supported"; \
    elif [ -f /etc/NIXOS ]; then \
        sudo -v; nixos-rebuild --sudo boot --flake . |& nom; \
    else \
        echo "Not supported"; \
    fi

check: update-bleeding-edge
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo -v; sudo darwin-rebuild check --flake . |& nom; \
    elif [ -f /etc/NIXOS ]; then \
        niri validate -c ./config/niri/config.kdl || exit 1; \
        nixos-rebuild dry-run --flake . |& nom; \
    else \
        echo "TODO"; \
    fi

fmt:
    nix fmt |& nom 

lint:
    nix flake check --all-systems |& nom

# Clean up old generations to free up disk space
gc:
    @if [ -f /etc/NIXOS ]; then \
        sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d; \
    fi
    nix-collect-garbage -d

# Pushes a specific package and its closure from the Nix store to Cachix with confirmation
push-to-cachix target cachix_cache="zeronone":
    #!/usr/bin/env bash
    set -euo pipefail
    
    echo "Searching for exact matches of '{{target}}' in /nix/store..."
    
    matches=$(find /nix/store -maxdepth 1 -name "*-{{target}}")
    
    if [[ -z "$matches" ]]; then
        echo "No exact builds found for '{{target}}'."
        exit 1
    fi
    
    echo -e "\nFound the following builds to upload:"
    for path in $matches; do
        echo "  - $path"
    done
    echo ""
    
    # Prompt for confirmation (Defaults to Y if the user just presses Enter)
    read -r -p "Upload these builds to '{{cachix_cache}}'? [Y/n] " response
    response=${response:-Y}
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo -e "\nStarting upload..."
        for path in $matches; do
            echo "Pushing recursively: $path"
            nix path-info --recursive "$path" | cachix push "{{cachix_cache}}"
        done
        echo "Push complete!"
    else
        echo "Upload cancelled."
    fi

clean-store:
    nix-store --gc --option keep-outputs false --option keep-derivations false

# Update the flake.lock file to get latest package versions
update-all:
    nix flake update
