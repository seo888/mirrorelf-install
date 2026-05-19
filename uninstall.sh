#!/usr/bin/env bash
# MirrorElf 完全卸载：停止容器、删除数据卷，可选删除安装目录与镜像。
# 需要：Docker 与 docker compose 插件。
#
# 用法：
#   bash uninstall.sh
# 或：
#   curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
#
# 可选环境变量：
#   MIRRORELF_INSTALL_DIR   安装目录（设置后不再交互询问，默认 /www/mirrorelf）
#   MIRRORELF_YES=1         非交互：全部按默认执行（完全卸载 + 删目录 + 删镜像）

set -euo pipefail

DEFAULT_INSTALL_DIR="/www/mirrorelf"
DEFAULT_IMAGE="seo888/mirrorelf:latest"

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
	if [[ ! -d "$d" ]]; then
		echo "目录不存在: $d" >&2
		exit 1
	fi
	(cd "$d" && pwd)
}

confirm_default_yes() {
	local prompt="$1"
	if [[ "${MIRRORELF_YES:-}" == "1" ]]; then
		return 0
	fi
	if [[ ! -t 0 ]]; then
		return 0
	fi
	local ans=""
	read -r -p "$prompt" ans
	ans="$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')"
	case "$ans" in
	n | no) return 1 ;;
	*) return 0 ;;
	esac
}

WORKDIR="$(resolve_install_dir)"
COMPOSE="$WORKDIR/compose.hub.yml"
ENV_FILE="$WORKDIR/env.hub"

if [[ ! -f "$COMPOSE" ]]; then
	echo "未找到 $COMPOSE，请确认安装目录是否正确。" >&2
	exit 1
fi

APP_IMAGE="$DEFAULT_IMAGE"
if [[ -f "$ENV_FILE" ]]; then
	# shellcheck disable=SC1090
	source "$ENV_FILE" 2>/dev/null || true
	APP_IMAGE="${MIRRORELF_IMAGE:-$DEFAULT_IMAGE}"
fi

if ! command -v docker >/dev/null 2>&1; then
	echo "未找到 docker 命令。" >&2
	exit 1
fi
if ! docker compose version >/dev/null 2>&1; then
	echo "未找到 docker compose，请安装 Docker Compose 插件。" >&2
	exit 1
fi

echo "安装目录: $WORKDIR"
echo
echo "将执行：停止并删除 app / postgres / watchtower 容器及数据卷（数据库与配置不可恢复）。"
if ! confirm_default_yes "确认完全卸载？[Y/n]: "; then
	echo "已取消。"
	exit 0
fi

COMPOSE_BASE=(docker compose -f "$COMPOSE" --env-file "$ENV_FILE")

echo
echo "正在停止并删除容器与卷 …"
"${COMPOSE_BASE[@]}" --profile watchtower down -v --remove-orphans 2>/dev/null || \
	"${COMPOSE_BASE[@]}" down -v --remove-orphans

while IFS= read -r vol; do
	[[ -z "$vol" ]] && continue
	docker volume rm "$vol" 2>/dev/null || true
done < <(docker volume ls -q 2>/dev/null | grep mirrorelf || true)

REMOVE_DIR=0
if confirm_default_yes "是否删除安装目录 ${WORKDIR}（含 compose.hub.yml、env.hub）？[Y/n]: "; then
	REMOVE_DIR=1
fi

REMOVE_IMAGES=0
if confirm_default_yes "是否删除 Docker 镜像（${APP_IMAGE}、postgres:16-bookworm、watchtower）？[Y/n]: "; then
	REMOVE_IMAGES=1
fi

if [[ "$REMOVE_DIR" == 1 ]]; then
	echo "正在删除安装目录 …"
	rm -rf "$WORKDIR"
	echo "已删除: $WORKDIR"
fi

if [[ "$REMOVE_IMAGES" == 1 ]]; then
	echo "正在删除镜像 …"
	docker image rm "$APP_IMAGE" 2>/dev/null || true
	docker image rm postgres:16-bookworm 2>/dev/null || true
	docker image rm nickfedor/watchtower:latest 2>/dev/null || true
fi

echo
echo "卸载完成。"
echo "  · 若曾在 Nginx、雷池等网关中配置回源，请手动删除对应站点/upstream。"
echo "  · 检查: docker ps -a | grep mirrorelf ; docker volume ls | grep mirrorelf ; ss -lntp | grep 18888"
