# ELK Stack 部署测试报告

## 测试概述

本测试在 Rocky Linux 9 Docker 容器环境中验证了 ELK Stack（Elasticsearch、Logstash、Kibana）和 Filebeat 的部署。

**测试日期**: 2026-01-08
**测试环境**: Docker 容器模拟 Rocky Linux 9 主机
**测试目的**: 验证 ELK Stack 基本功能，为生产环境部署做准备

## 架构说明

### 测试环境架构（单节点模式）

由于测试环境内存限制，本次测试采用单节点模式：

```
┌─────────────────────────────────────────────────────────┐
│                   Docker 网络 (172.21.0.0/16)           │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────────┐                                   │
│  │  Elasticsearch   │  172.21.0.10:9200 (HTTP)         │
│  │      (单节点)    │  172.21.0.10:9300 (Transport)     │
│  │  Heap: 512MB     │                                   │
│  └──────────────────┘                                   │
│           ▲                                              │
│           │                                              │
│  ┌────────┴────────┐      ┌──────────────────┐          │
│  │    Logstash     │      │    Kibana        │          │
│  │  172.21.0.13    │◄─────│  172.21.0.14    │          │
│  │  Heap: 512MB    │      │  Port: 5601      │          │
│  └─────────────────┘      └──────────────────┘          │
│           ▲                                              │
│           │                                              │
│  ┌────────┴────────┐                                    │
│  │    Filebeat     │                                    │
│  │  172.21.0.15    │                                    │
│  └─────────────────┘                                    │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 生产环境架构（完整集群）

**注意**: 生产环境应使用完整集群配置，包括：

- **Elasticsearch**: 3节点集群，每个节点堆内存 1GB
- **Logstash**: 1节点，堆内存 1GB
- **Kibana**: 1节点
- **Filebeat**: 1节点

完整集群配置提供：
- 高可用性
- 数据冗余
- 负载均衡
- 故障转移

## 组件版本

| 组件 | 版本 | 说明 |
|------|------|------|
| Elasticsearch | 9.0.2 | 搜索和分析引擎 |
| Logstash | 9.0.2 | 数据处理管道 |
| Kibana | 9.0.2 | 数据可视化平台 |
| Filebeat | 9.0.2 | 日志采集器 |

## 测试结果

### 1. Elasticsearch

**状态**: ✅ 运行正常

```json
{
  "cluster_name": "elk-cluster",
  "status": "green",
  "number_of_nodes": 1,
  "number_of_data_nodes": 1,
  "active_primary_shards": 31,
  "active_shards": 31,
  "active_shards_percent_as_number": 100.0
}
```

**配置**:
- 模式: 单节点 (discovery.type: single-node)
- 堆内存: 512MB (测试环境) / 1GB (生产环境)
- HTTP 端口: 9200
- Transport 端口: 9300

**访问地址**: http://172.21.0.10:9200

### 2. Logstash

**状态**: ✅ 运行正常

```json
{
  "status": "green",
  "pipeline": {
    "workers": 2,
    "batch_size": 125,
    "batch_delay": 50
  }
}
```

**配置**:
- 堆内存: 512MB (测试环境) / 1GB (生产环境)
- HTTP 端口: 9600
- Pipeline 输入: HTTP (端口 8080)
- Pipeline 输出: Elasticsearch

**访问地址**: http://172.21.0.13:9600

### 3. Kibana

**状态**: ✅ 运行正常

```json
{
  "status": {
    "overall": {
      "level": "available",
      "summary": "All services and plugins are available"
    }
  }
}
```

**配置**:
- HTTP 端口: 5601
- Elasticsearch 主机: http://172.21.0.10:9200

**访问地址**: http://172.21.0.14:5601

### 4. Filebeat

**状态**: ✅ 运行正常

```json
{
  "info": {
    "name": "filebeat",
    "version": "9.0.2",
    "uptime": "306ms"
  },
  "output": {
    "type": "elasticsearch",
    "events": {
      "acked": 0,
      "total": 0
    }
  }
}
```

**配置**:
- 输入: 日志文件 (/var/log/*.log)
- 输出: Elasticsearch
- 索引模式: filebeat-%{[agent.version]}-%{+yyyy.MM.dd}

## 部署说明

### 测试环境部署

使用简化测试脚本：

```bash
/opt/ansible/test-elk-simple.sh
```

该脚本会：
1. 启动 Docker 容器
2. 部署单节点 Elasticsearch
3. 部署 Logstash
4. 部署 Kibana
5. 部署 Filebeat
6. 验证所有组件状态

### 生产环境部署

使用 Ansible Playbook：

```bash
# 部署完整集群
cd /opt/ansible/ELK/Rocky
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-cluster.yml

