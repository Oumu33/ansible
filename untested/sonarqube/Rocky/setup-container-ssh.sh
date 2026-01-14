#!/bin/bash
# 配置 Docker 容器的 SSH 连接

# 生成 SSH 密钥对
ssh-keygen -t rsa -f /tmp/sonarqube_key -N "" -q

# 配置每个容器的 SSH
for container in postgresql-1 sonarqube-1; do
  echo "配置 $container 的 SSH..."

  # 创建 .ssh 目录
  docker exec $container bash -c "mkdir -p /root/.ssh"

  # 复制公钥到容器
  docker cp /tmp/sonarqube_key.pub $container:/root/.ssh/authorized_keys

  # 设置权限
  docker exec $container bash -c "chmod 700 /root/.ssh"
  docker exec $container bash -c "chmod 600 /root/.ssh/authorized_keys"

  # 启动 SSH 服务
  docker exec $container bash -c "dnf install -y openssh-server"
  docker exec $container bash -c "ssh-keygen -A"
  docker exec $container bash -c "/usr/sbin/sshd"

  echo "$container SSH 配置完成"
done

echo ""
echo "SSH 密钥已保存到: /tmp/sonarqube_key"
echo "现在可以使用 Ansible 部署了:"
echo "ansible-playbook -i inventory/hosts.yml playbooks/deploy-all.yml --private-key=/tmp/sonarqube_key"