# mirrorelf-install

MirrorElf 的 **Docker 一键安装**仓库（仅含安装脚本与 Compose，不含业务源码）。

应用通过 Docker Hub 镜像分发：`seo888/mirrorelf`

## 一条命令安装（Linux）

需已安装 [Docker](https://docs.docker.com/engine/install/) 与 **docker compose** 插件。

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

建议先看脚本再执行：

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh -o install.sh
less install.sh
bash install.sh
```

## 安装后

| 项 | 地址 |
|----|------|
| 站点 | `http://<服务器IP>:18888/` |
| 管理后台 | `http://<服务器IP>:18888/_/admin/` |
| 默认账号 | `admin` / `admin`（**生产环境请立即修改**） |

Compose 与配置默认写在 `~/.mirrorelf/`（可用环境变量 `MIRRORELF_INSTALL_DIR` 修改）。

## 指定镜像版本

```bash
MIRRORELF_IMAGE=seo888/mirrorelf:0.9.25 curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

## Watchtower 自动更新

安装完成后：

```bash
cd ~/.mirrorelf
docker compose -f compose.hub.yml --env-file env.hub --profile watchtower up -d
```

默认每 10 分钟检查 Docker Hub 上的 `latest` 并重建带 `watchtower.enable` 标签的 `app` 容器。

## 手动安装（克隆本仓库）

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

## 说明

- 本仓库 **不包含** MirrorElf 完整源代码；源码为私有维护。
- 与主项目 `docker/install.sh` 逻辑一致；发版时请同步更新两处 compose 段落。