# 或单独部署各组件
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-elasticsearch.yml
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-logstash.yml
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-kibana.yml
ansible-playbook -i inventory/hosts-docker.yml playbooks/deploy-filebeat.yml
```

## 配置文件位置

### Elasticsearch
- 配置文件: `/usr/share/elasticsearch/config/elasticsearch.yml`
- JVM 配置: `/usr/share/elasticsearch/config/jvm.options.d/heap.options`
- 数据目录: `/usr/share/elasticsearch/data`
- 日志目录: `/var/log/elasticsearch`

### Logstash
- 配置文件: `/etc/logstash/logstash.yml`
- Pipeline 配置: `/etc/logstash/conf.d/pipeline.conf`
- JVM 配置: `/usr/share/logstash/config/jvm.options.d/heap.options`
- 数据目录: `/usr/share/logstash/data`
- 日志目录: `/var/log/logstash`

### Kibana
- 配置文件: `/usr/share/kibana/config/kibana.yml`
- 数据目录: `/usr/share/kibana/data`
- 日志目录: `/var/log/kibana`

### Filebeat
- 配置文件: `/etc/filebeat/filebeat.yml`
- 数据目录: `/var/lib/filebeat`
- 日志目录: `/var/log/filebeat`

## 网络配置

| 组件 | IP 地址 | HTTP 端口 | Transport 端口 |
|------|---------|-----------|----------------|
| Elasticsearch | 172.21.0.10 | 9200 | 9300 |
| Logstash | 172.21.0.13 | 9600 | - |
| Kibana | 172.21.0.14 | 5601 | - |
| Filebeat | 172.21.0.15 | - | - |

## 性能优化建议

### 测试环境（内存受限）

- Elasticsearch 堆内存: 512MB
- Logstash 堆内存: 512MB
- 单节点模式

### 生产环境

- Elasticsearch 堆内存: 每节点 1GB 或更高
- Logstash 堆内存: 1GB 或更高
- 3节点 Elasticsearch 集群
- 启用数据持久化
- 配置适当的索引生命周期管理 (ILM)

## 故障排查

### Elasticsearch 无法启动

1. 检查 JVM 堆内存配置
2. 确认数据目录权限
3. 查看日志: `tail -f /var/log/elasticsearch/elasticsearch.log`

### Logstash 无法连接 Elasticsearch

1. 验证 Elasticsearch 运行状态
2. 检查网络连接
3. 确认输出配置正确

### Kibana 无法访问

1. 确认 Elasticsearch 可用
2. 检查 Kibana 配置
3. 查看日志: `tail -f /var/log/kibana/kibana.log`

### Filebeat 无法发送数据

1. 验证 Elasticsearch 连接
2. 检查输入路径配置
3. 查看日志: `tail -f /var/log/filebeat/filebeat.log`

## 安全配置

**注意**: 当前测试环境已禁用安全功能以简化配置。

生产环境应启用：
- X-Pack Security
- TLS/SSL 加密
- 用户认证和授权
- 网络安全组规则

## 下一步

1. 配置索引生命周期管理 (ILM)
2. 设置告警和监控
3. 配置数据保留策略
4. 启用安全功能
5. 配置备份和恢复

## 结论

ELK Stack 在 Rocky Linux 9 环境中部署成功，所有组件运行正常。测试环境采用单节点模式以节省内存，生产环境应使用完整集群配置以确保高可用性和数据冗余。

**测试状态**: ✅ 通过
**建议**: 可以继续在生产环境部署完整集群配置。