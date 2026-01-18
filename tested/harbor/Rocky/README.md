# Harbor 容器镜像仓库

## 项目简介

Harbor是一个企业级的Docker容器镜像仓库，提供安全、可信的容器镜像存储和分发服务。本项目提供基于Ansible的自动化部署方案。

## 功能特性

- ✅ 镜像存储和分发
- ✅ 安全扫描（Trivy）
- ✅ 签名验证（Notary）
- ✅ 访问控制
- ✅ 镜像复制
- ✅ 审计日志
- ✅ 高可用部署

## 安装要求

### 控制节点
- Ansible 2.9+
- Python 3.6+
- 网络连接到目标主机

### 目标主机
- Rocky Linux 8+ 或 Ubuntu 20.04+
- 最少 4GB RAM
- 最少 100GB 磁盘空间
- Docker和Docker Compose
- SSH 访问权限

### 网络要求
- 端口开放（见下方端口列表）

## 端口列表

| 服务 | 端口 | 说明 |
|------|------|------|
| Harbor UI | 80/443 | Web界面 |
| Registry | 5000 | Docker Registry |
| Notary | 4443 | 镜像签名服务 |
| Trivy | 8080 | 安全扫描服务 |

## 快速开始

### 1. 克隆项目

```bash
cd /opt/ansible/untested/harbor/Rocky
```

### 2. 配置主机IP

编辑 `inventory/group_vars/all.yml`，修改Harbor配置：

```yaml
harbor_hostname: "harbor.example.com"
harbor_admin_password: "Harbor12345"
harbor_storage_quota: "100GB"
```

### 3. 配置主机清单

编辑 `inventory/hosts.yml`：

```yaml
harbor:
  hosts:
    harbor-1:
      ansible_host: 172.22.0.40
      ansible_user: root
```

### 4. 下载Harbor安装包

```bash
cd /opt/ansible
./download-components.sh
```

或手动下载：

```bash
wget https://github.com/goharbor/harbor/releases/download/v2.11.0/harbor-online-installer-v2.11.0.tgz -O /tmp/harbor-online-installer-v2.11.0.tgz
```

### 5. 部署Harbor

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

## 配置说明

### 基础配置

```yaml
# Harbor版本
harbor_version: "2.11.0"

# 主机名
harbor_hostname: "harbor.example.com"

# 协议和端口
harbor_protocol: "https"
harbor_port: 443

# 管理员密码
harbor_admin_password: "Harbor12345"

# 存储配额
harbor_storage_quota: "100GB"
```

### 数据库配置

```yaml
# 数据库密码
harbor_db_password: "Harbor12345"

# 数据库端口
harbor_db_port: 5432
```

### Redis配置

```yaml
# Redis端口
harbor_redis_port: 6379
```

## 访问Harbor

### Web界面

- **地址**: http://<harbor_hostname>
- **默认用户名**: admin
- **默认密码**: Harbor12345

### Docker登录

```bash
docker login <harbor_hostname>
```

### 推送镜像

```bash
# 标记镜像
docker tag myimage:latest <harbor_hostname>/project/myimage:latest

# 推送镜像
docker push <harbor_hostname>/project/myimage:latest
```

### 拉取镜像

```bash
docker pull <harbor_hostname>/project/myimage:latest
```

## 安全配置

### HTTPS配置

1. 生成SSL证书：

```bash
mkdir -p /data/harbor/ssl
openssl req -newkey rsa:4096 -nodes -sha256 -keyout /data/harbor/ssl/<hostname>.key -x509 -days 365 -out /data/harbor/ssl/<hostname>.crt
```

2. 更新Harbor配置：

```yaml
https:
  port: 443
  certificate: /data/harbor/ssl/<hostname>.crt
  private_key: /data/harbor/ssl/<hostname>.key
```

3. 重启Harbor：

```bash
cd /opt/harbor
docker compose down && docker compose up -d
```

### 安全扫描

Harbor默认启用Trivy安全扫描：

```yaml
scanner:
  type: trivy
  offline_scan: false
  allow_disable_scanner: true
```

### 镜像签名

Harbor支持Notary镜像签名：

```yaml
notary:
  enabled: true
```

## 镜像复制

### 创建复制规则

1. 登录Harbor Web界面
2. 进入"管理" -> "复制"
3. 创建复制规则
4. 配置源和目标仓库

### 复制镜像

```bash
# 在Harbor Web界面中执行复制操作
# 或使用Harbor API
```

## 备份与恢复

### 备份数据

```bash
# 备份数据库
docker exec harbor-db pg_dump -U postgres registry > /tmp/harbor-backup.sql

# 备份数据目录
tar czf /tmp/harbor-data-backup.tar.gz /data/harbor
```

### 恢复数据

```bash
# 恢复数据库
docker exec -i harbor-db psql -U postgres registry < /tmp/harbor-backup.sql

# 恢复数据目录
tar xzf /tmp/harbor-data-backup.tar.gz -C /
```

## 监控与维护

### 查看服务状态

```bash
cd /opt/harbor
docker compose ps
```

### 查看日志

```bash
cd /opt/harbor
docker compose logs -f
```

### 重启服务

```bash
cd /opt/harbor
docker compose restart
```

### 更新Harbor

```bash
# 备份数据
# 下载新版本安装包
# 运行升级脚本
./upgrade.sh -v <new_version>
```

## 常见问题

### 1. Harbor无法启动

**问题**: Harbor服务启动失败

**解决**:
- 检查Docker服务状态
- 检查端口占用情况
- 查看Harbor日志
- 验证配置文件

### 2. 镜像推送失败

**问题**: Docker push失败

**解决**:
- 检查Docker登录状态
- 验证项目权限
- 检查存储空间
- 查看Harbor日志

### 3. 安全扫描失败

**问题**: Trivy扫描失败

**解决**:
- 检查Trivy服务状态
- 更新漏洞数据库
- 检查网络连接

## 性能优化

### 存储优化

```yaml
storage:
  filesystem:
    maxsize: 100GB
```

### 缓存配置

```yaml
cache:
  enabled: true
```

### 并发配置

```yaml
job_service:
  max_job_workers: 10
```

## 版本信息

当前版本：

| 组件 | 版本 |
|------|------|
| Harbor | 2.11.0 |

## 技术支持

- Harbor官方文档: https://goharbor.io/docs/
- Harbor GitHub: https://github.com/goharbor/harbor

## 许可证

本项目遵循相关组件的开源许可证。

---

**最后更新**: 2026-01-18