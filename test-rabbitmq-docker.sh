#!/bin/bash
# RabbitMQ 测试脚本 - 使用官方 Docker 镜像
# RabbitMQ 3.13.7 with Erlang 26.x

set -e

echo "=== RabbitMQ 测试 ==="
echo "版本信息:"
echo "- RabbitMQ: 3.13.7"
echo "- Erlang: 26.x (内置)"
echo ""
echo "注意: 此测试使用单节点模式以节省内存"
echo "生产环境请使用完整集群配置"

# 拉取 RabbitMQ 官方镜像
echo "拉取 RabbitMQ 官方镜像..."
docker pull rabbitmq:3.13.7-management-alpine

# 创建自定义网络
echo "创建 Docker 网络..."
docker network create rabbitmq-net 2>/dev/null || echo "网络已存在"

# 启动 RabbitMQ 容器
echo "启动 RabbitMQ 容器..."
docker run -d \
  --name rabbitmq-1 \
  --hostname rabbitmq-1 \
  --network rabbitmq-net \
  -p 5672:5672 \
  -p 15672:15672 \
  -e RABBITMQ_DEFAULT_USER=admin \
  -e RABBITMQ_DEFAULT_PASS=admin123 \
  -e RABBITMQ_ERLANG_COOKIE=test-secret-cookie-1234567890 \
  rabbitmq:3.13.7-management-alpine

# 等待 RabbitMQ 启动
echo "等待 RabbitMQ 启动..."
sleep 20

# 检查容器状态
echo "容器状态:"
docker ps --filter "name=rabbitmq-1" --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "=== 验证 RabbitMQ 状态 ==="

# 检查 RabbitMQ 日志
echo "1. RabbitMQ 启动日志 (最后20行):"
docker logs rabbitmq-1 2>&1 | tail -20

echo ""
echo "2. Erlang 版本:"
docker exec rabbitmq-1 erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>&1

echo ""
echo "3. RabbitMQ 版本:"
docker exec rabbitmq-1 rabbitmqctl version 2>&1

echo ""
echo "4. 集群状态:"
docker exec rabbitmq-1 rabbitmqctl cluster_status 2>&1

echo ""
echo "5. 列出用户:"
docker exec rabbitmq-1 rabbitmqctl list_users 2>&1

echo ""
echo "6. 检查端口监听:"
docker exec rabbitmq-1 netstat -tlnp 2>&1 | grep -E '(5672|15672)' || docker exec rabbitmq-1 ss -tlnp 2>&1 | grep -E '(5672|15672)'

echo ""
echo "7. 测试管理 API:"
curl -s -u admin:admin123 http://localhost:15672/api/overview 2>&1 | head -30

echo ""
echo "=== RabbitMQ 测试完成 ==="
echo "测试环境信息:"
echo "- RabbitMQ 管理界面: http://localhost:15672"
echo "- RabbitMQ AMQP 端口: localhost:5672"
echo "- 管理员用户: admin / admin123"
echo ""
echo "注意: 此为单节点测试配置，生产环境请使用完整集群配置"
echo ""
echo "停止容器命令: docker stop rabbitmq-1 && docker rm rabbitmq-1"
echo "查看日志命令: docker logs -f rabbitmq-1"