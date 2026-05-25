#!/bin/bash
# 说明：在 update feeds 之后执行，用于修改默认 IP、克隆自定义包

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