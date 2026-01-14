#!/bin/bash
# 测试单个 Ansible 项目
# 使用 Rocky Linux 镜像进行测试

set -e

ANSIBLE_DIR="/opt/ansible"
SSH_KEY="$ANSIBLE_DIR/.ssh/ansible_test_key"
PROJECT_NAME=""
COMPOSE_FILE="docker-test-hosts.yml"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

usage() {
    echo "用法: $0 <项目名称> [playbook]"
    echo ""
    echo "可用项目:"
    echo "  kafka-cluster      - Kafka + Zookeeper 集群"
    echo "  ELK                - Elasticsearch + Logstash + Kibana + Filebeat"
    echo "  redis-cluster      - Redis 集群"
    echo "  mongodb-replica    - MongoDB 副本集"
    echo "  mysql-mgr          - MySQL MGR 集群"
    echo "  mysql-replication  - MySQL 主从复制"
    echo "  postgresql-cluster - PostgreSQL 集群"
    echo "  RabbitMQ           - RabbitMQ 集群"
    echo "  Keepalived-Nginx   - Keepalived + Nginx 高可用"
    echo "  VictoriaMetrics    - VictoriaMetrics 集群"
    echo "  VictoriaMetrics-Full - VictoriaMetrics 完整集群"
    echo ""
    echo "示例:"
    echo "  $0 kafka-cluster"
    echo "  $0 ELK playbooks/deploy-cluster.yml"
    exit 1
}

if [ $# -lt 1 ]; then
    usage
fi

PROJECT_NAME="$1"
PLAYBOOK="${2:-}"

# 检查项目目录（优先使用Rocky文件夹）
PROJECT_DIR="$ANSIBLE_DIR/$PROJECT_NAME/Rocky"
if [ ! -d "$PROJECT_DIR" ]; then
    log_warn "Rocky目录不存在，尝试使用Ubuntu目录: $PROJECT_NAME"
    PROJECT_DIR="$ANSIBLE_DIR/$PROJECT_NAME/Ubuntu"
fi

if [ ! -d "$PROJECT_DIR" ]; then
    log_error "项目目录不存在: $PROJECT_DIR"
    exit 1
fi

# 检查 docker-compose 文件
if [ ! -f "$PROJECT_DIR/$COMPOSE_FILE" ]; then
    log_error "Docker Compose 文件不存在: $PROJECT_DIR/$COMPOSE_FILE"
    exit 1
fi

log_info "=== 测试项目: $PROJECT_NAME ==="

# 步骤 1: 启动 Docker 容器
log_step "1. 启动 Docker 容器..."
cd "$PROJECT_DIR"
docker-compose -f "$COMPOSE_FILE" up -d

# 等待容器启动
log_info "等待容器启动..."
sleep 5

# 获取所有容器名称
CONTAINERS=$(docker-compose -f "$COMPOSE_FILE" ps -q)
if [ -z "$CONTAINERS" ]; then
    log_error "没有找到运行的容器"
    exit 1
fi

# 步骤 2: 在容器中安装必要组件
log_step "2. 在容器中安装必要组件..."
for container in $CONTAINERS; do
    container_name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/\///')
    log_info "配置 $container_name..."

    # Rocky Linux 9 安装必要组件
    docker exec "$container" bash -c "dnf install -y --allowerasing openssh-server openssh-clients python3 python3-pip curl wget systemd which" 2>&1 || {
        log_warn "安装组件失败或已安装: $container_name，继续..."
    }

    # 配置 SSH
    docker exec "$container" bash -c "ssh-keygen -A" 2>&1 || true

    # 修改 SSH 配置允许 root 登录
    docker exec "$container" bash -c "sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config" 2>&1 || true
    docker exec "$container" bash -c "sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config" 2>&1 || true

    # 创建 .ssh 目录
    docker exec "$container" bash -c "mkdir -p /root/.ssh && chmod 700 /root/.ssh" 2>&1 || true

    # 复制 SSH 公钥
    docker cp "$SSH_KEY.pub" "$container:/root/.ssh/authorized_keys" 2>&1 || true
    docker exec "$container" bash -c "chmod 600 /root/.ssh/authorized_keys" 2>&1 || true

    # 启动 SSH 服务
    docker exec "$container" bash -c "/usr/sbin/sshd -D &" 2>&1 || true

    log_info "✓ $container_name 配置完成"
done

# 等待 SSH 服务启动
log_info "等待 SSH 服务启动..."
sleep 3

# 步骤 3: 测试 SSH 连接
log_step "3. 测试 SSH 连接..."
FIRST_CONTAINER=$(echo $CONTAINERS | awk '{print $1}')
FIRST_CONTAINER_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$FIRST_CONTAINER")

if ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 -i "$SSH_KEY" root@"$FIRST_CONTAINER_IP" "echo 'SSH 连接成功'" 2>/dev/null; then
    log_error "SSH 连接失败"
    exit 1
fi

log_info "✓ SSH 连接成功"

# 步骤 4: 运行 Ansible 部署
if [ -n "$PLAYBOOK" ]; then
    log_step "4. 运行 Ansible 部署: $PLAYBOOK"

    # 查找 inventory 文件
    INVENTORY_FILE=""
    if [ -f "$PROJECT_DIR/inventory/hosts.yml" ]; then
        INVENTORY_FILE="inventory/hosts.yml"
    elif [ -f "$PROJECT_DIR/inventory/hosts-test.yml" ]; then
        INVENTORY_FILE="inventory/hosts-test.yml"
    else
        log_error "找不到 inventory 文件"
        exit 1
    fi

    cd "$PROJECT_DIR"
    ansible-playbook -i "$INVENTORY_FILE" "$PLAYBOOK" --private-key="$SSH_KEY" -e "ansible_python_interpreter=/usr/bin/python3"

    if [ $? -eq 0 ]; then
        log_info "✓ Ansible 部署成功"
    else
        log_error "✗ Ansible 部署失败"
        exit 1
    fi
else
    log_warn "未指定 playbook，跳过 Ansible 部署"
fi

# 步骤 5: 显示容器信息
log_step "5. 容器信息:"
echo ""
COMPOSE_PROJECT_NAME="${PROJECT_NAME//-/}" docker-compose -f "$COMPOSE_FILE" ps
echo ""

log_info "=== 测试完成 ==="
log_info "容器 IP 地址:"
for container in $CONTAINERS; do
    container_name=$(docker inspect --format='{{.Name}}' "$container" | sed 's/\///')
    container_ip=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container")
    echo "  $container_name: $container_ip"
done

echo ""
log_info "SSH 连接命令:"
echo "  ssh -i $SSH_KEY root@<容器IP>"
echo ""
log_info "查看日志:"
echo "  COMPOSE_PROJECT_NAME=${PROJECT_NAME//-/} docker-compose -f $COMPOSE_FILE logs -f"
echo ""
log_info "停止容器:"
echo "  COMPOSE_PROJECT_NAME=${PROJECT_NAME//-/} docker-compose -f $COMPOSE_FILE down"