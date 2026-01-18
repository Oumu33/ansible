#!/bin/bash
# ============================================
# Nginx日志分析系统Rocky测试脚本
# ============================================
# 说明：使用Rocky镜像测试ClickHouse + Vector部署
# 作者：VictoriaMetrics-Full
# 更新时间：2026-01-18
# 内存控制：严格控制每个容器的内存使用
# ============================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查Docker是否运行
check_docker() {
    log_step "检查Docker环境..."
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker未运行"
        exit 1
    fi

    log_info "Docker环境正常"
}

# 停止并清理旧容器
cleanup_containers() {
    log_step "清理旧容器..."
    docker-compose -f docker-rocky-test.yml down -v 2>/dev/null || true
    log_info "旧容器已清理"
}

# 启动Rocky测试环境
start_rocky_containers() {
    log_step "启动Rocky测试容器..."
    docker-compose -f docker-rocky-test.yml up -d

    # 等待容器启动
    log_info "等待容器启动..."
    sleep 30

    # 检查容器状态
    log_info "检查容器状态..."
    docker-compose -f docker-rocky-test.yml ps

    log_info "Rocky测试容器启动完成"
}

# 等待SSH服务就绪
wait_for_ssh() {
    local host=$1
    local port=22
    local max_attempts=30
    local attempt=1

    log_info "等待 ${host} SSH服务就绪..."

    while [ $attempt -le $max_attempts ]; do
        if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@${host} "echo 'SSH OK'" &>/dev/null; then
            log_info "${host} SSH服务就绪"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    log_error "${host} SSH服务未就绪"
    return 1
}

# 在容器中安装ClickHouse
install_clickhouse() {
    log_step "在ClickHouse容器中安装ClickHouse..."

    docker exec clickhouse-1 bash -c "
        # 添加ClickHouse仓库
        yum install -y yum-utils &&
        yum-config-manager --add-repo https://packages.clickhouse.com/rpm/clickhouse.repo &&

        # 安装ClickHouse
        yum install -y clickhouse-server clickhouse-client &&

        # 配置ClickHouse
        mkdir -p /etc/clickhouse-server &&
        echo '<yandex>
            <listen_host>::</listen_host>
            <max_memory_usage>1500000000</max_memory_usage>
            <max_server_memory_usage_to_ram_ratio>0.9</max_server_memory_usage_to_ram_ratio>
        </yandex>' > /etc/clickhouse-server/config.d/memory.xml &&

        # 启动ClickHouse
        clickhouse-server --daemon &&

        # 等待ClickHouse启动
        sleep 10 &&

        # 创建数据库和表
        clickhouse-client --query 'CREATE DATABASE IF NOT EXISTS nginx_logs' &&

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
        ' &&

        # 创建用户
        clickhouse-client --query \"
            CREATE USER IF NOT EXISTS clickhouse IDENTIFIED BY 'clickhouse'
        \" &&

        clickhouse-client --query \"
            GRANT ALL ON nginx_logs.* TO clickhouse
        \" &&

        echo 'ClickHouse安装完成'
    "

    log_info "ClickHouse安装完成"
}

# 在容器中安装Vector
install_vector() {
    log_step "在Vector容器中安装Vector..."

    docker exec vector-1 bash -c "
        # 下载Vector
        wget https://github.com/vectordotdev/vector/releases/download/v0.52.0/vector-0.52.0-x86_64-unknown-linux-musl.tar.gz -O /tmp/vector.tar.gz &&

        # 解压Vector
        tar -xzf /tmp/vector.tar.gz -C /tmp &&

        # 安装Vector
        cp /tmp/vector-0.52.0-x86_64-unknown-linux-musl/vector /usr/local/bin/ &&
        chmod +x /usr/local/bin/vector &&

        # 下载GeoIP数据库
        mkdir -p /etc/vector &&
        wget https://github.com/P3TERX/GeoLite.mmdb/raw/download/GeoLite2-City.mmdb -O /etc/vector/GeoLite2-City.mmdb &&

        # 创建Vector配置
        cat > /etc/vector/vector.toml << 'EOF'
[sources.nginx_logs]
  type = \"file\"
  include = [\"/var/log/nginx/access.log\"]
  read_from = \"beginning\"

[transforms.parse_nginx]
  type = \"regex_parser\"
  inputs = [\"nginx_logs\"]
  regex = '^(?P<remote_addr>\\S+) \\S+ \\S+ \\[(?P<time_local>[^\\]]+)\\] \"(?P<request>\\S+ \\S+ \\S+)\\\" (?P<status>\\d+) (?P<body_bytes_sent>\\d+) \"(?P<http_referer>[^\\\"]*)\" \"(?P<http_user_agent>[^\\\"]*)\"'

[transforms.geoip]
  type = \"geoip\"
  inputs = [\"parse_nginx\"]
  database = \"/etc/vector/GeoLite2-City.mmdb\"
  source = \"remote_addr\"
  target = \"geoip\"

[transforms.to_clickhouse]
  type = \"remap\"
  inputs = [\"geoip\"]
  source = \''
    .timestamp = parse_timestamp(.time_local, \"%d/%b/%Y:%H:%M:%S %z\")
    .country = .geoip.country_code
    .city = .geoip.city
    .latitude = .geoip.latitude
    .longitude = .geoip.longitude
    .asn = .geoip.asn
    .organization = .geoip.organization
  \''

[sinks.clickhouse]
  type = \"clickhouse\"
  inputs = [\"to_clickhouse\"]
  endpoint = \"http://172.22.0.30:8123\"
  database = \"nginx_logs\"
  table = \"access_logs\"
  encoding.codec = \"json\"
  healthcheck.enabled = true

[sinks.console]
  type = \"console\"
  inputs = [\"to_clickhouse\"]
  encoding.codec = \"json\"
EOF

        # 启动Vector
        vector -c /etc/vector/vector.toml &

        echo 'Vector安装完成'
    "

    log_info "Vector安装完成"
}

# 配置Nginx
configure_nginx() {
    log_step "配置Nginx..."

    docker exec nginx-1 bash -c "
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
    log_format geoip '\$remote_addr - \$remote_user [\$time_local] \"\$request\" \$status \$body_bytes_sent \"\$http_referer\" \"\$http_user_agent\"';

    access_log /var/log/nginx/access.log geoip;

    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name localhost;

        location / {
            return 200 \"Hello from Rocky Linux\";
        }
    }
}
EOF

        # 重启Nginx
        nginx -s reload

        echo 'Nginx配置完成'
    "

    log_info "Nginx配置完成"
}

# 生成测试日志
generate_test_logs() {
    log_step "生成测试日志..."

    # 生成100个测试请求
    for i in {1..100}; do
        docker exec nginx-1 curl -s http://localhost/ > /dev/null
        sleep 0.1
    done

    log_info "测试日志生成完成"
}

# 验证数据对接
verify_data() {
    log_step "验证数据对接..."

    # 检查ClickHouse中的数据
    docker exec clickhouse-1 clickhouse-client --query "SELECT count() FROM nginx_logs.access_logs"

    # 查看最近的数据
    docker exec clickhouse-1 clickhouse-client --query "
        SELECT
            country,
            city,
            count() as requests
        FROM nginx_logs.access_logs
        GROUP BY country, city
        ORDER BY requests DESC
        LIMIT 10
    "

    log_info "数据对接验证完成"
}

# 检查内存使用
check_memory() {
    log_step "检查容器内存使用..."

    docker stats --no-stream --format "table {{.Name}}\t{{.MemUsage}}\t{{.MemPerc}}" clickhouse-1 vector-1 nginx-1

    log_info "内存使用检查完成"
}

# 主函数
main() {
    log_info "========================================"
    log_info "Nginx日志分析系统Rocky测试"
    log_info "========================================"

    check_docker
    cleanup_containers
    start_rocky_containers

    # 等待所有SSH服务就绪
    wait_for_ssh 172.22.0.30
    wait_for_ssh 172.22.0.31
    wait_for_ssh 172.22.0.32

    install_clickhouse
    install_vector
    configure_nginx
    generate_test_logs

    # 等待数据采集
    log_info "等待数据采集..."
    sleep 10

    verify_data
    check_memory

    log_info "========================================"
    log_info "测试完成！"
    log_info "========================================"
    log_info "ClickHouse: http://172.22.0.30:8123"
    log_info "Vector: http://172.22.0.31:8686"
    log_info "Nginx: http://172.22.0.32:80"
    log_info ""
    log_info "查看日志："
    log_info "  docker logs clickhouse-1"
    log_info "  docker logs vector-1"
    log_info "  docker logs nginx-1"
    log_info ""
    log_info "停止测试环境："
    log_info "  docker-compose -f docker-rocky-test.yml down"
}

# 运行主函数
main "$@"