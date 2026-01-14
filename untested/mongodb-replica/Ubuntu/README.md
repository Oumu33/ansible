# MongoDB 副本集高可用方案

## 架构说明

本方案使用 MongoDB 副本集实现高可用，支持自动故障转移。

```
┌─────────────────────────────────────────────────────┐
│  MongoDB 副本集（3 节点）                            │
│  ┌──────────────────────────────────────┐          │
│  │ Primary (可写)                       │          │
│  │ 172.27.0.10:27017                   │          │
│  └──────────────────────────────────────┘          │
│         ↓ 复制                                      │
│  ┌──────────────────────────────────────┐          │
│  │ Secondary (只读)                     │          │
│  │ 172.27.0.11:27017                   │          │
│  └──────────────────────────────────────┘          │
│         ↓ 复制                                      │
│  ┌──────────────────────────────────────┐          │
│  │ Secondary (只读)                     │          │
│  │ 172.27.0.12:27017                   │          │
│  └──────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## 快速开始

### 1. 启动 Docker 测试环境

```bash
cd /opt/ansible/mongodb-replica
docker-compose -f docker-test-hosts.yml up -d
```

### 2. 安装必要软件

```bash
for container in mongodb-1 mongodb-2 mongodb-3; do
  docker exec $container bash -c "apt-get update && apt-get install -y openssh-server wget"
  docker exec $container bash -c "mkdir -p /run/sshd && /usr/sbin/sshd"
done
```

### 3. 配置 SSH 密钥认证

```bash
ssh-keygen -t rsa -f /tmp/ansible_key -N "" -q

for container in mongodb-1 mongodb-2 mongodb-3; do
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

### 1. 检查副本集状态

```bash
docker exec mongodb-1 /usr/local/mongodb/bin/mongosh --eval "rs.status()"
```

### 2. 测试故障转移

```bash
# 停止 Primary
docker stop mongodb-1

# 等待自动选举（约 10 秒）

# 查看新 Primary
docker exec mongodb-2 /usr/local/mongodb/bin/mongosh --eval "rs.status()"
```

## 端口映射

| 组件 | 容器端口 | 宿主机端口 |
|------|---------|-----------|
| MongoDB 1 | 27017 | 27017 |
| MongoDB 2 | 27017 | 27018 |
| MongoDB 3 | 27017 | 27019 |