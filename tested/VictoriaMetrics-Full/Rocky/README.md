# VictoriaMetrics 完整监控栈部署指南

## 项目简介

本项目提供了一套完整的 VictoriaMetrics 监控生态系统，包括指标采集、存储、查询、告警、日志管理和可视化等全套功能。基于 Ansible 自动化部署，支持 Rocky Linux 和 Ubuntu 系统。

## 架构说明

### 核心组件

```
┌─────────────────────────────────────────────────────────────────┐
│                        监控栈架构图                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                  │
│  │ vmagent  │    │ vmalert  │    │ Vector   │                  │
│  │ (采集)   │    │ (告警)   │    │ (日志)   │                  │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘                  │
│       │               │               │                         │
│       └───────────────┴───────────────┼─────────┐               │
│                       │               │         │               │
│                       ▼               ▼         │               │
│                   ┌──────────────────────┐     │               │
│                   │      vmauth          │     │               │
│                   │  (认证+负载均衡)      │     │               │
│                   └──────────┬───────────┘     │               │
│                              │                 │               │
│              ┌───────────────┴───────────────┐ │               │
│              │                               │ │               │
│              ▼                               ▼ │               │
│      ┌──────────────┐               ┌──────────────┐          │
│      │  vminsert    │               │  vmselect    │          │
│      │  (写入节点)  │               │  (查询节点)  │          │
│      └──────┬───────┘               └──────┬───────┘          │
│             │                              │                   │
│             └──────────┬───────────────────┘                   │
│                        │                                       │
│                        ▼                                       │
│              ┌─────────────────────┐                          │
│              │    vmstorage        │                          │
│              │    (存储节点)        │                          │
│              └─────────────────────┘                          │
│                                                              │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐               │
│  │AlertMgr  │    │Victoria  │    │  Grafana  │               │
│  │(告警管理)│    │  Logs    │    │ (可视化)  │               │
│  └──────────┘    └──────────┘    └──────────┘               │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 组件说明

#### 1. VictoriaMetrics 集群
- **vmstorage** (3节点): 数据存储层，持久化时序数据
- **vminsert** (3节点): 数据写入层，接收并分发写入请求
- **vmselect** (3节点): 数据查询层，处理查询请求

#### 2. 认证与负载均衡
- **vmauth**: 提供认证和负载均衡功能，统一管理访问入口

#### 3. 指标采集与告警
- **vmagent**: 高性能指标采集代理，兼容 Prometheus
- **vmalert**: 告警规则引擎，支持 PromQL
- **Alertmanager**: 告警通知管理，支持多种通知渠道

#### 4. 日志管理
- **VictoriaLogs**: 高性能日志存储和查询引擎
- **Vector**: 现代化日志采集和转换工具

#### 5. 可视化
- **Grafana**: 数据可视化和监控仪表板

## 安装要求

### 控制节点
- Ansible 2.9+
- Python 3.6+
- 网络连接到目标主机

### 目标主机
- Rocky Linux 8+ 或 Ubuntu 20.04+
- 最少 2GB RAM
- 最少 20GB 磁盘空间
- SSH 访问权限

### 网络要求
- 所有主机之间网络互通
- 端口开放（见下方端口列表）

### 端口列表

| 服务 | 端口 | 说明 |
|------|------|------|
| vmstorage | 8482 | HTTP API |
| vmstorage | 8400 | vminsert 连接 |
| vmstorage | 8401 | vmselect 连接 |
| vminsert | 8480 | HTTP API |
| vmselect | 8481 | HTTP API |
| vmauth | 8427 | HTTP API |
| vmagent | 8429 | HTTP API |
| vmalert | 8880 | HTTP API |
| Alertmanager | 9093 | HTTP API |
| VictoriaLogs | 9428 | HTTP API |
| Vector | 8686 | HTTP API |
| Grafana | 3000 | Web UI |

## 快速开始

### 1. 克隆项目

```bash
cd /opt/ansible/VictoriaMetrics-Full/Rocky
```

### 2. 配置主机IP

编辑 `inventory/group_vars/all.yml`，修改所有主机的IP地址：

```yaml
# 主机IP地址配置 (修改这些IP即可更新所有配置)
vmstorage_1_ip: "172.22.0.10"
vmstorage_2_ip: "172.22.0.11"
vmstorage_3_ip: "172.22.0.12"
vminsert_1_ip: "172.22.0.13"
vminsert_2_ip: "172.22.0.14"
vminsert_3_ip: "172.22.0.15"
vmselect_1_ip: "172.22.0.16"
vmselect_2_ip: "172.22.0.17"
vmselect_3_ip: "172.22.0.18"
vmauth_1_ip: "172.22.0.19"
vmalert_1_ip: "172.22.0.20"
vmagent_1_ip: "172.22.0.21"
alertmanager_1_ip: "172.22.0.22"
grafana_1_ip: "172.22.0.23"
victorialogs_1_ip: "172.22.0.24"
vector_1_ip: "172.22.0.25"
```

### 3. 配置主机清单

编辑 `inventory/hosts.yml`，确保 ansible_host 与上面的IP一致：

```yaml
vm:
  hosts:
    vmstorage-1:
      ansible_host: 172.22.0.10
      ansible_user: root
    # ... 其他主机
