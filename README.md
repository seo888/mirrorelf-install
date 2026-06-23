# mirrorelf-install

MirrorElf（镜像精灵）Docker 一键安装仓库。

> 本仓库**仅含**安装脚本与 Compose，**不含**业务源码。程序以 Docker Hub 镜像 [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf) 分发。

[English](README-en.md)

## 📌 导航

标签文档 → [Mirror-Elf® 标签文档](https://dynalist.io/d/pDZjfOHDp4AefwWeQT1MIgn3#theme=light)

---

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

数据目录**直接映射到宿主机**（与 compose 同目录）：`config/`、`log/`、`data/`、`doc/`、`templates/`、`pgdata/`（数据库）、`_static/`（用户自写静态资源，含 `js/`、`images/`）。可直接编辑 `doc/target.txt`、模板 HTML 等；Watchtower 换镜像后仍会保留。管理后台 `/_/admin` 由镜像 entrypoint 同步，不会被覆盖。应用目录属主为 **uid 10001**（`install.sh` 会自动 `chown`）。

**若启动报 `cp: cannot create regular file 'config/config.yml': Permission denied`：**

```bash
cd /www/mirrorelf   # 你的安装目录
sudo chown -R 10001:10001 config log data doc templates _static
sudo chown -R 999:999 pgdata
docker compose -f compose.hub.yml --env-file env.hub up -d
```

仍失败时，用当前镜像里的 uid 修正（旧镜像 uid 可能不是 10001）：

```bash
uid=$(docker run --rm --entrypoint id seo888/mirrorelf:latest mirrorelf | sed -n 's/uid=\([0-9]*\).*/\1/p')
sudo chown -R "${uid}:${uid}" config log data doc templates _static
```

若宿主机 **5432** 已被占用（如 1Panel 的 PostgreSQL），在 `env.hub` 中设置 `MIRRORELF_PG_HOST_PORT=15432`（安装脚本检测到占用时会自动写入 15432）。容器启动时会自动把卷内 `config.yml` 的数据库地址改为 `127.0.0.1:该端口`，密码与 compose 中 Postgres 一致（`mirrorelf`）。

### 安装完成后

| 项目 | 地址 |
|------|------|
| 站点 | `http://<服务器IP>:16888/` |
| 管理后台 | `http://<服务器IP>:16888/_/admin/` |
| 默认账号 | `admin` / `admin`（**生产环境请立即修改**） |

### Watchtower 自动更新

安装时会询问：**是否安装 Watchtower？** 直接回车或输入 `Y` 为默认**安装**（约每 10 分钟检查 Hub）。

非交互强制指定：`MIRRORELF_INSTALL_WATCHTOWER=1` 或 `0`；兼容 `MIRRORELF_SKIP_WATCHTOWER=1` 表示不装。

安装后查看 Watchtower 日志：

```bash
cd /www/mirrorelf   # 或你的安装目录
docker compose -f compose.hub.yml --env-file env.hub --profile watchtower logs -f watchtower
```

### 手动安装

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

### 完全卸载

停止容器、**删除数据卷**（含数据库），并可删除安装目录与镜像。交互默认均为 **回车确认（Y）**。

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

`curl | bash` 会通过 `/dev/tty` 交互；若仅有一处 `compose.hub.yml` 也会自动选用。若 shell 里曾设置过错误的 `MIRRORELF_INSTALL_DIR`，脚本会提示并改由您选择。

若安装时改过目录，卸载时会提示输入**实际路径**（勿盲目回车默认 `/www/mirrorelf`）；也可从检测到的候选目录中选序号。

非交互须能**唯一确定**目录（自动检测或环境变量）：

```bash
MIRRORELF_INSTALL_DIR=/www/mirrorelf MIRRORELF_YES=1 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

卸载后请自行在 Nginx、雷池等网关中删除指向本机 `16888` 的回源配置。

### 目录说明

| 文件 | 说明 |
|------|------|
| `install.sh` | 一键安装脚本 |
| `uninstall.sh` | 完全卸载脚本 |
| `compose.hub.yml` | 应用 + Postgres（可选 Watchtower profile） |
| `env.hub.example` | 镜像名示例 `MIRRORELF_IMAGE` |

### 说明

- 本仓库不包含 MirrorElf 业务源码；源码为私有维护。
- 修改 `compose.hub.yml` 端口/卷时，若维护 fork，请同步 `install.sh` 内嵌 compose 段落。

### 新机安装保姆级教程

从零部署（含 kejilion 面板、Docker、可选 1Panel、雷池 WAF）可按以下步骤操作。

#### 1. 安装 curl 与 vim（按系统选）

**Debian / Ubuntu**

```bash
apt update -y && apt install -y curl vim jq tar
```

**CentOS**

```bash
yum update -y && yum install -y curl vim jq tar
```

#### 2. 下载安装 Linux 管理脚本

```bash
curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
```

命令：`k` 进入面板

#### 3. 安装 Docker

`k` 进入面板 → 选择：**6. Docker 管理 ▶** → **1. 安装更新 Docker 环境 ★**

#### 4. 安装 1Panel 面板（可选）

`k` 进入面板 → 选择：**11. 面板工具 ▶** → **3. 1Panel 新一代管理面板**（一路回车）

#### 5. 一键安装 Mirror-Elf®

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

#### 6. 雷池防火墙

先用 `k` 命令安装雷池防火墙：

`k` 进入面板 → 选择：**11. 面板工具 ▶** → **19. 雷池 WAF 防火墙面板**

- **注意：** 安装路径要手动指定为 `/www/safeline`
- **注意：** 攻击防护中设置：XSS 检测改为**仅观察**
- 安装完成后重置密码

进入 WAF 网站：`https://<你的主 IP>:9443`

**防火墙初始设置**

1. **防护应用** → **添加应用**
   - **填** 域名：`*`
   - **删** 443 端口
   - **填** 上游服务器：`http://127.0.0.1:16888`
   - **填** 备注：全站

**升级版本**（后面需要升级时）

```bash
bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/manager.sh)"
```

安装 Python 3：

```bash
apt update && apt install -y python3 python3-pip
```

#### 7. 进入 Mirror-Elf® 后台

`http://<你的主 IP>/_/admin`

- 账号：`admin`
- 密码：`admin`（请在后台设置中尽快修改密码）

#### 8. Docker 改安装目录（迁移）

**CentOS**

```bash
mkdir -p /www/docker && systemctl stop docker && echo '{"data-root": "/www/docker"}' > /etc/docker/daemon.json && (command -v apt >/dev/null && apt install -y rsync || command -v yum >/dev/null && yum install -y rsync) && rsync -aP /var/lib/docker/ /www/docker/ && systemctl start docker
```

**Debian**

```bash
mkdir -p /www/docker && systemctl stop docker && echo '{"data-root": "/www/docker"}' > /etc/docker/daemon.json && apt update && apt install -y rsync && rsync -aP /var/lib/docker/ /www/docker/ && systemctl start docker
```

迁移完成后启动 MirrorElf：

```bash
cd /www/mirrorelf && docker compose up -d
```

#### 9. 常用命令

**换程序**（先在旧程序上备份数据）

```bash
cd /www/MirrorElf-R && docker compose down && mkdir -p /www && curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**更新程序**（程序会自动更新到最新版本）

**停止**

```bash
docker compose --env-file env.hub -f compose.hub.yml down
```

**开始**

```bash
docker compose --env-file env.hub -f compose.hub.yml up
```

**开始（后台模式）**

```bash
cd /www/mirrorelf && docker compose --env-file env.hub -f compose.hub.yml up -d
```
