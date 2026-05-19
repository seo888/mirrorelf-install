#!/usr/bin/env bash
# MirrorElf 完全卸载：停止容器、删除数据卷，可选删除安装目录与镜像。
#
# 用法：
#   bash uninstall.sh
#   curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
# 推荐（便于交互）：curl -fsSL ... -o uninstall.sh && bash uninstall.sh
#
# 环境变量：
#   MIRRORELF_INSTALL_DIR   安装目录（与安装时一致）
#   MIRRORELF_YES=1         非交互；须能唯一确定目录（见脚本逻辑）

set -euo pipefail

DEFAULT_INSTALL_DIR="/www/mirrorelf"
DEFAULT_IMAGE="seo888/mirrorelf:latest"

# curl | bash 时 stdin 不是 TTY，从 /dev/tty 读写
can_prompt_user() {
	[[ -t 0 ]] || { [[ -r /dev/tty ]] && [[ -w /dev/tty ]]; }
}

read_prompt() {
	local prompt="$1"
	local __varname="$2"
	if [[ -t 0 ]]; then
		read -r -p "$prompt" "$__varname"
	elif [[ -r /dev/tty ]] && [[ -w /dev/tty ]]; then
		read -r -p "$prompt" "$__varname" </dev/tty
	else
		return 1
	fi
}

echo_prompt() {
	if [[ -t 1 ]]; then
		echo "$@"
	elif [[ -w /dev/tty ]]; then
		echo "$@" >/dev/tty
	else
		echo "$@"
	fi
}

is_valid_install_dir() {
	[[ -d "$1" && -f "$1/compose.hub.yml" ]]
}

list_install_dir_candidates() {
	local root dir
	for root in /www /opt /data /root "${HOME:-/root}"; do
		[[ -d "$root" ]] || continue
		while IFS= read -r -d '' dir; do
			printf '%s\n' "$(dirname "$dir")"
		done < <(find "$root" -maxdepth 5 -name 'compose.hub.yml' -print0 2>/dev/null)
	done
	if [[ -f "${HOME:-}/.mirrorelf/compose.hub.yml" ]]; then
		printf '%s\n' "${HOME}/.mirrorelf"
	fi
}

