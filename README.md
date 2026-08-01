# Munin PHP OPcache Monitor

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A [Munin](https://munin-monitoring.org/) plugin that monitors PHP OPcache statistics per Docker container.

## Features

- Separate graphs per container
- Memory usage (used / free / wasted / total)
- Keys usage (cached / free / max)
- Interned strings buffer usage
- Automatic container detection
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

1. Copy the plugin to `/usr/share/munin/plugins/`
2. Create a symlink in `/etc/munin/plugins/` for every running container whose name ends in `php`
3. Restart `munin-node`

### Docker access for the munin user

The `munin` user needs permission to run Docker commands, or the plugin will fail silently:

```bash
sudo usermod -aG docker munin
```

## Usage

Munin executes the plugin automatically. Each PHP container gets its own symlink:

```text
/etc/munin/plugins/php_opcache_<container> -> /usr/share/munin/plugins/php_opcache_
```

The container name is derived from the symlink's own name, so **no per-container configuration is needed**. Underscores in the container name are converted back to dashes to locate the FastCGI socket at `/run/php/<container>.sock`; dashes in the container name become underscores in the Munin graph names (Munin-safe).

Test a single container manually:

```bash
sudo munin-run php_opcache_<container> config
sudo munin-run php_opcache_<container>
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
make test   # runs munin-run config + data against every running *php* container
```

## License

This project is licensed under the [MIT License](LICENSE).
