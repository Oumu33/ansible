#!/bin/bash
# Harbor 组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/harbor/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 Harbor 组件..."

# 下载 Harbor
HARBOR_VERSION="2.11.0"
HARBOR_URL="https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-online-installer-v${HARBOR_VERSION}.tgz"
echo "下载 Harbor ${HARBOR_VERSION}..."
wget -c -t 3 -T 1800 "$HARBOR_URL" -O "$DOWNLOAD_DIR/harbor-online-installer-v${HARBOR_VERSION}.tgz"

# 下载 PostgreSQL
POSTGRESQL_VERSION="16"
POSTGRESQL_URL="https://get.enterprisedb.com/postgresql/postgresql-${POSTGRESQL_VERSION}-1-linux-x64-binaries.tar.gz"
echo "下载 PostgreSQL ${POSTGRESQL_VERSION}..."
wget -c -t 3 -T 1800 "$POSTGRESQL_URL" -O "$DOWNLOAD_DIR/postgresql-${POSTGRESQL_VERSION}-linux-x64-binaries.tar.gz"

# 下载 Redis
REDIS_VERSION="7.2"
REDIS_URL="https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"
echo "下载 Redis ${REDIS_VERSION}..."
wget -c -t 3 -T 1800 "$REDIS_URL" -O "$DOWNLOAD_DIR/redis-${REDIS_VERSION}.tar.gz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"