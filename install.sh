#!/bin/bash
# Installatie script voor Munin PHP OPcache plugin
# Location: /usr/local/src/munin-php-opcache/install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_SOURCE="${SCRIPT_DIR}/plugin/php_opcache_"
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

# Copy plugin to Munin directory
cp "$PLUGIN_SOURCE" "$MUNIN_PLUGIN_DIR/"
chmod +x "${MUNIN_PLUGIN_DIR}/php_opcache_"

# Remove old symlinks
rm -f /etc/munin/plugins/php_opcache_*

# Create symlinks for each PHP container
if docker ps --format "{{.Names}}" | grep -q -E 'php$'; then
    for container in $(docker ps --format "{{.Names}}" | grep -E 'php$'); do
        echo "Creating symlink for container: $container"
        ln -sf "${MUNIN_PLUGIN_DIR}/php_opcache_" "/etc/munin/plugins/php_opcache_${container}"
    done
else
    echo "Warning: No PHP containers found running"
fi

# Restart munin-node
systemctl restart munin-node

echo "Installation complete!"
echo ""
echo "Test with:"
for container in $(docker ps --format "{{.Names}}" | grep -E 'php$'); do
    echo "  munin-run php_opcache_${container} config"
done