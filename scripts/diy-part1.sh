#!/bin/bash
# 说明：在 update feeds 之前执行，用于添加和覆盖软件源

# 1. 挂载自定义的 nikki 源（你原本的逻辑，很完美）
echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki' >> feeds.conf.default

# 2. 强力抹去官方源中关于 rtp2httpd 的旧索引（拔草）
sed -i '/rtp2httpd/d' feeds.conf.default

# 3. 把 stackia 的最新稳定分支（-b stable）以原生 feed 的身份塞进去顶替（种花）
# 注意：在 feeds.conf 里面，指定分支的语法是 'src-git 源名 仓库地址;分支名'
echo 'src-git rtp2httpd https://github.com/stackia/rtp2httpd.git;stable' >> feeds.conf.default