```

### 4. 下载组件包

```bash
cd /opt/ansible
./download-components.sh
```

或手动下载：

```bash
# VictoriaMetrics
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.133.0/vmutils-linux-amd64-v1.133.0.tar.gz -O /tmp/vmutils-linux-amd64-v1.133.0.tar.gz

# Alertmanager
wget https://github.com/prometheus/alertmanager/releases/download/v0.30.0/alertmanager-0.30.0.linux-amd64.tar.gz -O /tmp/alertmanager-0.30.0.linux-amd64.tar.gz

# Grafana
wget https://dl.grafana.com/oss/release/grafana-12.3.1.linux-amd64.tar.gz -O /tmp/grafana-12.3.1.linux-amd64.tar.gz

# VictoriaLogs
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.43.1/victoria-logs-linux-amd64-v1.43.1.tar.gz -O /tmp/victoria-logs-linux-amd64-v1.43.1.tar.gz

# Vector
wget https://github.com/vectordotdev/vector/releases/download/v0.52.0/vector-0.52.0-x86_64-unknown-linux-musl.tar.gz -O /tmp/vector-0.52.0-x86_64-unknown-linux-musl.tar.gz
```

### 5. 部署到真实主机

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

### 6. 部署到Docker容器（测试环境）

```bash
# 启动Docker测试容器
docker-compose -f docker-test-hosts.yml up -d

# 等待容器启动
sleep 30

# 部署到容器
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy.yml
```

## 配置说明

### 认证配置

默认认证信息（在 `roles/vmauth/tasks/main.yml` 中配置）：

```yaml
username: "admin"
password: "admin"
```

**重要**: 生产环境请修改默认密码！

### Grafana 访问

- 地址: `http://<grafana_1_ip>:3000`
- 用户名: `admin`
- 密码: `admin`

### vmauth 负载均衡配置

vmauth 自动将写入请求分发到3个 vminsert 节点，查询请求分发到3个 vmselect 节点：

```yaml
url_map:
  - src_paths: ["/insert/.*"]
    url_prefix:
      - "http://{{ vminsert_1_ip }}:8480"
      - "http://{{ vminsert_2_ip }}:8480"
      - "http://{{ vminsert_3_ip }}:8480"
  - src_paths: ["/select/.*"]
    url_prefix:
      - "http://{{ vmselect_1_ip }}:8481"
      - "http://{{ vmselect_2_ip }}:8481"
      - "http://{{ vmselect_3_ip }}:8481"
```

## 版本管理

所有组件的版本都集中在 `inventory/group_vars/all.yml` 中配置，修改版本只需编辑这一个文件即可。

### 当前版本配置

在 `inventory/group_vars/all.yml` 中：

