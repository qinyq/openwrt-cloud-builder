#!/bin/bash
# 说明：在 update feeds 之后执行，用于修改默认 IP、克隆自定义包
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/resolve-versions.sh"

# 1. 修改默认 LAN IP 为 192.168.99.1 (请按需修改)
sed -i 's/192.168.1.1/192.168.99.1/g' package/base-files/files/bin/config_generate


# 判断压缩包是否存在，存在则解压到 package/custom/ 目录下
if [ -f ../local-packages/openwrt-passwall2.tgz ]; then
    echo "Found openwrt-passwall2.tgz, extracting..."
    # 确保 custom 目录存在
    mkdir -p package/custom
    # 解压文件
    tar -zxf ../local-packages/openwrt-passwall2.tgz -C package/custom/
else
    echo "Warning: openwrt-passwall2.tgz not found!"
fi

# ========================================================
# 1. 物理抹杀 ImmortalWrt 官方版 rtp2httpd (拔草除根)
# ========================================================
echo "Removing official rtp2httpd from feeds..."
# 抹杀物理本体
rm -rf feeds/packages/net/rtp2httpd
rm -rf feeds/luci/applications/luci-app-rtp2httpd

# (可选：代码洁癖专属) 顺手把生成的死软链接也打扫干净
rm -rf package/feeds/*/rtp2httpd
rm -rf package/feeds/*/luci-app-rtp2httpd

# ========================================================
# 2. 注入 Stackia 官方 rtp2httpd（最新稳定 tag，不用 rolling stable 分支）
#    openwrt-support/*/Makefile 仅在「当前 commit 正好是干净 v* tag」时用语义化版本；
#    否则会回退成 date +%Y%m%d。因此必须按 release tag 检出并保留该 tag。
# ========================================================
echo "Resolving stackia/rtp2httpd stable tag..."
mkdir -p package/custom
rm -rf package/custom/rtp2httpd
RTP2HTTPD_GIT_TAG="$(resolve_rtp2httpd_stable_tag)"
if [ -z "$RTP2HTTPD_GIT_TAG" ]; then
  echo "ERROR: failed to resolve stackia/rtp2httpd stable tag" >&2
  exit 1
fi
echo "Cloning stackia/rtp2httpd at ${RTP2HTTPD_GIT_TAG}..."
git clone --depth 1 --branch "$RTP2HTTPD_GIT_TAG" \
  https://github.com/stackia/rtp2httpd.git package/custom/rtp2httpd
# 浅克隆有时没有 refs/tags；补上本地 tag，让 Makefile 的 git describe --exact-match 生效
git -C package/custom/rtp2httpd tag -f "$RTP2HTTPD_GIT_TAG" HEAD
RTP2HTTPD_PKG_VER="$(git -C package/custom/rtp2httpd describe --tags --exact-match --match 'v*' | sed 's/^v//')"
echo "rtp2httpd ready: tag=${RTP2HTTPD_GIT_TAG} PKG_VERSION=${RTP2HTTPD_PKG_VER}"

# ========================================================
# 3. 注入 daeuniverse/openwrt-packages（官方 dae / honk / LuCI）
#    https://github.com/daeuniverse/openwrt-packages
#    Makefile 要求 dae/src、honk/src 预先检出上游源码。
#    ImmortalWrt 自带内核 BTF，用 vmlinux-btf-builtin，去掉 SDK 专用的 vmlinux-btf。
# ========================================================
echo "Removing ImmortalWrt feeds dae / luci-app-dae..."
rm -rf feeds/packages/net/dae
rm -rf feeds/luci/applications/luci-app-dae
rm -rf package/feeds/*/dae
rm -rf package/feeds/*/dae-*
rm -rf package/feeds/*/luci-app-dae
rm -rf package/custom/dae

echo "Cloning daeuniverse/openwrt-packages..."
DAEUNIVERSE_DIR=package/custom/daeuniverse
rm -rf "$DAEUNIVERSE_DIR"
git clone --depth 1 https://github.com/daeuniverse/openwrt-packages.git "$DAEUNIVERSE_DIR"
# ImmortalWrt 内核自带 BTF，用仓库里的 vmlinux-btf-builtin；SDK 专用的 vmlinux-btf 会抢依赖，去掉即可。
# keys/docs/scripts/src 等是官方发 apk / 编 BTF blob 用的，留着也不影响编译，不必删。
rm -rf "$DAEUNIVERSE_DIR/vmlinux-btf"

# 版本跟官方 Makefile 默认值走（与 smoke-test-versions.sh 同一套解析）
DAE_GIT_TAG="$(parse_dae_git_tag_from_makefile "$DAEUNIVERSE_DIR/dae/Makefile")"
HONK_GIT_TAG="$(parse_honk_git_tag_from_makefile "$DAEUNIVERSE_DIR/honk/Makefile")"


echo "Checking out dae sources at ${DAE_GIT_TAG} (from official Makefile)..."
git clone --depth 1 --recurse-submodules --branch "$DAE_GIT_TAG" \
  https://github.com/daeuniverse/dae.git "$DAEUNIVERSE_DIR/dae/src"

echo "Checking out honk sources at ${HONK_GIT_TAG} (from official Makefile)..."
git clone --depth 1 --branch "$HONK_GIT_TAG" \
  https://github.com/daeuniverse/honk.git "$DAEUNIVERSE_DIR/honk/src"

echo "dae/honk ready: dae=${DAE_GIT_TAG} honk=${HONK_GIT_TAG}"

# ========================================================
# 4. 注入 jerrykuku/luci-theme-argon（上游最新稳定版）
#    https://github.com/jerrykuku/luci-theme-argon
#    Argon 3.x 已内置 Config，不再需要独立 luci-app-argon-config。
# ========================================================
echo "Removing ImmortalWrt feeds luci-theme-argon / luci-app-argon-config..."
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/luci/applications/luci-app-argon-config
rm -rf package/feeds/*/luci-theme-argon
rm -rf package/feeds/*/luci-app-argon-config
rm -rf package/custom/luci-theme-argon

ARGON_GIT_TAG="$(resolve_argon_stable_tag)"
if [ -z "$ARGON_GIT_TAG" ]; then
  echo "ERROR: failed to resolve jerrykuku/luci-theme-argon stable tag" >&2
  exit 1
fi

echo "Cloning jerrykuku/luci-theme-argon at ${ARGON_GIT_TAG}..."
git clone --depth 1 --branch "$ARGON_GIT_TAG" \
  https://github.com/jerrykuku/luci-theme-argon.git package/custom/luci-theme-argon
echo "argon ready: ${ARGON_GIT_TAG}"
