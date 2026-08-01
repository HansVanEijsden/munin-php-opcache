# AGENTS.md

Guidelines for AI coding agents working in this repository.

## Project Overview

`munin-php-opcache` is a [Munin](https://munin-monitoring.org/) plugin that monitors PHP OPcache statistics per Docker container. The entire plugin is a single bash script (`plugin/php_opcache_`) that Munin invokes via one symlink per running PHP container (`php_opcache_<container>`).

## Build & Test

Install/uninstall/update require `sudo` and are driven by the Makefile or the shell scripts:

```bash
make install    # sudo bash install.sh  — copies plugin, creates symlinks, restarts munin-node
make uninstall  # sudo bash uninstall.sh
make update     # git pull origin main && sudo bash install.sh
make test       # runs munin-run config + data against every running *php* container
make clean      # git clean -fdX
```

Manual test of a single container:

```bash
munin-run php_opcache_<container> config
munin-run php_opcache_<container>
```

These require a running container using the custom PHP image and a live `/run/php/<container>.sock` socket. See [README.md](README.md) for install prerequisites.

## Architecture

- `plugin/php_opcache_` — the only plugin source file. Munin invokes it through a symlink named `php_opcache_<container>`.
- The container name is derived from the plugin's own invocation name (`${0##*/}`, strip the `php_opcache_` prefix), so **no per-container config files exist**.
- Output is Munin **multigraph**: three graphs per run — `memory`, `keys`, `interned_strings`.
- Stats come from a FastCGI endpoint in a custom PHP Docker image (<https://github.com/HansVanEijsden/php-wordpress-base>) via `cgi-fcgi`, **not** from the `php`/`opcache` CLI.
- JSON parsing prefers `jq`, with a `grep`/`sed` fallback (see `parse_json` / `parse_nested_json`).

### Naming conversions (critical, non-obvious)

| Step | Example | Conversion | Used for |
| --- | --- | --- | --- |
| Invocation name → container | `php_opcache_wordpress-php` | strip `php_opcache_` | container name |
| Container → socket | `wordpress-php` | `_` → `-` | `/run/php/<container>.sock` |
| Container → Munin-safe name | `wordpress-php` | `-` → `_` | `multigraph php_opcache_memory_<safe>` |

Symlink layout: `/etc/munin/plugins/php_opcache_<container>` → `/usr/share/munin/plugins/php_opcache_`.

## Conventions

- Bash scripts; the install/uninstall/update scripts use `set -e`.
- Code comments are in **English** — the project is public and targets a worldwide audience, so no Dutch in code or docs.
- Munin output format: every graph sets `graph_title`, `graph_vlabel`, `graph_category php-opcache`, `graph_order`, and per field `.label`, `.type GAUGE`, `.min`, `.draw`, `.colour`, plus `.warning`/`.critical` where relevant.
- A `.warning`/`.critical` value with a **trailing colon** means "alert if value is **below** N" — used for free-memory / free-keys thresholds.
- If stats are unavailable, the plugin falls back to defaults: total memory 256 MiB, max keys 16229, interned-strings buffer 32 MiB.
- `make test` and `install.sh` auto-detect containers whose names end in `php` (regex `php$`).

## Pitfalls

- Install scripts must run as root; `make` targets invoke `sudo` internally.
- Requires `docker` and `cgi-fcgi` (`libfcgi0ldbl`); `jq` is optional but recommended (fallback is slower).
- The `munin` user needs Docker access (e.g. added to the `docker` group) or plugins fail silently.
- Only works with the custom PHP Docker image exposing the OPcache FastCGI endpoint — not with stock PHP images.
- The plugin exits 1 with a message on stderr when the container or socket is missing.
