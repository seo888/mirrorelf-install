#!/usr/bin/env bash
# 一键安装：只依赖 Docker Hub 上的应用镜像 + Postgres 官方镜像（无需克隆代码仓库）。
# 需要本机已安装 Docker 与 docker compose 插件。
#
# 用法：
#   bash install.sh
# 或一条命令（公开安装仓）：
#   curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
#
# 完全卸载：
#   curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
#
# 可选环境变量：
#   MIRRORELF_IMAGE        应用镜像，默认 seo888/mirrorelf:latest
#   MIRRORELF_INSTALL_DIR          安装目录（设置后不再交互询问，默认 /www/mirrorelf）
#   MIRRORELF_INSTALL_WATCHTOWER   1/0 强制是否安装 Watchtower（设置后不再询问）
#   MIRRORELF_SKIP_WATCHTOWER      同 0，兼容：设为 1 则不安装 Watchtower

set -euo pipefail

DEFAULT_IMAGE="${MIRRORELF_IMAGE:-seo888/mirrorelf:latest}"
DEFAULT_INSTALL_DIR="/www/mirrorelf"

# 交互选择安装目录；非 TTY（如部分 CI）或已设 MIRRORELF_INSTALL_DIR 则用默认/指定值
resolve_install_dir() {
	local d="" chosen=""
	if [[ -n "${MIRRORELF_INSTALL_DIR:-}" ]]; then
		d="${MIRRORELF_INSTALL_DIR}"
	elif [[ -t 0 ]]; then
		read -r -p "安装目录 [${DEFAULT_INSTALL_DIR}]: " chosen
		d="${chosen:-$DEFAULT_INSTALL_DIR}"
	else
		d="$DEFAULT_INSTALL_DIR"
	fi
	d="${d%/}"
	if [[ -z "$d" ]]; then
		echo "安装目录不能为空。" >&2
		exit 1
	fi
	if ! mkdir -p "$d"; then
		echo "无法创建安装目录: $d（若无 /www 写权限，请指定其他路径或 sudo 执行）" >&2
		exit 1
	fi
	(cd "$d" && pwd)
}

# 是否安装 Watchtower：交互默认 Y；非 TTY 默认安装
resolve_install_watchtower() {
	if [[ "${MIRRORELF_SKIP_WATCHTOWER:-}" == "1" ]] || [[ "${MIRRORELF_INSTALL_WATCHTOWER:-}" == "0" ]]; then
		return 1
	fi
	if [[ "${MIRRORELF_INSTALL_WATCHTOWER:-}" == "1" ]]; then
		return 0
	fi
	if [[ -t 0 ]]; then
		local ans=""
		read -r -p "是否安装 Watchtower 自动更新（约每 10 分钟检查 Hub）？[Y/n]: " ans
		ans="$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')"
		case "$ans" in
		n | no) return 1 ;;
		*) return 0 ;;
		esac
	fi
	return 0
}

WORKDIR="$(resolve_install_dir)"

COMPOSE="$WORKDIR/compose.hub.yml"
ENV_FILE="$WORKDIR/env.hub"

# 本机主 IP（默认路由出口，供对外访问与 Nginx/雷池回源提示）
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
    ports:
      - '127.0.0.1:5432:5432'
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
    network_mode: host
    environment:
      MIRRORELF_SYNC_RELEASES_MANIFEST: '1'
      MIRRORELF_HOST_NETWORK: '1'
    labels:
      - com.centurylinklabs.watchtower.enable=true
    depends_on:
      postgres:
        condition: service_healthy
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

if [[ ! -f "$COMPOSE" ]]; then
	echo "正在写入 $COMPOSE …"
	write_embedded_compose
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
COMPOSE_BASE=(docker compose -f "$COMPOSE" --env-file "$ENV_FILE")
INSTALL_WATCHTOWER=0
if resolve_install_watchtower; then
	INSTALL_WATCHTOWER=1
	COMPOSE_PROFILE=(--profile watchtower)
else
	COMPOSE_PROFILE=()
	echo "已选择不安装 Watchtower。"
fi
"${COMPOSE_BASE[@]}" "${COMPOSE_PROFILE[@]}" pull
"${COMPOSE_BASE[@]}" "${COMPOSE_PROFILE[@]}" up -d

HOST_IP="$(detect_primary_ip)"
echo
echo "已启动。"
echo "  站点:     http://${HOST_IP}:16888/"
echo "  管理后台: http://${HOST_IP}:16888/_/admin/ （默认 admin / admin，生产环境请修改）"
if [[ "$HOST_IP" == "127.0.0.1" ]]; then
	echo "  （未能自动检测服务器 IP，请将上文地址中的 IP 改为本机内网或公网地址）"
fi
echo
echo "若使用 Nginx、雷池（SafeLine）等反向代理 / WAF 对外暴露，请在网关配置回源："
echo "  · 回源地址（upstream）: ${HOST_IP}"
echo "  · 回源端口: 16888（app 为 host 网络，直接监听宿主机 16888）"
echo "  公网入口填在 Nginx/雷池 的站点或监听上，不要直接把 16888 暴露到公网（除非已做访问控制）。"
	echo "  仅在本机调试时可访问: http://127.0.0.1:16888/"
if [[ "$INSTALL_WATCHTOWER" == 1 ]]; then
	echo
	echo "Watchtower 已启动，将自动拉取并重建带更新标签的 app 容器（镜像 ${DEFAULT_IMAGE}）。"
	echo "  查看日志: cd \"$WORKDIR\" && ${COMPOSE_BASE[*]} ${COMPOSE_PROFILE[*]} logs -f watchtower"
fi
