#!/usr/bin/env bash
set -e

FIRMWARE_REPO="git@github.com:zeronone/asahi-firmware.git"
FIRMWARE_DIR="m1pro"
FIRMWARE_SOURCE="/boot/asahi"

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Push Apple Silicon firmware to private git repository."
    echo ""
    echo "Options:"
    echo "  -r, --repo URL      Git repository URL (default: $FIRMWARE_REPO)"
    echo "  -d, --dir NAME      Subdirectory in repo for this machine (default: $FIRMWARE_DIR)"
    echo "  -s, --source PATH   Source firmware path (default: $FIRMWARE_SOURCE)"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Example:"
    echo "  $0 --dir m2max"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--repo)
            FIRMWARE_REPO="$2"
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

if [[ ! -d "$FIRMWARE_SOURCE" ]]; then
    echo "Error: Firmware source directory not found: $FIRMWARE_SOURCE"
    echo "Make sure you're running this on an Asahi Linux system with firmware installed."
    exit 1
fi

if [[ ! -f "$FIRMWARE_SOURCE/all_firmware.tar.gz" ]]; then
    echo "Error: all_firmware.tar.gz not found in $FIRMWARE_SOURCE"
    exit 1
fi

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Cloning firmware repository..."
git clone "$FIRMWARE_REPO" "$TEMP_DIR/repo"
cd "$TEMP_DIR/repo"

echo "Copying firmware to $FIRMWARE_DIR/..."
mkdir -p "$FIRMWARE_DIR"
cp -p "$FIRMWARE_SOURCE/all_firmware.tar.gz" "$FIRMWARE_DIR/"
cp -p "$FIRMWARE_SOURCE"/kernelcache* "$FIRMWARE_DIR/" 2>/dev/null || true
git lfs track "$FIRMWARE_SOURCE/*"

echo "Checking for changes..."
git add "$FIRMWARE_DIR"

if git diff --cached --quiet; then
    echo "No firmware changes detected. Repository is up to date."
    exit 0
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
