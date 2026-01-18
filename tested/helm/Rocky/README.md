# Helm 包管理器

## 项目简介

Helm是Kubernetes的包管理器，用于简化Kubernetes应用的部署和管理。本项目提供基于Ansible的自动化部署方案。

## 功能特性

- ✅ Kubernetes应用包管理
- ✅ Chart仓库管理
- ✅ 应用版本控制
- ✅ 模板化配置
- ✅ 依赖管理
- ✅ 回滚和升级

## 安装要求

### 控制节点
- Ansible 2.9+
- Python 3.6+
- 网络连接到目标主机

### 目标主机
- Rocky Linux 8+ 或 Ubuntu 20.04+
- 最少 1GB RAM
- 最少 5GB 磁盘空间
- SSH 访问权限
- Kubernetes集群访问权限

## 快速开始

### 1. 克隆项目

```bash
cd /opt/ansible/untested/helm/Rocky
```

### 2. 配置主机IP

编辑 `inventory/hosts.yml`：

```yaml
helm:
  hosts:
    helm-1:
      ansible_host: 172.22.0.50
      ansible_user: root
```

### 3. 部署Helm

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

## 配置说明

### 基础配置

```yaml
# Helm版本
helm_version: "3.15.0"

# 安装目录
helm_install_dir: "/usr/local/bin"

# 配置目录
helm_config_dir: "/etc/helm"
helm_data_dir: "/var/lib/helm"
```

### 仓库配置

```yaml
helm_repositories:
  - name: "stable"
    url: "https://charts.helm.sh/stable"
  - name: "bitnami"
    url: "https://charts.bitnami.com/bitnami"
  - name: "jetstack"
    url: "https://charts.jetstack.io"
```

## 使用方法

### 验证安装

```bash
helm version
```

### 添加仓库

```bash
helm repo add stable https://charts.helm.sh/stable
helm repo update
```

### 搜索Chart

```bash
helm search repo nginx
```

### 安装应用

```bash
helm install my-release bitnami/nginx
```

### 列出已安装的应用

```bash
helm list
```

### 升级应用

```bash
helm upgrade my-release bitnami/nginx
```

### 卸载应用

```bash
helm uninstall my-release
```

### 查看应用状态

```bash
helm status my-release
```

## 常用命令

### Helm基本操作

```bash
# 查看版本
helm version

# 查看帮助
helm help

# 查看环境信息
helm env

# 查看仓库列表
helm repo list

# 更新仓库
helm repo update
```

### Chart管理

```bash
# 搜索Chart
helm search repo <keyword>

# 查看Chart详情
helm show chart <repo>/<chart>

# 查看Chart值
helm show values <repo>/<chart>

# 拉取Chart
helm pull <repo>/<chart>
```

### 应用管理

```bash
# 安装应用
helm install <release> <chart>

# 列出应用
helm list

# 查看应用状态
helm status <release>

# 升级应用
helm upgrade <release> <chart>

# 回滚应用
helm rollback <release>

# 卸载应用
helm uninstall <release>
```

### 历史管理

```bash
# 查看历史
helm history <release>

# 回滚到指定版本
helm rollback <release> <revision>
```

## 配置文件

### values.yaml

```yaml
# 自定义配置
replicaCount: 1

image:
  repository: nginx
  tag: "1.25"
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

resources:
  limits:
    cpu: 100m
    memory: 128Mi
  requests:
    cpu: 100m
    memory: 128Mi
```

### 使用自定义配置

```bash
helm install my-release bitnami/nginx -f values.yaml
```

## 常见问题

### 1. Helm无法连接Kubernetes

**问题**: Helm无法连接到Kubernetes集群

**解决**:
- 检查kubeconfig配置
- 验证Kubernetes集群状态
- 检查网络连接

### 2. Chart安装失败

**问题**: Chart安装失败

**解决**:
- 检查Chart是否存在
- 验证仓库配置
- 查看详细错误信息

### 3. 版本冲突

**问题**: Helm版本与Chart不兼容

**解决**:
- 检查Helm版本要求
- 升级Helm版本
- 使用兼容的Chart版本

## 版本信息

当前版本：

| 组件 | 版本 |
|------|------|
| Helm | 3.15.0 |

## 技术支持

- Helm官方文档: https://helm.sh/docs/
- Helm GitHub: https://github.com/helm/helm
- Chart仓库: https://artifacthub.io/

## 许可证

本项目遵循相关组件的开源许可证。

---

**最后更新**: 2026-01-18