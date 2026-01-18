# Nginx日志分析系统

## 项目简介

本项目提供了一套完整的Nginx日志分析解决方案，基于ClickHouse + Vector + Grafana，支持实时日志采集、地理位置分析和可视化展示。

## 架构说明

### 核心组件

```
┌─────────────────────────────────────────────────────────────────┐
│                        日志分析架构图                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐                  │
│  │  Nginx   │    │  Vector  │    │ClickHouse│                  │
│  │ (日志源)  │───▶│ (采集+转换)│───▶│ (存储+分析)│                │
│  └──────────┘    └──────────┘    └──────────┘                  │
│       │               │               │                         │
│       │               │               │                         │
│       │               │               ▼                         │
│       │               │         ┌──────────┐                    │
│       │               │         │  Grafana │                    │
│       │               │         │ (可视化)  │                    │
│       │               │         └──────────┘                    │
│       │               │               │                         │
│       │               │               ▼                         │
│       │               │         ┌──────────┐                    │
│       │               │         │ 高德地图  │                    │
│       │               │         │ (地理位置)│                    │
│       │               │         └──────────┘                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 组件说明

#### 1. ClickHouse
- **用途**：高性能列式数据库，用于存储和分析日志
- **特点**：
  - 列式存储，压缩比高
  - 查询性能优秀
  - 原生支持GeoIP功能
  - 支持实时分析

#### 2. Vector
- **用途**：日志采集和转换工具
- **特点**：
  - 高性能日志采集
  - 支持GeoIP转换
  - 实时处理
  - 灵活的转换规则

#### 3. Nginx
- **用途**：Web服务器，产生访问日志
- **特点**：
  - 支持自定义日志格式
  - 高性能
  - 广泛使用

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

## 端口列表

| 服务 | 端口 | 说明 |
|------|------|------|
| ClickHouse HTTP | 8123 | HTTP API |
| ClickHouse TCP | 9000 | 原生协议 |
| ClickHouse MySQL | 9004 | MySQL协议 |
| Vector API | 8686 | API端点 |

## 快速开始

### 1. 克隆项目

```bash
cd /opt/ansible/untested/nginx-logs-analysis/Rocky
```

### 2. 配置主机IP

编辑 `inventory/group_vars/all.yml`，修改主机IP地址：

```yaml
# 主机IP地址配置
clickhouse_1_ip: "172.22.0.30"
vector_1_ip: "172.22.0.31"
nginx_1_ip: "172.22.0.32"
```

### 3. 配置主机清单

编辑 `inventory/hosts.yml`，确保ansible_host与上面的IP一致：

```yaml
clickhouse:
  hosts:
    clickhouse-1:
      ansible_host: 172.22.0.30
      ansible_user: root

vector:
  hosts:
    vector-1:
      ansible_host: 172.22.0.31
      ansible_user: root

nginx:
  hosts:
    nginx-1:
      ansible_host: 172.22.0.32
      ansible_user: root
```

### 4. 部署系统

```bash
ansible-playbook -i inventory/hosts.yml playbooks/deploy.yml
```

## 配置说明

### ClickHouse配置

数据库名：`nginx_logs`
表名：`access_logs`

表结构：
```sql
CREATE TABLE nginx_logs.access_logs (
    timestamp DateTime,
    remote_addr String,
    remote_user String,
    request String,
    status UInt16,
    body_bytes_sent UInt64,
    http_referer String,
    http_user_agent String,
    request_time Float32,
    upstream_response_time Float32,
    country String,
    city String,
    latitude Float32,
    longitude Float32,
    asn UInt32,
    organization String
) ENGINE = MergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, remote_addr)
```

### Vector配置

**数据源**：Nginx访问日志
**转换**：
1. 解析Nginx日志格式
2. 转换时间戳
3. GeoIP地理位置转换
4. 提取地理位置信息
5. 转换为ClickHouse格式

**目标**：ClickHouse数据库

### Nginx配置

日志格式：
```
$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" $request_time $upstream_response_time
```

## Grafana配置

### 1. 安装ClickHouse插件

```bash
grafana-cli plugins install grafana-clickhouse-datasource
```

### 2. 配置ClickHouse数据源

在Grafana中添加ClickHouse数据源：
- **类型**：ClickHouse
- **URL**：http://<clickhouse_1_ip>:8123
- **数据库**：nginx_logs
- **用户名**：default
- **密码**：clickhouse

### 3. 创建仪表板

#### 全球访问热力图

```sql
SELECT
    country,
    avg(latitude) AS lat,
    avg(longitude) AS lon,
    count() AS value
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY country
```

#### 城市访问分布

```sql
SELECT
    city,
    latitude AS lat,
    longitude AS lon,
    count() AS value
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
AND country = 'CN'
GROUP BY city, latitude, longitude
```

#### 访问趋势

```sql
SELECT
    toStartOfInterval(timestamp, INTERVAL 1 HOUR) AS time,
    count() AS requests
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY time
ORDER BY time
```

#### 访问状态码分布

```sql
SELECT
    status,
    count() AS count
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY status
ORDER BY count DESC
```

#### Top 10访问IP

```sql
SELECT
    remote_addr,
    count() AS count
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY remote_addr
ORDER BY count DESC
LIMIT 10
```

## 高德地图配置

### 1. 获取高德地图API Key

访问高德开放平台：https://lbs.amap.com/
注册账号并申请Web服务API Key

### 2. 配置Grafana高德地图

在VictoriaMetrics-Full的Grafana配置中设置：
```yaml
grafana_map_provider: "amap"
grafana_amap_api_key: "YOUR_API_KEY"
grafana_amap_style: "normal"
```

### 3. 使用高德地图GeoMap面板

在Grafana中创建GeoMap面板，使用上述SQL查询，选择高德地图作为底图。

## 查询示例

### 按国家统计访问量

```sql
SELECT
    country,
    count() AS requests
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY country
ORDER BY requests DESC
```

### 按城市统计访问量

```sql
SELECT
    country,
    city,
    count() AS requests
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY country, city
ORDER BY requests DESC
```

### 按ASN统计访问量

```sql
SELECT
    asn,
    organization,
    count() AS requests
