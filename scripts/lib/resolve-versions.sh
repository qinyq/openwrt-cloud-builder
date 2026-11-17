#!/bin/bash
# 共享版本解析逻辑：ImmortalWrt 稳定 tag、daeuniverse Makefile 默认 pin
# 供 diy-part2.sh 与 smoke-test-versions.sh 复用，避免两处漂移。

resolve_immortalwrt_stable_tag() {
  local repo_url="${1:-https://github.com/immortalwrt/immortalwrt}"
  git ls-remote --tags --refs "$repo_url" 'v*' \
    | awk -F/ '{print $NF}' \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -1
}

# 从 dae/Makefile 解析默认 PKG_VERSION，并变成 git tag（补 v 前缀）
parse_dae_git_tag_from_makefile() {
  local makefile="$1"
  local version
  version="$(sed -n 's/^PKG_VERSION:=.*\$(if[^,]*,[^,]*,\([^)]*\)).*/\1/p' "$makefile" | head -1)"
  [ -n "$version" ] || version="$(sed -n 's/^PKG_VERSION:=//p' "$makefile" | head -1)"
  version="${version#"${version%%[![:space:]]*}"}"
  version="${version%"${version##*[![:space:]]}"}"
  [ -n "$version" ] || return 1
  printf 'v%s\n' "${version#v}"
}

# 从 honk/Makefile 解析默认 HONK_GIT_TAG
parse_honk_git_tag_from_makefile() {
  local makefile="$1"
  local tag
  tag="$(sed -n 's/^HONK_GIT_TAG:=.*\$(if[^,]*,[^,]*,\([^)]*\)).*/\1/p' "$makefile" | head -1)"
  [ -n "$tag" ] || tag="$(sed -n 's/^HONK_GIT_TAG:=//p' "$makefile" | head -1)"
  tag="${tag#"${tag%%[![:space:]]*}"}"
  tag="${tag%"${tag##*[![:space:]]}"}"
  [ -n "$tag" ] || return 1
  printf '%s\n' "$tag"
}

# 确认远端存在该 tag（不 clone）
git_remote_tag_exists() {
  local repo_url="$1"
  local tag="$2"
  git ls-remote --tags --refs "$repo_url" "refs/tags/${tag}" | grep -q .
}
