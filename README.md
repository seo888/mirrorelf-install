# mirrorelf-install

MirrorElf（镜像精灵）Docker 一键安装仓库。

> 本仓库**仅含**安装脚本与 Compose，**不含**业务源码。程序以 Docker Hub 镜像 [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf) 分发。

[English](#english) · [中文](#中文)

---

## 中文

### 产品简介

MirrorElf（镜像精灵）是面向 **网站镜像、缓存与 SEO 运营** 的自托管平台：实时同步目标站、将页面缓存到 PostgreSQL，并提供现代化管理后台，用于站点配置、TDK/AI 改写、蜘蛛统计、数据采集与批量运维。

### 核心优势

- **实时镜像** — 内置 `/-/` 代理拉取并缓存目标页，适合迁移、备份与多站托管
- **完整管理后台** — Svelte 单页应用（`/_/admin/`）：网站、缓存、目标站、文件、站点检测、数据采集
- **AI 就绪** — 兼容 OpenAI 接口；正文提取、TDK 生成、替换行建议与网站缓存流程联动
- **SEO 与蜘蛛** — QPS/最近访问、sitemap、蜘蛛策略、指定出口 IP
- **运维友好** — Docker Compose 一键起服务（应用 + Postgres）；可选 Watchtower 跟随 Hub 自动更新
- **服务器无需编译** — 拉取预构建镜像即可；配置与数据保存在 Docker 卷

### 技术栈

| 层级 | 技术 |
|------|------|
| 运行时 | Rust（Tokio），单二进制部署 |
| Web 框架 | Axum、Tower（压缩、会话等） |
| 数据库 | PostgreSQL 16（Compose 官方镜像） |
| 数据访问 | SQLx（异步 Postgres） |
| 出站 HTTP | Reqwest（rustls），支持多 IP / 代理场景 |
| 页面处理 | scraper、lol_html、markup_fmt；分块缓存（lz4、fastcdc 等） |
| 管理端 | Svelte 5 + Vite（构建进镜像 `/_/admin/`） |
| 认证 | axum-login、Argon2、tower-sessions |
| 监控 | Prometheus 指标（axum-prometheus） |
| 部署 | Docker / Docker Compose；镜像发布于 Docker Hub |
| 可选组件 | Watchtower（约每 10 分钟检查 Hub 更新） |

### 快速安装

**前置条件：** 已安装 [Docker](https://docs.docker.com/engine/install/) 与 **docker compose** 插件。

**一条命令：**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**建议先查看脚本再执行：**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh -o install.sh
less install.sh
bash install.sh
```

**指定镜像版本：**

```bash
MIRRORELF_IMAGE=seo888/mirrorelf:0.9.27 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

安装时会提示安装目录，**直接回车** 默认为 `/www/mirrorelf`（`compose.hub.yml`、`env.hub` 写在该目录）。也可输入自定义路径，或非交互：`MIRRORELF_INSTALL_DIR=/opt/mirrorelf bash install.sh`。

### 安装完成后

| 项目 | 地址 |
|------|------|
| 站点 | `http://<服务器IP>:18888/` |
| 管理后台 | `http://<服务器IP>:18888/_/admin/` |
| 默认账号 | `admin` / `admin`（**生产环境请立即修改**） |

### Watchtower 自动更新

```bash
cd /www/mirrorelf   # 或你选择的安装目录
docker compose -f compose.hub.yml --env-file env.hub --profile watchtower up -d
```

启用后约每 10 分钟检查 Docker Hub 上的 `latest`，并重建带 `watchtower.enable` 标签的 `app` 容器。

### 手动安装

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

### 目录说明

| 文件 | 说明 |
|------|------|
| `install.sh` | 一键安装脚本 |
| `compose.hub.yml` | 应用 + Postgres（可选 Watchtower profile） |
| `env.hub.example` | 镜像名示例 `MIRRORELF_IMAGE` |

### 说明

- 本仓库不包含 MirrorElf 业务源码；源码为私有维护。
- 修改 `compose.hub.yml` 端口/卷时，若维护 fork，请同步 `install.sh` 内嵌 compose 段落。

---

## English

### Introduction

**MirrorElf** is a self-hosted **website mirroring and SEO operations platform**. It syncs target sites in real time, caches pages in PostgreSQL, and ships a modern admin UI for site management, TDK/AI workflows, spider analytics, data collection, and batch operations.

### Key features

- **Real-time mirroring** — Built-in `/-/` proxy fetch and cache; suited for migration, backup, and multi-site hosting
- **Full admin console** — Svelte SPA at `/_/admin/`: websites, caches, targets, files, site checks, data collection
- **AI-ready** — OpenAI-compatible APIs; plain-text extraction, TDK generation, replace-line suggestions tied to cache workflows
- **SEO & spiders** — QPS/recent visits, sitemap, bot policies, configurable outbound IPs
- **Simple ops** — One Compose stack (app + Postgres); optional Watchtower updates from Docker Hub
- **No compile on server** — Pull a pre-built image; config and data live in Docker volumes

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

### After install

| Item | URL |
|------|-----|
| Site | `http://<host>:18888/` |
| Admin | `http://<host>:18888/_/admin/` |
| Default login | `admin` / `admin` — **change in production** |

### Watchtower (auto-update)

```bash
cd /www/mirrorelf   # or your chosen install path
docker compose -f compose.hub.yml --env-file env.hub --profile watchtower up -d
```

Polls Docker Hub about every 10 minutes and recreates the `app` container when `latest` changes.

### Manual install

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

### Files in this repo

| File | Purpose |
|------|---------|
| `install.sh` | One-line / local install script |
| `compose.hub.yml` | App + Postgres (+ optional Watchtower) |
| `env.hub.example` | Sample `MIRRORELF_IMAGE` |

### Notes

- Application source code is **not** included; it is maintained privately.
- If you fork and change ports/volumes in `compose.hub.yml`, keep the embedded compose in `install.sh` in sync.
