# mirrorelf-install

**MirrorElf** — Docker one-click install repository

> This repo contains **install scripts and Compose only** — **not** application source.  
> Images are published on Docker Hub as [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf).

[中文](README.md) · [English](README-en.md)

---

## Contents

- [Introduction](#introduction)
- [Key features](#key-features)
- [Tech stack](#tech-stack)
- [Quick install](#quick-install)
- [After install](#after-install)
- [Operations](#operations)
- [Files in this repo](#files-in-this-repo)

---

## Introduction

**MirrorElf** is a self-hosted **website mirroring and SEO operations platform**. It syncs target sites in real time, caches pages in PostgreSQL, and ships a modern admin UI for site management, TDK/AI workflows, spider analytics, data collection, and batch operations.

## Key features

| | |
|---|---|
| **Real-time mirroring** | Built-in `/-/` proxy fetch and cache; suited for migration, backup, and multi-site hosting |
| **Full admin console** | Svelte SPA at `/_/admin/`: websites, caches, targets, files, site checks, data collection |
| **AI-ready** | OpenAI-compatible APIs; plain-text extraction, TDK generation, replace-line suggestions |
| **SEO & spiders** | QPS/recent visits, sitemap, bot policies, configurable outbound IPs |
| **Simple ops** | One Compose stack (app + Postgres); optional Watchtower updates from Docker Hub |
| **No compile on server** | Pull a pre-built image; config and data live in host bind mounts |

## Tech stack

| Layer | Technology |
|-------|------------|
| Runtime | Rust (Tokio), single binary |
| Web | Axum, Tower (compression, sessions, etc.) |
| Database | PostgreSQL 16 (official Compose image) |
| Data access | SQLx (async Postgres) |
| HTTP client | Reqwest (rustls), multi-IP / proxy friendly |
| HTML | scraper, lol_html, markup_fmt; chunked cache (lz4, fastcdc, …) |
| Admin UI | Svelte 5 + Vite (served at `/_/admin/` in the image) |
| Auth | axum-login, Argon2, tower-sessions |
| Metrics | Prometheus (axum-prometheus) |
| Deploy | Docker / Docker Compose; images on Docker Hub |
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

| Scenario | Command |
|----------|---------|
| Review script first | `curl -fsSL …/install.sh -o install.sh` → `less install.sh` → `bash install.sh` |
| Pin an image tag | `MIRRORELF_IMAGE=seo888/mirrorelf:0.9.27 curl -fsSL …/install.sh \| bash` |
| Custom install dir | `MIRRORELF_INSTALL_DIR=/opt/mirrorelf bash install.sh` |

On install you will be prompted for a directory; press **Enter** for default `/www/mirrorelf`.

### Data directories

All paths are **bind-mounted on the host** under the install directory:

| Directory | Purpose |
|-----------|---------|
| `config/` | App configuration (`config.yml`, etc.) |
| `log/` | Runtime logs |
| `data/` | Application data |
| `doc/` | Docs and `target.txt` — editable on host |
| `templates/` | HTML templates |
| `pgdata/` | PostgreSQL data files |
| `_static/` | User static assets (`js/`, `images/`, etc.) |

> The admin UI at `/_/admin` is synced from the image entrypoint on startup and is **not overwritten**.  
> App directories are owned by **uid 10001** (`install.sh` runs `chown` automatically).

<details>
<summary><strong>Troubleshooting</strong></summary>

**Permission denied** — if you see `cp: cannot create regular file 'config/config.yml': Permission denied`:

```bash
cd /www/mirrorelf
sudo chown -R 10001:10001 config log data doc templates _static
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
