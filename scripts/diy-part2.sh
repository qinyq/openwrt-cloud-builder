#!/bin/bash
# 说明：在 update feeds 之后执行，用于修改默认 IP、克隆自定义包

# 1. 修改默认 LAN IP 为 192.168.99.1 (请按需修改)
sed -i 's/192.168.1.1/192.168.99.1/g' package/base-files/files/bin/config_generate
