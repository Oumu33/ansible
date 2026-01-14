#!/bin/bash
# PostgreSQL 单机版组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/postgresql/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 PostgreSQL 单机版组件..."

# 下载 PostgreSQL
POSTGRESQL_VERSION="16"
POSTGRESQL_URL="https://get.enterprisedb.com/postgresql/postgresql-${POSTGRESQL_VERSION}-1-linux-x64-binaries.tar.gz"
echo "下载 PostgreSQL ${POSTGRESQL_VERSION}..."
wget -c -t 3 -T 1800 "$POSTGRESQL_URL" -O "$DOWNLOAD_DIR/postgresql-${POSTGRESQL_VERSION}-linux-x64-binaries.tar.gz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"