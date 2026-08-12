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
- JSON parsing prefers `jq`, with a `grep`/`sed` fallback (see `parse_all` — one `jq` call per container, or an inline `grep`/`sed` path when `jq` is absent).
- The interned-strings graph reads `interned_strings_usage.{used,free}_memory` — v2.0.1 fixed a bug where it read the full OPcache `memory_usage` values instead (graphs showed whole-cache memory).
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

## Alerts & thresholds (reading Munin emails)

Thresholds are computed at `config` time from current stats (fallback totals apply only when stats are missing):

| Field | Threshold | Meaning |
| --- | --- | --- |
| `free` | none (since v2.0.2) | low free memory is normal — OPcache keeps memory ~full and auto-restarts; deliberately no alert |
| `used_perc.warning` / `.critical` | 95 / 98 | high used percentage |
| `wasted_perc.critical` | 30 | wasted memory > 30% — the only alert implying real manual intervention |
| interned `free.warning` / `.critical` | 10% / 5% of buffer | interned-strings buffer nearly full |

Fallback totals (256 MiB, 16229 keys, 32 MiB) apply when stats are unavailable. Historical note: pre-v2.0.2 the memory graph alerted at `free.critical` = 1% of total (`total*1/100`, trailing colon), and 1% of the 256 MiB fallback = `2684354` — that exact number was seen in old "Free memory is N (outside range [X:])" alert emails. v2.0.2 removed this alert because it fired on every full-but-healthy OPcache.

**OPcache semantics — low free memory is NOT a fault.** OPcache deliberately keeps memory ~full. "Wasted" memory is old script versions left behind after plugin/core updates. When wasted % exceeds `opcache.max_wasted_percentage` (default 5%), OPcache **auto-restarts the cache** (full invalidation, all memory reclaimed, re-cached on demand) — the designed safety valve. Since v2.0.2 the plugin never alerts on low free memory (the graph still shows it); don't "fix" it by raising `opcache.memory_consumption` or treating it as a leak. Only `wasted_perc.critical` (>30%) indicates memory is not being reclaimed.

## Pitfalls

- Install scripts must run as root; `make` targets invoke `sudo` internally.
- Requires `docker` and `cgi-fcgi` (`libfcgi0ldbl`); `jq` is optional but recommended (fallback is slower).
- The `munin` user needs Docker access (e.g. added to the `docker` group) or plugins fail silently.
- Only works with the custom PHP Docker image exposing the OPcache FastCGI endpoint — not with stock PHP images.
- The multi plugin silently skips containers that are stopped or lack a socket (no per-container errors). If no containers match, it outputs nothing — only install it on hosts that run the custom PHP image.