```yaml
# 版本
victoriametrics_version: "v1.133.0"
alertmanager_version: "v0.30.0"
grafana_version: "12.3.1"
victorialogs_version: "v1.43.1"
vector_version: "0.52.0"
```

### 升级组件版本

#### 步骤

1. **编辑 `inventory/group_vars/all.yml`**

```bash
vim inventory/group_vars/all.yml
```

2. **修改对应的版本变量**

```yaml
# 例如：升级 VictoriaMetrics 到 v1.134.0
victoriametrics_version: "v1.134.0"
```

3. **下载新版本包**

```bash
cd /opt/ansible

# 下载 VictoriaMetrics
wget https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v1.134.0/vmutils-linux-amd64-v1.134.0.tar.gz -O /tmp/vmutils-linux-amd64-v1.134.0.tar.gz

# 下载其他组件（如需升级）
wget https://github.com/prometheus/alertmanager/releases/download/v0.31.0/alertmanager-0.31.0.linux-amd64.tar.gz -O /tmp/alertmanager-0.31.0.linux-amd64.tar.gz
```

4. **重新部署**

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

### 版本下载地址

| 组件 | 下载地址格式 | 示例 |
|------|-------------|------|
| VictoriaMetrics | `https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/{version}/vmutils-linux-amd64-{version}.tar.gz` | v1.133.0 |
| Alertmanager | `https://github.com/prometheus/alertmanager/releases/download/{version}/alertmanager-{version}.linux-amd64.tar.gz` | v0.30.0 |
| Grafana | `https://dl.grafana.com/oss/release/grafana-{version}.linux-amd64.tar.gz` | 12.3.1 |
| VictoriaLogs | `https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/{version}/victoria-logs-linux-amd64-{version}.tar.gz` | v1.43.1 |
| Vector | `https://github.com/vectordotdev/vector/releases/download/{version}/vector-{version}-x86_64-unknown-linux-musl.tar.gz` | 0.52.0 |

### 批量下载脚本

使用项目提供的下载脚本自动下载所有组件：

```bash
cd /opt/ansible
./download-components.sh
```

该脚本会根据 `inventory/group_vars/all.yml` 中配置的版本自动下载对应版本。

### 版本兼容性

- VictoriaMetrics: 建议使用最新的稳定版本
- Alertmanager: 建议使用 v0.27.0+ 版本
- Grafana: 建议使用 12.x 版本
- VictoriaLogs: 建议与 VictoriaMetrics 保持相同主版本
- Vector: 建议使用最新的稳定版本

### 回滚版本

如果升级后出现问题，可以回滚到之前的版本：

1. **修改 `inventory/group_vars/all.yml`** 回到旧版本

```yaml
victoriametrics_version: "v1.133.0"  # 回滚到旧版本
```

2. **重新部署**

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

## IP变更指南

当主机IP地址变更时，只需修改一个配置文件：

### 步骤

1. **编辑 `inventory/group_vars/all.yml`**

```bash
vim inventory/group_vars/all.yml
```

2. **修改对应的IP变量**

```yaml
# 例如：修改 vminsert-1 的IP
vminsert_1_ip: "192.168.1.100"  # 新IP
```

3. **编辑 `inventory/hosts.yml`**（同步更新）

```bash
vim inventory/hosts.yml
```

```yaml
vminsert-1:
  ansible_host: 192.168.1.100  # 新IP
```

4. **重新部署**

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

所有配置会自动更新，无需手动修改每个服务的配置文件！

## 服务管理

### 查看服务状态

```bash
ansible vm -m shell -a "systemctl status vmauth"
ansible vm -m shell -a "systemctl status vmagent"
ansible vm -m shell -a "systemctl status vmalert"
```

### 重启服务

```bash
ansible vm -m shell -a "systemctl restart vmauth"
ansible vm -m shell -a "systemctl restart vmagent"
```

### 查看日志

```bash
ansible vm -m shell -a "journalctl -u vmauth -f"
ansible vm -m shell -a "journalctl -u vmagent -f"
```

## 访问地址

部署完成后，可以通过以下地址访问各个服务：

