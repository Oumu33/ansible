#!/bin/bash
# RabbitMQ 测试脚本 - 包含 Erlang 26.2.5 编译安装

set -e

echo "=== RabbitMQ 测试 ==="
echo "版本信息:"
echo "- Erlang: 26.2.5"
echo "- RabbitMQ: 3.13.7"
echo ""
echo "注意: 此测试使用单节点模式以节省内存"
echo "生产环境请使用完整集群配置"

cd /opt/ansible/RabbitMQ/Rocky

# 启动容器（只启动一个节点以节省内存）
echo "启动 RabbitMQ 测试容器..."
docker-compose -f docker-test-hosts.yml up -d rabbitmq-1 2>&1 | grep -v "orphan" || true

# 等待容器启动
echo "等待容器启动..."
sleep 10

# 检查容器状态
docker ps --filter "name=rabbitmq-1" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "=== 开始安装 Erlang 26.2.5 ==="

# 复制 Erlang 源码到容器
echo "复制 Erlang 源码到容器..."
docker cp /opt/ansible/downloads/otp_src_26.2.5.tar.gz rabbitmq-1:/tmp/

# 安装编译依赖
echo "安装编译依赖..."
docker exec rabbitmq-1 bash -c "
  dnf install -y make autoconf gcc gcc-c++ glibc-devel glibc-devel.i686 \
    ncurses-devel openssl-devel unixODBC-devel wxBase3 wxGTK3-devel \
    fop xsltproc java java-devel
"

# 解压并编译安装 Erlang
echo "编译安装 Erlang 26.2.5（这可能需要几分钟）..."
docker exec rabbitmq-1 bash -c "
  cd /tmp
  tar -xzf otp_src_26.2.5.tar.gz
  cd otp_src_26.2.5
  ./configure --prefix=/usr/local
  make -j\$(nproc)
  make install
  export PATH=/usr/local/bin:\$PATH
  erl -version
  echo 'export PATH=/usr/local/bin:\$PATH' >> /root/.bashrc
"

echo ""
echo "=== 开始安装 RabbitMQ 3.13.7 ==="

# 复制 RabbitMQ 到容器
echo "复制 RabbitMQ 到容器..."
docker cp /opt/ansible/downloads/rabbitmq-server-generic-unix-3.13.7.tar.xz rabbitmq-1:/tmp/

# 解压 RabbitMQ
echo "解压 RabbitMQ..."
docker exec rabbitmq-1 bash -c "
  cd /usr/local
  tar -xf /tmp/rabbitmq-server-generic-unix-3.13.7.tar.xz
  mv rabbitmq_server-3.13.7 rabbitmq
  ln -s /usr/local/rabbitmq/sbin/* /usr/local/bin/
"

# 创建 RabbitMQ 用户
echo "创建 RabbitMQ 用户..."
docker exec rabbitmq-1 bash -c "
  useradd -r -s /bin/false rabbitmq 2>/dev/null || true
  mkdir -p /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq
  chown -R rabbitmq:rabbitmq /var/lib/rabbitmq /var/log/rabbitmq /etc/rabbitmq /usr/local/rabbitmq
"

# 配置 RabbitMQ
echo "配置 RabbitMQ..."
docker exec rabbitmq-1 bash -c "
  cat > /etc/rabbitmq/rabbitmq.conf << 'EOF'
listeners.tcp.default = 5672
management.tcp.port = 15672
loopback_users = none
EOF

  # 设置 Erlang Cookie
  echo 'RABBITMQ_ERLANG_COOKIE=test-secret-cookie-1234567890' > /etc/rabbitmq/rabbitmq-env.conf
  echo 'RABBITMQ_NODENAME=rabbit@rabbitmq-1' >> /etc/rabbitmq/rabbitmq-env.conf
  echo 'RABBITMQ_LOGS=/var/log/rabbitmq' >> /etc/rabbitmq/rabbitmq-env.conf
  echo 'RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq' >> /etc/rabbitmq/rabbitmq-env.conf
"

# 启动 RabbitMQ
echo "启动 RabbitMQ..."
docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH
  export RABBITMQ_ERLANG_COOKIE=test-secret-cookie-1234567890
  export RABBITMQ_NODENAME=rabbit@rabbitmq-1
  cd /usr/local/rabbitmq
  su - rabbitmq -s /bin/bash -c '/usr/local/rabbitmq/sbin/rabbitmq-server -detached'
"

# 等待 RabbitMQ 启动
echo "等待 RabbitMQ 启动..."
sleep 20

# 启用管理插件
echo "启用管理插件..."
docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH
  /usr/local/rabbitmq/sbin/rabbitmq-plugins enable rabbitmq_management
"

# 添加管理员用户
echo "添加管理员用户..."
docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH
  /usr/local/rabbitmq/sbin/rabbitmqctl add_user admin admin123
  /usr/local/rabbitmq/sbin/rabbitmqctl set_user_tags admin administrator
  /usr/local/rabbitmq/sbin/rabbitmqctl set_permissions -p / admin '.*' '.*' '.*'
"

echo ""
echo "=== 验证 RabbitMQ 状态 ==="

# 检查 RabbitMQ 状态
echo "1. RabbitMQ 集群状态:"
docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH
  /usr/local/rabbitmq/sbin/rabbitmqctl cluster_status
"

echo ""
echo "2. Erlang 版本:"
docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH
  erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell
"

echo ""
echo "3. RabbitMQ 版本:"
docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH
  /usr/local/rabbitmq/sbin/rabbitmqctl version
"

echo ""
echo "4. 列出用户:"
docker exec rabbitmq-1 bash -c "
  export PATH=/usr/local/bin:\$PATH
  /usr/local/rabbitmq/sbin/rabbitmqctl list_users
"

echo ""
echo "5. 检查端口监听:"
docker exec rabbitmq-1 bash -c "netstat -tlnp | grep -E '(5672|15672)' || ss -tlnp | grep -E '(5672|15672)'"

echo ""
echo "=== RabbitMQ 测试完成 ==="
echo "测试环境信息:"
echo "- RabbitMQ 管理界面: http://172.29.0.10:15672"
echo "- RabbitMQ AMQP 端口: 172.29.0.10:5672"
echo "- 管理员用户: admin / admin123"
echo ""
echo "注意: 此为单节点测试配置，生产环境请使用完整集群配置"