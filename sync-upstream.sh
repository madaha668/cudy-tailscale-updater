#!/usr/bin/env bash
# sync-upstream.sh — compare local workflow against upstream admonstrator/glinet-tailscale-updater
# Usage: ./sync-upstream.sh

set -euo pipefail

UPSTREAM_URL="https://raw.githubusercontent.com/admonstrator/glinet-tailscale-updater/main/.github/workflows/build-tailscale.yaml"
ORIG_FILE=".github/workflows/build-tailscale.yaml.orig"
LOCAL_FILE=".github/workflows/build-tailscale.yaml"

echo "Fetching upstream workflow..."
curl -fsSL "$UPSTREAM_URL" -o "$ORIG_FILE"
echo "Updated: $ORIG_FILE"
echo ""
echo "Diff (upstream vs cudy local) — lines marked '# CUDY:' are intentional:"
echo "------------------------------------------------------------------------"
diff "$ORIG_FILE" "$LOCAL_FILE" || true
echo "------------------------------------------------------------------------"
echo ""
echo "If upstream has new improvements to cherry-pick, edit $LOCAL_FILE manually"
echo "and preserve all '# CUDY:' markers."
