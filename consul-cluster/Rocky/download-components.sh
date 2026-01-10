#!/bin/bash
# Consul 集群组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/consul-cluster/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 Consul 集群组件..."

# 下载 Consul
CONSUL_VERSION="1.17.1"
CONSUL_URL="https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip"
echo "下载 Consul ${CONSUL_VERSION}..."
wget -c -t 3 -T 1800 "$CONSUL_URL" -O "$DOWNLOAD_DIR/consul_${CONSUL_VERSION}_linux_amd64.zip"

# 下载 Consul UI（可选，通常包含在二进制中）
echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"