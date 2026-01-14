# GitLab + Jenkins + ArgoCD CI/CD 环境

## 架构说明

完整的 CI/CD 环境，包含代码仓库 (GitLab)、持续集成 (Jenkins) 和持续部署 (ArgoCD)。

```
┌──────────────────────────────────────┐
│  GitLab (代码仓库)                   │
│  - 172.130.0.20:80 (HTTP)            │
│  - 172.130.0.20:443 (HTTPS)          │
│  - 172.130.0.20:2222 (SSH)           │
└──────────────────────────────────────┘
         ↓
┌──────────────────────────────────────┐
│  Jenkins (持续集成)                  │
│  - 172.130.0.30:8080 (Web UI)        │
│  - 172.130.0.30:50000 (Agent)        │
└──────────────────────────────────────┘
         ↓
┌──────────────────────────────────────┐
│  ArgoCD (持续部署)                   │
│  - 172.130.0.10:8080 (HTTP)          │
│  - 172.130.0.10:8443 (HTTPS)         │
└──────────────────────────────────────┘
```

## 快速开始

### 使用 Rocky Linux 镜像测试

```bash
# 1. 设置测试环境（生成 SSH 密钥）
cd /opt/ansible
./setup-rocky-test-env.sh

# 2. 测试并部署完整的 CI/CD 环境
./test-project.sh gitlab-argocd playbooks/deploy-all.yml

# 或者分别部署各个组件
./test-project.sh gitlab-argocd playbooks/deploy-argocd.yml
./test-project.sh gitlab-argocd playbooks/deploy-jenkins-gitlab.yml
```

### 手动部署步骤

```bash
cd /opt/ansible/gitlab-argocd/Rocky

# 1. 启动 Docker 容器
docker-compose -f docker-test-hosts.yml up -d

# 2. 等待容器启动并安装基础软件
sleep 30

# 3. 在容器中安装必要的软件（如果容器未预装）
for container in argocd-server gitlab-server jenkins-server; do
  docker exec $container bash -c "dnf install -y openssh-server openssh-clients python3 python3-pip curl wget java-17-openjdk java-17-openjdk-devel"
  docker exec $container bash -c "ssh-keygen -A && /usr/sbin/sshd -D &"
done

# 4. 配置 SSH 访问
ssh-keygen -t rsa -f /tmp/ansible_key -N "" -q
for container in argocd-server gitlab-server jenkins-server; do
  docker exec $container bash -c "mkdir -p /root/.ssh"
  docker cp /tmp/ansible_key.pub $container:/root/.ssh/authorized_keys
done

# 5. 部署 ArgoCD
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-argocd.yml --private-key=/tmp/ansible_key

# 6. 部署 Jenkins 和 GitLab
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-jenkins-gitlab.yml --private-key=/tmp/ansible_key

# 或者一次性部署所有组件
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-all.yml --private-key=/tmp/ansible_key
```

## 访问信息

### ArgoCD
- Web UI: http://172.130.0.10:8080
- 默认用户: admin
- 默认密码: admin
- 首次登录后请使用 `argocd account update-password` 修改密码

### GitLab
- Web UI: http://172.130.0.20
- SSH: git@172.130.0.20:2222
- 默认用户: root
- 初始密码: 查看 `/etc/gitlab/initial_root_password` 文件
- 注意: 初始密码文件将在 24 小时后自动删除

### Jenkins
- Web UI: http://172.130.0.30:8080
- Agent 端口: 50000
- 初始管理员密码: 查看 `/var/lib/jenkins/secrets/initialAdminPassword` 文件

## 配置说明

### 主机清单配置

编辑 `inventory/hosts.yml` 文件，替换 `<argocd_server_ip>`, `<gitlab_server_ip>`, `<jenkins_server_ip>` 为实际的服务器 IP 地址。

### 变量配置

所有配置变量都在 `inventory/group_vars/all.yml` 中定义，可以根据需要修改：

- ArgoCD 版本和端口
- GitLab 版本和外部 URL
- Jenkins 版本和端口
- Java 内存配置

## 工作流程

1. **代码提交**: 开发者将代码推送到 GitLab
2. **触发构建**: GitLab Webhook 触发 Jenkins 构建
3. **构建测试**: Jenkins 执行构建和测试
4. **部署应用**: Jenkins 构建成功后，通知 ArgoCD
5. **自动部署**: ArgoCD 将应用部署到 Kubernetes 集群

## 清理环境

```bash
# 停止并删除 Docker 容器
docker-compose -f docker-test-hosts.yml down -v

# 或者删除所有测试容器
docker stop argocd-server gitlab-server jenkins-server
docker rm argocd-server gitlab-server jenkins-server
```

## 注意事项

1. 确保 Docker 镜像 `rockylinux-java:17` 已存在，如不存在请先构建
2. GitLab 首次启动和配置可能需要较长时间（5-10 分钟）
3. Jenkins 首次启动需要下载插件，可能需要较长时间
4. ArgoCD 通常需要 Kubernetes 环境，当前配置仅安装 CLI 工具
5. 确保防火墙允许相应端口的访问
6. 在生产环境中，请修改所有默认密码

## 故障排查

### GitLab 无法访问
```bash
# 检查 GitLab 服务状态
docker exec gitlab-server gitlab-ctl status

# 查看 GitLab 日志
docker exec gitlab-server gitlab-ctl tail

# 重新配置 GitLab
docker exec gitlab-server gitlab-ctl reconfigure
```

### Jenkins 无法访问
```bash
# 检查 Jenkins 服务状态
docker exec jenkins-server systemctl status jenkins

# 查看 Jenkins 日志
docker exec jenkins-server journalctl -u jenkins -f

# 重启 Jenkins
docker exec jenkins-server systemctl restart jenkins
```

### ArgoCD 无法访问
```bash
# 检查 ArgoCD 服务状态
docker exec argocd-server systemctl status argocd

# 查看 ArgoCD 日志
docker exec argocd-server journalctl -u argocd -f

# 重启 ArgoCD
docker exec argocd-server systemctl restart argocd
```