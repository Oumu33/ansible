# SonarQube 代码质量分析平台 - Rocky Linux 部署

## 架构说明

本方案使用 SonarQube + PostgreSQL 实现代码质量分析平台。

```
┌─────────────────────────────────────────────────────┐
│  SonarQube 代码质量分析平台                          │
│  ┌──────────────────────────────────────┐          │
│  │ SonarQube Server                     │          │
│  │ 172.28.0.30:9000                    │          │
│  └──────────────┬───────────────────────┘          │
│                 ↓                                    │
│  ┌──────────────────────────────────────┐          │
│  │ PostgreSQL Database                  │          │
│  │ 172.28.0.31:5432                    │          │
│  └──────────────────────────────────────┘          │
└─────────────────────────────────────────────────────┘
```

## 快速开始

### 1. 启动 Docker 测试环境

```bash
cd /opt/ansible/sonarqube/Rocky
docker-compose -f docker-test-hosts.yml up -d
```

### 2. 配置 SSH 密钥认证

```bash
ssh-keygen -t rsa -f /tmp/sonarqube_key -N "" -q

for container in postgresql-1 sonarqube-1; do
  docker exec $container bash -c "mkdir -p /root/.ssh"
  docker cp /tmp/sonarqube_key.pub $container:/root/.ssh/authorized_keys
  docker exec $container bash -c "chmod 600 /root/.ssh/authorized_keys"
done
```

### 3. 部署集群

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy-all.yml --private-key=/tmp/sonarqube_key
```

## 验证部署

### 1. 检查 PostgreSQL 服务

```bash
docker exec postgresql-1 systemctl status postgresql
```

### 2. 检查 SonarQube 服务

```bash
docker exec sonarqube-1 systemctl status sonarqube
```

### 3. 访问 SonarQube Web 界面

在浏览器中访问: `http://172.28.0.30:9000`

默认登录凭据:
- 用户名: `admin`
- 密码: `admin`

## 端口映射

| 组件 | 容器端口 | 宿主机端口 |
|------|---------|-----------|
| SonarQube | 9000 | 9000 |
| PostgreSQL | 5432 | 5432 |

## 配置变量

主要配置变量位于 `inventory/group_vars/all.yml`:

- `sonarqube_version`: SonarQube 版本
- `postgresql_version`: PostgreSQL 版本
- `sonarqube_port`: SonarQube Web 端口
- `postgresql_host`: PostgreSQL 主机地址
- `postgresql_port`: PostgreSQL 端口
- `postgresql_db_name`: 数据库名称
- `postgresql_user`: 数据库用户
- `postgresql_password`: 数据库密码

## 目录结构

```
/opt/ansible/sonarqube/Rocky/
├── docker-test-hosts.yml      # Docker 测试环境配置
├── inventory/
│   ├── hosts.yml              # 主机清单
│   ├── hosts-docker.yml       # Docker 连接清单
│   └── group_vars/
│       └── all.yml            # 全局变量
├── playbooks/
│   └── deploy-all.yml         # 部署 playbook
└── roles/
    ├── postgresql/            # PostgreSQL 角色
    └── sonarqube/             # SonarQube 角色
```

## 常见问题

### 1. SonarQube 启动失败

检查日志:
```bash
docker exec sonarqube-1 tail -f /var/log/sonarqube/sonar.log
```

### 2. PostgreSQL 连接失败

检查 PostgreSQL 服务状态:
```bash
docker exec postgresql-1 systemctl status postgresql
```

### 3. 内存不足

调整 JVM 参数，在 `inventory/group_vars/all.yml` 中修改:
- `sonarqube_web_jvm_opts`
- `sonarqube_ce_jvm_opts`
- `sonarqube_search_jvm_opts`