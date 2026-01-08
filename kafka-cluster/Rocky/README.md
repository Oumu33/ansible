# Kafka 集群

## 架构说明

Kafka 分布式消息队列，由 Zookeeper 协调。

```
┌──────────────────────────────────────┐
│  Zookeeper 集群 (3 节点)              │
│  - 172.128.0.10:2181                 │
│  - 172.128.0.11:2181                 │
│  - 172.128.0.12:2181                 │
└──────────────────────────────────────┘
         ↓
┌──────────────────────────────────────┐
│  Kafka Broker 集群 (3 节点)           │
│  - 172.128.0.13:9092                 │
│  - 172.128.0.14:9092                 │
│  - 172.128.0.15:9092                 │
└──────────────────────────────────────┘
```

## 快速开始

### 使用 Rocky Linux 镜像测试

```bash
# 1. 设置测试环境（生成 SSH 密钥）
cd /opt/ansible
./setup-rocky-test-env.sh

# 2. 测试并部署 Kafka 集群
./test-project.sh kafka-cluster playbooks/deploy-all.yml
```

### 手动部署步骤

```bash
cd /opt/ansible/kafka-cluster/Ubuntu

# 启动 Docker 容器
docker-compose -f docker-test-hosts.yml up -d

# 安装软件和配置 SSH
for container in zookeeper-{1..3} kafka-{1..3}; do
  docker exec $container bash -c "dnf install -y openssh-server openssh-clients python3 python3-pip curl wget java-17-openjdk-headless"
  docker exec $container bash -c "ssh-keygen -A && /usr/sbin/sshd -D &"
done

# 配置 SSH
ssh-keygen -t rsa -f /tmp/ansible_key -N "" -q
for container in zookeeper-{1..3} kafka-{1..3}; do
  docker exec $container bash -c "mkdir -p /root/.ssh"
  docker cp /tmp/ansible_key.pub $container:/root/.ssh/authorized_keys
done

# 部署
ansible-playbook -i inventory/hosts.yml playbooks/deploy-all.yml --private-key=/tmp/ansible_key -e "ansible_python_interpreter=/usr/bin/python3"
```