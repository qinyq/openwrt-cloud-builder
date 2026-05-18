#!/bin/bash
# 说明：在 update feeds 之前执行，用于添加额外的软件源

# 添加自定义的 passwall 或其他源 (按需)
# echo 'src-git passwall https://github.com/xiaorouji/openwrt-passwall' >>feeds.conf.default
echo 'src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki' >>feeds.conf.default
