#!/usr/bin/env bash
# 修复：website 等 LIST 分区过多时，扫父表触发
#   ERROR: out of shared memory
#   HINT: You might need to increase max_locks_per_transaction.
#
# 用法（生产机，无需 python3）：
#   curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/fix-pg-max-locks.sh | bash
# 或指定安装目录：
#   MIRRORELF_HOME=/www/mirrorelf bash fix-pg-max-locks.sh
#
# 会：备份并改 compose.hub.yml → ALTER SYSTEM → 重建 postgres → 重启 app → 校验

set -euo pipefail

LOCKS="${MIRRORELF_MAX_LOCKS:-512}"
PRED_LOCKS="${MIRRORELF_MAX_PRED_LOCKS:-256}"
SHM="${MIRRORELF_PG_SHM_SIZE:-512mb}"
COMPOSE_FILE_NAME="${MIRRORELF_COMPOSE_FILE:-compose.hub.yml}"
ENV_FILE_NAME="${MIRRORELF_ENV_FILE:-env.hub}"
PG_CONTAINER="${MIRRORELF_PG_CONTAINER:-mirrorelf-postgres-1}"

log() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "需要命令: $1"
}

need_cmd docker
need_cmd awk

if ! docker compose version >/dev/null 2>&1; then
  die "需要 docker compose 插件"
fi

resolve_home() {
  if [[ -n "${MIRRORELF_HOME:-}" ]]; then
    printf '%s\n' "$MIRRORELF_HOME"
    return
  fi
  for d in /www/mirrorelf "$PWD"; do
    if [[ -f "$d/$COMPOSE_FILE_NAME" ]]; then
      printf '%s\n' "$d"
      return
    fi
  done
  # pipe 到 bash 时 $0 可能是 bash，忽略
  if [[ -n "${BASH_SOURCE[0]:-}" && -f "${BASH_SOURCE[0]}" ]]; then
    d="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [[ -f "$d/$COMPOSE_FILE_NAME" ]]; then
      printf '%s\n' "$d"
      return
    fi
  fi
  die "找不到 $COMPOSE_FILE_NAME（请设置 MIRRORELF_HOME=/path/to/mirrorelf）"
}

# 幂等改写 compose：postgres 段写入 shm_size + command 锁参数（纯 awk，无 python）
patch_compose() {
  local src="$1" dst="$2"
  LOCKS="$LOCKS" PRED_LOCKS="$PRED_LOCKS" SHM="$SHM" awk '
BEGIN {
  locks = ENVIRON["LOCKS"]
  pred = ENVIRON["PRED_LOCKS"]
  shm = ENVIRON["SHM"]
  in_pg = 0
  skip_cmd = 0
  wrote_shm = 0
  wrote_cmd = 0
}
function emit_cmd() {
  print "    command:"
  print "      - postgres"
  print "      - -c"
  print "      - max_locks_per_transaction=" locks
  print "      - -c"
  print "      - max_pred_locks_per_transaction=" pred
  wrote_cmd = 1
}
function emit_shm() {
  print "    shm_size: " shm
  wrote_shm = 1
}
{
  # 进入 / 离开 postgres 服务
  if ($0 ~ /^  [a-zA-Z0-9_-]+:[[:space:]]*$/) {
    if (in_pg && !wrote_cmd) {
      # 异常兜底：离开前补 command
      if (!wrote_shm) emit_shm()
      emit_cmd()
    }
    in_pg = ($0 ~ /^  postgres:[[:space:]]*$/)
    skip_cmd = 0
    if (in_pg) { wrote_shm = 0; wrote_cmd = 0 }
    print
    next
  }

  if (!in_pg) { print; next }

  # 跳过旧 command 块
  if (skip_cmd) {
    if ($0 ~ /^      / || $0 ~ /^    command:/) next
    skip_cmd = 0
  }
  if ($0 ~ /^    command:[[:space:]]*$/) {
    skip_cmd = 1
    next
  }

  # 替换已有 shm_size
  if ($0 ~ /^    shm_size:[[:space:]]*/) {
    emit_shm()
    next
  }

  # 在 environment 前插入 shm（若尚未写）+ command
  if ($0 ~ /^    environment:[[:space:]]*$/) {
    if (!wrote_shm) emit_shm()
    if (!wrote_cmd) emit_cmd()
    print
    next
  }

  print
}
END {
  if (in_pg && !wrote_cmd) {
    if (!wrote_shm) emit_shm()
    emit_cmd()
  }
}
' "$src" >"$dst"
}

