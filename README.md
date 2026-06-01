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
sudo git clone https://github.com/hansvaneijsden/munin-php-opcache.git
cd munin-php-opcache
sudo ./install.sh

## Note:

This package relies on the `docker` command being available to the user running the Munin plugins (usually `munin`). Ensure that the `munin` user has permission to execute Docker commands, which may involve adding it to the `docker` group:

```bash
sudo usermod -aG docker munin
```

Must be used with my custom PHP Docker image that exposes OPcache stats via a simple HTTP endpoint. See https://github.com/HansVanEijsden/php-wordpress-base