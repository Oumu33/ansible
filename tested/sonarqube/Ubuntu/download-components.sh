#!/bin/bash
# SonarQube 组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/sonarqube/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 SonarQube 组件..."

# 下载 SonarQube
SONARQUBE_VERSION="10.6.0.92116"
SONARQUBE_URL="https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip"
echo "下载 SonarQube ${SONARQUBE_VERSION}..."
wget -c -t 3 -T 1800 "$SONARQUBE_URL" -O "$DOWNLOAD_DIR/sonarqube-${SONARQUBE_VERSION}.zip"

# 下载 PostgreSQL
POSTGRESQL_VERSION="16"
POSTGRESQL_URL="https://get.enterprisedb.com/postgresql/postgresql-${POSTGRESQL_VERSION}-1-linux-x64-binaries.tar.gz"
echo "下载 PostgreSQL ${POSTGRESQL_VERSION}..."
wget -c -t 3 -T 1800 "$POSTGRESQL_URL" -O "$DOWNLOAD_DIR/postgresql-${POSTGRESQL_VERSION}-linux-x64-binaries.tar.gz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"