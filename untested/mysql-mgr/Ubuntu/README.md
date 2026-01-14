# MySQL Group Replication (MGR) + Router 高可用方案

## 架构说明

本方案使用 MySQL Group Replication (MGR) + MySQL Router 实现高可用，支持自动故障转移和读写分离。

```
┌─────────────────────────────────────────────────────┐
│  应用层                                              │
│         ↓                                           │
│  ┌──────────────────────────────────────┐          │
│  │  MySQL Router (智能路由)             │          │
│  │  - 写请求 → Primary 节点             │          │
│  │  - 读请求 → Secondary 节点           │          │
│  │  - 自动感知 Primary 变化             │          │
│  │  - 端口: 6446(读), 6447(写)          │          │
│  └──────────────────────────────────────┘          │
│         ↓                                           │
│  ┌──────────────────────────────────────┐          │
│  │  MGR 集群 (3 节点)                    │          │
│  │  ┌──────────────────────────────┐   │          │
│  │  │ Primary (可写)                │   │          │
│  │  │ 172.25.0.10:3306             │   │          │
│  │  └──────────────────────────────┘   │          │
│  │  ┌──────────────────────────────┐   │          │
│  │  │ Secondary (只读)              │   │          │
│  │  │ 172.25.0.11:3306             │   │          │
│  │  └──────────────────────────────┘   │          │
│  │  ┌──────────────────────────────┐   │          │
│  │  │ Secondary (只读)              │   │          │
│  │  │ 172.25.0.12:3306             │   │          │
│  │  └──────────────────────────────┘   │          │
│  └──────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## 组件说明

### 1. MySQL Group Replication (MGR)
- **MGR 节点 1**: 172.25.0.10:3306 - Primary/Secondary
- **MGR 节点 2**: 172.25.0.11:3306 - Primary/Secondary
- **MGR 节点 3**: 172.25.0.12:3306 - Primary/Secondary
- **复制模式**: 基于 Paxos 的同步复制
- **模式**: 单主模式（Single Primary）

### 2. MySQL Router
- **作用**: 智能路由、读写分离、自动故障转移
- **地址**: 172.25.0.13
- **端口**:
  - 6446: 读端口（路由到 Secondary）
  - 6447: 写端口（路由到 Primary）
  - 6448: 读端口（路由到 Secondary）

## 快速开始

### 1. 启动 Docker 测试环境

```bash
cd /opt/ansible/mysql-mgr
docker-compose -f docker-test-hosts.yml up -d
```

### 2. 安装必要软件

```bash
# 在所有容器中安装 SSH 和基础软件
for container in mysql-mgr-1 mysql-mgr-2 mysql-mgr-3 router-1; do
  docker exec $container bash -c "apt-get update && apt-get install -y openssh-server curl wget net-tools"
  docker exec $container bash -c "mkdir -p /run/sshd && /usr/sbin/sshd"
done
```

### 3. 配置 SSH 密钥认证

```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -f /tmp/ansible_key -N "" -q

# 分发公钥到所有容器
for container in mysql-mgr-1 mysql-mgr-2 mysql-mgr-3 router-1; do
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

### 1. 检查 MGR 集群状态

```bash
# 在任意 MGR 节点查看
docker exec mysql-mgr-1 /usr/local/mysql/bin/mysql -u root -p'Root@123456' -e "SELECT * FROM performance_schema.replication_group_members;"
```

输出示例：
```
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| CHANNEL_NAME              | MEMBER_ID                            | MEMBER_HOST | MEMBER_PORT | MEMBER_STATE | MEMBER_ROLE | MEMBER_VERSION |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
| group_replication_applier | 12345678-1234-1234-1234-123456789abc | mysql-mgr-1 |        3306 | ONLINE       | PRIMARY     | 8.0.40         |
| group_replication_applier | 87654321-4321-4321-4321-210987654321 | mysql-mgr-2 |        3306 | ONLINE       | SECONDARY   | 8.0.40         |
| group_replication_applier | abcdef01-2345-3456-4567-567890123456 | mysql-mgr-3 |        3306 | ONLINE       | SECONDARY   | 8.0.40         |
+---------------------------+--------------------------------------+-------------+-------------+--------------+-------------+----------------+
```

### 2. 测试读写分离

