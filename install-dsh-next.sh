#!/usr/bin/env bash
# ==============================================================================
#  DSH NEXT 桌面版 · Linux / WSL 安装 & 升级（应用 + 中文字体 + 可选浏览器）
#
#  用法：
#    bash install-dsh-next.sh                 安装；已装则自动升级到最新
#    bash install-dsh-next.sh --check         只看版本状态，不做任何改动
#    bash install-dsh-next.sh --browser       额外安装 Google Chrome
#    bash install-dsh-next.sh --force         强制重装当前版本
#    bash install-dsh-next.sh --no-fonts      跳过字体
#    DSH_VERSION=v2.0.22-next bash install-dsh-next.sh   锁定到指定版本
#
#  幂等：可重复执行。无更新时秒级返回；有更新时原地升级。
#  缓存：/tmp/dsh-install（DSH_CACHE 可改）
#  适用：Ubuntu 22.04 / 24.04、Debian 12、WSL2（需 WSLg 才有图形界面）
# ==============================================================================
set -euo pipefail

REPO="${DSH_REPO:-anywhere-labs/dsh-desktop}"
PIN_VERSION="${DSH_VERSION:-}"
CACHE_DIR="${DSH_CACHE:-/tmp/dsh-install}"
PKG_NAME="dsh-desktop-next"
WITH_BROWSER=0
FORCE=0
SKIP_FONTS=0
CHECK_ONLY=0

for a in "$@"; do
  case "$a" in
    --browser|--with-browser) WITH_BROWSER=1 ;;
    --force|-f)               FORCE=1 ;;
    --no-fonts)               SKIP_FONTS=1 ;;
    --check|-n)               CHECK_ONLY=1 ;;
    -h|--help)                sed -n '2,19p' "$0"; exit 0 ;;
    *)                        echo "未知参数: $a（--help 查看用法）" >&2; exit 2 ;;
  esac
done

SUDO=""
[ "$(id -u)" -ne 0 ] && SUDO="sudo"
log()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[!]\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m[x]\033[0m %s\n' "$*" >&2; exit 1; }

# ---------- 0. 环境检查 -------------------------------------------------------
command -v curl >/dev/null || die "缺少 curl：$SUDO apt-get install -y curl"
command -v python3 >/dev/null || die "缺少 python3：$SUDO apt-get install -y python3"

case "$(uname -m)" in
  x86_64|amd64)  DEB_ARCH=amd64 ;;
  aarch64|arm64) DEB_ARCH=arm64 ;;
  *)             die "不支持的架构：$(uname -m)" ;;
esac
log "架构 $DEB_ARCH · $(. /etc/os-release && echo "$PRETTY_NAME")"

CUR_VER=$(dpkg-query -W -f='${Version}' "$PKG_NAME" 2>/dev/null || true)
log "已安装版本：${CUR_VER:-（未安装）}"

# ---------- 1. 解析目标版本 ---------------------------------------------------
if [ -n "$PIN_VERSION" ]; then
  TAG="$PIN_VERSION"
else
  TAG=$(curl -fsSL --max-time 30 "https://api.github.com/repos/$REPO/releases/latest" \
        | python3 -c 'import sys,json;print(json.load(sys.stdin)["tag_name"])')
fi
[ -n "${TAG:-}" ] || die "无法解析发布版本"
log "最新发布版本：$TAG"

# 由 tag 推断 deb 版本号（v2.0.22-next -> 2.0.22~next），用于免下载快速比对
_tag_body="${TAG#v}"
GUESS_VER="${_tag_body%-*}~${_tag_body##*-}"

# ---------- 2. 版本决策（免下载快路径）---------------------------------------
if [ "$FORCE" -eq 0 ] && [ -n "$CUR_VER" ] && [ "$CUR_VER" = "$GUESS_VER" ]; then
  ok "已是最新（$CUR_VER），无需下载"
  NEED_INSTALL=0
elif [ "$FORCE" -eq 1 ]; then
  log "强制重装模式"
  NEED_INSTALL=1
else
  NEED_INSTALL=1
fi

