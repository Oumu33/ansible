# Ansible 自动化部署项目

基于 Ansible 的企业级应用自动化部署方案，支持 Rocky Linux 和 Ubuntu 系统。

## 项目概述

本项目提供了一套完整的 Ansible Playbooks 和 Roles，用于自动化部署各种企业级应用和服务。所有部署都经过 Docker 容器环境测试验证，确保在生产环境中的可靠性。

## 支持的应用

### 监控与日志
- **ELK Stack** (Elasticsearch, Logstash, Kibana) - 日志收集与分析
- **VictoriaMetrics** - 时序数据库监控
- **VictoriaMetrics-Full** - 完整监控解决方案

### 数据库
- **MySQL** - 关系型数据库
  - MySQL MGR (MySQL Group Replication) - 高可用集群
  - MySQL Replication - 主从复制
- **PostgreSQL** - 对象关系型数据库
  - PostgreSQL Cluster - 高可用集群
- **MongoDB** - NoSQL 文档数据库
  - MongoDB Replica Set - 副本集集群
- **Redis** - 内存数据库
  - Redis Cluster - 集群模式
  - Redis Standalone - 单机模式
- **ClickHouse** - 列式数据库
- **RabbitMQ** - 消息队列

### CI/CD 与代码质量
- **Jenkins** - 持续集成与持续部署
- **GitLab** - 代码托管与 CI/CD
- **ArgoCD** - GitOps 持续部署
- **SonarQube** - 代码质量分析平台

### 负载均衡与高可用
- **Keepalived + Nginx** - 高可用负载均衡

### 消息队列
- **Kafka Cluster** - 分布式消息系统

### 容器编排
- **Harbor** - 企业级 Docker 镜像仓库
- **Helm** - Kubernetes 包管理

## 系统要求

### 控制节点
- Ansible 2.9+
- Python 3.6+
- SSH 客户端

### 目标节点
- Rocky Linux 8/9 或 Ubuntu 20.04/22.04
- 最小 2GB RAM（某些服务需要更多）
- 最小 20GB 磁盘空间
- SSH 服务运行中

## 快速开始

### 1. 克隆项目

```bash
git clone git@github.com:Oumu33/ansible.git
cd ansible
```

### 2. 安装依赖

```bash
# 安装 Ansible
pip install ansible

# 安装 Docker (用于测试环境)
curl -fsSL https://get.docker.com | bash
```

### 3. 配置 SSH 密钥

```bash
# 生成 SSH 密钥
ssh-keygen -t rsa -f ~/.ssh/ansible_key -N ""

# 复制公钥到目标节点
ssh-copy-id -i ~/.ssh/ansible_key.pub user@target-host
```

### 4. 下载组件

```bash
# 下载所有需要的组件
./download-components.sh

# 或单独下载特定组件
cd <service>/Ubuntu
./download-components.sh
```

### 5. 配置主机清单

编辑对应服务的 inventory 文件：

```bash
cd <service>/<os>
vim inventory/hosts.yml
```

### 6. 执行部署

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy-all.yml
```

## 测试环境

项目提供了 Docker Compose 配置文件，可以在本地容器环境中测试部署：

### 启动测试环境

```bash
cd <service>/<os>
docker-compose -f docker-test-hosts.yml up -d
```

### 配置容器 SSH

```bash
./setup-container-ssh.sh
```

### 在测试环境部署

```bash
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-all.yml
```

## 目录结构

```
/opt/ansible/
├── ansible.cfg                 # Ansible 配置文件
├── downloads/                  # 下载的软件包
├── .ssh/                       # SSH 密钥
├── ELK/                        # ELK Stack 部署
│   ├── Rocky/
│   └── Ubuntu/
├── jenkins-gitlab/             # Jenkins + GitLab 部署
├── sonarqube/                  # SonarQube 代码审计
├── gitlab-argocd/              # GitLab + ArgoCD
├── mysql-mgr/                  # MySQL Group Replication
├── mysql-replication/          # MySQL 主从复制
├── postgresql-cluster/         # PostgreSQL 集群
├── mongodb-replica/            # MongoDB 副本集
├── redis-cluster/              # Redis 集群
├── kafka-cluster/              # Kafka 集群
├── VictoriaMetrics/            # 监控系统
├── Keepalived-Nginx/           # 负载均衡
├── harbor/                     # Docker 镜像仓库
└── ...
```

## 测试验证

### 测试代码审计部署

```bash
ansible-playbook test-code-audit.yml
```

### 测试基础部署

```bash
ansible-playbook test-deploy.yml
```

## 配置说明

### 全局变量

主要配置变量位于各服务的 `inventory/group_vars/all.yml`：

- 服务版本
- 端口配置
- 资源限制
- 存储路径

### 主机变量

特定主机的配置位于 `inventory/host_vars/`：

- 主机特定配置
- 网络设置
- 环境变量

## 常见问题

### 1. SSH 连接失败

检查 SSH 密钥权限：
```bash
chmod 600 ~/.ssh/ansible_key
```

### 2. 内存不足

调整服务资源限制，在 `group_vars/all.yml` 中修改：
- JVM 参数
- 内存限制
- 缓存大小

### 3. 端口冲突

修改服务端口配置：
```yaml
service_port: <new_port>
```

### 4. Docker 测试环境问题

清理测试环境：
```bash
docker-compose -f docker-test-hosts.yml down -v
```

## 性能优化

### 1. Ansible 性能

- 启用 SSH pipelining
- 使用 fact 缓存
- 并行执行任务

### 2. 服务性能

- 调整 JVM 参数
- 优化数据库配置
- 使用 SSD 存储

## 安全建议

1. **修改默认密码**：部署后立即修改所有默认密码
2. **使用防火墙**：限制服务端口访问
3. **启用 SSL/TLS**：为 Web 服务配置 HTTPS
4. **定期更新**：保持系统和软件包最新
5. **备份策略**：配置定期数据备份

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License

## 联系方式

- GitHub: https://github.com/Oumu33/ansible

## 更新日志

### 2026-01-10
- 清理存储空间，优化下载文件管理
- 添加代码审计部署测试
- 更新文档结构

### 2025-12-XX
- 初始版本发布
- 支持多种企业级应用部署
- Docker 测试环境支持