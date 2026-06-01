# Munin PHP OPcache Monitor

Monitor OPcache statistics per PHP Docker container.

## Features
- Separate graphs per container
- Memory usage (used/free/wasted/total)
- Keys usage (cached/max/free)
- Automatic container detection

## Installation on Munin server

```bash
cd /usr/local/src
sudo git clone https://github.com/YOUR_USERNAME/munin-php-opcache.git
cd munin-php-opcache
sudo ./install.sh