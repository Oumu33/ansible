# MySQL 主从复制 + Orchestrator 高可用方案

## 架构说明

本方案使用 MySQL 主从复制 + Orchestrator 实现高可用，支持自动故障转移。

```
┌─────────────────────────────────────────────────────┐
│  Orchestrator (监控 + 自动故障转移)                  │
│  - 监控所有 MySQL 节点                              │
│  - 自动检测 Master 故障                             │
│  - 自动提升 Slave 为新 Master                        │
│  - 重新配置复制拓扑                                  │
│  - Web UI: http://172.24.0.13:3000                  │
└─────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────┐
│  MySQL 主从复制集群                                  │
│  ┌──────────────────────────────────────┐          │
│  │ Master (可写)                         │          │
│  │ 172.24.0.10:3306                     │          │
│  └──────────────────────────────────────┘          │
│         ↓ 复制                                      │
│  ┌──────────────────────────────────────┐          │
│  │ Slave 1 (只读)                       │          │
│  │ 172.24.0.11:3306                     │          │
│  └──────────────────────────────────────┘          │
│         ↓ 复制                                      │
│  ┌──────────────────────────────────────┐          │
│  │ Slave 2 (只读)                       │          │
│  │ 172.24.0.12:3306                     │          │
│  └──────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## 组件说明

### 1. MySQL 主从复制
- **Master**: 172.24.0.10:3306 - 主节点，可写
- **Slave 1**: 172.24.0.11:3306 - 从节点，只读
- **Slave 2**: 172.24.0.12:3306 - 从节点，只读
- **复制模式**: 基于 GTID 的异步复制

### 2. Orchestrator
- **作用**: MySQL 拓扑发现、监控、自动故障转移
- **地址**: 172.24.0.13:3000
- **功能**:
  - 自动发现 MySQL 复制拓扑
  - 监控节点健康状态
  - Master 故障时自动提升 Slave
  - Web UI 可视化管理

## 快速开始

### 1. 启动 Docker 测试环境

```bash
cd /opt/ansible/mysql-replication
docker-compose -f docker-test-hosts.yml up -d
```

### 2. 安装必要软件

```bash
# 在所有容器中安装 SSH 和基础软件
for container in mysql-master mysql-slave-1 mysql-slave-2 orchestrator-1; do
  docker exec $container bash -c "apt-get update && apt-get install -y openssh-server curl wget net-tools"
  docker exec $container bash -c "mkdir -p /run/sshd && /usr/sbin/sshd"
done
```

### 3. 配置 SSH 密钥认证

```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -f /tmp/ansible_key -N "" -q

# 分发公钥到所有容器
for container in mysql-master mysql-slave-1 mysql-slave-2 orchestrator-1; do
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

### 1. 检查 MySQL 复制状态

```bash
# 在 Master 上查看
docker exec mysql-master /usr/local/mysql/bin/mysql -u root -p'Root@123456' -e "SHOW MASTER STATUS\G"

# 在 Slave 上查看
docker exec mysql-slave-1 /usr/local/mysql/bin/mysql -u root -p'Root@123456' -e "SHOW SLAVE STATUS\G"
```

### 2. 访问 Orchestrator Web UI

```
http://172.24.0.13:3000
```

### 3. 测试故障转移

```bash
# 停止 Master
docker stop mysql-master

# 等待 Orchestrator 自动故障转移（约 30 秒）

# 查看新 Master
docker exec mysql-slave-1 /usr/local/mysql/bin/mysql -u root -p'Root@123456' -e "SHOW SLAVE STATUS\G"
```

## 配置说明

### 全局变量 (inventory/group_vars/all.yml)

```yaml
mysql_version: "8.0.40"
mysql_root_password: "Root@123456"
mysql_replication_user: "repl"
mysql_replication_password: "Repl@123456"

orchestrator_version: "3.2.6"
orchestrator_port: 3000
```

### 主机清单 (inventory/hosts.yml)

```yaml
mysql_cluster:
  hosts:
    mysql-master:    # 主节点
      ansible_host: 172.24.0.10
    mysql-slave-1:   # 从节点 1
      ansible_host: 172.24.0.11
    mysql-slave-2:   # 从节点 2
      ansible_host: 172.24.0.12

orchestrator:
  hosts:
    orchestrator-1:  # Orchestrator
      ansible_host: 172.24.0.13
```

## 端口映射

| 组件 | 容器端口 | 宿主机端口 |
|------|---------|-----------|
| MySQL Master | 3306 | 3306 |
| MySQL Slave 1 | 3306 | 3307 |
| MySQL Slave 2 | 3306 | 3308 |
| Orchestrator | 3000 | 3000 |

## 故障转移流程

1. **检测故障**: Orchestrator 监控到 Master 宕机
2. **选择新主**: 选择最健康的 Slave（数据最新）
3. **提升为主**: 停止 Slave 复制，提升为新 Master
4. **重新配置**: 其他 Slave 重新指向新 Master
5. **应用切换**: 应用需要更新连接地址

## 优缺点

### 优点
- 配置简单，成熟稳定
- 读写分离，提升读性能
- 自动故障转移
- Web UI 可视化管理

### 缺点
- 异步复制，可能有数据延迟
- Master 故障时应用需要感知切换
- 写操作只能在 Master 上

## 生产环境建议

1. 使用半同步复制减少数据丢失
2. 配置自动故障转移通知
3. 使用 ProxySQL 实现读写分离和自动路由
4. 定期备份 Master 数据
5. 监控复制延迟

## 参考文档

- [Orchestrator 官方文档](https://github.com/openark/orchestrator)
- [MySQL 复制文档](https://dev.mysql.com/doc/refman/8.0/en/replication.html)