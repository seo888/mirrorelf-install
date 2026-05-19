# mirrorelf-install

**MirrorElf / 镜像精灵** — Docker one-line install · Docker 一键安装

> This repository contains **only** install scripts and Compose files.  
> Application images are published on Docker Hub; **source code is not public**.  
> 本仓库**仅含**安装脚本与 Compose，**不含**业务源码；程序以镜像 `seo888/mirrorelf` 分发。

---

## About MirrorElf · 产品简介

**EN** — MirrorElf is a self-hosted **website mirroring & SEO operations platform**. It clones target sites in real time, caches pages in PostgreSQL, and provides a modern admin UI for site management, TDK/AI rewrite, spider analytics, keyword/article collection, and batch tooling.

**中文** — MirrorElf（镜像精灵）是面向 **网站镜像、缓存与 SEO 运营** 的自托管平台：实时同步目标站、数据库缓存页面，并提供管理后台完成站点配置、TDK/AI 改写、蜘蛛统计、数据采集与批量运维。

**Docker image:** [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf)

---

## Key advantages · 核心优势

| EN | 中文 |
|----|------|
| **Real-time mirroring** — Stream and cache target pages via built-in proxy (`/-/`), suitable for migration, backup, and multi-site hosting | **实时镜像** — 内置 `/-/` 代理拉取并缓存，适合迁移、备份与多站托管 |
| **Full admin console** — Svelte SPA at `/_/admin/`: websites, caches, targets, files, site health checks, data collection | **完整管理后台** — Svelte 单页应用：网站/缓存/目标站/文件/站点检测/数据采集 |
| **AI-ready** — OpenAI-compatible APIs; HTML→plain text, TDK generation, replace-line suggestions tied to cache workflows | **AI 就绪** — 兼容 OpenAI 接口；正文提取、TDK 生成、替换行建议与缓存流程联动 |
| **SEO & spider tooling** — Spider QPS/recent visits, sitemap, configurable bot policies, outbound IP control | **SEO 与蜘蛛** — QPS/最近访问、sitemap、蜘蛛策略、指定出口 IP |
| **Ops-friendly deploy** — Single Compose stack (app + Postgres); optional Watchtower auto-update from Hub | **运维友好** — Compose 一键起服务；可选 Watchtower 自动跟 Hub 更新 |
| **No build on server** — Pull pre-built image; config/data in Docker volumes | **服务器无需编译** — 拉取镜像即可；配置与数据落在卷里 |

---

## Tech stack · 技术栈

| Layer · 层级 | Technology · 技术 |
|--------------|-------------------|
| **Runtime · 运行时** | Rust (Tokio), single binary · 单二进制 |
| **Web · Web 框架** | [Axum](https://github.com/tokio-rs/axum), Tower (HTTP/2, compression, sessions) |
| **Database · 数据库** | PostgreSQL 16 (official image in Compose) |
| **Data access · 数据访问** | SQLx (async Postgres) |
| **HTTP client · 出站** | Reqwest (rustls), multi-IP / proxy-friendly |
| **HTML · 页面处理** | scraper, lol_html, markup_fmt; CDC/chunk cache (lz4, fastcdc) |
| **Admin UI · 管理端** | Svelte 5 + Vite (built into image under `/_/admin/`) |
| **Auth · 认证** | axum-login, Argon2, tower-sessions |
| **Metrics · 监控** | Prometheus metrics (axum-prometheus) |
| **Deploy · 部署** | Docker / Docker Compose; image on Docker Hub |
| **Optional · 可选** | Watchtower (Hub image updates, 10 min poll) |

---

## Quick install · 快速安装

**Requirements · 前置条件:** [Docker Engine](https://docs.docker.com/engine/install/) + **Docker Compose v2** plugin.

### One command · 一条命令

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**Review before run · 建议先查看脚本:**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh -o install.sh
less install.sh    # or: cat install.sh
bash install.sh
```

### Pin image version · 指定镜像版本

```bash
MIRRORELF_IMAGE=seo888/mirrorelf:0.9.27 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

Install files default to `~/.mirrorelf/` (override with `MIRRORELF_INSTALL_DIR`).

安装文件默认写入 `~/.mirrorelf/`（可用 `MIRRORELF_INSTALL_DIR` 覆盖）。

---

## After install · 安装完成后

| Item · 项目 | URL / 说明 |
|-------------|------------|
| Site · 站点 | `http://<host>:18888/` |
| Admin · 管理后台 | `http://<host>:18888/_/admin/` |
| Default login · 默认账号 | `admin` / `admin` — **change immediately in production · 生产环境请立即修改** |

---

## Watchtower (auto-update) · 自动更新

Enables periodic pull of `seo888/mirrorelf:latest` and recreate of the `app` container (labeled for Watchtower).

启用后约每 **10 分钟** 检查 Hub 并重建 `app` 容器：

```bash
cd ~/.mirrorelf
docker compose -f compose.hub.yml --env-file env.hub --profile watchtower up -d
```

---

## Manual install · 手动安装

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

---

## Repository layout · 目录说明

| File | Purpose |
|------|---------|
| `install.sh` | One-line / local install script |
| `compose.hub.yml` | App + Postgres (+ optional Watchtower profile) |
| `env.hub.example` | Example `MIRRORELF_IMAGE` |

---

## Notes · 说明

- **EN:** This repo does not include MirrorElf application source. For issues with the running product, use your private support channel or image tags on Docker Hub.  
- **中文:** 业务源码私有维护；运行问题请走内部支持或查阅 Hub 镜像版本说明。  
- When changing ports/volumes in `compose.hub.yml`, keep `install.sh` embedded compose in sync if you maintain a fork.

---

## License & branding

MirrorElf / mirrorelf — install artifacts in this repo are provided as-is for deployment convenience.
