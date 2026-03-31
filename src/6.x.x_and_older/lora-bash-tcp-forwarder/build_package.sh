#!/bin/bash
# =============================================================================
# build_package.sh — lora-bash-tcp-forwarder packaging script (mPower 6.x.x)
#
# Usage:
#   ./build_package.sh
#
# What it does:
#   1. Reads the app version from manifest.json
#   2. Checks that the socat .ipk is present in provisioning/
#   3. Creates a .tar.gz ready to upload on mPower via Apps > Custom Apps
#
# Output:
#   lora-bash-tcp-forwarder_<version>.tar.gz  (in the current directory)
#
# Prerequisites:
#   - The socat .ipk file must be placed in provisioning/ first.
#     See README.md section "Obtenir le fichier socat .ipk"
# =============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# ---------------------------------------------------------------------------
# 1. Read version from manifest.json
# ---------------------------------------------------------------------------
if [ ! -f manifest.json ]; then
    echo "ERROR: manifest.json not found. Run this script from the app directory."
    exit 1
fi

# Use python3 if available, otherwise fall back to sed/grep parsing
if command -v python3 >/dev/null 2>&1; then
    APP_NAME=$(python3 -c "import json; d=json.load(open('manifest.json')); print(d['AppName'])" 2>/dev/null)
    APP_VERSION=$(python3 -c "import json; d=json.load(open('manifest.json')); print(d['AppVersion'])" 2>/dev/null)
else
    APP_NAME=$(grep '"AppName"' manifest.json | sed 's/.*"AppName"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
    APP_VERSION=$(grep '"AppVersion"' manifest.json | sed 's/.*"AppVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
fi

if [ -z "$APP_NAME" ] || [ -z "$APP_VERSION" ]; then
    echo "ERROR: Could not read AppName/AppVersion from manifest.json"
    exit 1
fi

PACKAGE_NAME="${APP_NAME}_${APP_VERSION}.tar.gz"
echo "----------------------------------------------------"
echo "  App:     $APP_NAME"
echo "  Version: $APP_VERSION"
echo "  Output:  $PACKAGE_NAME"
echo "----------------------------------------------------"

# ---------------------------------------------------------------------------
# 2. Check required files exist
# ---------------------------------------------------------------------------
MISSING=0
for f in manifest.json Start Install forwarder.sh handle_packet.sh \
          config/forwarder.cfg provisioning/p_manifest.json; do
    if [ ! -f "$f" ]; then
        echo "ERROR: Required file missing: $f"
        MISSING=1
    fi
done
if [ $MISSING -ne 0 ]; then
    exit 1
fi

# ---------------------------------------------------------------------------
# 3. Check that at least one .ipk file is present in provisioning/
# ---------------------------------------------------------------------------
IPK_COUNT=$(ls provisioning/*.ipk 2>/dev/null | wc -l)
if [ "$IPK_COUNT" -eq 0 ]; then
    echo ""
    echo "WARNING: No .ipk file found in provisioning/"
    echo ""
    echo "  The socat .ipk must be placed in provisioning/ before packaging."
    echo "  Expected filename: socat_1.7.3.2-3_arm926ejste.ipk"
    echo ""
    echo "  To obtain it, download from the OpenWRT repository:"
    echo "    wget https://downloads.openwrt.org/releases/21.02.7/packages/arm_arm926ej-s/base/socat_1.7.3.2-3_arm_arm926ej-s.ipk"
    echo "    mv socat_*.ipk provisioning/socat_1.7.3.2-3_arm926ejste.ipk"
    echo ""
    read -r -p "Continue packaging WITHOUT the .ipk (not installable on device)? [y/N] " REPLY
    if [[ ! "$REPLY" =~ ^[Yy]$ ]]; then
        echo "Aborted. Add the .ipk file and run again."
        exit 1
    fi
fi

# ---------------------------------------------------------------------------
# 4. Create the .tar.gz package
# ---------------------------------------------------------------------------
echo ""
echo "Building package..."

tar -czf "$PACKAGE_NAME" \
    manifest.json \
    Start \
    Install \
    forwarder.sh \
    handle_packet.sh \
    config/ \
    provisioning/

echo ""
echo "SUCCESS: Package created -> $PACKAGE_NAME"
echo ""
echo "Next steps:"
echo "  1. Connect to the mPower web interface"
echo "  2. Go to Apps > Custom Apps"
echo "  3. Upload $PACKAGE_NAME"
echo "  OR"
echo "  scp $PACKAGE_NAME admin@<gateway-ip>:/tmp/"
echo "  ssh admin@<gateway-ip> 'app-manager --install /tmp/$PACKAGE_NAME'"
echo ""
