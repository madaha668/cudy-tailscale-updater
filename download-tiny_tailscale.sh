#!/bin/bash
# shellcheck shell=dash
#
# Description: Lightweight tailscale update checker and downloader
# - Check prerequisites
# - Get latest version from GitHub
# - Compare with current version
# - Download if newer version available

OWNER="madaha668"
REPO="openwrt-tailscale-updater"
DOWNLOAD_DIR="/tmp/tailscale"
VERSION_FILE="./version.txt"

# Step 1: Check prerequisites
check_prerequisites() {
    echo "Checking prerequisites..."
    
    # Check architecture (arm64 only)
    if [ "$(uname -m)" != "aarch64" ]; then
        echo "ERROR: Only arm64 (aarch64) architecture supported"
        exit 1
    fi
    
    # Check if curl is available
    if ! command -v curl >/dev/null; then
        echo "ERROR: curl not installed"
        exit 1
    fi
    
    # Check if tailscale is installed
    if ! command -v tailscale >/dev/null; then
        echo "ERROR: tailscale not installed"
        exit 1
    fi
    
    echo "Prerequisites OK"
}

# Step 2: Get latest version from GitHub
get_latest_version() {
    echo "Getting latest version..."
    
    # Get version.txt from latest release
    DOWNLOAD_URL=$(curl -s -L "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" | \
      grep "browser_download_url.*version.txt" | \
      cut -d '"' -f 4)

    if [ -z "$DOWNLOAD_URL" ]; then
      echo "ERROR: version.txt not found in latest release"
      exit 1
    fi

    # Download and extract version
    #echo $DOWNLOAD_URL
    curl -s -L "$DOWNLOAD_URL" -o $VERSION_FILE
    LATEST_VERSION=$(cat $VERSION_FILE| sed 's/^v//')
    #echo $LATEST_VERSION
    
    if [ -z "$LATEST_VERSION" ]; then
        echo "ERROR: Could not extract version from version.txt"
        exit 1
    fi
    
    echo "Latest version: $LATEST_VERSION"
}

# Step 3: Compare versions
compare_versions() {
    echo "Getting current version..."
    #CURRENT_VERSION=$(tailscale --version | head -1)
    CURRENT_VERSION=$(tailscale version --json | jq ".majorMinorPatch" | sed 's/^"\|"$//g')
    
    if [ -z "$CURRENT_VERSION" ]; then
        echo "ERROR: Could not get current tailscale version"
        exit 1
    fi
    
    echo "Current version: $CURRENT_VERSION"
    
    if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
        echo "Tailscale is up to date ($CURRENT_VERSION)"
        exit 0
    fi
    
    local v1="$LATEST_VERSION"
    local v2="$CURRENT_VERSION"
    echo "compare $v1 vs $v2"
    IFS='.' read -r -a arr1 <<< "$v1"
    IFS='.' read -r -a arr2 <<< "$v2"

    local DOWNLOAD_LATEST_VERSION=0
    for i in {0..2}; do
        local n1=${arr1[i]:-0}
        local n2=${arr2[i]:-0}

        if (( n1 > n2 )); then
            DOWNLOAD_LATEST_VERSION=1
            break
        fi
    done

    if [ $DOWNLOAD_LATEST_VERSION -eq 0 ]; then
        echo "Tailscale is up to date ($CURRENT_VERSION)"
        exit 0
    fi

    echo "New version available: $LATEST_VERSION"
}

# Step 4: Download new version
check_and_download() {
    echo "Downloading new version..."
    
    # Create download directory
    mkdir -p "$DOWNLOAD_DIR"
    
    # Get download URL for arm64 binary
    BINARY_URL=$(curl -s -L "https://api.github.com/repos/${OWNER}/${REPO}/releases/latest" | \
        grep "browser_download_url.*tailscaled-linux-arm64" | \
        cut -d '"' -f 4)
    
    if [ -z "$BINARY_URL" ]; then
        echo "ERROR: tailscaled-linux-arm64 not found in latest release"
        exit 1
    fi
    
    # Download the binary
    curl -L -s --output "$DOWNLOAD_DIR/tailscaled-linux-arm64" "$BINARY_URL"
    
    if [ ! -f "$DOWNLOAD_DIR/tailscaled-linux-arm64" ]; then
        echo "ERROR: Download failed"
        exit 1
    fi
    
    chmod +x "$DOWNLOAD_DIR/tailscaled-linux-arm64"
    echo "Downloaded: $DOWNLOAD_DIR/tailscaled-linux-arm64"
    echo "Ready for manual installation"
}

# Main execution
echo "=== Tailscale Update Check ==="

check_prerequisites
get_latest_version  
compare_versions
check_and_download

echo "=== Done ==="
