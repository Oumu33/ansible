#!/bin/bash
# 设置 Docker 测试环境 - Rocky Linux 镜像
# 使用 Rocky Linux 9 最小镜像模拟真实系统部署

set -e

ANSIBLE_DIR="/opt/ansible"
SSH_KEY="$ANSIBLE_DIR/.ssh/ansible_test_key"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查 Docker 是否运行
if ! docker info > /dev/null 2>&1; then
    log_error "Docker 未运行，请先启动 Docker"
    exit 1
fi

log_info "=== 设置 Ansible Docker 测试环境 (Rocky Linux 9) ==="

# 1. 生成 SSH 密钥对（如果不存在）
if [ ! -f "$SSH_KEY" ]; then
    log_info "生成 SSH 密钥对..."
    mkdir -p "$ANSIBLE_DIR/.ssh"
    ssh-keygen -t rsa -f "$SSH_KEY" -N "" -q
    chmod 600 "$SSH_KEY"
    chmod 644 "$SSH_KEY.pub"
else
    log_info "SSH 密钥已存在，跳过生成"
fi

# 2. 清理旧的测试容器
log_info "清理旧的测试容器..."
for project in kafka-cluster ELK VictoriaMetrics VictoriaMetrics-Full redis-cluster mongodb-replica mysql-mgr mysql-replication postgresql-cluster RabbitMQ Keepalived-Nginx; do
    if [ -f "$ANSIBLE_DIR/$project/Ubuntu/docker-test-hosts.yml" ]; then
        cd "$ANSIBLE_DIR/$project/Ubuntu"
        COMPOSE_PROJECT_NAME="${project//-/}" docker-compose -f docker-test-hosts.yml down -v 2>/dev/null || true
    fi
done

log_info "测试环境设置完成！"
log_info "SSH 密钥位置: $SSH_KEY"