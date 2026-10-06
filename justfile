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
        nix flake update claude-code-nix antigravity-nix
    else
        echo "Skipping beleeding-edge deps update (lockfile only $((AGE / 3600))h old)."
    fi

# Build and apply configuration based on the host
switch: update-bleeding-edge
    @if [ "$(uname)" = "Darwin" ]; then \
        sudo -v; sudo darwin-rebuild switch --flake . |& nom; \
    elif [ -f /etc/NIXOS ]; then \
        sudo -v; nixos-rebuild --sudo switch --flake . |& nom; \
        if command -v niri >/dev/null; then niri validate -c ./config/niri/config.kdl; fi; \
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
        if command -v niri >/dev/null; then niri validate -c ./config/niri/config.kdl || exit 1; fi; \
        nixos-rebuild dry-run --flake . |& nom; \
    else \
        echo "TODO"; \
    fi

fmt:
    nix fmt |& nom 

lint:
    nix flake check --all-systems |& nom

# Clean up old generations to free up disk space
gc: clean-boot
    @if [ -f /etc/NIXOS ]; then \
        sudo nix profile wipe-history --profile /nix/var/nix/profiles/system --older-than 7d; \
    fi
    nix-collect-garbage -d

# Safely remove orphaned kernels and initrds from /boot/EFI/nixos
clean-boot:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -d /boot/EFI/nixos ]; then echo "Not a NixOS system with EFI boot"; exit 0; fi
    echo "Cleaning up orphaned kernels and initrds in /boot/EFI/nixos..."
    
    # 1. Clear any .tmp files left by failed copies
    sudo rm -vf /boot/EFI/nixos/*.tmp
    
    # 2. Identify files referenced by current boot entries
    # We grep for linux/initrd lines and extract the filename
    ACTIVE_FILES=$(grep -E 'linux|initrd' /boot/loader/entries/*.conf | awk '{print $2}' | xargs -n1 basename | sort -u)
    
    # 3. Find and remove files not in that list
    find /boot/EFI/nixos -maxdepth 1 -type f | while read -r FILE; do
        BASENAME=$(basename "$FILE")
        if ! echo "$ACTIVE_FILES" | grep -q "^$BASENAME$"; then
            sudo rm -v "$FILE"
        fi
    done
    df -h /boot

# Deploy the NAS from this machine. Builds on the NAS itself (it is x86_64)
# Usage: just deploy-homelab [switch|boot|test|dry-activate]
deploy-homelab action="switch" host="arif@192.168.100.3":
    nix run --inputs-from . nixpkgs#nixos-rebuild -- {{action}} --flake .#momiji-homelab \
        --target-host {{host}} --build-host {{host}} --sudo --ask-sudo-password

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
# (except nixpkgs-immich: Immich DB migrations are one-way, bump it with `just update-immich`)
update-all:
    nix flake update $(nix flake metadata --json | jq -r '.locks.nodes.root.inputs | keys[] | select(. != "nixpkgs-immich")')

# Bump Immich on momiji-homelab (read the Immich release notes first)
update-immich:
    nix flake update nixpkgs-immich
    nix eval --raw .#nixosConfigurations.momiji-homelab.config.services.immich.package.version; echo

# Edit the secrets.yaml of a host or directory, e.g. `just edit-secrets momiji-homelab`, `just edit-secrets routers/rtx1300`
edit-secrets name:
    #!/usr/bin/env bash
    set -euo pipefail
    shopt -s nullglob
    for f in machines/*/{{name}}/secrets.yaml {{name}}/secrets.yaml; do
        [ -e "$f" ] && exec {{just_executable()}} sops "$f"
    done
    echo "no secrets.yaml for {{name}}" >&2
    exit 1

# sops with the passphrase-protected age key, e.g. `just sops updatekeys <file>` after editing .sops.yaml
sops *args:
    SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt.age nix run --inputs-from . nixpkgs#sops -- {{args}}

# Fill a template's ${VAR}s from the sops secrets.yaml next to it into dist/ (gitignored), e.g. `just render routers/rtx1300/config1.txt`
render template:
    #!/usr/bin/env bash
    set -euo pipefail
    out="dist/{{template}}"
    mkdir -p "$(dirname "$out")"
    umask 077
    SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt.age nix shell --inputs-from . nixpkgs#sops nixpkgs#gettext -c \
        sops exec-env "$(dirname {{template}})/secrets.yaml" "scripts/render-template.sh {{template}}" > "$out.tmp"
    mv "$out.tmp" "$out"
    echo "$out (contains secrets; delete after use: rm -r dist)"
