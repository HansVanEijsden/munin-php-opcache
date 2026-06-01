#!/bin/bash
# Uninstall script
# Location: /usr/local/src/munin-php-opcache/uninstall.sh

set -e

echo "Removing Munin PHP OPcache plugin..."

# Remove symlinks
rm -f /etc/munin/plugins/php_opcache_*

# Remove plugin
rm -f /usr/share/munin/plugins/php_opcache_

# Restart munin-node
systemctl restart munin-node

echo "Uninstall complete!"