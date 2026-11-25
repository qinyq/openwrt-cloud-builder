#!/bin/bash
# 冒烟测试：ImmortalWrt / Argon / dae / honk 版本解析是否可用
# 不拉完整源码树，只 ls-remote + 拉 Makefile；结束后删除临时目录。
#
# 用法：
#   ./scripts/smoke-test-versions.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib/resolve-versions.sh"

REPO_IMMORTALWRT="${REPO_IMMORTALWRT:-https://github.com/immortalwrt/immortalwrt}"
REPO_ARGON="${REPO_ARGON:-https://github.com/jerrykuku/luci-theme-argon}"
REPO_RTP2HTTPD="${REPO_RTP2HTTPD:-https://github.com/stackia/rtp2httpd}"
REPO_DAE="${REPO_DAE:-https://github.com/daeuniverse/dae}"
REPO_HONK="${REPO_HONK:-https://github.com/daeuniverse/honk}"
PACKAGES_RAW="${PACKAGES_RAW:-https://raw.githubusercontent.com/daeuniverse/openwrt-packages/main}"

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/owrt-version-smoke.XXXXXX")"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

pass=0
fail=0

ok() {
  echo "  OK  $*"
  pass=$((pass + 1))
}

bad() {
  echo "  FAIL $*" >&2
  fail=$((fail + 1))
}

echo "==> [1/5] ImmortalWrt stable tag"
IMMORTAL_TAG="$(resolve_immortalwrt_stable_tag "$REPO_IMMORTALWRT" || true)"
if [ -z "${IMMORTAL_TAG:-}" ]; then
  bad "resolve_immortalwrt_stable_tag returned empty"
elif [[ ! "$IMMORTAL_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  bad "tag format unexpected: $IMMORTAL_TAG"
elif [[ "$IMMORTAL_TAG" == *snapshot* ]] || [[ "$IMMORTAL_TAG" == openwrt-* ]]; then
  bad "got snapshot/branch-like ref: $IMMORTAL_TAG"
elif ! git_remote_tag_exists "$REPO_IMMORTALWRT" "$IMMORTAL_TAG"; then
  bad "tag does not exist on remote: $IMMORTAL_TAG"
else
  ok "ImmortalWrt=$IMMORTAL_TAG"
fi

echo "==> [2/5] jerrykuku luci-theme-argon stable tag"
ARGON_TAG="$(resolve_argon_stable_tag "$REPO_ARGON" || true)"
if [ -z "${ARGON_TAG:-}" ]; then
  bad "resolve_argon_stable_tag returned empty"
elif [[ ! "$ARGON_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  bad "tag format unexpected: $ARGON_TAG"
elif ! git_remote_tag_exists "$REPO_ARGON" "$ARGON_TAG"; then
  bad "tag does not exist on remote: $ARGON_TAG"
else
  ok "Argon=$ARGON_TAG"
fi

echo "==> [3/5] stackia rtp2httpd stable tag"
RTP2HTTPD_TAG="$(resolve_rtp2httpd_stable_tag "$REPO_RTP2HTTPD" || true)"
if [ -z "${RTP2HTTPD_TAG:-}" ]; then
  bad "resolve_rtp2httpd_stable_tag returned empty"
elif [[ ! "$RTP2HTTPD_TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  bad "tag format unexpected: $RTP2HTTPD_TAG"
elif ! git_remote_tag_exists "$REPO_RTP2HTTPD" "$RTP2HTTPD_TAG"; then
  bad "tag does not exist on remote: $RTP2HTTPD_TAG"
else
  ok "rtp2httpd=$RTP2HTTPD_TAG"
fi

echo "==> [4/5] daeuniverse Makefile pins (dae / honk)"
curl -fsSL "$PACKAGES_RAW/dae/Makefile" -o "$TMP_DIR/dae.Makefile"
curl -fsSL "$PACKAGES_RAW/honk/Makefile" -o "$TMP_DIR/honk.Makefile"

DAE_GIT_TAG="$(parse_dae_git_tag_from_makefile "$TMP_DIR/dae.Makefile" || true)"
HONK_GIT_TAG="$(parse_honk_git_tag_from_makefile "$TMP_DIR/honk.Makefile" || true)"

if [ -z "${DAE_GIT_TAG:-}" ]; then
  bad "failed to parse dae git tag from Makefile"
else
  ok "parsed dae=$DAE_GIT_TAG"
fi

if [ -z "${HONK_GIT_TAG:-}" ]; then
  bad "failed to parse honk git tag from Makefile"
else
  ok "parsed honk=$HONK_GIT_TAG"
fi

echo "==> [5/5] remote tags exist (no full clone)"
if [ -n "${DAE_GIT_TAG:-}" ]; then
  if git_remote_tag_exists "$REPO_DAE" "$DAE_GIT_TAG"; then
    ok "dae remote has $DAE_GIT_TAG"
  else
    bad "dae remote missing $DAE_GIT_TAG"
  fi
fi

if [ -n "${HONK_GIT_TAG:-}" ]; then
  if git_remote_tag_exists "$REPO_HONK" "$HONK_GIT_TAG"; then
    ok "honk remote has $HONK_GIT_TAG"
  else
    bad "honk remote missing $HONK_GIT_TAG"
  fi
fi

echo
echo "summary: pass=$pass fail=$fail (temp cleaned: $TMP_DIR)"
if [ "$fail" -ne 0 ]; then
  exit 1
fi
echo "smoke-test-versions: PASS"
