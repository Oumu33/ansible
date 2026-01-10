#!/bin/bash
# 设置 Docker 测试环境的脚本（Rocky Linux）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== 设置 Ansible Docker 测试环境 ==="

# 1. 生成 SSH 密钥对（如果不存在）
if [ ! -f ~/.ssh/id_rsa ]; then
    echo "生成 SSH 密钥对..."
    ssh-keygen -t rsa -f ~/.ssh/id_rsa -N "" -q
else
    echo "SSH 密钥已存在，跳过生成"
fi

# 2. 启动测试容器
echo "启动测试容器..."
docker-compose -f docker-test-hosts.yml up -d

# 3. 等待容器启动
echo "等待容器启动..."
sleep 5

# 4. 在每个容器中配置 SSH
echo "在容器中配置 SSH..."
for container in vmselect-1 vmselect-2 vminsert-1 vminsert-2 vmstorage-1 vmstorage-2 vmstorage-3; do
    echo "配置 $container..."

    # 生成 SSH 密钥
    docker exec $container bash -c "ssh-keygen -A"

    # 配置 SSH 允许 root 登录
    docker exec $container bash -c "sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config"

    # 创建 .ssh 目录并复制授权密钥
    docker exec $container bash -c "mkdir -p /root/.ssh && chmod 700 /root/.ssh"
    docker exec $container bash -c "echo '$(cat ~/.ssh/id_rsa.pub)' > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"

    # 启动 SSH 服务
    docker exec $container bash -c "/usr/sbin/sshd -D &"

    echo "✓ $container 配置完成"
done

echo ""
echo "=== 测试环境设置完成 ==="
echo "容器 IP 地址："
docker network inspect VictoriaMetrics_Rocky_vmnet 2>/dev/null || docker network inspect vmnet 2>/dev/null | grep -A 8 "vmselect-1\|vmselect-2\|vminsert-1\|vminsert-2\|vmstorage-1\|vmstorage-2\|vmstorage-3" | grep IPv4Address | awk '{print $2}' | sed 's/\/24//' | nl -v 1 -w 2 -s '. ' || echo "容器已启动"

echo ""
echo "下一步："
echo "1. 测试 SSH 连接：ssh -o StrictHostKeyChecking=no root@172.20.0.10"
echo "2. 运行 Ansible 部署：ansible-playbook -i inventory/hosts-test.yml playbooks/deploy-cluster.yml"