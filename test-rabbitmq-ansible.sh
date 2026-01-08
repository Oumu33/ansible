#!/bin/bash
# RabbitMQ Ansible 部署测试脚本
# 使用 Rocky Linux 容器 + Ansible 部署

set -e

echo "=== RabbitMQ Ansible 部署测试 ==="
echo "版本信息:"
echo "- RabbitMQ: 3.13.7"
echo "- Erlang: 26.2.5 (源码编译)"
echo ""
echo "注意: 此测试使用单节点模式以节省内存"
echo "生产环境请使用完整集群配置"

cd /opt/ansible/RabbitMQ/Rocky

# 启动容器
echo "启动 RabbitMQ 测试容器..."
docker-compose -f docker-test-hosts.yml up -d rabbitmq-1 2>&1 | grep -v "orphan" || true

# 等待容器启动
echo "等待容器启动..."
sleep 10

# 检查容器状态
docker ps --filter "name=rabbitmq-1" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "=== 准备编译环境 ==="

# 复制源码包到容器
echo "复制源码包..."
docker cp /opt/ansible/downloads/otp_src_26.2.5.tar.gz rabbitmq-1:/tmp/
docker cp /opt/ansible/downloads/rabbitmq-server-generic-unix-3.13.7.tar.xz rabbitmq-1:/tmp/

echo ""
echo "=== 编译安装 Erlang 26.2.5 ==="

# 检查是否已安装 Erlang
docker exec rabbitmq-1 bash -c "
  if [ -f /usr/local/bin/erl ]; then
    echo 'Erlang 已安装'
    /usr/local/bin/erl -version
  else
    echo '开始编译 Erlang...'
    cd /tmp
    tar -xzf otp_src_26.2.5.tar.gz
    cd otp_src_26.2.5

    # 配置编译选项
    echo '配置编译选项...'
    ./configure --prefix=/usr/local --without-javac 2>&1 | tail -20

    # 编译（可能需要较长时间）
    echo '开始编译（这可能需要10-20分钟）...'
    make -j\$(nproc) 2>&1 | tail -30

    # 安装
    echo '安装 Erlang...'
    make install

    # 验证安装
    /usr/local/bin/erl -version
    echo 'export PATH=/usr/local/bin:\$PATH' >> /root/.bashrc
  fi
"

echo ""
echo "=== 安装 RabbitMQ 3.13.7 ==="

docker exec rabbitmq-1 bash -c "
  # 创建 RabbitMQ 用户
  useradd -r -s /bin/false rabbitmq 2>/dev/null || true

  # 创建目录
  mkdir -p /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq
  chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq

  # 解压 RabbitMQ
  cd /usr/local
  if [ ! -d /usr/local/rabbitmq ]; then
    tar -xf /tmp/rabbitmq-server-generic-unix-3.13.7.tar.xz
    mv rabbitmq_server-3.13.7 rabbitmq
    chown -R rabbitmq:rabbitmq /usr/local/rabbitmq
  fi

  # 创建符号链接
  ln -sf /usr/local/rabbitmq/sbin/* /usr/local/bin/

  # 配置 RabbitMQ
  cat > /etc/rabbitmq/rabbitmq.conf << 'EOF'
listeners.tcp.default = 5672
management.tcp.port = 15672
loopback_users = none
disk_free_limit.relative = 2.0
vm_memory_high_watermark.relative = 0.6
EOF

  # 配置环境变量
  cat > /etc/rabbitmq/rabbitmq-env.conf << 'EOF'
RABBITMQ_NODENAME=rabbit@rabbitmq-1
RABBITMQ_LOGS=/var/log/rabbitmq
RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq
RABBITMQ_ENABLED_PLUGINS_FILE=/etc/rabbitmq/enabled_plugins
EOF
"

echo ""
echo "=== 启动 RabbitMQ ==="

docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH

  # 设置 Erlang Cookie
  echo 'test-secret-cookie-1234567890' > /var/lib/rabbitmq/.erlang.cookie
  chmod 400 /var/lib/rabbitmq/.erlang.cookie
  chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie

  # 启用管理插件
  echo '[rabbitmq_management].' > /etc/rabbitmq/enabled_plugins

  # 启动 RabbitMQ
  cd /usr/local/rabbitmq
  su - rabbitmq -s /bin/bash -c '/usr/local/rabbitmq/sbin/rabbitmq-server -detached'
"

# 等待 RabbitMQ 启动
echo "等待 RabbitMQ 启动..."
sleep 25

echo ""
echo "=== 配置管理员用户 ==="

docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH

  # 添加管理员用户
  /usr/local/rabbitmq/sbin/rabbitmqctl add_user admin admin123 2>/dev/null || echo '用户已存在'

  # 设置管理员权限
  /usr/local/rabbitmq/sbin/rabbitmqctl set_user_tags admin administrator

  # 设置权限
  /usr/local/rabbitmq/sbin/rabbitmqctl set_permissions -p / admin '.*' '.*' '.*'
"

echo ""
echo "=== 验证 RabbitMQ 状态 ==="

echo "1. Erlang 版本:"
docker exec rabbitmq-1 bash -c "export PATH=/usr/local/bin:\$PATH; erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell"

echo ""
echo "2. RabbitMQ 版本:"
docker exec rabbitmq-1 bash -c "export PATH=/usr/local/bin:\$PATH; /usr/local/rabbitmq/sbin/rabbitmqctl version"

echo ""
echo "3. 集群状态:"
docker exec rabbitmq-1 bash -c "export PATH=/usr/local/bin:\$PATH; /usr/local/rabbitmq/sbin/rabbitmqctl cluster_status"

echo ""
echo "4. 列出用户:"
docker exec rabbitmq-1 bash -c "export PATH=/usr/local/bin:\$PATH; /usr/local/rabbitmq/sbin/rabbitmqctl list_users"

echo ""
echo "5. 列出队列:"
docker exec rabbitmq-1 bash -c "export PATH=/usr/local/bin:\$PATH; /usr/local/rabbitmq/sbin/rabbitmqctl list_queues"

echo ""
echo "6. 检查端口监听:"
docker exec rabbitmq-1 bash -c "netstat -tlnp 2>/dev/null | grep -E '(5672|15672)' || ss -tlnp 2>/dev/null | grep -E '(5672|15672)' || echo '端口检查命令不可用'"

echo ""
echo "7. RabbitMQ 日志（最后20行）:"
docker exec rabbitmq-1 bash -c "tail -20 /var/log/rabbitmq/rabbit@\$(hostname).log 2>/dev/null || echo '日志文件不存在'"

echo ""
echo "=== RabbitMQ 测试完成 ==="
echo "测试环境信息:"
echo "- RabbitMQ 管理界面: http://172.29.0.10:15672"
echo "- RabbitMQ AMQP 端口: 172.29.0.10:5672"
echo "- 管理员用户: admin / admin123"
echo ""
echo "注意: 此为单节点测试配置，生产环境请使用完整集群配置"
echo ""
echo "清理命令: cd /opt/ansible/RabbitMQ/Rocky && docker-compose -f docker-test-hosts.yml down"