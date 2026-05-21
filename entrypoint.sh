#!/bin/sh
set -e
cd /app

mkdir -p config log data doc templates

if [ ! -f config/config.yml ]; then
  echo "[entrypoint] No config/config.yml — copying docker default (mount a volume to override)."
  cp -f /app/docker/config.default.yml config/config.yml
fi

# host 网络：改连宿主机映射端口，密码与 compose 中 Postgres 一致（覆盖卷内旧配置）
if [ "${MIRRORELF_HOST_NETWORK:-}" = "1" ] && [ -f config/config.yml ]; then
  PG_HOST_PORT="${MIRRORELF_PG_HOST_PORT:-5432}"
  PG_USER="${MIRRORELF_PG_USER:-postgres}"
  PG_PASSWORD="${MIRRORELF_PG_PASSWORD:-mirrorelf}"
  PG_DATABASE="${MIRRORELF_PG_DATABASE:-mirror}"
  PG_URL="postgresql://${PG_USER}:${PG_PASSWORD}@127.0.0.1:${PG_HOST_PORT}/${PG_DATABASE}"
  sed -i "s|^  pg_database_url:.*|  pg_database_url: ${PG_URL}|" config/config.yml
  echo "[entrypoint] MIRRORELF_HOST_NETWORK=1 — pg_database_url -> 127.0.0.1:${PG_HOST_PORT} (user=${PG_USER})"
fi

# 版本日志：默认仅首次从镜像内嵌 manifest 写入卷；Hub 部署可设 MIRRORELF_SYNC_RELEASES_MANIFEST=1 每次启动覆盖（随镜像升级）
if [ -f /app/docker/releases.manifest.json ]; then
  if [ ! -f config/releases.manifest.json ] || [ "${MIRRORELF_SYNC_RELEASES_MANIFEST:-}" = "1" ]; then
    cp -f /app/docker/releases.manifest.json config/releases.manifest.json
  fi
fi

exec ./mirrorelf
