#!/usr/bin/env bash
# 修复：website 等 LIST 分区过多时，扫父表触发
#   ERROR: out of shared memory
#   HINT: You might need to increase max_locks_per_transaction.
#
# 用法（生产机）：
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
APP_CONTAINER="${MIRRORELF_APP_CONTAINER:-mirrorelf-app-1}"

log() { printf '%s\n' "$*"; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "需要命令: $1"
}

need_cmd docker
need_cmd python3

if ! docker compose version >/dev/null 2>&1; then
  die "需要 docker compose 插件"
fi

resolve_home() {
  if [[ -n "${MIRRORELF_HOME:-}" ]]; then
    printf '%s\n' "$MIRRORELF_HOME"
    return
  fi
  for d in /www/mirrorelf "$PWD" "$(dirname "$0")"; do
    if [[ -f "$d/$COMPOSE_FILE_NAME" ]]; then
      printf '%s\n' "$d"
      return
    fi
  done
  die "找不到 $COMPOSE_FILE_NAME（请设置 MIRRORELF_HOME=/path/to/mirrorelf）"
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

# 幂等改写 compose：写入/替换 postgres 的 shm_size 与 command 锁参数
python3 - "$COMPOSE" "$LOCKS" "$PRED_LOCKS" "$SHM" <<'PY'
import re, sys
from pathlib import Path

path = Path(sys.argv[1])
locks, pred, shm = sys.argv[2], sys.argv[3], sys.argv[4]
text = path.read_text(encoding="utf-8")

cmd_block = (
    "    command:\n"
    "      - postgres\n"
    "      - -c\n"
    f"      - max_locks_per_transaction={locks}\n"
    "      - -c\n"
    f"      - max_pred_locks_per_transaction={pred}\n"
)

# shm_size
if re.search(r"(?m)^\s*shm_size:\s*", text):
    text = re.sub(r"(?m)^(\s*)shm_size:\s*.*$", rf"\1shm_size: {shm}", text, count=1)
else:
    text = re.sub(
        r"(?m)^(  postgres:\s*\n(?:    .*\n)*?)(    image:\s*postgres[^\n]*\n)",
        rf"\1\2    shm_size: {shm}\n",
        text,
        count=1,
    )

# 去掉旧 command 块（仅 postgres 服务内、environment 之前）
text2 = re.sub(
    r"(?ms)^(  postgres:\n(?:    .*\n)*?)(    command:\n(?:      .*\n)+)",
    r"\1",
    text,
    count=1,
)

# 在 postgres.environment 前插入 command
if re.search(r"(?m)^  postgres:\n(?:    .*\n)*?    environment:", text2):
    text2 = re.sub(
        r"(?m)^(  postgres:\n(?:    .*\n)*?)(    environment:)",
        rf"\1{cmd_block}\2",
        text2,
        count=1,
    )
else:
    # 兜底：紧跟 image 行后插入
    text2 = re.sub(
        r"(?m)^(  postgres:\n(?:    .*\n)*?    image:\s*postgres[^\n]*\n)",
        rf"\1    shm_size: {shm}\n{cmd_block}",
        text2,
        count=1,
    )

path.write_text(text2, encoding="utf-8")
print("compose patched OK")
PY

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
    # running 且无 healthcheck 也接受；再等 isready
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
log "用法回顾: curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/fix-pg-max-locks.sh | bash"
