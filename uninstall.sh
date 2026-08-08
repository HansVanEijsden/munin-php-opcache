#!/bin/bash
# Uninstall script
# Location: /usr/local/src/munin-php-opcache/uninstall.sh

set -e

echo "Removing Munin PHP OPcache plugin..."

# Remove plugin symlinks (multi + any legacy per-container ones)
rm -f /etc/munin/plugins/php_opcache_*

# Remove plugins (multi + legacy wildcard)
rm -f /usr/share/munin/plugins/php_opcache_multi
rm -f /usr/share/munin/plugins/php_opcache_

# Restart munin-node
systemctl restart munin-node

echo "Uninstall complete!"