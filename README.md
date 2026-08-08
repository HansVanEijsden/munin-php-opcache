# Munin PHP OPcache Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A [Munin](https://munin-monitoring.org/) plugin that monitors PHP OPcache statistics per Docker container.

## Features

- Separate graphs per container
- Memory usage (used / free / wasted / total)
- Keys usage (cached / free / max)
- Interned strings buffer usage
- Automatic container detection (any container exposing `/run/php/<name>.sock`)
- Single process for all containers (v2.0.0) — one `docker ps`, one FastCGI query per container
- Pure bash implementation — no PHP CLI dependency (`jq` with `grep`/`sed` fallback)

## Requirements

- A Linux host running Munin (or `munin-node`) with `docker`
- `cgi-fcgi` (package `libfcgi0ldbl`)
- `jq` — optional but recommended for faster JSON parsing
- The [custom PHP Docker image](https://github.com/HansVanEijsden/php-wordpress-base) that exposes OPcache statistics via a FastCGI endpoint

> **Note:** This plugin only works with the custom PHP Docker image mentioned above. It does **not** work with stock PHP images.

## Installation

```bash
cd /usr/local/src
sudo git clone https://github.com/hansvaneijsden/munin-php-opcache.git
cd munin-php-opcache
sudo bash install.sh
```

The installer will:

1. Copy `plugin/php_opcache_multi` to `/usr/share/munin/plugins/`
2. Create a single symlink `/etc/munin/plugins/php_opcache_multi` (containers are auto-discovered at every poll)
3. Remove any legacy per-container `php_opcache_*` symlinks from v1.x
4. Restart `munin-node`

### Docker access for the munin user

The `munin` user needs permission to run Docker commands, or the plugin will fail silently:

```bash
sudo usermod -aG docker munin
```

## Usage

Munin executes the plugin automatically. A single plugin process (`php_opcache_multi`)
discovers every running container that exposes a FastCGI socket at `/run/php/<container>.sock`
on each poll — **no per-container symlinks or configuration needed**. Dashes in container
names become underscores in the Munin graph names (Munin-safe).

Test manually:

```bash
sudo munin-run php_opcache_multi config | head -15
sudo munin-run php_opcache_multi | head -15
```

### Graphs

The plugin outputs three [multigraph](https://munin-monitoring.org/wiki/notes_on_multigraph_monitoring) sections per run:

| Graph | Description |
| --- | --- |
| `php_opcache_memory_<container>` | Used, free, wasted and total OPcache memory, plus used/wasted percentages |
| `php_opcache_keys_<container>` | Cached, free and maximum OPcache keys |
| `php_opcache_interned_strings_<container>` | Used, free and total interned strings buffer |

## Update & Uninstall

```bash
make update      # git pull origin main && sudo bash install.sh
make uninstall   # sudo bash uninstall.sh
```

## Development & Testing

```bash
make test   # runs munin-run config + data for the php_opcache_multi plugin
```

## Upgrading from v1.x

v2.0.0 replaced the per-container symlinks (`php_opcache_<container>`) with a single
auto-discovering plugin (`php_opcache_multi`). Graph names are unchanged, so existing
RRD data is preserved when you run `install.sh`. If you still have v1.x symlinks,
`install.sh` removes them automatically.

## License

This project is licensed under the [MIT License](LICENSE).
