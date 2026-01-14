#!/bin/bash
# MongoDB 单机版组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/mongodb/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 MongoDB 单机版组件..."

# 下载 MongoDB
MONGODB_VERSION="7.0.9"
MONGODB_URL="https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2204-${MONGODB_VERSION}.tgz"
echo "下载 MongoDB ${MONGODB_VERSION}..."
wget -c -t 3 -T 1800 "$MONGODB_URL" -O "$DOWNLOAD_DIR/mongodb-linux-x86_64-ubuntu2204-${MONGODB_VERSION}.tgz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"