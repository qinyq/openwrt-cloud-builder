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
# 2. 注入 Stackia 官方原版 (新皇登基)
# ========================================================
echo "Cloning original stackia rtp2httpd..."
mkdir -p package/custom
git clone -b stable --depth 1 https://github.com/stackia/rtp2httpd.git package/custom/rtp2httpd