FROM nginx_logs.access_logs
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY asn, organization
ORDER BY requests DESC
```

### 查询特定IP的访问记录

```sql
SELECT
    *
FROM nginx_logs.access_logs
WHERE remote_addr = '1.2.3.4'
AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
```

### 查询慢请求

```sql
SELECT
    remote_addr,
    request,
    request_time,
    timestamp
FROM nginx_logs.access_logs
WHERE request_time > 1.0
AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY request_time DESC
LIMIT 100
```

## 性能优化

### 1. ClickHouse优化

```sql
-- 创建物化视图（可选）
CREATE MATERIALIZED VIEW nginx_logs.access_logs_hourly_mv
ENGINE = SummingMergeTree()
PARTITION BY toYYYYMM(timestamp)
ORDER BY (timestamp, country, city)
AS SELECT
    toStartOfInterval(timestamp, INTERVAL 1 HOUR) AS timestamp,
    country,
    city,
    count() AS requests,
    avg(request_time) AS avg_request_time
FROM nginx_logs.access_logs
GROUP BY timestamp, country, city;
```

### 2. Vector优化

```toml
# 增加批处理大小
batch.max_events = 5000
batch.timeout_secs = 5

# 启用压缩
compression = "gzip"
```

### 3. Nginx优化

```nginx
# 使用异步日志
access_log {{ nginx_log_dir }}/access.log {{ nginx_log_format_name }} buffer=32k flush=5s;
```

## 监控与告警

### Vector监控

访问Vector API：
```bash
curl http://<vector_1_ip>:8686/health
```

### ClickHouse监控

```sql
-- 查看表大小
SELECT
    table,
    formatReadableSize(sum(bytes)) AS size
FROM system.parts
WHERE database = 'nginx_logs'
AND active
GROUP BY table;
```

## 常见问题

### 1. Vector无法连接ClickHouse

**问题**: Vector日志显示连接失败

**解决**:
- 检查ClickHouse服务状态
- 检查防火墙规则
- 验证连接配置

### 2. GeoIP转换失败

**问题**: 地理位置信息为空

**解决**:
- 检查GeoIP数据库是否下载成功
- 验证数据库路径配置
- 确保IP地址格式正确

### 3. ClickHouse查询慢

**问题**: 查询响应时间过长

**解决**:
- 创建物化视图
- 优化查询语句
- 增加内存配置

## 版本信息

当前版本：

| 组件 | 版本 |
|------|------|
| ClickHouse | 24.3 |
| Vector | 0.52.0 |
| GeoIP | GeoLite2-City |

## 备份与恢复

### 备份数据

```bash
# 备份ClickHouse数据
clickhouse-client --host <clickhouse_1_ip> --port 9000 --user default --password clickhouse --query "BACKUP TABLE nginx_logs.access_logs TO File('/tmp/backup/')"
```

### 恢复数据

```bash
# 恢复ClickHouse数据
clickhouse-client --host <clickhouse_1_ip> --port 9000 --user default --password clickhouse --query "RESTORE TABLE nginx_logs.access_logs FROM File('/tmp/backup/')"
```

## 技术支持

- ClickHouse官方文档: https://clickhouse.com/docs/
- Vector官方文档: https://vector.dev/docs/
- Grafana官方文档: https://grafana.com/docs/
- 高德地图API文档: https://lbs.amap.com/api/

## 许可证

本项目遵循相关组件的开源许可证。

---

**最后更新**: 2026-01-18