pick_install_dir_noninteractive() {
	local -a candidates=()
	mapfile -t candidates < <(list_install_dir_candidates | sort -u || true)
	if [[ ${#candidates[@]} -eq 1 ]]; then
		echo_prompt "自动检测到安装目录: ${candidates[0]}"
		printf '%s' "${candidates[0]}"
		return 0
	fi
	echo_prompt "无法交互且未能唯一确定安装目录。请指定 MIRRORELF_INSTALL_DIR，例如：" >&2
	if [[ ${#candidates[@]} -gt 0 ]]; then
		echo_prompt "检测到的可能路径：" >&2
		local c
		for c in "${candidates[@]}"; do
			echo_prompt "  $c" >&2
		done
	fi
	echo_prompt "  MIRRORELF_INSTALL_DIR=/实际路径 bash uninstall.sh" >&2
	return 1
}

resolve_install_dir() {
	local d="" chosen="" candidates=()

	if [[ -n "${MIRRORELF_INSTALL_DIR:-}" ]] && is_valid_install_dir "${MIRRORELF_INSTALL_DIR%/}"; then
		(cd "${MIRRORELF_INSTALL_DIR%/}" && pwd)
		return 0
	fi
	if [[ -n "${MIRRORELF_INSTALL_DIR:-}" ]]; then
		echo_prompt "注意: 环境变量 MIRRORELF_INSTALL_DIR=${MIRRORELF_INSTALL_DIR} 无效（目录不存在或无 compose.hub.yml），将请您选择或自动检测。"
		echo_prompt
	fi

	if can_prompt_user; then
		local prompt_default="$DEFAULT_INSTALL_DIR"
		local i=1 c

		while true; do
			mapfile -t candidates < <(list_install_dir_candidates | sort -u || true)

			if is_valid_install_dir "$DEFAULT_INSTALL_DIR"; then
				prompt_default="$DEFAULT_INSTALL_DIR"
			elif [[ ${#candidates[@]} -eq 1 ]]; then
				prompt_default="${candidates[0]}"
			elif [[ ${#candidates[@]} -gt 1 ]]; then
				prompt_default="${candidates[0]}"
			else
				prompt_default="$DEFAULT_INSTALL_DIR"
			fi

			if [[ ${#candidates[@]} -gt 1 ]]; then
				i=1
				for c in "${candidates[@]}"; do
					echo_prompt "  [$i] $c"
					i=$((i + 1))
				done
			fi

			if ! read_prompt "安装目录 [${prompt_default}]: " chosen; then
				echo_prompt "无法读取终端输入。请使用: curl -fsSL ... -o uninstall.sh && bash uninstall.sh" >&2
				echo_prompt "或设置 MIRRORELF_INSTALL_DIR=/实际路径" >&2
				exit 1
			fi

			if [[ -n "$chosen" ]] && [[ "$chosen" =~ ^[0-9]+$ ]] && [[ ${#candidates[@]} -gt 0 ]]; then
				local idx="$chosen"
				if [[ "$idx" -ge 1 && "$idx" -le ${#candidates[@]} ]]; then
					d="${candidates[$((idx - 1))]}"
				else
					echo_prompt "序号无效，请重新输入。" >&2
					continue
				fi
			elif [[ -n "$chosen" ]]; then
				d="${chosen%/}"
			else
				d="$prompt_default"
			fi

			if [[ -z "$d" ]]; then
				echo_prompt "安装目录不能为空。" >&2
				continue
			fi
			if ! is_valid_install_dir "$d"; then
				if [[ -d "$d" ]]; then
					echo_prompt "未找到 $d/compose.hub.yml，请重新输入。" >&2
				else
					echo_prompt "目录不存在: $d，请填写安装时实际路径。" >&2
				fi
				continue
			fi

			(cd "$d" && pwd)
			return 0
		done
	fi

	# 完全非交互（无 /dev/tty）
	d="$(pick_install_dir_noninteractive)" || exit 1
	(cd "$d" && pwd)
}

confirm_default_yes() {
	local prompt="$1"
	if [[ "${MIRRORELF_YES:-}" == "1" ]]; then
		return 0
	fi
	if ! can_prompt_user; then
		return 0
	fi
	local ans=""
	if ! read_prompt "$prompt" ans; then
		return 0
	fi
	ans="$(printf '%s' "$ans" | tr '[:upper:]' '[:lower:]')"
	case "$ans" in
	n | no) return 1 ;;
	*) return 0 ;;
	esac
}

WORKDIR="$(resolve_install_dir)"
COMPOSE="$WORKDIR/compose.hub.yml"
ENV_FILE="$WORKDIR/env.hub"

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

echo_prompt
echo_prompt "安装目录: $WORKDIR"
echo_prompt
echo_prompt "将执行：停止并删除 app / postgres / watchtower 容器及数据卷（数据库与配置不可恢复）。"
echo_prompt "直接回车=是，输入 n=否。"
if ! confirm_default_yes "确认完全卸载？[Y/n]: "; then
	echo_prompt "已取消。"
	exit 0
fi

COMPOSE_BASE=(docker compose -f "$COMPOSE" --env-file "$ENV_FILE")

echo_prompt
echo_prompt "正在停止并删除容器与卷 …"
"${COMPOSE_BASE[@]}" --profile watchtower down -v --remove-orphans 2>/dev/null || \
	"${COMPOSE_BASE[@]}" down -v --remove-orphans

while IFS= read -r vol; do
	[[ -z "$vol" ]] && continue
	docker volume rm "$vol" 2>/dev/null || true
done < <(docker volume ls -q 2>/dev/null | grep mirrorelf || true)

REMOVE_DIR=0
if confirm_default_yes "删除安装目录 ${WORKDIR}？[Y/n]: "; then
	REMOVE_DIR=1
fi

REMOVE_IMAGES=0
if confirm_default_yes "删除 Docker 镜像（${APP_IMAGE} 等）？[Y/n]: "; then
	REMOVE_IMAGES=1
fi

if [[ "$REMOVE_DIR" == 1 ]]; then
	echo_prompt "正在删除安装目录 …"
	rm -rf "$WORKDIR"
	echo_prompt "已删除: $WORKDIR"
fi

if [[ "$REMOVE_IMAGES" == 1 ]]; then
	echo_prompt "正在删除镜像 …"
	docker image rm "$APP_IMAGE" 2>/dev/null || true
	docker image rm postgres:16-bookworm 2>/dev/null || true
	docker image rm nickfedor/watchtower:latest 2>/dev/null || true
fi

echo_prompt
echo_prompt "卸载完成。"
echo_prompt "  · 若曾在 Nginx、雷池等网关中配置回源，请手动删除对应站点/upstream。"
echo_prompt "  · 检查: docker ps -a | grep mirrorelf ; docker volume ls | grep mirrorelf ; ss -lntp | grep 18888"
