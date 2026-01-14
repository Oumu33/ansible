#!/bin/bash
# 设置 Docker 测试环境的脚本

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

# 2. 创建 docker-compose 卷用于存储 SSH 密钥
echo "创建 SSH 密钥卷..."
docker volume create ssh-keys

# 3. 将公钥复制到卷中
echo "复制 SSH 公钥到 Docker 卷..."
docker run --rm -v ssh-keys:/keys alpine sh -c "echo '$(cat ~/.ssh/id_rsa.pub)' > /keys/authorized_keys"

# 4. 启动测试容器
echo "启动测试容器..."
docker-compose -f docker-test-hosts.yml up -d

# 5. 等待容器启动
echo "等待容器启动..."
sleep 3

# 6. 在每个容器中安装必要组件
echo "在容器中安装必要组件..."
for container in vmselect-1 vmselect-2 vminsert-1 vminsert-2 vmstorage-1 vmstorage-2 vmstorage-3; do
    echo "配置 $container..."

    # 安装 OpenSSH 和 systemd
    docker exec $container sh -c "apk add --no-cache openssh-server openssh-client python3 py3-pip curl bash systemd"

    # 配置 SSH
    docker exec $container sh -c "ssh-keygen -A"
    docker exec $container sh -c "sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config"
    docker exec $container sh -c "sed -i 's/#PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"

    # 创建 .ssh 目录并复制授权密钥
    docker exec $container sh -c "mkdir -p /root/.ssh && chmod 700 /root/.ssh"
    docker exec $container sh -c "echo '$(cat ~/.ssh/id_rsa.pub)' > /root/.ssh/authorized_keys && chmod 600 /root/.ssh/authorized_keys"

    # 启动 SSH 服务
    docker exec $container sh -c "/usr/sbin/sshd -D &"

    echo "✓ $container 配置完成"
done

echo ""
echo "=== 测试环境设置完成 ==="
echo "容器 IP 地址："
docker network inspect ansible_vmnet | grep -A 8 "vmselect-1\|vmselect-2\|vminsert-1\|vminsert-2\|vmstorage-1\|vmstorage-2\|vmstorage-3" | grep IPv4Address | awk '{print $2}' | sed 's/\/24//' | nl -v 1 -w 2 -s '. '

echo ""
echo "下一步："
echo "1. 测试 SSH 连接：ssh root@172.20.0.10"
echo "2. 运行 Ansible 部署：ansible-playbook -i inventory/hosts-test.yml playbooks/deploy-cluster.yml"