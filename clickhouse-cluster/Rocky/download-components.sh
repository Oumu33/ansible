#!/bin/bash
# ClickHouse 集群组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/clickhouse-cluster/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 ClickHouse 集群组件..."

# 下载 ClickHouse
CLICKHOUSE_VERSION="24.3.1.2652"
CLICKHOUSE_URL="https://packages.clickhouse.com/tgz/stable/clickhouse-common-static-${CLICKHOUSE_VERSION}.amd64.tgz"
echo "下载 ClickHouse ${CLICKHOUSE_VERSION}..."
wget -c -t 3 -T 1800 "$CLICKHOUSE_URL" -O "$DOWNLOAD_DIR/clickhouse-common-static-${CLICKHOUSE_VERSION}.amd64.tgz"

# 下载 ClickHouse Server
CLICKHOUSE_SERVER_URL="https://packages.clickhouse.com/tgz/stable/clickhouse-server-${CLICKHOUSE_VERSION}.amd64.tgz"
wget -c -t 3 -T 1800 "$CLICKHOUSE_SERVER_URL" -O "$DOWNLOAD_DIR/clickhouse-server-${CLICKHOUSE_VERSION}.amd64.tgz"

# 下载 ClickHouse Client
CLICKHOUSE_CLIENT_URL="https://packages.clickhouse.com/tgz/stable/clickhouse-client-${CLICKHOUSE_VERSION}.amd64.tgz"
wget -c -t 3 -T 1800 "$CLICKHOUSE_CLIENT_URL" -O "$DOWNLOAD_DIR/clickhouse-client-${CLICKHOUSE_VERSION}.amd64.tgz"

# 下载 Zookeeper
ZOOKEEPER_VERSION="3.9.2"
ZOOKEEPER_URL="https://downloads.apache.org/zookeeper/zookeeper-${ZOOKEEPER_VERSION}/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz"
echo "下载 Zookeeper ${ZOOKEEPER_VERSION}..."
wget -c -t 3 -T 1800 "$ZOOKEEPER_URL" -O "$DOWNLOAD_DIR/apache-zookeeper-${ZOOKEEPER_VERSION}-bin.tar.gz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"