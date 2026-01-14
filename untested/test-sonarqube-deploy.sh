#!/bin/bash
# 简化的 SonarQube 部署测试脚本

set -e

echo "=== SonarQube 代码审计部署测试 ==="

# 检查内存
echo "当前内存使用:"
free -h

# 检查容器状态
echo -e "\n容器状态:"
docker ps --filter "name=sonarqube-1\|postgresql-1" --format "table {{.Names}}\t{{.Status}}\t{{.MemUsage}}"

# 测试 PostgreSQL 容器
echo -e "\n=== 测试 PostgreSQL 容器 ==="
docker exec postgresql-1 bash -c "which psql && psql --version || echo 'PostgreSQL 未安装'"

# 测试 SonarQube 容器
echo -e "\n=== 测试 SonarQube 容器 ==="
docker exec sonarqube-1 bash -c "ls -la /opt/ 2>/dev/null || echo 'SonarQube 未安装'"

# 测试网络连接
echo -e "\n=== 测试网络连接 ==="
docker exec sonarqube-1 bash -c "ping -c 2 172.28.0.31 || echo '网络连接失败'"

echo -e "\n=== 测试完成 ==="