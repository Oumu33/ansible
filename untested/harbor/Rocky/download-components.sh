#!/bin/bash
# ============================================
# Harbor组件下载脚本
# ============================================
# 说明：下载Harbor安装包
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
mkdir -p /tmp
cd /tmp

log_info "开始下载Harbor组件..."

# ============================================
# 下载Harbor
# ============================================

HARBOR_VERSION="2.11.0"

log_info "下载Harbor ${HARBOR_VERSION}..."

wget -O harbor-online-installer-v${HARBOR_VERSION}.tgz \
    https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-online-installer-v${HARBOR_VERSION}.tgz

log_info "Harbor下载完成"

# ============================================
# 验证下载文件
# ============================================

log_info "验证下载文件..."

FILES=(
    "harbor-online-installer-v${HARBOR_VERSION}.tgz"
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
log_info "下载目录: /tmp"
log_info ""
log_info "下一步："
log_info "1. 配置主机IP: inventory/hosts.yml"
log_info "2. 运行部署playbook: ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml"