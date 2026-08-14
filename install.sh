#!/bin/bash
# Installation script for the Munin PHP OPcache plugin
# Location: /usr/local/src/munin-php-opcache/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SOURCE="${SCRIPT_DIR}/plugin/php_opcache_multi"
MUNIN_PLUGIN_DIR="/usr/share/munin/plugins"

echo "Installing Munin PHP OPcache plugin from ${SCRIPT_DIR}..."

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root (sudo)" 
   exit 1
fi

# Check dependencies
if ! command -v docker >/dev/null 2>&1; then
    echo "Error: docker command not found"
    exit 1
fi

if ! command -v cgi-fcgi >/dev/null 2>&1; then
    echo "Error: cgi-fcgi not found. Install with: apt-get install libfcgi0ldbl"
    exit 1
fi

# Optional: check jq (not required, but nice to have)
if ! command -v jq >/dev/null 2>&1; then
    echo "Warning: jq not found. Will use grep/cut fallback for JSON parsing."
    echo "Install jq for better performance: apt-get install jq"
fi

# Copy the single auto-discovering multi plugin to the Munin directory
cp "$PLUGIN_SOURCE" "$MUNIN_PLUGIN_DIR/"
chmod +x "${MUNIN_PLUGIN_DIR}/php_opcache_multi"

# Remove the legacy per-container wildcard plugin + symlinks (v1.x layout)
rm -f /etc/munin/plugins/php_opcache_*
rm -f /usr/share/munin/plugins/php_opcache_

# Create the single plugin symlink. Containers are auto-discovered via
# `docker ps` + FastCGI socket presence, so no per-container symlinks needed.
ln -sf "${MUNIN_PLUGIN_DIR}/php_opcache_multi" "/etc/munin/plugins/php_opcache_multi"

# Restart munin-node
systemctl restart munin-node

echo ""
echo "Installation complete!"
echo ""
echo "Test with:"
echo "  munin-run php_opcache_multi config | head -15"
echo "  munin-run php_opcache_multi | head -15"
echo ""
echo "Note: Install jq for better JSON parsing performance:"
echo "  apt-get install jq"