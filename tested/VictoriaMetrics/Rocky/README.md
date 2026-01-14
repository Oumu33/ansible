# VictoriaMetrics 集群 Ansible 部署

使用 Ansible 自动化部署 VictoriaMetrics 时序数据库集群。

## 目录结构

```
ansible/VictoriaMetrics/
├── ansible.cfg                    # Ansible 配置文件
├── README.md                      # 说明文档
├── .env.example                   # 环境变量示例
├── inventory/                     # 主机清单
│   ├── hosts.yml                  # 主机定义
│   └── group_vars/                # 组变量
│       ├── all.yml                # 全局变量
│       ├── vmcluster.yml          # 集群配置
│       ├── vmselect.yml           # vmselect 特定变量
│       ├── vminsert.yml           # vminsert 特定变量
│       └── vmstorage.yml          # vmstorage 特定变量
├── playbooks/                     # Playbook 文件
│   ├── deploy-cluster.yml         # 完整集群部署
│   ├── deploy-storage.yml         # 仅部署存储节点
│   ├── deploy-insert.yml          # 仅部署写入节点
│   ├── deploy-select.yml          # 仅部署查询节点
│   └── backup.yml                 # 数据备份
├── roles/                         # 角色
│   └── vmcluster/                 # 集群角色
│       ├── defaults/              # 默认变量
│       ├── handlers/              # 处理器
│       ├── tasks/                 # 任务
│       ├── templates/             # 模板
│       └── vars/                  # 变量
├── scripts/                       # 辅助脚本
└── templates/                     # 通用模板
```

## 前置要求

- Ansible 2.9+
- 目标主机需要：
  - SSH 访问权限
  - Root 或 sudo 权限
  - 至少 4GB 可用内存
  - 足够的磁盘空间用于数据存储

## 快速开始

### 1. 配置主机清单

编辑 `inventory/hosts.yml`，根据实际环境修改主机 IP 和配置：

```yaml
vmcluster:
  hosts:
    vmselect-1:
      ansible_host: 192.168.1.10
      ansible_user: root
    vmstorage-1:
      ansible_host: 192.168.1.14
      ansible_user: root
```

### 2. 配置变量

编辑 `inventory/group_vars/all.yml` 修改全局配置：

```yaml
vm_version: "v1.104.0"
vm_memory_limit: 4096
vm_retention_period: "1"
```

### 3. 部署集群

#### 完整部署（推荐顺序）

```bash
# 1. 先部署存储节点
ansible-playbook -i inventory/hosts.yml playbooks/deploy-storage.yml

# 2. 再部署写入节点
ansible-playbook -i inventory/hosts.yml playbooks/deploy-insert.yml

# 3. 最后部署查询节点
ansible-playbook -i inventory/hosts.yml playbooks/deploy-select.yml
```

#### 一键部署所有节点

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy-cluster.yml
```

## Playbook 说明

### deploy-cluster.yml
部署完整的 VictoriaMetrics 集群，包括所有组件。

### deploy-storage.yml
仅部署 vmstorage 存储节点。建议先部署此组件。

### deploy-insert.yml
仅部署 vminsert 写入节点，用于接收数据。

### deploy-select.yml
仅部署 vmselect 查询节点，用于数据查询。

### backup.yml
备份 vmstorage 数据，支持自动清理 7 天前的备份。

## 配置说明

### 端口配置

| 组件 | 端口 | 说明 |
|------|------|------|
| vminsert | 8480 | 数据写入接口 |
| vmselect | 8481 | 数据查询接口 |
| vmstorage | 8482 | 存储节点接口 |
| vmstorage vminsert | 8400 | 接收 vminsert 数据 |
| vmstorage vmselect | 8401 | 响应 vmselect 查询 |

### 重要变量

- `vm_version`: VictoriaMetrics 版本
- `vm_memory_limit`: 内存限制（MB）
- `vm_retention_period`: 数据保留时间（月）
- `vm_cache_size`: vmselect 缓存大小
- `vm_max_concurrent_inserts`: 最大并发插入数

## 验证部署

### 检查服务状态

```bash
ansible vmcluster -i inventory/hosts.yml -m shell -a "systemctl status vmstorage"
ansible vmcluster -i inventory/hosts.yml -m shell -a "systemctl status vminsert"
ansible vmcluster -i inventory/hosts.yml -m shell -a "systemctl status vmselect"
```

### 测试写入数据

```bash
curl -X POST 'http://<vminsert-ip>:8480/insert/0/prometheus/api/v1/write' -d 'test_metric{label="value"} 123'
```

### 测试查询数据

```bash
curl 'http://<vmselect-ip>:8481/select/0/prometheus/api/v1/query?query=test_metric'
```

## 常见问题

### 服务启动失败
检查日志：
```bash
journalctl -u vmstorage -f
journalctl -u vminsert -f
journalctl -u vmselect -f
```

### 端口被占用
修改 `group_vars/*.yml` 中的端口配置。

### 内存不足
增加 `vm_memory_limit` 或减少 `vm_cache_size`。

## 扩展集群

### 添加存储节点
1. 在 `inventory/hosts.yml` 中添加新主机
2. 运行 `deploy-storage.yml`

### 添加查询节点
1. 在 `inventory/hosts.yml` 中添加新主机
2. 运行 `deploy-select.yml`

## 维护操作

### 重启服务
```bash
ansible vmstorage -i inventory/hosts.yml -m systemd -a "name=vmstorage state=restarted"
```

### 备份数据
```bash
ansible-playbook -i inventory/hosts.yml playbooks/backup.yml
```

### 升级版本
1. 修改 `vm_version`
2. 设置 `vm_force_download: true`
3. 重新运行部署 playbook

## 注意事项

1. **部署顺序**: 建议按照 storage → insert → select 的顺序部署
2. **存储节点**: 至少需要 1 个，建议使用奇数个（如 3、5）
3. **内存配置**: 根据数据量调整内存限制
4. **磁盘空间**: 确保有足够的存储空间用于数据保留
5. **网络延迟**: 确保节点间网络延迟低，建议在同一数据中心

## 许可证

MIT License