#!/bin/bash
# ============================================
# Nginx日志分析系统组件下载脚本
# ============================================
# 说明：下载ClickHouse、Vector、GeoIP数据库
# 作者：VictoriaMetrics-Full
# 更新时间：2026-01-18
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 创建下载目录
mkdir -p /tmp/nginx-logs-components
cd /tmp/nginx-logs-components

log_info "开始下载Nginx日志分析系统组件..."

# ============================================
# 下载ClickHouse
# ============================================

CLICKHOUSE_VERSION="24.3"

log_info "下载ClickHouse ${CLICKHOUSE_VERSION}..."

wget -O clickhouse-common-static-${CLICKHOUSE_VERSION}.amd64.tgz \
    https://github.com/ClickHouse/ClickHouse/releases/download/${CLICKHOUSE_VERSION}/clickhouse-common-static-${CLICKHOUSE_VERSION}.amd64.tgz

wget -O clickhouse-server-${CLICKHOUSE_VERSION}.amd64.tgz \
    https://github.com/ClickHouse/ClickHouse/releases/download/${CLICKHOUSE_VERSION}/clickhouse-server-${CLICKHOUSE_VERSION}.amd64.tgz

wget -O clickhouse-client-${CLICKHOUSE_VERSION}.amd64.tgz \
    https://github.com/ClickHouse/ClickHouse/releases/download/${CLICKHOUSE_VERSION}/clickhouse-client-${CLICKHOUSE_VERSION}.amd64.tgz

log_info "ClickHouse下载完成"

# ============================================
# 下载Vector
# ============================================

VECTOR_VERSION="0.52.0"

log_info "下载Vector ${VECTOR_VERSION}..."

wget -O vector-${VECTOR_VERSION}-x86_64-unknown-linux-musl.tar.gz \
    https://github.com/vectordotdev/vector/releases/download/${VECTOR_VERSION}/vector-${VECTOR_VERSION}-x86_64-unknown-linux-musl.tar.gz

log_info "Vector下载完成"

# ============================================
# 下载GeoIP数据库
# ============================================

log_info "下载GeoIP数据库..."

wget -O GeoLite2-City.mmdb \
    https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb

log_info "GeoIP数据库下载完成"

# ============================================
# 验证下载文件
# ============================================

log_info "验证下载文件..."

FILES=(
    "clickhouse-common-static-${CLICKHOUSE_VERSION}.amd64.tgz"
    "clickhouse-server-${CLICKHOUSE_VERSION}.amd64.tgz"
    "clickhouse-client-${CLICKHOUSE_VERSION}.amd64.tgz"
    "vector-${VECTOR_VERSION}-x86_64-unknown-linux-musl.tar.gz"
    "GeoLite2-City.mmdb"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        SIZE=$(du -h "$file" | cut -f1)
        log_info "✓ $file ($SIZE)"
    else
        log_error "✗ $file 下载失败"
        exit 1
    fi
done

# ============================================
# 完成
# ============================================

log_info "所有组件下载完成！"
log_info "下载目录: /tmp/nginx-logs-components"
log_info ""
log_info "下一步："
log_info "1. 将组件传输到目标主机"
log_info "2. 运行部署playbook: ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml"