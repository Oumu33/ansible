# Rocky镜像测试环境指南

## 概述

本文档说明如何使用Rocky Linux镜像模拟Ansible部署ClickHouse + Vector日志分析系统，并进行数据对接测试。

## 内存配置

为了防止内存溢出，每个容器的内存配置如下：

| 容器 | 内存限制 | 保留内存 | CPU限制 | 说明 |
|------|---------|---------|---------|------|
| clickhouse-1 | 2GB | 1GB | 2核 | ClickHouse数据库 |
| vector-1 | 512MB | 256MB | 1核 | Vector日志采集 |
| nginx-1 | 512MB | 256MB | 1核 | Nginx服务器 |

**总内存需求：** 约3GB

## 快速开始

### 1. 启动测试环境

```bash
cd /opt/ansible/untested/nginx-logs-analysis/Rocky
./test-rocky-deployment.sh
```

脚本会自动完成以下步骤：
1. 启动3个Rocky Linux容器
2. 安装ClickHouse
3. 安装Vector
4. 配置Nginx
5. 生成测试日志
6. 验证数据对接
7. 检查内存使用

### 2. 手动启动容器

```bash
docker-compose -f docker-rocky-test.yml up -d
```

### 3. 查看容器状态

```bash
docker-compose -f docker-rocky-test.yml ps
```

### 4. 查看日志

```bash
# ClickHouse日志
docker logs clickhouse-1

# Vector日志
docker logs vector-1

# Nginx日志
docker logs nginx-1

# Nginx访问日志
docker exec nginx-1 tail -f /var/log/nginx/access.log
```

### 5. 检查内存使用

```bash
docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" clickhouse-1 vector-1 nginx-1
```

### 6. 验证数据对接

```bash
# 连接到ClickHouse
docker exec -it clickhouse-1 clickhouse-client

# 查看数据库
SHOW DATABASES;

# 查看表
USE nginx_logs;
SHOW TABLES;

# 查看数据量
SELECT count() FROM nginx_logs.access_logs;

# 查看最近的数据
SELECT
    timestamp,
    remote_addr,
    country,
    city,
    status,
    request
FROM nginx_logs.access_logs
ORDER BY timestamp DESC
LIMIT 10;

# 按国家统计
SELECT
    country,
    count() as requests
FROM nginx_logs.access_logs
GROUP BY country
ORDER BY requests DESC;

# 按城市统计
SELECT
    country,
    city,
    count() as requests
FROM nginx_logs.access_logs
GROUP BY country, city
ORDER BY requests DESC
LIMIT 10;
```

## 手动部署步骤

### 1. 进入ClickHouse容器

```bash
docker exec -it clickhouse-1 bash
```

### 2. 安装ClickHouse

```bash
# 添加ClickHouse仓库
yum install -y yum-utils
yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo

# 安装ClickHouse
yum install -y clickhouse-server clickhouse-client

# 配置内存限制
mkdir -p /etc/clickhouse-server
cat > /etc/clickhouse-server/config.d/memory.xml << 'EOF'
<yandex>
    <listen_host>::</listen_host>
    <max_memory_usage>1500000000</max_memory_usage>
    <max_server_memory_usage_to_ram_ratio>0.9</max_server_memory_usage_to_ram_ratio>
</yandex>
EOF

# 启动ClickHouse
clickhouse-server --daemon

# 等待启动
sleep 10

# 创建数据库和表
clickhouse-client --query 'CREATE DATABASE IF NOT EXISTS nginx_logs'

clickhouse-client --query '
    CREATE TABLE IF NOT EXISTS nginx_logs.access_logs (
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
    SETTINGS index_granularity = 8192
'

# 创建用户
clickhouse-client --query "CREATE USER IF NOT EXISTS clickhouse IDENTIFIED BY 'clickhouse'"
clickhouse-client --query "GRANT ALL ON nginx_logs.* TO clickhouse"
```

### 3. 进入Vector容器

```bash
docker exec -it vector-1 bash
```

### 4. 安装Vector

```bash
# 下载Vector
wget https://github.com/vectordotdev/vector/releases/download/v0.52.0/vector-0.52.0-x86_64-unknown-linux-musl.tar.gz -O /tmp/vector.tar.gz

# 解压
tar -xzf /tmp/vector.tar.gz -C /tmp

# 安装
cp /tmp/vector-0.52.0-x86_64-unknown-linux-musl/vector /usr/local/bin/
chmod +x /usr/local/bin/vector

# 下载GeoIP数据库
mkdir -p /etc/vector
wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb -O /etc/vector/GeoLite2-City.mmdb

# 创建配置
cat > /etc/vector/vector.toml << 'EOF'
[sources.nginx_logs]
  type = "file"
  include = ["/var/log/nginx/access.log"]
  read_from = "beginning"

[transforms.parse_nginx]
  type = "regex_parser"
  inputs = ["nginx_logs"]
  regex = '^(?P<remote_addr>\S+) \S+ \S+ \[(?P<time_local>[^\]]+)\] "(?P<request>\S+ \S+ \S+)" (?P<status>\d+) (?P<body_bytes_sent>\d+) "(?P<http_referer>[^"]*)" "(?P<http_user_agent>[^"]*)"'

[transforms.geoip]
  type = "geoip"
  inputs = ["parse_nginx"]
  database = "/etc/vector/GeoLite2-City.mmdb"
  source = "remote_addr"
  target = "geoip"

[transforms.to_clickhouse]
  type = "remap"
  inputs = ["geoip"]
  source = '''
    .timestamp = parse_timestamp(.time_local, "%d/%b/%Y:%H:%M:%S %z")
    .country = .geoip.country_code
    .city = .geoip.city
    .latitude = .geoip.latitude
    .longitude = .geoip.longitude
    .asn = .geoip.asn
    .organization = .geoip.organization
  '''

[sinks.clickhouse]
  type = "clickhouse"
  inputs = ["to_clickhouse"]
  endpoint = "http://172.22.0.30:8123"
  database = "nginx_logs"
  table = "access_logs"
  encoding.codec = "json"
  healthcheck.enabled = true

[sinks.console]
  type = "console"
  inputs = ["to_clickhouse"]
  encoding.codec = "json"
EOF

# 启动Vector
vector -c /etc/vector/vector.toml &
```

### 5. 进入Nginx容器

```bash
docker exec -it nginx-1 bash
```

### 6. 配置Nginx

```bash
# 配置Nginx日志格式
cat > /etc/nginx/nginx.conf << 'EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format geoip '$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent"';

    access_log /var/log/nginx/access.log geoip;

    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name localhost;

        location / {
            return 200 "Hello from Rocky Linux";
        }
    }
}
EOF

# 重启Nginx
nginx -s reload
```

### 7. 生成测试日志

```bash
# 在Nginx容器中
for i in {1..100}; do
    curl -s http://localhost/ > /dev/null
    sleep 0.1
done
```

## 性能优化

### ClickHouse内存优化

```xml
<!-- /etc/clickhouse-server/config.d/memory.xml -->
<yandex>
    <listen_host>::</listen_host>
    <max_memory_usage>1500000000</max_memory_usage>
    <max_server_memory_usage_to_ram_ratio>0.9</max_server_memory_usage_to_ram_ratio>
    <max_concurrent_queries>10</max_concurrent_queries>
    <max_concurrent_insert_queries>5</max_concurrent_insert_queries>
</yandex>
```

### Vector内存优化

```toml
# /etc/vector/vector.toml
[sinks.clickhouse]
  type = "clickhouse"
  inputs = ["to_clickhouse"]
  endpoint = "http://172.22.0.30:8123"
  database = "nginx_logs"
  table = "access_logs"
  encoding.codec = "json"
  healthcheck.enabled = true
  batch.max_events = 500
  batch.timeout_secs = 5
```

## 故障排查

### 1. 内存不足

**症状**：容器被OOM killer杀死

**解决**：
- 减少并发请求数
- 降低ClickHouse的max_memory_usage
- 增加容器内存限制

### 2. Vector无法连接ClickHouse

**症状**：Vector日志显示连接失败

**解决**：
```bash
# 检查ClickHouse是否运行
docker exec clickhouse-1 clickhouse-client --query "SELECT 1"

# 检查网络连接
docker exec vector-1 ping 172.22.0.30
docker exec vector-1 curl http://172.22.0.30:8123

# 检查Vector配置
docker exec vector-1 cat /etc/vector/vector.toml
```

### 3. GeoIP转换失败

**症状**：地理位置信息为空

**解决**：
```bash
# 检查GeoIP数据库
docker exec vector-1 ls -lh /etc/vector/GeoLite2-City.mmdb

# 检查Vector日志
docker logs vector-1 | grep geoip

# 查看转换后的数据
docker exec vector-1 cat /etc/vector/vector.toml
```

### 4. 数据未写入ClickHouse

**症状**：ClickHouse表中没有数据

**解决**：
```bash
# 检查Vector日志
docker logs vector-1

# 检查ClickHouse表结构
docker exec clickhouse-1 clickhouse-client --query "DESCRIBE nginx_logs.access_logs"

# 手动插入测试数据
docker exec clickhouse-1 clickhouse-client --query "
    INSERT INTO nginx_logs.access_logs VALUES
    (now(), '1.2.3.4', '', 'GET / HTTP/1.1', 200, 123, '', '', 0.1, 0.1, 'CN', 'Beijing', 39.9042, 116.4074, 0, '')
"
```

## 清理环境

```bash
# 停止容器
docker-compose -f docker-rocky-test.yml down

# 删除容器和卷
docker-compose -f docker-rocky-test.yml down -v

# 删除镜像（可选）
docker rmi rockylinux:8
```

## 下一步

1. 使用Grafana连接ClickHouse
2. 创建GeoMap仪表板
3. 配置高德地图
4. 分析访问数据

## 参考资料

- [ClickHouse官方文档](https://clickhouse.com/docs/)
- [Vector官方文档](https://vector.dev/docs/)
- [Rocky Linux官方文档](https://docs.rockylinux.org/)

---

**最后更新**: 2026-01-18