if [ "$CHECK_ONLY" -eq 1 ]; then
  echo
  printf '  %-14s %s\n' "当前版本" "${CUR_VER:-未安装}"
  printf '  %-14s %s\n' "远端最新" "$TAG（deb 版本约 $GUESS_VER）"
  if [ -z "$CUR_VER" ]; then      echo "  → 未安装，可执行安装"
  elif [ "$CUR_VER" = "$GUESS_VER" ]; then echo "  → 已是最新"
  else                            echo "  → 有更新，执行脚本即升级"
  fi
  exit 0
fi

# ---------- 3. 中文字体 -------------------------------------------------------
if [ "$SKIP_FONTS" -eq 0 ]; then
  log "检查中文字体 Noto CJK / Emoji"
  if ! dpkg-query -W -f='${Status}' fonts-noto-cjk 2>/dev/null | grep -q 'install ok installed'; then
    $SUDO apt-get update -qq
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      fontconfig fonts-noto-cjk fonts-noto-color-emoji >/dev/null
  fi

  if [ ! -f /etc/fonts/local.conf ] || ! grep -q 'Noto Sans CJK SC' /etc/fonts/local.conf 2>/dev/null; then
    log "写入字体别名 /etc/fonts/local.conf（YaHei/SimSun/PingFang → Noto）"
    $SUDO tee /etc/fonts/local.conf >/dev/null <<'CONF'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <alias binding="same"><family>Microsoft YaHei</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <alias binding="same"><family>Microsoft YaHei UI</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <alias binding="same"><family>微软雅黑</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <alias binding="same"><family>SimSun</family><prefer><family>Noto Serif CJK SC</family></prefer></alias>
  <alias binding="same"><family>宋体</family><prefer><family>Noto Serif CJK SC</family></prefer></alias>
  <alias binding="same"><family>SimHei</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <alias binding="same"><family>黑体</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <alias binding="same"><family>PingFang SC</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <alias binding="same"><family>Heiti SC</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <alias binding="same"><family>Microsoft JhengHei</family><prefer><family>Noto Sans CJK TC</family></prefer></alias>
  <alias binding="same"><family>WenQuanYi Micro Hei</family><prefer><family>Noto Sans CJK SC</family></prefer></alias>
  <match target="pattern">
    <test name="lang" compare="contains"><string>zh</string></test>
    <test name="family"><string>sans-serif</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Noto Sans CJK SC</string></edit>
  </match>
  <match target="pattern">
    <test name="lang" compare="contains"><string>zh</string></test>
    <test name="family"><string>serif</string></test>
    <edit name="family" mode="prepend" binding="strong"><string>Noto Serif CJK SC</string></edit>
  </match>
</fontconfig>
CONF
    fc-cache -f >/dev/null 2>&1 || true
  fi
  ok "字体就绪（zh 匹配：$(fc-match 'sans-serif:lang=zh-cn' | cut -d: -f1)）"
fi

# ---------- 4. 下载 + 校验（仅在需要安装/升级时）------------------------------
if [ "$NEED_INSTALL" -eq 1 ]; then
  DEB_URL=$(python3 - "$REPO" "$TAG" "$DEB_ARCH" <<'PY'
import json, sys, urllib.request
repo, tag, arch = sys.argv[1:4]
req = urllib.request.Request(f"https://api.github.com/repos/{repo}/releases/tags/{tag}",
                             headers={"User-Agent": "dsh-install-script"})
for a in json.load(urllib.request.urlopen(req, timeout=30)).get("assets", []):
    if a["name"].endswith(f"-{arch}.deb"):
        print(a["browser_download_url"]); break
PY
)
  [ -n "$DEB_URL" ] || die "版本 $TAG 下找不到 $DEB_ARCH 的 .deb"
  DEB_FILE="$(basename "$DEB_URL")"

  mkdir -p "$CACHE_DIR"
  DEB="$CACHE_DIR/$DEB_FILE"
  SUMS="$CACHE_DIR/SHA256SUMS-$TAG.txt"

  if [ ! -f "$SUMS" ]; then
    log "获取校验清单 SHA256SUMS.txt"
    curl -fsSL --retry 3 --max-time 60 -o "$SUMS" \
      "https://github.com/$REPO/releases/download/$TAG/SHA256SUMS.txt"
  fi
  verify_deb() { ( cd "$CACHE_DIR" && grep -F "  $DEB_FILE" "$SUMS" | sha256sum -c --status - ) 2>/dev/null; }

  if [ -f "$DEB" ] && verify_deb; then
    log "缓存命中且校验通过：$DEB_FILE"
  else
    log "下载 $DEB_FILE"
    curl -fL --retry 3 --retry-delay 2 -o "$DEB.part" "$DEB_URL"
    mv "$DEB.part" "$DEB"
    verify_deb || die "SHA256 校验失败，文件可能损坏：$DEB"
    ok "SHA256 校验通过"
  fi

  # 用包内真实版本号做精确比对（不依赖 tag 推断）
  TARGET_VER=$(dpkg-deb -f "$DEB" Version)
  log "目标 deb 版本：$TARGET_VER"

  if [ -n "$CUR_VER" ] && [ "$FORCE" -eq 0 ]; then
    if dpkg --compare-versions "$CUR_VER" eq "$TARGET_VER"; then
      ok "已是该版本（$CUR_VER），跳过安装"
      NEED_INSTALL=0
    elif dpkg --compare-versions "$CUR_VER" gt "$TARGET_VER"; then
      warn "本地版本 $CUR_VER 高于远端 $TARGET_VER，跳过（--force 可降级重装）"
      NEED_INSTALL=0
    else
      log "升级：$CUR_VER → $TARGET_VER"
    fi
  fi
