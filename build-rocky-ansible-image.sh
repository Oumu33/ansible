#!/bin/bash
# 创建预配置的 Rocky Linux Ansible 测试镜像

set -e

IMAGE_NAME="rockylinux-ansible-test:9"

echo "=== 创建预配置的 Rocky Linux Ansible 测试镜像 ==="

# 检查镜像是否已存在
if docker images | grep -q "$IMAGE_NAME"; then
    echo "镜像已存在: $IMAGE_NAME"
    echo "如需重建，请先删除: docker rmi $IMAGE_NAME"
    exit 0
fi

# 创建 Dockerfile
cat > /tmp/Dockerfile.rocky-ansible << 'EOF'
FROM rockylinux:9

# 安装必要软件
RUN dnf install -y --allowerasing \
    openssh-server \
    openssh-clients \
    python3 \
    python3-pip \
    curl \
    wget \
    systemd \
    which \
    && dnf clean all

# 配置 SSH
RUN ssh-keygen -A \
    && sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && mkdir -p /root/.ssh \
    && chmod 700 /root/.ssh

# 创建启动脚本
RUN echo '#!/bin/bash' > /start.sh \
    && echo '/usr/sbin/sshd -D &' >> /start.sh \
    && echo 'tail -f /dev/null' >> /start.sh \
    && chmod +x /start.sh

CMD ["/start.sh"]
EOF

# 构建镜像
echo "构建镜像..."
docker build -t "$IMAGE_NAME" -f /tmp/Dockerfile.rocky-ansible /tmp

# 清理临时文件
rm -f /tmp/Dockerfile.rocky-ansible

echo ""
echo "✓ 镜像构建完成: $IMAGE_NAME"
echo ""
echo "使用方法:"
echo "  在 docker-test-hosts.yml 中将 image: rockylinux:9 改为 image: $IMAGE_NAME"