| 服务 | 地址 | 认证 |
|------|------|------|
| Grafana | http://<grafana_1_ip>:3000 | admin/admin |
| vmauth | http://<vmauth_1_ip>:8427 | admin/admin |
| vmagent | http://<vmagent_1_ip>:8429 | 无 |
| vmalert | http://<vmalert_1_ip>:8880 | 无 |
| Alertmanager | http://<alertmanager_1_ip>:9093 | 无 |
| VictoriaLogs | http://<victorialogs_1_ip>:9428 | 无 |
| Vector | http://<vector_1_ip>:8686 | 无 |

## 常见问题

### 1. systemd 在 Docker 容器中不可用

**问题**: 在 Docker 容器中部署时，systemd 服务无法启动

**解决**: Ansible playbook 会自动使用 nohup 在后台启动服务

### 2. 端口冲突

**问题**: 服务启动失败，提示端口已被占用

**解决**: 检查端口占用情况，修改 `inventory/group_vars/all.yml` 中的端口配置

```bash
netstat -tlnp | grep <port>
```

### 3. 磁盘空间不足

**问题**: vmstorage 数据目录磁盘空间不足

**解决**: 
- 清理旧数据：调整 `vmstorage_retention_period` 参数
- 扩容磁盘：增加数据目录所在分区的空间

### 4. 内存不足

**问题**: 服务因内存不足被 OOM killer 杀死

**解决**: 调整内存限制参数

```yaml
vmstorage_memory_allowed_bytes: "4GB"
```

### 5. 网络不通

**问题**: 服务之间无法通信

**解决**: 
- 检查防火墙规则
- 确认所有主机在同一网络
- 验证 IP 配置是否正确

## 性能优化

### 1. 数据保留策略

修改数据保留时间：

```yaml
vmstorage_retention_period: "90d"  # 保留90天
```

### 2. 缓存配置

增加 vmselect 缓存大小：

```yaml
vmselect_cache_size_bytes: "2GB"
```

### 3. 内存配置

根据服务器配置调整内存限制：

```yaml
vmstorage_memory_allowed_bytes: "4GB"
```

## 版本信息

当前版本：

| 组件 | 版本 |
|------|------|
| VictoriaMetrics | v1.133.0 |
| Alertmanager | v0.30.0 |
| Grafana | 12.3.1 |
| VictoriaLogs | v1.43.1 |
| Vector | 0.52.0 |

## 备份与恢复

### 备份数据

```bash
# 备份 vmstorage 数据
ansible vmstorage -m shell -a "tar czf /tmp/vmstorage-backup-$(date +%Y%m%d).tar.gz -C /var/lib/victoriametrics vmstorage"

# 拉取备份到本地
ansible vmstorage-1 -m fetch -a "src=/tmp/vmstorage-backup-*.tar.gz dest=./backup/"
```

### 恢复数据

```bash
# 上传备份文件
ansible vmstorage-1 -m copy -a "src=./backup/vmstorage-backup-20240108.tar.gz dest=/tmp/"

# 解压恢复
ansible vmstorage -m shell -a "tar xzf /tmp/vmstorage-backup-20240108.tar.gz -C /var/lib/victoriametrics"

# 重启服务
ansible vmstorage -m shell -a "systemctl restart vmstorage"
```

## 监控与告警

### 添加告警规则

编辑 `roles/vmalert/tasks/main.yml` 中的告警规则：

```yaml
groups:
  - name: system
    interval: 30s
    rules:
      - alert: HighCPUUsage
        expr: up == 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Service is down"
          description: "Service has been down for more than 5 minutes"
```

### 配置告警通知

编辑 `roles/alertmanager/tasks/main.yml` 中的通知配置：

```yaml
receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://your-webhook-url'
```

## 技术支持

- VictoriaMetrics 官方文档: https://docs.victoriametrics.com/
- Grafana 官方文档: https://grafana.com/docs/
- Vector 官方文档: https://vector.dev/docs/

## 许可证

本项目遵循相关组件的开源许可证。

---

**最后更新**: 2026-01-08