fi

# ---------- 5. 安装 / 升级 ----------------------------------------------------
if [ "$NEED_INSTALL" -eq 1 ]; then
  APT_ARGS=(-y)
  # 同版本时 apt 会判定 "already the newest" 直接跳过，强制重装需显式 --reinstall
  [ "$FORCE" -eq 1 ] && APT_ARGS+=(--reinstall)
  log "安装 $DEB_FILE（约 1.3 GB 落盘，请稍候）"
  $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install "${APT_ARGS[@]}" "$DEB"
  NEW_VER=$(dpkg-query -W -f='${Version}' "$PKG_NAME")
  if [ -n "$CUR_VER" ] && [ "$CUR_VER" != "$NEW_VER" ]; then
    ok "升级完成：$CUR_VER → $NEW_VER"
  else
    ok "安装完成：$NEW_VER"
  fi
  warn "若应用正在运行，请完全退出后重启才会生效"
fi

# ---------- 6. 可选浏览器 -----------------------------------------------------
if [ "$WITH_BROWSER" -eq 1 ]; then
  if [ "$DEB_ARCH" != amd64 ]; then
    warn "Chrome 仅提供 amd64 包，当前 $DEB_ARCH 跳过"
  elif dpkg-query -W -f='${Status}' google-chrome-stable 2>/dev/null | grep -q 'install ok installed'; then
    ok "Google Chrome 已安装，跳过"
  else
    log "安装 Google Chrome（deb，WSLg 下可用）"
    TMPD=$(mktemp -d); trap 'rm -rf "$TMPD"' EXIT
    curl -fL -o "$TMPD/chrome.deb" \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
    $SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y "$TMPD/chrome.deb"
  fi
fi

# ---------- 7. 结果自检 -------------------------------------------------------
echo
log "安装结果"
printf '  %-16s %s\n' "包版本"     "$(dpkg-query -W -f='${Version}' "$PKG_NAME")"
printf '  %-16s %s\n' "可执行文件" "$(command -v dsh-desktop-next || echo '/opt/DSH NEXT/dsh-desktop-next')"
printf '  %-16s %s\n' "安装体积"   "$($SUDO du -sh "/opt/DSH NEXT" 2>/dev/null | cut -f1)"
printf '  %-16s %s\n' "中文字体"   "$(fc-list :lang=zh 2>/dev/null | wc -l) 条目 / $(fc-match 'sans-serif:lang=zh-cn' | cut -d: -f1)"

if [ -d /mnt/wslg ]; then
  echo
  log "WSLg 已就绪，启动：dsh-desktop-next"
  log "SSH 会话需先：export DISPLAY=:0 XDG_RUNTIME_DIR=/mnt/wslg/runtime-dir WAYLAND_DISPLAY=wayland-0"
else
  warn "未检测到 WSLg，无图形界面时无法启动 GUI"
fi
echo
log "完成。"
