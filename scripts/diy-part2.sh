#!/bin/bash
###
 # @Author: qinyq qinyongqiang@gmail.com
 # @Date: 2026-05-18 16:56:09
 # @LastEditors: qinyq qinyongqiang@gmail.com
 # @LastEditTime: 2026-05-18 17:48:40
 # @FilePath: /openwrt-cloud-builder/scripts/diy-part2.sh
 # @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
### 
# 说明：在 update feeds 之后执行，用于修改默认 IP、克隆自定义包

# 1. 修改默认 LAN IP 为 192.168.99.1 (请按需修改)
sed -i 's/192.168.1.1/192.168.99.1/g' package/base-files/files/bin/config_generate


# 判断压缩包是否存在，存在则解压到 package/custom/ 目录下
if [ -f ../local-packages/openwrt-passwall2.tgz ]; then
    echo "Found openwrt-passwall2.tgz, extracting..."
    # 确保 custom 目录存在
    mkdir -p package/custom
    # 解压文件
    tar -zxvf ../local-packages/openwrt-passwall2.tgz -C package/custom/
else
    echo "Warning: openwrt-passwall2.tgz not found!"
fi