```bash
# 写操作（通过 Router 写端口）
docker exec router-1 /usr/local/mysql/bin/mysql -h 127.0.0.1 -P 6447 -u root -p'Root@123456' -e "CREATE DATABASE test;"

# 读操作（通过 Router 读端口）
docker exec router-1 /usr/local/mysql/bin/mysql -h 127.0.0.1 -P 6446 -u root -p'Root@123456' -e "SHOW DATABASES;"
```

### 3. 测试故障转移

```bash
# 停止 Primary
docker stop mysql-mgr-1

# 等待 MGR 自动选举（约 10 秒）

# 查看新 Primary
docker exec mysql-mgr-2 /usr/local/mysql/bin/mysql -u root -p'Root@123456' -e "SELECT * FROM performance_schema.replication_group_members;"

# 测试写操作（应该自动路由到新 Primary）
docker exec router-1 /usr/local/mysql/bin/mysql -h 127.0.0.1 -P 6447 -u root -p'Root@123456' -e "CREATE DATABASE test2;"
```

## 配置说明

### 全局变量 (inventory/group_vars/all.yml)

```yaml
mysql_version: "8.0.40"
mysql_root_password: "Root@123456"
mysql_replication_user: "repl"
mysql_replication_password: "Repl@123456"

mgr_group_name: "mgr_cluster"
mgr_group_seeds: "172.25.0.10:33061,172.25.0.11:33061,172.25.0.12:33061"

router_bootstrap_port: 6446
router_read_write_port: 6447
router_read_only_port: 6448
```

### 主机清单 (inventory/hosts.yml)

```yaml
mgr_cluster:
  hosts:
    mysql-mgr-1:   # MGR 节点 1
      ansible_host: 172.25.0.10
    mysql-mgr-2:   # MGR 节点 2
      ansible_host: 172.25.0.11
    mysql-mgr-3:   # MGR 节点 3
      ansible_host: 172.25.0.12

router:
  hosts:
    router-1:     # MySQL Router
      ansible_host: 172.25.0.13
```

## 端口映射

| 组件 | 容器端口 | 宿主机端口 |
|------|---------|-----------|
| MGR 节点 1 | 3306 | - |
| MGR 节点 2 | 3306 | - |
| MGR 节点 3 | 3306 | - |
| Router | 6446 | 6446 (读) |
| Router | 6447 | 6447 (写) |
| Router | 6448 | 6448 (读) |

## 故障转移流程

1. **检测故障**: MGR 集群检测到 Primary 宕机
2. **自动选举**: 剩余节点投票选举新 Primary
3. **Router 感知**: Router 自动检测到 Primary 变化
4. **路由更新**: Router 更新路由表
5. **应用无感知**: 应用无需修改，自动路由到新 Primary

## MGR 工作原理

### 单主模式
- 只有一个 Primary 可写
- 其他节点为 Secondary，只读
- 基于 Paxos 算法选举 Primary
- 同步复制，保证数据一致性

### 复制流程
1. Primary 接收写请求
2. 写入本地 binlog
3. 发送给所有 Secondary
4. 等待多数节点确认
5. 提交事务并返回成功

## 优缺点

### 优点
- 官方内置，无需额外工具
- 自动故障转移，秒级切换
- 同步复制，数据一致性强
- Router 自动路由，应用无感知
- 读写分离透明

### 缺点
- 需要 MySQL 8.0+
- 网络延迟影响性能
- 配置相对复杂
- 只支持单主模式写操作

## 生产环境建议

1. 使用至少 3 个节点保证高可用
2. 配置网络延迟监控
3. 使用 Router 实现读写分离
4. 定期备份 Primary 数据
5. 监控 MGR 集群状态
6. 配置告警通知

## 与主从复制的区别

| 特性 | 主从复制 | MGR |
|------|---------|-----|
| 复制方式 | 异步复制 | 同步复制 |
| 故障转移 | 需要额外工具 | 自动选举 |
| 数据一致性 | 可能丢失 | 强一致性 |
| 配置复杂度 | 简单 | 中等 |
| 写节点 | 单节点 | 单节点（单主模式） |
| 读节点 | 多个 | 多个 |

## 参考文档

- [MySQL Group Replication 官方文档](https://dev.mysql.com/doc/refman/8.0/en/group-replication.html)
- [MySQL Router 官方文档](https://dev.mysql.com/doc/mysql-router/8.0/en/)