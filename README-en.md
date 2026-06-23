# mirrorelf-install

MirrorElf Docker one-click install repository.

> This repo contains **install scripts and Compose only** — **not** application source. Images are published on Docker Hub as [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf).

[中文](README.md)

---

### Introduction

**MirrorElf** is a self-hosted **website mirroring and SEO operations platform**. It syncs target sites in real time, caches pages in PostgreSQL, and ships a modern admin UI for site management, TDK/AI workflows, spider analytics, data collection, and batch operations.

### Key features

- **Real-time mirroring** — Built-in `/-/` proxy fetch and cache; suited for migration, backup, and multi-site hosting
- **Full admin console** — Svelte SPA at `/_/admin/`: websites, caches, targets, files, site checks, data collection
- **AI-ready** — OpenAI-compatible APIs; plain-text extraction, TDK generation, replace-line suggestions tied to cache workflows
- **SEO & spiders** — QPS/recent visits, sitemap, bot policies, configurable outbound IPs
- **Simple ops** — One Compose stack (app + Postgres); optional Watchtower updates from Docker Hub
- **No compile on server** — Pull a pre-built image; config and data live in host bind mounts under the install directory

### Tech stack

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

### Quick install

**Requirements:** [Docker Engine](https://docs.docker.com/engine/install/) and the **Docker Compose v2** plugin.

**One command:**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**Review the script first (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh -o install.sh
less install.sh
bash install.sh
```

**Pin an image tag:**

```bash
MIRRORELF_IMAGE=seo888/mirrorelf:0.9.27 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

On install you will be prompted for a directory; press **Enter** for default `/www/mirrorelf`, or set `MIRRORELF_INSTALL_DIR` for non-interactive installs.

Data directories are **bind-mounted on the host** (under the install directory): `config/`, `log/`, `data/`, `doc/`, `templates/`, `pgdata/` (database), `_static/` (user static assets). The admin UI at `/_/admin` is synced from the image entrypoint on startup. App directories are owned by **uid 10001** (`install.sh` runs `chown` automatically).

**If you see `cp: cannot create regular file 'config/config.yml': Permission denied`:**

```bash
cd /www/mirrorelf
sudo chown -R 10001:10001 config log data doc templates _static
sudo chown -R 999:999 pgdata
docker compose -f compose.hub.yml --env-file env.hub up -d
```

If port **5432** is already in use, set `MIRRORELF_PG_HOST_PORT=15432` in `env.hub` (the installer may auto-detect and write this).

### After install

| Item | URL |
|------|-----|
| Site | `http://<host>:16888/` |
| Admin | `http://<host>:16888/_/admin/` |
| Default login | `admin` / `admin` — **change in production** |

### Watchtower (auto-update)

The installer asks whether to enable Watchtower; **Enter** or `Y` installs it (~10 min Hub poll).

Non-interactive: `MIRRORELF_INSTALL_WATCHTOWER=1` or `0`; `MIRRORELF_SKIP_WATCHTOWER=1` skips Watchtower.

View logs: `docker compose -f compose.hub.yml --env-file env.hub --profile watchtower logs -f watchtower` (from your install directory).

### Manual install

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

### Full uninstall

Stops containers, **removes volumes** (database included), and optionally deletes the install directory and images. Prompts default to **Yes** on Enter.

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

`curl | bash` prompts via `/dev/tty`; a single detected install dir is auto-selected. Wrong `MIRRORELF_INSTALL_DIR` in your shell is ignored with a warning.

If you used a custom install path, enter it when asked (do not blindly accept `/www/mirrorelf`). Non-interactive needs a unique detected path or `MIRRORELF_INSTALL_DIR`:

```bash
MIRRORELF_INSTALL_DIR=/www/mirrorelf MIRRORELF_YES=1 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

Remove any Nginx / WAF upstream pointing at port **16888** on this host manually.

### Files in this repo

| File | Purpose |
|------|---------|
| `install.sh` | One-line / local install script |
| `uninstall.sh` | Full uninstall script |
| `compose.hub.yml` | App + Postgres (+ optional Watchtower) |
| `env.hub.example` | Sample `MIRRORELF_IMAGE` |

### Notes

- Application source code is **not** included; it is maintained privately.
- If you fork and change ports/volumes in `compose.hub.yml`, keep the embedded compose in `install.sh` in sync.
