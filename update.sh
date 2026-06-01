#!/bin/bash
# Update script - pull latest from git and reinstall
# Location: /usr/local/src/munin-php-opcache/update.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Updating Munin PHP OPcache plugin..."

# Pull latest changes
cd "$SCRIPT_DIR"
git pull origin main

# Reinstall
sudo bash install.sh

echo "Update complete!"