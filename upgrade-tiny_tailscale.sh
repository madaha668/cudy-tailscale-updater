#!/bin/sh
# Upgrade tiny tailscale from downloaded binary
# Simplified upgrade script for tiny tailscale version

set -e

DOWNLOAD_DIR="/tmp/tailscale"
NEW_BINARY="$DOWNLOAD_DIR/tailscaled-linux-arm64"
TARGET_BINARY="/usr/sbin/tailscaled"

# Helper functions
log() {
    echo "$(date '+%H:%M:%S') $*"
}

error() {
    echo "ERROR: $*" >&2
    exit 1
}

warn() {
    echo "WARNING: $*" >&2
}

# Parse version number from binary output (remove 'v' prefix)
get_version() {
    local binary="$1"
    local version=""
    
    # Try to get version and clean it up
    version=$("$binary" --version 2>/dev/null | head -1 | sed 's/^v//' | grep -o '[0-9]*\.[0-9]*\.[0-9]*' | head -1 2>/dev/null || true)
    
    if [ -z "$version" ]; then
        return 1
    fi
    
    echo "$version"
}

# Compare version numbers mathematically
version_greater() {
    # Convert version to comparable number (e.g., 1.70.0 -> 1070000)
    local ver1=$(echo "$1" | awk -F. '{printf "%d%02d%03d", $1, $2, $3}')
    local ver2=$(echo "$2" | awk -F. '{printf "%d%02d%03d", $1, $2, $3}')
    [ "$ver1" -gt "$ver2" ]
}

# Main upgrade process
main() {
    log "Starting tiny tailscale upgrade process"
    
    # Step 1: Check if downloaded binary exists
    log "Checking for downloaded binary..."
    if [ ! -f "$NEW_BINARY" ]; then
        error "Downloaded binary not found: $NEW_BINARY"
    fi
    
    if [ ! -x "$NEW_BINARY" ]; then
        chmod +x "$NEW_BINARY" 2>/dev/null || error "Cannot make downloaded binary executable"
    fi
    
    log "Found downloaded binary: $NEW_BINARY"
    
    # Step 2: Get version from downloaded binary
    log "Getting version from downloaded binary..."
    NEW_VERSION=$(get_version "$NEW_BINARY")
    if [ -z "$NEW_VERSION" ]; then
        error "Cannot get version from downloaded binary. Please check if the binary is valid."
    fi
    log "Downloaded version: $NEW_VERSION"
    
    # Step 3: Check if current tailscaled exists and get its version
    log "Getting current installed version..."
    if [ ! -f "$TARGET_BINARY" ]; then
        error "Current tailscaled binary not found: $TARGET_BINARY"
    fi
    
    CURRENT_VERSION=$(get_version "$TARGET_BINARY")
    if [ -z "$CURRENT_VERSION" ]; then
        error "Cannot get version from current tailscaled installation"
    fi
    log "Current version: $CURRENT_VERSION"
    
    # Step 4: Compare versions
    log "Comparing versions..."
    if [ "$NEW_VERSION" = "$CURRENT_VERSION" ]; then
        warn "Downloaded version ($NEW_VERSION) is the same as current version ($CURRENT_VERSION)"
        warn "No upgrade needed. Aborting."
        exit 0
    elif version_greater "$CURRENT_VERSION" "$NEW_VERSION"; then
        warn "Downloaded version ($NEW_VERSION) is older than current version ($CURRENT_VERSION)"
        warn "Downgrade not recommended. Aborting."
        exit 1
    else
        log "Upgrade available: $CURRENT_VERSION -> $NEW_VERSION"
    fi
    
    # Step 5: Confirm upgrade
    echo ""
    echo "=== UPGRADE CONFIRMATION ==="
    echo "Current version: $CURRENT_VERSION"
    echo "New version:     $NEW_VERSION"
    echo "Target binary:   $TARGET_BINARY"
    echo ""
    printf "Proceed with upgrade? (y/N): "
    read -r answer
    
    if [ "$answer" != "${answer#[Yy]}" ]; then
        log "Proceeding with upgrade..."
    else
        log "Upgrade cancelled by user"
        exit 0
    fi
    
    # Step 6: Perform upgrade
    log "Copying new binary to $TARGET_BINARY..."
    if ! cp -f "$NEW_BINARY" "$TARGET_BINARY"; then
        error "Failed to copy new binary to $TARGET_BINARY"
    fi
    
    # Ensure proper permissions
    chmod 755 "$TARGET_BINARY" 2>/dev/null || error "Failed to set permissions on $TARGET_BINARY"
    
    # Create/update symlink for tailscale command (tiny version uses same binary)
    if [ -e "/usr/sbin/tailscale" ] && [ ! -L "/usr/sbin/tailscale" ]; then
        # Remove regular file if exists
        rm -f "/usr/sbin/tailscale" 2>/dev/null || true
    fi
    ln -sf "$TARGET_BINARY" "/usr/sbin/tailscale" 2>/dev/null || warn "Failed to create tailscale symlink"
    
    log "Binary installation completed"
    
    # Step 7: Restart service
    log "Restarting tailscaled service..."
    if ! service tailscaled restart 2>/dev/null; then
        error "Failed to restart tailscaled service"
    fi
    
    # Wait for service to stabilize
    log "Waiting for service to stabilize..."
    sleep 5
    
    # Step 8: Validate upgrade
    log "Validating upgrade..."
    
    # Check if service is running
    if ! pgrep tailscaled >/dev/null 2>&1; then
        error "tailscaled service is not running after restart"
    fi
    
    # Verify version
    UPGRADED_VERSION=$(get_version "$TARGET_BINARY")
    if [ -z "$UPGRADED_VERSION" ]; then
        error "Cannot get version from upgraded tailscaled"
    fi
    
    if [ "$UPGRADED_VERSION" = "$NEW_VERSION" ]; then
        log "Upgrade validation successful"
        log "Version confirmed: $UPGRADED_VERSION"
    else
        error "Version mismatch! Expected: $NEW_VERSION, Got: $UPGRADED_VERSION"
    fi
    
    # Final status check
    log "Checking tailscale status..."
    if tailscale --version >/dev/null 2>&1; then
        FINAL_VERSION=$(tailscale --version 2>/dev/null | head -1 | sed 's/^v//' | grep -o '[0-9]*\.[0-9]*\.[0-9]*' | head -1 2>/dev/null || echo "unknown")
        log "Tailscale command version: $FINAL_VERSION"
    else
        warn "tailscale command not working properly"
    fi
    
    echo ""
    echo "=== UPGRADE COMPLETED ==="
    echo "Successfully upgraded from $CURRENT_VERSION to $UPGRADED_VERSION"
    echo "Service status: Running"
    echo ""
    
    log "Tiny tailscale upgrade completed successfully!"
}

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    error "This script must be run as root"
fi

# Execute main function
main "$@"
