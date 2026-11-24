#!/bin/sh
set -e
cd /app

mkdir -p config config/seo log log/app log/access data doc templates prompt website _/static/js _/static/images _/admin

# prompt：
# - 一般文件：仅缺失时写入（用户可在文件管理改；升级不覆盖）
# - 官方 Agent skills（prompt/agent/skills/**）：随镜像覆盖，避免升级后仍读旧 SKILL.md
if [ -d /app/docker/bundled/prompt ]; then
  find /app/docker/bundled/prompt -type f | while read -r src; do
    rel="${src#/app/docker/bundled/prompt/}"
    case "$rel" in
      agent/skills/*) continue ;;
    esac
    dest="prompt/${rel}"
    if [ ! -f "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  done
  if [ -d /app/docker/bundled/prompt/agent/skills ]; then
    mkdir -p prompt/agent/skills
    # 覆盖官方 skill；不删除用户自行安装、镜像里没有的 skill 目录。
    # 若卷上误放了同名「文件」（曾用 DIY/文件管理写成 skills/<名> 而非 <名>/SKILL.md），
    # mkdir -p 会失败且 set -e 导致容器起不来——先挪开再同步。
    find /app/docker/bundled/prompt/agent/skills -type f | while read -r src; do
      rel="${src#/app/docker/bundled/prompt/}"
      dest="prompt/${rel}"
      parent="$(dirname "$dest")"
      if [ -e "$parent" ] && [ ! -d "$parent" ]; then
        bak="${parent}.file.bak.$(date +%s)"
        echo "[entrypoint] skill path was a file, moving aside: $parent -> $bak"
        mv -f "$parent" "$bak" || rm -f "$parent"
      fi
      mkdir -p "$parent"
      cp -a "$src" "$dest"
    done
  fi
fi

# SEO 预设：仅缺失时从镜像写入 config/seo（用户可改；升级不覆盖已有文件）
if [ -d /app/docker/bundled/seo ]; then
  find /app/docker/bundled/seo -type f \( -name '*.yml' -o -name '*.yaml' \) | while read -r src; do
    rel="${src#/app/docker/bundled/seo/}"
    dest="config/seo/${rel}"
    if [ ! -f "$dest" ]; then
      mkdir -p "$(dirname "$dest")"
      cp -a "$src" "$dest"
    fi
  done
fi

# 管理后台随镜像更新；_/static 为用户目录，永不从镜像覆盖
if [ -d /app/docker/bundled/admin ]; then
  cp -a /app/docker/bundled/admin/. _/admin/
fi
# 旧版 favicon 在 _/static，迁移到 _/admin（仅当新路径不存在时）
if [ ! -f _/admin/favicon.ico ] && [ -f _/static/favicon.ico ]; then
  cp -a _/static/favicon.ico _/admin/favicon.ico
fi

# bind mount 由 install/root 创建时多为 root 属主；启动前改为应用用户可写
if [ "$(id -u)" = "0" ] && [ "$1" != "--app" ]; then
  chown -R mirrorelf:mirrorelf config log data doc templates prompt website _/static _/admin 2>/dev/null || true
  exec su -s /bin/sh mirrorelf -c '/app/entrypoint.sh --app'
fi
[ "$1" = "--app" ] && shift

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

# 版本日志：首次写入卷；镜像版本高于卷内时自动同步；MIRRORELF_SYNC_RELEASES_MANIFEST=1 强制覆盖；MIRRORELF_KEEP_RELEASES_MANIFEST=1 禁止自动同步
if [ -f /app/docker/releases.manifest.json ]; then
  if [ ! -f config/releases.manifest.json ]; then
    cp -f /app/docker/releases.manifest.json config/releases.manifest.json
  elif [ "${MIRRORELF_SYNC_RELEASES_MANIFEST:-}" = "1" ]; then
    cp -f /app/docker/releases.manifest.json config/releases.manifest.json
  elif [ "${MIRRORELF_KEEP_RELEASES_MANIFEST:-}" != "1" ]; then
    bundled_ver=$(grep -m1 '"version"' /app/docker/releases.manifest.json | sed -E 's/.*"version": *"([^"]+)".*/\1/')
    config_ver=$(grep -m1 '"version"' config/releases.manifest.json | sed -E 's/.*"version": *"([^"]+)".*/\1/')
    if [ -n "$bundled_ver" ] && [ "$bundled_ver" != "$config_ver" ]; then
      cp -f /app/docker/releases.manifest.json config/releases.manifest.json
    fi
  fi
fi

exec ./mirrorelf
