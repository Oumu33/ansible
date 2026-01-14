#!/bin/bash
# 配置容器的 SSH 服务

set -e

echo "开始配置容器 SSH 服务..."

# 更新系统并安装必要的依赖
echo "1. 安装必要的依赖包..."
dnf install -y --allowerasing \
    openssh-server \
    openssh-clients \
    python3 \
    python3-pip \
    curl \
    wget \
    systemd \
    which \
    iproute \
    net-tools \
    tcpdump \
    strace \
    lsof \
    vim \
    less \
    procps-ng \
    util-linux \
    coreutils \
    grep \
    sed \
    awk \
    findutils \
    tar \
    gzip \
    unzip \
    zip \
    ca-certificates \
    openssl \
    openssl-libs \
    libxcrypt-compat

# 生成 SSH 主机密钥
echo "2. 生成 SSH 主机密钥..."
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# 配置 SSHD
echo "3. 配置 SSHD..."
cat > /etc/ssh/sshd_config.d/99-custom.conf << 'EOF'
# 允许 root 登录
PermitRootLogin yes

# 允许密码认证
PasswordAuthentication yes

# 允许公钥认证
PubkeyAuthentication yes

# 禁用 DNS 反向解析
UseDNS no

# 设置最大认证尝试次数
MaxAuthTries 3

# 设置登录超时时间
LoginGraceTime 60

# 启用 PAM
UsePAM yes

# 设置 X11 转发
X11Forwarding no

# 设置 TCP KeepAlive
TCPKeepAlive yes

# 设置 ClientAliveInterval
ClientAliveInterval 300
ClientAliveCountMax 3

# 设置最大启动数
MaxStartups 10:30:100

# 设置日志级别
LogLevel INFO

# 禁用空密码
PermitEmptyPasswords no

# 设置严格模式
StrictModes yes
EOF

# 创建 .ssh 目录
echo "4. 配置 SSH 密钥..."
mkdir -p /root/.ssh
chmod 700 /root/.ssh

# 如果提供了公钥，添加到 authorized_keys
if [ -f /tmp/ssh_public_key ]; then
    cp /tmp/ssh_public_key /root/.ssh/authorized_keys
    chmod 600 /root/.ssh/authorized_keys
    echo "SSH 公钥已配置"
fi

# 确保 SSHD 服务已启用
echo "5. 启用 SSHD 服务..."
systemctl enable sshd

# 启动 SSHD 服务
echo "6. 启动 SSHD 服务..."
systemctl start sshd

# 等待 SSHD 完全启动
sleep 2

# 检查 SSHD 状态
echo "7. 检查 SSHD 状态..."
systemctl status sshd --no-pager || true

# 检查 SSHD 是否在监听
echo "8. 检查 SSHD 监听端口..."
ss -tlnp | grep :22 || netstat -tlnp | grep :22 || echo "无法检查端口监听状态"

echo "SSH 服务配置完成！"