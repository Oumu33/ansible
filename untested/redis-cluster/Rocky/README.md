# Redis 集群（Sentinel 高可用）

## 架构说明

本方案使用 Redis 主从复制 + Sentinel 实现高可用，支持自动故障转移。

```
┌─────────────────────────────────────────────────────┐
│  Redis Sentinel (3 节点)                             │
│  - 监控 Redis 节点                                   │
│  - 自动检测 Master 故障                              │
│  - 自动提升 Slave 为新 Master                        │
│  - 通知应用更新连接地址                              │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  Redis 主从复制集群                                  │
│  ┌──────────────────────────────────────┐          │
│  │ Master (可写)                         │          │
│  │ 172.26.0.10:6379                     │          │
│  └──────────────────────────────────────┘          │
│         ↓ 复制                                      │
│  ┌──────────────────────────────────────┐          │
│  │ Slave 1 (只读)                       │          │
│  │ 172.26.0.11:6379                     │          │
│  └──────────────────────────────────────┘          │
│         ↓ 复制                                      │
│  ┌──────────────────────────────────────┐          │
│  │ Slave 2 (只读)                       │          │
│  │ 172.26.0.12:6379                     │          │
│  └──────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## 组件说明

### 1. Redis 主从复制
- **Master**: 172.26.0.10:6379 - 主节点，可写
- **Slave 1**: 172.26.0.11:6379 - 从节点，只读
- **Slave 2**: 172.26.0.12:6379 - 从节点，只读
- **复制模式**: 异步复制

### 2. Redis Sentinel
- **Sentinel 1**: 172.26.0.13:26379
- **Sentinel 2**: 172.26.0.14:26379
- **Sentinel 3**: 172.26.0.15:26379
- **功能**:
  - 监控 Redis 节点健康
  - 自动故障转移
  - 配置提供者

## 快速开始

### 1. 启动 Docker 测试环境

```bash
cd /opt/ansible/redis-cluster
docker-compose -f docker-test-hosts.yml up -d
```

### 2. 安装必要软件

```bash
# 在所有容器中安装 SSH 和基础软件
for container in redis-1 redis-2 redis-3 sentinel-1 sentinel-2 sentinel-3; do
  docker exec $container bash -c "dnf install -y openssh-server curl wget net-tools gcc make tcl"
  docker exec $container bash -c "mkdir -p /run/sshd && /usr/sbin/sshd"
done
```

### 3. 配置 SSH 密钥认证

```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -f /tmp/ansible_key -N "" -q

# 分发公钥到所有容器
for container in redis-1 redis-2 redis-3 sentinel-1 sentinel-2 sentinel-3; do
  docker exec $container bash -c "mkdir -p /root/.ssh"
  docker cp /tmp/ansible_key.pub $container:/root/.ssh/authorized_keys
  docker exec $container bash -c "chmod 600 /root/.ssh/authorized_keys"
done
```

### 4. 部署集群

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy-all.yml --private-key=/tmp/ansible_key
```

## 验证部署

### 1. 检查 Redis 复制状态

```bash
# 在 Master 上查看
docker exec redis-1 /usr/local/redis/bin/redis-cli -a Redis@123456 info replication

# 在 Slave 上查看
docker exec redis-2 /usr/local/redis/bin/redis-cli -a Redis@123456 info replication
```

### 2. 检查 Sentinel 状态

```bash
docker exec sentinel-1 /usr/local/redis/bin/redis-cli -p 26379 -a Sentinel@123456 sentinel master mymaster
```

### 3. 测试故障转移

```bash
# 停止 Master
docker stop redis-1

# 等待 Sentinel 自动故障转移（约 10 秒）

# 查看新 Master
docker exec sentinel-1 /usr/local/redis/bin/redis-cli -p 26379 -a Sentinel@123456 sentinel master mymaster
```

## 优缺点

### 优点
- 配置简单，成熟稳定
- 自动故障转移
- 读写分离
- 应用可以通过 Sentinel 获取当前 Master 地址

### 缺点
- 异步复制，可能有数据丢失
- Master 故障时应用需要重新获取地址

## 参考文档

- [Redis Sentinel 官方文档](https://redis.io/docs/manual/sentinel/)