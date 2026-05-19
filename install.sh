#!/usr/bin/env bash
# MirrorElf 一键安装（Docker Hub 镜像 + Postgres，无需克隆业务源码）
# 需要：Docker 与 docker compose 插件
#
# 用法：
#   curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
# 或：
#   bash install.sh
#
# 可选环境变量：
#   MIRRORELF_IMAGE         应用镜像，默认 seo888/mirrorelf:latest
#   MIRRORELF_INSTALL_DIR   compose/env 目录，默认 ~/.mirrorelf

set -euo pipefail

DEFAULT_IMAGE="${MIRRORELF_IMAGE:-seo888/mirrorelf:latest}"
INSTALL_DIR="${MIRRORELF_INSTALL_DIR:-${HOME}/.mirrorelf}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"

if [[ -f "$SCRIPT_DIR/compose.hub.yml" ]]; then
	WORKDIR="$SCRIPT_DIR"
else
	WORKDIR="$INSTALL_DIR"
	mkdir -p "$WORKDIR"
fi

COMPOSE="$WORKDIR/compose.hub.yml"
ENV_FILE="$WORKDIR/env.hub"

detect_primary_ip() {
	local ip=""
	if command -v ip >/dev/null 2>&1; then
		ip="$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}')"
	fi
	if [[ -z "$ip" ]] && command -v hostname >/dev/null 2>&1; then
		ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
	fi
	if [[ -z "$ip" ]]; then
		ip="127.0.0.1"
	fi
	printf '%s' "$ip"
}

write_embedded_compose() {
	cat <<'COMPOSE_EOF' >"$COMPOSE"
services:
  postgres:
    image: postgres:16-bookworm
    shm_size: 256mb
    environment:
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: mirrorelf
      POSTGRES_DB: mirror
    volumes:
      - mirrorelf_pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U postgres -d mirror']
      interval: 5s
      timeout: 5s
      retries: 12
      start_period: 15s

  app:
    image: ${MIRRORELF_IMAGE}
    environment:
      MIRRORELF_SYNC_RELEASES_MANIFEST: '1'
    labels:
      - com.centurylinklabs.watchtower.enable=true
    depends_on:
      postgres:
        condition: service_healthy
    ports:
      - '18888:16888'
    volumes:
      - mirrorelf_config:/app/config
      - mirrorelf_log:/app/log
      - mirrorelf_data:/app/data

  watchtower:
    profiles: [watchtower]
    image: nickfedor/watchtower:latest
    restart: unless-stopped
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      WATCHTOWER_LABEL_ENABLE: 'true'
      WATCHTOWER_POLL_INTERVAL: '600'
      WATCHTOWER_CLEANUP: 'true'
      WATCHTOWER_INCLUDE_RESTARTING: 'true'
      TZ: Asia/Shanghai

volumes:
  mirrorelf_pgdata:
  mirrorelf_config:
  mirrorelf_log:
  mirrorelf_data:
COMPOSE_EOF
}

if [[ "$WORKDIR" == "$INSTALL_DIR" ]]; then
	if [[ ! -f "$COMPOSE" ]]; then
		echo "正在写入 $COMPOSE …"
		write_embedded_compose
	fi
fi

if ! command -v docker >/dev/null 2>&1; then
	echo "未找到 docker 命令，请先安装 Docker。" >&2
	exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
	echo "未找到 docker compose，请安装 Docker Compose 插件。" >&2
	exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
	echo "MIRRORELF_IMAGE=${DEFAULT_IMAGE}" >"$ENV_FILE"
	echo "已写入 $ENV_FILE（MIRRORELF_IMAGE=${DEFAULT_IMAGE}），可按需编辑后重新执行本脚本。"
fi

cd "$WORKDIR"
echo "工作目录: $WORKDIR"
docker compose -f "$COMPOSE" --env-file "$ENV_FILE" pull
docker compose -f "$COMPOSE" --env-file "$ENV_FILE" up -d

HOST_IP="$(detect_primary_ip)"
echo
echo "已启动。"
echo "  站点:     http://${HOST_IP}:18888/"
echo "  管理后台: http://${HOST_IP}:18888/_/admin/ （默认 admin / admin，生产环境请修改）"
if [[ "$HOST_IP" == "127.0.0.1" ]]; then
	echo "  （未能自动检测服务器 IP，请将上文地址中的 IP 改为本机内网或公网地址）"
fi
echo
echo "若使用 Nginx、雷池（SafeLine）等反向代理 / WAF 对外暴露，请在网关配置回源："
echo "  · 回源地址（upstream）: ${HOST_IP}"
echo "  · 回源端口: 18888"
echo "  公网入口填在 Nginx/雷池 的站点或监听上，不要直接把 18888 暴露到公网（除非已做访问控制）。"
echo "  仅在本机调试时可访问: http://127.0.0.1:18888/"
echo
echo "启用 Watchtower 自动更新（每 10 分钟检查 Hub）："
echo "  cd \"$WORKDIR\" && docker compose -f \"$COMPOSE\" --env-file \"$ENV_FILE\" --profile watchtower up -d"
