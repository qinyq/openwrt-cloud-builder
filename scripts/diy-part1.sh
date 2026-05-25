#!/bin/bash
# 说明：在 update feeds 之前执行，用于添加和覆盖软件源

# 1. 挂载自定义的 nikki 源（你原本的逻辑，很完美）
echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki' >> feeds.conf.default

