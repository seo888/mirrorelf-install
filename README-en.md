# mirrorelf-install

**MirrorElf** — Docker one-click install repository

> This repo contains **install scripts and Compose only** — **not** application source.  
> Images are published on Docker Hub as [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf).

[中文](README.md) · [English](README-en.md)

---

## Contents

- [Introduction](#introduction)
- [Features](#features)
- [Admin console](#admin-console)
- [Tech stack](#tech-stack)
- [Quick install](#quick-install)
- [After install](#after-install)
- [Operations](#operations)
- [Files in this repo](#files-in-this-repo)

---

## Introduction

**MirrorElf** is a **Rust-based site mirroring engine and SEO operations platform**. A single service (default `:16888`) hosts many domains with real-time mirroring, PostgreSQL dual-layer cache, templated SEO processing, spider analytics, and AI automation. It ships a **Svelte 5 bilingual admin UI** and deploys via Docker with **no compile on the server**.

## Features

### Mirroring & cache

- **Dual-layer cache**: processed pages (`website_cache`) + upstream originals (`target_cache`) with FastCDC + LZ4 block dedup
- Full-site mirroring, preview stream `/-/`, link mapping, path normalization, static asset streaming
- Main site vs wildcard sites, DNS auto-provisioning, random target assignment and reachability probes
- Language detection & HTML translation, page preload (background warm-up of in-page links)

### SEO & content

- TDK templates & tag expressions, head/footer injection, friend-link segments & style templates
- Sitemap / Robots, JSON-LD, SEO 404, external link filtering & random div/class
- **Article CMS**: draft / published / archived; Markdown→HTML into site cache
- **Template center**: edit `templates/web/` online; AI generation; jump from cache to editor

### AI automation

- OpenAI-compatible APIs (multi-model, text/image split, outbound IP pinning)
- **AI cache tasks**: auto queue replace-lines + TDK after cache writes (PostgreSQL-backed queue)
- **AI CHAT** multi-session chat, **AI link wheel** friend-link graph & batch edits
- Cache Meta replace/TDK, template AI generation, Markdown analysis
- **Page Agent**: natural-language control of the admin UI

### Ops & analytics

- Dashboard: site scale, cache overview, system resources, QPS, 7-day/24h spider trends
- Per-engine spider policies (Baidu, Sogou, 360, ByteDance, Bing, Google, etc.); SSE live access logs
- **Site logs hub**: access logs, runtime logs, daily site reports
- **Site query**: batch HTTP checks, search-engine indexing, WHOIS
- **Data collection**: title generator, keyword combiner, article collector
- **Backup & restore**: granular `.mefbackup` export/import (SSE progress); **recycle bin** soft delete & restore
- UA/IP ban, forced domain binding, ad redirects, global code injection, Telegram notifications

### Domain DNS

- **Cloudflare / Gname / Dynadot** integration; Zone & record CRUD
- One-click transfer from Gname/Dynadot to Cloudflare (full record sync)
- Batch A records, WHOIS expiry, linked site counts

## Admin console

Open `http://<host>:16888/_/admin/` (hash routing; zh/en UI, light/dark theme)

| Module | Description |
|--------|-------------|
| Dashboard | Site & cache overview, system metrics, spider QPS & trends |
| Websites | Mirror site CRUD, batch settings, DNS/WHOIS, TDK, preview |
| Site cache | Browse/edit cache, Meta, AI replace, soft delete & restore |
| Articles | Article editor, AI generation, publish/unpublish/republish |
| Targets | Upstream targets + target cache (split view) |
| Files | Online edit `doc/`, `prompt/`, `log/` |
| Templates | HTML/CSS/JS/images; AI generation; image editor |
| Tag docs | Embedded TDK / friend-link tag syntax reference |
| Site query | Batch status/indexing/WHOIS; TSV export |
| Data collection | Title generator, keyword combiner, article collector |
| AI tasks | Cache task queue, parallelism, conversation details |
| AI link wheel | Friend-link graph, ++/-- batch edits, AI analysis |
| AI CHAT | Multi-session chat, attachments, image generation |
| Site logs | Access / runtime logs / daily reports |
| Domain DNS | Cloudflare/Gname/Dynadot accounts & records |
| Backup & restore | `.mefbackup` export/import with progress |
| Recycle bin | Unified restore for sites/targets/cache/files |
| Settings | Visual YAML editor (6 tabs) |

## Tech stack

| Layer | Technology |
|-------|------------|
| Runtime | Rust (Tokio), single binary |
| Web | Axum 0.8, Tower (Brotli/Zstd/Gzip, sessions) |
| Database | PostgreSQL 16 (SQLx async) |
| Cache storage | FastCDC + BLAKE3 + LZ4 block dedup |
| HTTP client | wreq + 256 browser persona pool; multi-IP / proxy |
| HTML | scraper, lol_html, markup_fmt; jieba-rs tokenization |
| Admin UI | Svelte 5 + Vite 8 + TypeScript; Chart.js, CodeMirror 6, AntV G6 |
| AI | OpenAI-compatible APIs; Page Agent natural-language control |
| Auth | axum-login, Argon2, tower-sessions |
| Metrics | Prometheus (`/metrics`, login required) |
| Deploy | Docker / Docker Compose; image [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf) |
| Optional | Watchtower (~10 min Hub poll) |

---

## Quick install

### Requirements

[Docker Engine](https://docs.docker.com/engine/install/) and the **Docker Compose v2** plugin.

### One command

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

### Install options

**Review the script first (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh -o install.sh
less install.sh
bash install.sh
```

**Pin an image tag:**

```bash
MIRRORELF_IMAGE=seo888/mirrorelf:0.9.85 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**Custom install dir (non-interactive):** `MIRRORELF_INSTALL_DIR=/opt/mirrorelf bash install.sh`

On install you will be prompted for a directory; press **Enter** for default `/www/mirrorelf`.

### Data directories

All paths are **bind-mounted on the host** under the install directory:

| Directory | Purpose |
|-----------|---------|
| `config/` | App config (`config.yml`, hot-reload) |
| `log/` | Runtime & access logs (JSONL by day) |
| `data/` | App data (spider counters, backup staging, etc.) |
| `doc/` | Word lists & `target.txt` — editable on host |
| `templates/` | Site HTML templates (`templates/web/`) |
| `prompt/` | AI prompt templates (page-replace, tdk-rules, etc.) |
| `pgdata/` | PostgreSQL data files |
| `_static/` | User static assets (`js/`, `images/`, etc.) |

> The admin UI at `/_/admin` is synced from the image entrypoint on startup and is **not overwritten**.  
> App directories are owned by **uid 10001** (`install.sh` runs `chown` automatically).

<details>
<summary><strong>Troubleshooting</strong></summary>

**Permission denied** — if you see `cp: cannot create regular file 'config/config.yml': Permission denied`:

```bash
cd /www/mirrorelf
sudo chown -R 10001:10001 config log data doc templates prompt _static
sudo chown -R 999:999 pgdata
docker compose -f compose.hub.yml --env-file env.hub up -d
```

**Port conflict** — if host port **5432** is in use, set `MIRRORELF_PG_HOST_PORT=15432` in `env.hub` (the installer may auto-detect and write this).

</details>

## After install

| Item | URL |
|------|-----|
| Site | `http://<host>:16888/` |
| Admin | `http://<host>:16888/_/admin/` |
| Default login | `admin` / `admin` |

> **Change the default password in production.**

---

## Operations

### Watchtower (auto-update)

The installer asks whether to enable Watchtower; **Enter** or `Y` installs it (~10 min Hub poll).

| Variable | Effect |
|----------|--------|
| `MIRRORELF_INSTALL_WATCHTOWER=1` | Non-interactive: install Watchtower |
| `MIRRORELF_INSTALL_WATCHTOWER=0` | Non-interactive: skip |
| `MIRRORELF_SKIP_WATCHTOWER=1` | Legacy alias to skip |

View logs:

```bash
cd /www/mirrorelf
docker compose -f compose.hub.yml --env-file env.hub --profile watchtower logs -f watchtower
```

### Manual install

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

### Full uninstall

Stops containers, **removes volumes** (database included), and optionally deletes the install directory and images.

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

- `curl | bash` prompts via `/dev/tty`; a single detected install dir is auto-selected
- Wrong `MIRRORELF_INSTALL_DIR` in your shell is ignored with a warning
- If you used a custom path, enter it when asked (do not blindly accept `/www/mirrorelf`)

Non-interactive uninstall:

```bash
MIRRORELF_INSTALL_DIR=/www/mirrorelf MIRRORELF_YES=1 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

> Remove any Nginx / WAF upstream pointing at port **16888** on this host manually.

---

## Files in this repo

| File | Purpose |
|------|---------|
| `install.sh` | One-line / local install script |
| `uninstall.sh` | Full uninstall script |
| `compose.hub.yml` | App + Postgres (+ optional Watchtower) |
| `env.hub.example` | Sample `MIRRORELF_IMAGE` |

- Application source code is **not** included; it is maintained privately
- If you fork and change ports/volumes in `compose.hub.yml`, keep the embedded compose in `install.sh` in sync
