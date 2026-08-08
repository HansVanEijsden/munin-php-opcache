# AGENTS.md

Guidelines for AI coding agents working in this repository.

## Project Overview

`munin-php-opcache` is a [Munin](https://munin-monitoring.org/) plugin that monitors PHP OPcache statistics per Docker container. The entire plugin is a single bash script (`plugin/php_opcache_multi`) installed as one symlink (`php_opcache_multi`) that auto-discovers every running container exposing a FastCGI socket — no per-container symlinks.

## Build & Test

Install/uninstall/update require `sudo` and are driven by the Makefile or the shell scripts:

```bash
make install    # sudo bash install.sh  — copies plugin, creates symlinks, restarts munin-node
make uninstall  # sudo bash uninstall.sh
make update     # git pull origin main && sudo bash install.sh
make test       # runs munin-run config + data for the php_opcache_multi plugin
make clean      # git clean -fdX
```

Manual test:

```bash
munin-run php_opcache_multi config | head -15
munin-run php_opcache_multi | head -15
```

These require a running container using the custom PHP image and a live `/run/php/<container>.sock` socket. See [README.md](README.md) for install prerequisites.

## Architecture

- `plugin/php_opcache_multi` — the only plugin source file. Munin invokes it via a single symlink `/etc/munin/plugins/php_opcache_multi`.
- On every poll the plugin lists running containers once (`docker ps`), keeps those exposing `/run/php/<name>.sock`, and queries each socket once via `cgi-fcgi` — a huge reduction in subprocess spawns vs the old one-process-per-container layout.
- Output is Munin **multigraph**: three graphs per container — `memory`, `keys`, `interned_strings`.
- Stats come from a FastCGI endpoint in a custom PHP Docker image (<https://github.com/HansVanEijsden/php-wordpress-base>) via `cgi-fcgi`, **not** from the `php`/`opcache` CLI.
- JSON parsing prefers `jq`, with a `grep`/`sed` fallback (see `parse_json` / `parse_nested_json`).
- Graph names are byte-for-byte identical to v1.x, so existing RRDs survive an upgrade.

### Naming conversions (critical, non-obvious)

| Step | Example | Conversion | Used for |
| --- | --- | --- | --- |
| Container → socket | `wordpress-php` | (as-is) | `/run/php/<container>.sock` |
| Container → Munin-safe name | `wordpress-php` | `-` → `_` | `multigraph php_opcache_memory_<safe>` |

Symlink layout: `/etc/munin/plugins/php_opcache_multi` → `/usr/share/munin/plugins/php_opcache_multi`.

## Conventions

- Bash scripts; the install/uninstall/update scripts use `set -e`.
- Code comments are in **English** — the project is public and targets a worldwide audience, so no Dutch in code or docs.
- Munin output format: every graph sets `graph_title`, `graph_vlabel`, `graph_category php-opcache`, `graph_order`, and per field `.label`, `.type GAUGE`, `.min`, `.draw`, `.colour`, plus `.warning`/`.critical` where relevant.
- A `.warning`/`.critical` value with a **trailing colon** means "alert if value is **below** N" — used for free-memory / free-keys thresholds.
- If stats are unavailable, the plugin falls back to defaults: total memory 256 MiB, max keys 16229, interned-strings buffer 32 MiB.
- `install.sh` and the plugin discover containers via `docker ps` + FastCGI socket presence (`/run/php/<name>.sock`), not by name suffix.

## Pitfalls

- Install scripts must run as root; `make` targets invoke `sudo` internally.
- Requires `docker` and `cgi-fcgi` (`libfcgi0ldbl`); `jq` is optional but recommended (fallback is slower).
- The `munin` user needs Docker access (e.g. added to the `docker` group) or plugins fail silently.
- Only works with the custom PHP Docker image exposing the OPcache FastCGI endpoint — not with stock PHP images.
- The multi plugin silently skips containers that are stopped or lack a socket (no per-container errors). If no containers match, it outputs nothing — only install it on hosts that run the custom PHP image.
