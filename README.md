# MirrorElf 安装文档

## 📌 导航

标签文档 → [Mirror-Elf® 标签文档](https://dynalist.io/d/pDZjfOHDp4AefwWeQT1MIgn3#theme=light)

---

## 新机安装保姆级教程

### 1. 安装 curl 与 vim（按系统选）

**Debian / Ubuntu**

```bash
apt update -y && apt install -y curl vim jq tar
```

**CentOS**

```bash
yum update -y && yum install -y curl vim jq tar
```

### 2. 下载安装 Linux 管理脚本

```bash
curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
```

命令：`k` 进入面板

### 3. 安装 Docker

`k` 进入面板 → 选择：**6. Docker 管理 ▶** → **1. 安装更新 Docker 环境 ★**

### 4. 安装 1Panel 面板（可选）

`k` 进入面板 → 选择：**11. 面板工具 ▶** → **3. 1Panel 新一代管理面板**（一路回车）

### 5. 一键安装 Mirror-Elf®（按系统选）

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

### 6. 雷池防火墙

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

### 7. 进入 Mirror-Elf® 后台

`http://<你的主 IP>/_/admin`

- 账号：`admin`
- 密码：`admin`（请在后台设置中尽快修改密码）

### 8. Docker 改安装目录（迁移）

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

### 9. 常用命令

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

---

## mirrorelf-install 版本清单同步

发版时将本目录 `releases.manifest.json` 推送到 [seo888/mirrorelf-install](https://github.com/seo888/mirrorelf-install) 仓库根目录，供已部署实例通过 `remote_manifest_url` 拉取完整版本历史。

### 一键同步（推荐）

在 MirrorElf 根目录（需已克隆 `mirrorelf-install` 到同级目录，默认 `../mirrorelf-install`）：

```powershell
.\scripts\sync-install-manifest.ps1
```

自定义 install 仓路径或预览：

```powershell
.\scripts\sync-install-manifest.ps1 -InstallRepo D:\code\mirrorelf-install
.\scripts\sync-install-manifest.ps1 -DryRun
```

脚本会：`config/releases.manifest.json` → `scripts/mirrorelf-install/` → install 仓根目录 → `git commit` → `git push`。

### 手动步骤

```bash
# 在 MirrorElf 根目录更新清单后复制到此处，再提交 install 仓
cp config/releases.manifest.json scripts/mirrorelf-install/releases.manifest.json
```

```bash
# 在 mirrorelf-install 克隆目录
cp /path/to/MirrorElf/scripts/mirrorelf-install/releases.manifest.json ./releases.manifest.json
git add releases.manifest.json && git commit -m "chore: sync releases manifest 0.9.56" && git push
```

远程 URL（与 `config/releases.manifest.json` 中 `remote_manifest_url` 一致）：

`https://raw.githubusercontent.com/seo888/mirrorelf-install/main/releases.manifest.json`
