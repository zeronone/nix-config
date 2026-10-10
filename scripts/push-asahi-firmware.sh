#!/usr/bin/env nix-shell
#!nix-shell -i bash -p git git-lfs openssh asahi-fwextract
set -e

FIRMWARE_REPO="git@github.com:zeronone/asahi-firmware.git"
FIRMWARE_DIR="m1pro"
FIRMWARE_SOURCE="/boot/asahi"
LOCAL_REPO="$HOME/myfiles/asahi-firmware"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Push Apple Silicon firmware to private git repository."
    echo "Dependencies (git, git-lfs, openssh, asahi-fwextract) are provided via nix-shell."
    echo ""
    echo "Options:"
    echo "  -r, --repo URL         Git repository URL (default: $FIRMWARE_REPO)"
    echo "  -l, --local-dir PATH   Local path for firmware repository (default: $LOCAL_REPO)"
    echo "  -d, --dir NAME         Subdirectory in repo for this machine (default: $FIRMWARE_DIR)"
    echo "  -s, --source PATH      Source firmware directory (default: $FIRMWARE_SOURCE)"
    echo "  -h, --help             Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --dir m1pro"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            FIRMWARE_REPO="$2"
            shift 2
            ;;
        -l|--local-dir)
            LOCAL_REPO="$2"
            shift 2
            ;;
        -d|--dir)
            FIRMWARE_DIR="$2"
            shift 2
            ;;
        -s|--source)
            FIRMWARE_SOURCE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Initialize git-lfs
git lfs install --skip-repo > /dev/null 2>&1 || true

# Check GitHub SSH credentials
echo "Checking GitHub SSH credentials..."
if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    echo "Error: GitHub SSH authentication failed."
    echo "Please ensure your SSH key is set up correctly:"
    echo "  1. Generate a key: ssh-keygen -t ed25519"
    echo "  2. Add to GitHub: https://github.com/settings/keys"
    echo "  3. Test: ssh -T git@github.com"
    exit 1
fi
echo "GitHub SSH authentication successful."

if [[ ! -d "$FIRMWARE_SOURCE" ]]; then
    echo "Error: Firmware source directory not found: $FIRMWARE_SOURCE"
    exit 1
fi

if [[ ! -f "$FIRMWARE_SOURCE/all_firmware.tar.gz" ]]; then
    echo "Error: all_firmware.tar.gz not found in $FIRMWARE_SOURCE"
    echo ""
    echo "If you recently updated macOS, the vendor firmware needs to be exported:"
    echo "  1. Reboot into macOS."
    echo "  2. Open Terminal and run: curl -sL https://alx.sh | sh"
    echo "  3. Choose the option to export/update firmware for your existing Linux install."
    echo "  4. Reboot into NixOS and re-run this script."
    exit 1
fi

FW_EXTRACT_DIR=$(mktemp -d)

cleanup() {
    rm -rf "$FW_EXTRACT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

echo "Extracting firmware package using asahi-fwextract..."
mkdir -p "$FW_EXTRACT_DIR"
asahi-fwextract "$FIRMWARE_SOURCE" "$FW_EXTRACT_DIR"

if [[ ! -d "$LOCAL_REPO/.git" ]]; then
    echo "Cloning firmware repository to $LOCAL_REPO..."
    mkdir -p "$(dirname "$LOCAL_REPO")"
    git clone "$FIRMWARE_REPO" "$LOCAL_REPO"
    cd "$LOCAL_REPO"
else
    echo "Using existing firmware repository at $LOCAL_REPO..."
    cd "$LOCAL_REPO"
    echo "Pulling latest changes from remote..."
    git pull origin main 2>/dev/null || git pull origin master 2>/dev/null || true
fi

echo "Copying firmware to $FIRMWARE_DIR/..."
mkdir -p "$FIRMWARE_DIR"
cp -p "$FIRMWARE_SOURCE/all_firmware.tar.gz" "$FIRMWARE_DIR/"
cp -p "$FIRMWARE_SOURCE"/kernelcache* "$FIRMWARE_DIR/" 2>/dev/null || true
cp -pr "$FW_EXTRACT_DIR"/* "$FIRMWARE_DIR/"

git lfs track "$FIRMWARE_DIR/*"

echo "Checking for changes..."
git add .gitattributes "$FIRMWARE_DIR"

if git diff --cached --quiet; then
    echo "No firmware changes detected. Repository is up to date."
    exit 0
fi

echo ""
echo "Files to be committed:"
echo "----------------------"
git diff --cached --name-status
echo "----------------------"
echo ""

read -p "Proceed with commit and push? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

echo "Committing firmware..."
git commit -m "Update $FIRMWARE_DIR firmware $(date +%Y-%m-%d)"

echo "Pushing to remote..."
git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null || {
    echo "Creating initial branch and pushing..."
    git branch -M main
    git push -u origin main
}

echo ""
echo "Firmware pushed successfully!"
echo ""
echo "Next steps:"
echo "  1. Update flake.lock: nix flake lock --update-input asahi-firmware"
echo "  2. Rebuild: just switch"
