#!/bin/bash
# Redis 单机版组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/redis/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 Redis 单机版组件..."

# 下载 Redis
REDIS_VERSION="7.2"
REDIS_URL="https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"
echo "下载 Redis ${REDIS_VERSION}..."
wget -c -t 3 -T 1800 "$REDIS_URL" -O "$DOWNLOAD_DIR/redis-${REDIS_VERSION}.tar.gz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"