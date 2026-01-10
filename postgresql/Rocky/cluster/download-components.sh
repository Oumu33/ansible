#!/bin/bash
# PostgreSQL 集群版组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/postgresql/cluster/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 PostgreSQL 集群版组件..."

# 下载 PostgreSQL
POSTGRESQL_VERSION="16"
POSTGRESQL_URL="https://get.enterprisedb.com/postgresql/postgresql-${POSTGRESQL_VERSION}-1-linux-x64-binaries.tar.gz"
echo "下载 PostgreSQL ${POSTGRESQL_VERSION}..."
wget -c -t 3 -T 1800 "$POSTGRESQL_URL" -O "$DOWNLOAD_DIR/postgresql-${POSTGRESQL_VERSION}-linux-x64-binaries.tar.gz"

# 下载 Patroni
PATRONI_VERSION="3.1.0"
PATRONI_URL="https://github.com/zalando/patroni/archive/refs/tags/v${PATRONI_VERSION}.tar.gz"
echo "下载 Patroni ${PATRONI_VERSION}..."
wget -c -t 3 -T 1800 "$PATRONI_URL" -O "$DOWNLOAD_DIR/patroni-${PATRONI_VERSION}.tar.gz"

# 下载 Etcd
ETCD_VERSION="3.5.10"
ETCD_URL="https://github.com/etcd-io/etcd/releases/download/v${ETCD_VERSION}/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"
echo "下载 Etcd ${ETCD_VERSION}..."
wget -c -t 3 -T 1800 "$ETCD_URL" -O "$DOWNLOAD_DIR/etcd-v${ETCD_VERSION}-linux-amd64.tar.gz"

# 下载 HAProxy
HAPROXY_VERSION="2.9.6"
HAPROXY_URL="https://www.haproxy.org/download/2.9/src/haproxy-${HAPROXY_VERSION}.tar.gz"
echo "下载 HAProxy ${HAPROXY_VERSION}..."
wget -c -t 3 -T 1800 "$HAPROXY_URL" -O "$DOWNLOAD_DIR/haproxy-${HAPROXY_VERSION}.tar.gz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"