HOME_DIR="$(resolve_home)"
HOME_DIR="$(cd "$HOME_DIR" && pwd)"
COMPOSE="$HOME_DIR/$COMPOSE_FILE_NAME"
ENV_FILE="$HOME_DIR/$ENV_FILE_NAME"

[[ -f "$COMPOSE" ]] || die "缺少 $COMPOSE"
[[ -f "$ENV_FILE" ]] || die "缺少 $ENV_FILE（通常为 env.hub）"

log "==> 安装目录: $HOME_DIR"
log "==> 目标: max_locks_per_transaction=$LOCKS  shm_size=$SHM"

bak="$COMPOSE.bak.$(date +%Y%m%d%H%M%S)"
cp -a "$COMPOSE" "$bak"
log "==> 已备份: $bak"

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
patch_compose "$COMPOSE" "$tmp"
# 基本校验：必须含锁参数
grep -q "max_locks_per_transaction=${LOCKS}" "$tmp" || die "改写 compose 失败：未写入 max_locks_per_transaction"
mv "$tmp" "$COMPOSE"
trap - EXIT
log "==> compose 已更新"

log "==> ALTER SYSTEM（写入 postgresql.auto.conf，重建后仍生效）"
if docker ps --format '{{.Names}}' | grep -qx "$PG_CONTAINER"; then
  docker exec "$PG_CONTAINER" psql -U postgres -v ON_ERROR_STOP=1 \
    -c "ALTER SYSTEM SET max_locks_per_transaction = ${LOCKS};" \
    -c "ALTER SYSTEM SET max_pred_locks_per_transaction = ${PRED_LOCKS};" \
    || log "WARN: ALTER SYSTEM 跳过（容器未就绪时将依赖 compose command）"
else
  log "WARN: 未找到运行中的 $PG_CONTAINER，跳过 ALTER SYSTEM"
fi

log "==> 重建 postgres（短暂不可用）"
cd "$HOME_DIR"
docker compose -f "$COMPOSE_FILE_NAME" --env-file "$ENV_FILE_NAME" up -d postgres --force-recreate

log "==> 等待 postgres healthy"
ok=0
for _ in $(seq 1 60); do
  st="$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}{{.State.Status}}{{end}}' "$PG_CONTAINER" 2>/dev/null || echo missing)"
  log "    health=$st"
  if [[ "$st" == "healthy" || "$st" == "running" ]]; then
    if docker exec "$PG_CONTAINER" pg_isready -U postgres -d mirror >/dev/null 2>&1; then
      ok=1
      break
    fi
  fi
  sleep 2
done
[[ "$ok" -eq 1 ]] || die "postgres 未在时限内就绪"

got="$(docker exec "$PG_CONTAINER" psql -U postgres -tAc 'SHOW max_locks_per_transaction;' | tr -d '[:space:]')"
log "==> max_locks_per_transaction=$got"
[[ "$got" == "$LOCKS" ]] || die "期望 $LOCKS，实际 $got"

log "==> 重启 app（重连连接池）"
docker compose -f "$COMPOSE_FILE_NAME" --env-file "$ENV_FILE_NAME" up -d app

log "==> 冒烟: SELECT domain FROM website …"
docker exec "$PG_CONTAINER" psql -U postgres -d mirror -v ON_ERROR_STOP=1 \
  -c "SELECT domain FROM website ORDER BY domain ASC LIMIT 5;"

log "OK: 已提高 Postgres 锁上限。管理端列表若仍偶发超时，多半是 website_cache 统计慢，与本次锁表无关。"
log "用法: curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/fix-pg-max-locks.sh | bash"
