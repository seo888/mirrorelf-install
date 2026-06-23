# mirrorelf-install

MirrorElf锛堥暅鍍忕簿鐏碉級Docker 涓€閿畨瑁呬粨搴撱€?
> 鏈粨搴?*浠呭惈**瀹夎鑴氭湰涓?Compose锛?*涓嶅惈**涓氬姟婧愮爜銆傜▼搴忎互 Docker Hub 闀滃儚 [`seo888/mirrorelf`](https://hub.docker.com/r/seo888/mirrorelf) 鍒嗗彂銆?
[English](#english) 路 [涓枃](#涓枃)

## 馃搶 瀵艰埅

鏍囩鏂囨。 鈫?[Mirror-Elf庐 鏍囩鏂囨。](https://dynalist.io/d/pDZjfOHDp4AefwWeQT1MIgn3#theme=light)

---

## 涓枃

### 浜у搧绠€浠?
MirrorElf锛堥暅鍍忕簿鐏碉級鏄潰鍚?**缃戠珯闀滃儚銆佺紦瀛樹笌 SEO 杩愯惀** 鐨勮嚜鎵樼骞冲彴锛氬疄鏃跺悓姝ョ洰鏍囩珯銆佸皢椤甸潰缂撳瓨鍒?PostgreSQL锛屽苟鎻愪緵鐜颁唬鍖栫鐞嗗悗鍙帮紝鐢ㄤ簬绔欑偣閰嶇疆銆乀DK/AI 鏀瑰啓銆佽湗铔涚粺璁°€佹暟鎹噰闆嗕笌鎵归噺杩愮淮銆?
### 鏍稿績浼樺娍

- **瀹炴椂闀滃儚** 鈥?鍐呯疆 `/-/` 浠ｇ悊鎷夊彇骞剁紦瀛樼洰鏍囬〉锛岄€傚悎杩佺Щ銆佸浠戒笌澶氱珯鎵樼
- **瀹屾暣绠＄悊鍚庡彴** 鈥?Svelte 鍗曢〉搴旂敤锛坄/_/admin/`锛夛細缃戠珯銆佺紦瀛樸€佺洰鏍囩珯銆佹枃浠躲€佺珯鐐规娴嬨€佹暟鎹噰闆?- **AI 灏辩华** 鈥?鍏煎 OpenAI 鎺ュ彛锛涙鏂囨彁鍙栥€乀DK 鐢熸垚銆佹浛鎹㈣寤鸿涓庣綉绔欑紦瀛樻祦绋嬭仈鍔?- **SEO 涓庤湗铔?* 鈥?QPS/鏈€杩戣闂€乻itemap銆佽湗铔涚瓥鐣ャ€佹寚瀹氬嚭鍙?IP
- **杩愮淮鍙嬪ソ** 鈥?Docker Compose 涓€閿捣鏈嶅姟锛堝簲鐢?+ Postgres锛夛紱鍙€?Watchtower 璺熼殢 Hub 鑷姩鏇存柊
- **鏈嶅姟鍣ㄦ棤闇€缂栬瘧** 鈥?鎷夊彇棰勬瀯寤洪暅鍍忓嵆鍙紱閰嶇疆涓庢暟鎹繚瀛樺湪 Docker 鍗?
### 鎶€鏈爤

| 灞傜骇 | 鎶€鏈?|
|------|------|
| 杩愯鏃?| Rust锛圱okio锛夛紝鍗曚簩杩涘埗閮ㄧ讲 |
| Web 妗嗘灦 | Axum銆乀ower锛堝帇缂┿€佷細璇濈瓑锛?|
| 鏁版嵁搴?| PostgreSQL 16锛圕ompose 瀹樻柟闀滃儚锛?|
| 鏁版嵁璁块棶 | SQLx锛堝紓姝?Postgres锛?|
| 鍑虹珯 HTTP | Reqwest锛坮ustls锛夛紝鏀寔澶?IP / 浠ｇ悊鍦烘櫙 |
| 椤甸潰澶勭悊 | scraper銆乴ol_html銆乵arkup_fmt锛涘垎鍧楃紦瀛橈紙lz4銆乫astcdc 绛夛級 |
| 绠＄悊绔?| Svelte 5 + Vite锛堟瀯寤鸿繘闀滃儚 `/_/admin/`锛?|
| 璁よ瘉 | axum-login銆丄rgon2銆乼ower-sessions |
| 鐩戞帶 | Prometheus 鎸囨爣锛坅xum-prometheus锛?|
| 閮ㄧ讲 | Docker / Docker Compose锛涢暅鍍忓彂甯冧簬 Docker Hub |
| 鍙€夌粍浠?| Watchtower锛堢害姣?10 鍒嗛挓妫€鏌?Hub 鏇存柊锛?|

### 鏂版満瀹夎淇濆绾ф暀绋?
浠庨浂閮ㄧ讲锛堝惈 kejilion 闈㈡澘銆丏ocker銆佸彲閫?1Panel銆侀浄姹?WAF锛夊彲鎸変互涓嬫楠ゆ搷浣溿€?
#### 1. 瀹夎 curl 涓?vim锛堟寜绯荤粺閫夛級

**Debian / Ubuntu**

```bash
apt update -y && apt install -y curl vim jq tar
```

**CentOS**

```bash
yum update -y && yum install -y curl vim jq tar
```

#### 2. 涓嬭浇瀹夎 Linux 绠＄悊鑴氭湰

```bash
curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
```

鍛戒护锛歚k` 杩涘叆闈㈡澘

#### 3. 瀹夎 Docker

`k` 杩涘叆闈㈡澘 鈫?閫夋嫨锛?*6. Docker 绠＄悊 鈻?* 鈫?**1. 瀹夎鏇存柊 Docker 鐜 鈽?*

#### 4. 瀹夎 1Panel 闈㈡澘锛堝彲閫夛級

`k` 杩涘叆闈㈡澘 鈫?閫夋嫨锛?*11. 闈㈡澘宸ュ叿 鈻?* 鈫?**3. 1Panel 鏂颁竴浠ｇ鐞嗛潰鏉?*锛堜竴璺洖杞︼級

#### 5. 涓€閿畨瑁?Mirror-Elf庐

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

#### 6. 闆锋睜闃茬伀澧?
鍏堢敤 `k` 鍛戒护瀹夎闆锋睜闃茬伀澧欙細

`k` 杩涘叆闈㈡澘 鈫?閫夋嫨锛?*11. 闈㈡澘宸ュ叿 鈻?* 鈫?**19. 闆锋睜 WAF 闃茬伀澧欓潰鏉?*

- **娉ㄦ剰锛?* 瀹夎璺緞瑕佹墜鍔ㄦ寚瀹氫负 `/www/safeline`
- **娉ㄦ剰锛?* 鏀诲嚮闃叉姢涓缃細XSS 妫€娴嬫敼涓?*浠呰瀵?*
- 瀹夎瀹屾垚鍚庨噸缃瘑鐮?
杩涘叆 WAF 缃戠珯锛歚https://<浣犵殑涓?IP>:9443`

**闃茬伀澧欏垵濮嬭缃?*

1. **闃叉姢搴旂敤** 鈫?**娣诲姞搴旂敤**
   - **濉?* 鍩熷悕锛歚*`
   - **鍒?* 443 绔彛
   - **濉?* 涓婃父鏈嶅姟鍣細`http://127.0.0.1:16888`
   - **濉?* 澶囨敞锛氬叏绔?
**鍗囩骇鐗堟湰**锛堝悗闈㈤渶瑕佸崌绾ф椂锛?
```bash
bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/manager.sh)"
```

瀹夎 Python 3锛?
```bash
apt update && apt install -y python3 python3-pip
```

#### 7. 杩涘叆 Mirror-Elf庐 鍚庡彴

`http://<浣犵殑涓?IP>/_/admin`

- 璐﹀彿锛歚admin`
- 瀵嗙爜锛歚admin`锛堣鍦ㄥ悗鍙拌缃腑灏藉揩淇敼瀵嗙爜锛?
#### 8. Docker 鏀瑰畨瑁呯洰褰曪紙杩佺Щ锛?
**CentOS**

```bash
mkdir -p /www/docker && systemctl stop docker && echo '{"data-root": "/www/docker"}' > /etc/docker/daemon.json && (command -v apt >/dev/null && apt install -y rsync || command -v yum >/dev/null && yum install -y rsync) && rsync -aP /var/lib/docker/ /www/docker/ && systemctl start docker
```

**Debian**

```bash
mkdir -p /www/docker && systemctl stop docker && echo '{"data-root": "/www/docker"}' > /etc/docker/daemon.json && apt update && apt install -y rsync && rsync -aP /var/lib/docker/ /www/docker/ && systemctl start docker
```

杩佺Щ瀹屾垚鍚庡惎鍔?MirrorElf锛?
```bash
cd /www/mirrorelf && docker compose up -d
```

#### 9. 甯哥敤鍛戒护

**鎹㈢▼搴?*锛堝厛鍦ㄦ棫绋嬪簭涓婂浠芥暟鎹級

```bash
cd /www/MirrorElf-R && docker compose down && mkdir -p /www && curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**鏇存柊绋嬪簭**锛堢▼搴忎細鑷姩鏇存柊鍒版渶鏂扮増鏈級

**鍋滄**

```bash
docker compose --env-file env.hub -f compose.hub.yml down
```

**寮€濮?*

```bash
docker compose --env-file env.hub -f compose.hub.yml up
```

**寮€濮嬶紙鍚庡彴妯″紡锛?*

```bash
cd /www/mirrorelf && docker compose --env-file env.hub -f compose.hub.yml up -d
```

### 蹇€熷畨瑁?
**鍓嶇疆鏉′欢锛?* 宸插畨瑁?[Docker](https://docs.docker.com/engine/install/) 涓?**docker compose** 鎻掍欢銆?
**涓€鏉″懡浠わ細**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**寤鸿鍏堟煡鐪嬭剼鏈啀鎵ц锛?*

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh -o install.sh
less install.sh
bash install.sh
```

**鎸囧畾闀滃儚鐗堟湰锛?*

```bash
MIRRORELF_IMAGE=seo888/mirrorelf:0.9.27 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

瀹夎鏃朵細鎻愮ず瀹夎鐩綍锛?*鐩存帴鍥炶溅** 榛樿涓?`/www/mirrorelf`锛坄compose.hub.yml`銆乣env.hub` 鍐欏湪璇ョ洰褰曪級銆備篃鍙緭鍏ヨ嚜瀹氫箟璺緞锛屾垨闈炰氦浜掞細`MIRRORELF_INSTALL_DIR=/opt/mirrorelf bash install.sh`銆?
鏁版嵁鐩綍**鐩存帴鏄犲皠鍒板涓绘満**锛堜笌 compose 鍚岀洰褰曪級锛歚config/`銆乣log/`銆乣data/`銆乣doc/`銆乣templates/`銆乣pgdata/`锛堟暟鎹簱锛夈€乣_static/`锛堢敤鎴疯嚜鍐欓潤鎬佽祫婧愶紝鍚?`js/`銆乣images/`锛夈€傚彲鐩存帴缂栬緫 `doc/target.txt`銆佹ā鏉?HTML 绛夛紱Watchtower 鎹㈤暅鍍忓悗浠嶄細淇濈暀銆傜鐞嗗悗鍙?`/_/admin` 鐢遍暅鍍?entrypoint 鍚屾锛屼笉浼氳瑕嗙洊銆傚簲鐢ㄧ洰褰曞睘涓讳负 **uid 10001**锛坄install.sh` 浼氳嚜鍔?`chown`锛夈€?
**鑻ュ惎鍔ㄦ姤 `cp: cannot create regular file 'config/config.yml': Permission denied`锛?*

```bash
cd /www/mirrorelf   # 浣犵殑瀹夎鐩綍
sudo chown -R 10001:10001 config log data doc templates _static
sudo chown -R 999:999 pgdata
docker compose -f compose.hub.yml --env-file env.hub up -d
```

浠嶅け璐ユ椂锛岀敤褰撳墠闀滃儚閲岀殑 uid 淇锛堟棫闀滃儚 uid 鍙兘涓嶆槸 10001锛夛細

```bash
uid=$(docker run --rm --entrypoint id seo888/mirrorelf:latest mirrorelf | sed -n 's/uid=\([0-9]*\).*/\1/p')
sudo chown -R "${uid}:${uid}" config log data doc templates _static
```

鑻ュ涓绘満 **5432** 宸茶鍗犵敤锛堝 1Panel 鐨?PostgreSQL锛夛紝鍦?`env.hub` 涓缃?`MIRRORELF_PG_HOST_PORT=15432`锛堝畨瑁呰剼鏈娴嬪埌鍗犵敤鏃朵細鑷姩鍐欏叆 15432锛夈€傚鍣ㄥ惎鍔ㄦ椂浼氳嚜鍔ㄦ妸鍗峰唴 `config.yml` 鐨勬暟鎹簱鍦板潃鏀逛负 `127.0.0.1:璇ョ鍙锛屽瘑鐮佷笌 compose 涓?Postgres 涓€鑷达紙`mirrorelf`锛夈€?
### 瀹夎瀹屾垚鍚?
| 椤圭洰 | 鍦板潃 |
|------|------|
| 绔欑偣 | `http://<鏈嶅姟鍣↖P>:16888/` |
| 绠＄悊鍚庡彴 | `http://<鏈嶅姟鍣↖P>:16888/_/admin/` |
| 榛樿璐﹀彿 | `admin` / `admin`锛?*鐢熶骇鐜璇风珛鍗充慨鏀?*锛?|

### Watchtower 鑷姩鏇存柊

瀹夎鏃朵細璇㈤棶锛?*鏄惁瀹夎 Watchtower锛?* 鐩存帴鍥炶溅鎴栬緭鍏?`Y` 涓洪粯璁?*瀹夎**锛堢害姣?10 鍒嗛挓妫€鏌?Hub锛夈€?
闈炰氦浜掑己鍒舵寚瀹氾細`MIRRORELF_INSTALL_WATCHTOWER=1` 鎴?`0`锛涘吋瀹?`MIRRORELF_SKIP_WATCHTOWER=1` 琛ㄧず涓嶈銆?
瀹夎鍚庢煡鐪?Watchtower 鏃ュ織锛?
```bash
cd /www/mirrorelf   # 鎴栦綘鐨勫畨瑁呯洰褰?docker compose -f compose.hub.yml --env-file env.hub --profile watchtower logs -f watchtower
```

### 鎵嬪姩瀹夎

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

### 瀹屽叏鍗歌浇

鍋滄瀹瑰櫒銆?*鍒犻櫎鏁版嵁鍗?*锛堝惈鏁版嵁搴擄級锛屽苟鍙垹闄ゅ畨瑁呯洰褰曚笌闀滃儚銆備氦浜掗粯璁ゅ潎涓?**鍥炶溅纭锛圷锛?*銆?
```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

`curl | bash` 浼氶€氳繃 `/dev/tty` 浜や簰锛涜嫢浠呮湁涓€澶?`compose.hub.yml` 涔熶細鑷姩閫夌敤銆傝嫢 shell 閲屾浘璁剧疆杩囬敊璇殑 `MIRRORELF_INSTALL_DIR`锛岃剼鏈細鎻愮ず骞舵敼鐢辨偍閫夋嫨銆?
鑻ュ畨瑁呮椂鏀硅繃鐩綍锛屽嵏杞芥椂浼氭彁绀鸿緭鍏?*瀹為檯璺緞**锛堝嬁鐩茬洰鍥炶溅榛樿 `/www/mirrorelf`锛夛紱涔熷彲浠庢娴嬪埌鐨勫€欓€夌洰褰曚腑閫夊簭鍙枫€?
闈炰氦浜掗』鑳?*鍞竴纭畾**鐩綍锛堣嚜鍔ㄦ娴嬫垨鐜鍙橀噺锛夛細

```bash
MIRRORELF_INSTALL_DIR=/www/mirrorelf MIRRORELF_YES=1 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

鍗歌浇鍚庤鑷鍦?Nginx銆侀浄姹犵瓑缃戝叧涓垹闄ゆ寚鍚戞湰鏈?`16888` 鐨勫洖婧愰厤缃€?
### 鐩綍璇存槑

| 鏂囦欢 | 璇存槑 |
|------|------|
| `install.sh` | 涓€閿畨瑁呰剼鏈?|
| `uninstall.sh` | 瀹屽叏鍗歌浇鑴氭湰 |
| `compose.hub.yml` | 搴旂敤 + Postgres锛堝彲閫?Watchtower profile锛?|
| `env.hub.example` | 闀滃儚鍚嶇ず渚?`MIRRORELF_IMAGE` |

### 璇存槑

- 鏈粨搴撲笉鍖呭惈 MirrorElf 涓氬姟婧愮爜锛涙簮鐮佷负绉佹湁缁存姢銆?- 淇敼 `compose.hub.yml` 绔彛/鍗锋椂锛岃嫢缁存姢 fork锛岃鍚屾 `install.sh` 鍐呭祵 compose 娈佃惤銆?
---

## English

### Introduction

**MirrorElf** is a self-hosted **website mirroring and SEO operations platform**. It syncs target sites in real time, caches pages in PostgreSQL, and ships a modern admin UI for site management, TDK/AI workflows, spider analytics, data collection, and batch operations.

### Key features

- **Real-time mirroring** 鈥?Built-in `/-/` proxy fetch and cache; suited for migration, backup, and multi-site hosting
- **Full admin console** 鈥?Svelte SPA at `/_/admin/`: websites, caches, targets, files, site checks, data collection
- **AI-ready** 鈥?OpenAI-compatible APIs; plain-text extraction, TDK generation, replace-line suggestions tied to cache workflows
- **SEO & spiders** 鈥?QPS/recent visits, sitemap, bot policies, configurable outbound IPs
- **Simple ops** 鈥?One Compose stack (app + Postgres); optional Watchtower updates from Docker Hub
- **No compile on server** 鈥?Pull a pre-built image; config and data live in host bind mounts under the install directory

### Tech stack

| Layer | Technology |
|-------|------------|
| Runtime | Rust (Tokio), single binary |
| Web | Axum, Tower (compression, sessions, etc.) |
| Database | PostgreSQL 16 (official Compose image) |
| Data access | SQLx (async Postgres) |
| HTTP client | Reqwest (rustls), multi-IP / proxy friendly |
| HTML | scraper, lol_html, markup_fmt; chunked cache (lz4, fastcdc, 鈥? |
| Admin UI | Svelte 5 + Vite (served at `/_/admin/` in the image) |
| Auth | axum-login, Argon2, tower-sessions |
| Metrics | Prometheus (axum-prometheus) |
| Deploy | Docker / Docker Compose; images on Docker Hub |
| Optional | Watchtower (~10 min Hub poll) |

### Quick install

**Requirements:** [Docker Engine](https://docs.docker.com/engine/install/) and the **Docker Compose v2** plugin.

**One command:**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

**Review the script first (recommended):**

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh -o install.sh
less install.sh
bash install.sh
```

**Pin an image tag:**

```bash
MIRRORELF_IMAGE=seo888/mirrorelf:0.9.27 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/install.sh | bash
```

On install you will be prompted for a directory; press **Enter** for default `/www/mirrorelf`, or set `MIRRORELF_INSTALL_DIR` for non-interactive installs.

### After install

| Item | URL |
|------|-----|
| Site | `http://<host>:16888/` |
| Admin | `http://<host>:16888/_/admin/` |
| Default login | `admin` / `admin` 鈥?**change in production** |

### Watchtower (auto-update)

The installer asks whether to enable Watchtower; **Enter** or `Y` installs it (~10 min Hub poll).

Non-interactive: `MIRRORELF_INSTALL_WATCHTOWER=1` or `0`; `MIRRORELF_SKIP_WATCHTOWER=1` skips Watchtower.

View logs: `docker compose -f compose.hub.yml --env-file env.hub --profile watchtower logs -f watchtower` (from your install directory).

### Manual install

```bash
git clone https://github.com/seo888/mirrorelf-install.git
cd mirrorelf-install
cp env.hub.example env.hub
bash install.sh
```

### Full uninstall

Stops containers, **removes volumes** (database included), and optionally deletes the install directory and images. Prompts default to **Yes** on Enter.

```bash
curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

`curl | bash` prompts via `/dev/tty`; a single detected install dir is auto-selected. Wrong `MIRRORELF_INSTALL_DIR` in your shell is ignored with a warning.

If you used a custom install path, enter it when asked (do not blindly accept `/www/mirrorelf`). Non-interactive needs a unique detected path or `MIRRORELF_INSTALL_DIR`:

```bash
MIRRORELF_INSTALL_DIR=/www/mirrorelf MIRRORELF_YES=1 \
  curl -fsSL https://raw.githubusercontent.com/seo888/mirrorelf-install/main/uninstall.sh | bash
```

Remove any Nginx / WAF upstream pointing at port **16888** on this host manually.

### Files in this repo

| File | Purpose |
|------|---------|
| `install.sh` | One-line / local install script |
| `uninstall.sh` | Full uninstall script |
| `compose.hub.yml` | App + Postgres (+ optional Watchtower) |
| `env.hub.example` | Sample `MIRRORELF_IMAGE` |

### Notes

- Application source code is **not** included; it is maintained privately.
- If you fork and change ports/volumes in `compose.hub.yml`, keep the embedded compose in `install.sh` in sync.

---

## mirrorelf-install 鐗堟湰娓呭崟鍚屾锛堝紑鍙戣€咃級

> 鏈妭渚?MirrorElf 婧愮爜浠撶淮鎶よ€呬娇鐢紱鍙戠増鏃跺皢 `releases.manifest.json` 鎺ㄩ€佸埌鏈?install 浠撳簱銆?
鍙戠増鏃跺皢 `releases.manifest.json` 鎺ㄩ€佸埌 [seo888/mirrorelf-install](https://github.com/seo888/mirrorelf-install) 浠撳簱鏍圭洰褰曪紝渚涘凡閮ㄧ讲瀹炰緥閫氳繃 `remote_manifest_url` 鎷夊彇瀹屾暣鐗堟湰鍘嗗彶銆?
### 涓€閿悓姝ワ紙鎺ㄨ崘锛?
鍦?MirrorElf 鏍圭洰褰曪紙闇€宸插厠闅?`mirrorelf-install` 鍒板悓绾х洰褰曪紝榛樿 `../mirrorelf-install`锛夛細

```powershell
.\scripts\sync-install-manifest.ps1
```

鑷畾涔?install 浠撹矾寰勬垨棰勮锛?
```powershell
.\scripts\sync-install-manifest.ps1 -InstallRepo D:\code\mirrorelf-install
.\scripts\sync-install-manifest.ps1 -DryRun
```

鑴氭湰浼氾細`config/releases.manifest.json` 鈫?`scripts/mirrorelf-install/` 鈫?install 浠撴牴鐩綍 鈫?`git commit` 鈫?`git push`銆?
### 鎵嬪姩姝ラ

```bash
# 鍦?MirrorElf 鏍圭洰褰曟洿鏂版竻鍗曞悗澶嶅埗鍒版澶勶紝鍐嶆彁浜?install 浠?cp config/releases.manifest.json scripts/mirrorelf-install/releases.manifest.json
```

```bash
# 鍦?mirrorelf-install 鍏嬮殕鐩綍
cp /path/to/MirrorElf/scripts/mirrorelf-install/releases.manifest.json ./releases.manifest.json
git add releases.manifest.json && git commit -m "chore: sync releases manifest 0.9.56" && git push
```

