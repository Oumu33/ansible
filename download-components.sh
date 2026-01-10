#!/bin/bash
# 下载 Kafka 和 Zookeeper 安装包到本地

set -e

DOWNLOAD_DIR="/opt/ansible/downloads"
mkdir -p "$DOWNLOAD_DIR"

KAFKA_VERSION="3.7.0"
ZOOKEEPER_VERSION="3.9.2"

echo "=== 下载安装包到本地 ==="

# 下载 Zookeeper
if [ ! -f "$DOWNLOAD_DIR/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz" ]; then
    echo "下载 Zookeeper $ZOOKEEPER_VERSION..."
    curl -L -o "$DOWNLOAD_DIR/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz" \
        "https://archive.apache.org/dist/zookeeper/zookeeper-$ZOOKEEPER_VERSION/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz"
else
    echo "Zookeeper 已存在，跳过下载"
fi

# 下载 Kafka
if [ ! -f "$DOWNLOAD_DIR/kafka_2.13-$KAFKA_VERSION.tgz" ]; then
    echo "下载 Kafka $KAFKA_VERSION..."
    curl -L -o "$DOWNLOAD_DIR/kafka_2.13-$KAFKA_VERSION.tgz" \
        "https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz"
else
    echo "Kafka 已存在，跳过下载"
fi

echo ""
echo "下载完成！"
ls -lh "$DOWNLOAD_DIR/"