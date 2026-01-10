#!/bin/bash
# 统一下载所有项目所需的软件组件
# 用法: ./download-all-components.sh [项目名称]
# 如果不指定项目名称，则下载所有组件

set -e

DOWNLOAD_DIR="/opt/ansible/downloads"
mkdir -p "$DOWNLOAD_DIR"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# 下载函数
download_file() {
    local url="$1"
    local filename="$2"
    local dest_file="$DOWNLOAD_DIR/$filename"

    if [ -f "$dest_file" ]; then
        log_warn "$filename 已存在，跳过下载"
        return 0
    fi

    log_info "正在下载 $filename..."
    if curl -L -o "$dest_file" "$url" --retry 3 --retry-delay 5 --connect-timeout 30; then
        log_info "下载成功: $filename"
        return 0
    else
        log_error "下载失败: $filename"
        rm -f "$dest_file"
        return 1
    fi
}

# Kafka 组件
download_kafka() {
    log_info "=== 下载 Kafka 组件 ==="
    KAFKA_VERSION="3.7.0"
    ZOOKEEPER_VERSION="3.9.2"

    download_file \
        "https://archive.apache.org/dist/zookeeper/zookeeper-$ZOOKEEPER_VERSION/apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz" \
        "apache-zookeeper-$ZOOKEEPER_VERSION-bin.tar.gz"

    download_file \
        "https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_2.13-$KAFKA_VERSION.tgz" \
        "kafka_2.13-$KAFKA_VERSION.tgz"
}

# MongoDB 组件
download_mongodb() {
    log_info "=== 下载 MongoDB 组件 ==="
    MONGODB_VERSION="7.0.14"

    download_file \
        "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel90-${MONGODB_VERSION}.tgz" \
        "mongodb-linux-x86_64-rhel90-${MONGODB_VERSION}.tgz"
}

# MySQL 组件
download_mysql() {
    log_info "=== 下载 MySQL 组件 ==="
    MYSQL_VERSION="8.0.40"

    download_file \
        "https://dev.mysql.com/get/Downloads/MySQL-${MYSQL_VERSION%%.*}/mysql-${MYSQL_VERSION}-linux-glibc2.28-x86_64.tar.xz" \
        "mysql-${MYSQL_VERSION}-linux-glibc2.28-x86_64.tar.xz"

    download_file \
        "https://dev.mysql.com/get/Downloads/MySQL-Router-${MYSQL_VERSION%%.*}/mysql-router-${MYSQL_VERSION}-linux-glibc2.28-x86_64.tar.xz" \
        "mysql-router-${MYSQL_VERSION}-linux-glibc2.28-x86_64.tar.xz"
}

# PostgreSQL 组件
download_postgresql() {
    log_info "=== 下载 PostgreSQL 组件 ==="
    PG_VERSION="16.2"

    download_file \
        "https://ftp.postgresql.org/pub/source/v${PG_VERSION}/postgresql-${PG_VERSION}.tar.gz" \
        "postgresql-${PG_VERSION}.tar.gz"

    download_file \
        "https://get.enterprisedb.com/postgresql/postgresql-${PG_VERSION}-1-linux-x64-binaries.tar.gz" \
        "postgresql-${PG_VERSION}-linux-x64-binaries.tar.gz"
}

# RabbitMQ 组件
download_rabbitmq() {
    log_info "=== 下载 RabbitMQ 组件 ==="
    RABBITMQ_VERSION="3.13.7"
    ERLANG_VERSION="26.2.5"

    download_file \
        "https://github.com/rabbitmq/rabbitmq-server/releases/download/v${RABBITMQ_VERSION}/rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz" \
        "rabbitmq-server-generic-unix-${RABBITMQ_VERSION}.tar.xz"

    download_file \
        "https://github.com/erlang/otp/releases/download/OTP-${ERLANG_VERSION}/otp_src_${ERLANG_VERSION}.tar.gz" \
        "otp_src_${ERLANG_VERSION}.tar.gz"
}

# Redis 组件
download_redis() {
    log_info "=== 下载 Redis 组件 ==="
    REDIS_VERSION="7.2.5"

    download_file \
        "https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz" \
        "redis-${REDIS_VERSION}.tar.gz"
}

# ClickHouse 组件
download_clickhouse() {
    log_info "=== 下载 ClickHouse 组件 ==="
    CH_VERSION="24.3.1.2652"

    download_file \
        "https://packages.clickhouse.com/tgz/stable/clickhouse-common-static-${CH_VERSION}.amd64.tgz" \
        "clickhouse-common-static-${CH_VERSION}.amd64.tgz"

    download_file \
        "https://packages.clickhouse.com/tgz/stable/clickhouse-server-${CH_VERSION}.amd64.tgz" \
        "clickhouse-server-${CH_VERSION}.amd64.tgz"

    download_file \
        "https://packages.clickhouse.com/tgz/stable/clickhouse-client-${CH_VERSION}.amd64.tgz" \
        "clickhouse-client-${CH_VERSION}.amd64.tgz"
}

# Harbor 组件
download_harbor() {
    log_info "=== 下载 Harbor 组件 ==="
    HARBOR_VERSION="2.11.0"

    download_file \
        "https://github.com/goharbor/harbor/releases/download/v${HARBOR_VERSION}/harbor-online-installer-v${HARBOR_VERSION}.tgz" \
        "harbor-online-installer-v${HARBOR_VERSION}.tgz"
}

# Jenkins 组件
download_jenkins() {
    log_info "=== 下载 Jenkins 组件 ==="
    JENKINS_VERSION="2.452.1"

    download_file \
        "https://get.jenkins.io/war-stable/${JENKINS_VERSION}/jenkins.war" \
        "jenkins-${JENKINS_VERSION}.war"
}

# GitLab 组件
download_gitlab() {
    log_info "=== 下载 GitLab 组件 ==="
    GITLAB_VERSION="16.11.0"

    # Ubuntu 版本
    download_file \
        "https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/jammy/gitlab-ce_${GITLAB_VERSION}-ce.0_amd64.deb" \
        "gitlab-ce_${GITLAB_VERSION}-ce.0_amd64.deb"

    # Rocky/CentOS 版本
    download_file \
        "https://packages.gitlab.com/gitlab/gitlab-ce/packages/el/9/gitlab-ce-${GITLAB_VERSION}-ce.0.el9.x86_64.rpm" \
        "gitlab-ce-${GITLAB_VERSION}-ce.0.el9.x86_64.rpm"
}

# Consul 组件
download_consul() {
    log_info "=== 下载 Consul 组件 ==="
    CONSUL_VERSION="1.18.1"

    download_file \
        "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip" \
        "consul_${CONSUL_VERSION}_linux_amd64.zip"
}

# VictoriaMetrics 组件
download_victoriametrics() {
    log_info "=== 下载 VictoriaMetrics 组件 ==="
    VM_VERSION="1.103.0"

    # VictoriaMetrics 主程序
    download_file \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/victoria-metrics-linux-amd64-v${VM_VERSION}.tar.gz" \
        "victoria-metrics-linux-amd64-v${VM_VERSION}.tar.gz"

    # VictoriaMetrics 工具集（vmagent, vmalert, vmauth 等）
    download_file \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/vmutils-linux-amd64-v${VM_VERSION}.tar.gz" \
        "vmutils-linux-amd64-v${VM_VERSION}.tar.gz"

    # VictoriaMetrics 备份工具
    download_file \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/vmbackup-linux-amd64-v${VM_VERSION}.tar.gz" \
        "vmbackup-linux-amd64-v${VM_VERSION}.tar.gz"

    # VictoriaMetrics 恢复工具
    download_file \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/vmrestore-linux-amd64-v${VM_VERSION}.tar.gz" \
        "vmrestore-linux-amd64-v${VM_VERSION}.tar.gz"

    # VictoriaMetrics 数据迁移工具
    download_file \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/vmctl-linux-amd64-v${VM_VERSION}.tar.gz" \
        "vmctl-linux-amd64-v${VM_VERSION}.tar.gz"

    # VictoriaMetrics Pro 版本（可选）
    download_file \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/victoria-metrics-pro-linux-amd64-v${VM_VERSION}.tar.gz" \
        "victoria-metrics-pro-linux-amd64-v${VM_VERSION}.tar.gz"

    # VictoriaMetrics Cluster 版本（可选）
    download_file \
        "https://github.com/VictoriaMetrics/VictoriaMetrics/releases/download/v${VM_VERSION}/victoria-metrics-cluster-linux-amd64-v${VM_VERSION}.tar.gz" \
        "victoria-metrics-cluster-linux-amd64-v${VM_VERSION}.tar.gz"
}

# ArgoCD 组件
download_argocd() {
    log_info "=== 下载 ArgoCD 组件 ==="
    ARGOCD_VERSION="2.10.0"

    download_file \
        "https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64" \
        "argocd-linux-amd64"
}

# Helm 组件
download_helm() {
    log_info "=== 下载 Helm 组件 ==="
    HELM_VERSION="3.15.0"

    download_file \
        "https://get.helm.sh/helm-v${HELM_VERSION}-linux-amd64.tar.gz" \
        "helm-v${HELM_VERSION}-linux-amd64.tar.gz"
}

# SonarQube 组件
download_sonarqube() {
    log_info "=== 下载 SonarQube 组件 ==="
    SONARQUBE_VERSION="10.5.1.90531"

    download_file \
        "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${SONARQUBE_VERSION}.zip" \
        "sonarqube-${SONARQUBE_VERSION}.zip"
}

# Orchestrator 组件
download_orchestrator() {
    log_info "=== 下载 Orchestrator 组件 ==="
    ORCHESTRATOR_VERSION="3.2.6"

    # Rocky/CentOS 版本
    download_file \
        "https://github.com/openark/orchestrator/releases/download/v${ORCHESTRATOR_VERSION}/orchestrator-${ORCHESTRATOR_VERSION}-1.x86_64.rpm" \
        "orchestrator-${ORCHESTRATOR_VERSION}-1.x86_64.rpm"

    # Ubuntu 版本
    download_file \
        "https://github.com/openark/orchestrator/releases/download/v${ORCHESTRATOR_VERSION}/orchestrator-client_${ORCHESTRATOR_VERSION}_amd64.deb" \
        "orchestrator-client_${ORCHESTRATOR_VERSION}_amd64.deb"
}

# ELK 组件
download_elk() {
    log_info "=== 下载 ELK 组件 ==="
    ELASTIC_VERSION="8.13.0"

    download_file \
        "https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-${ELASTIC_VERSION}-linux-x86_64.tar.gz" \
        "elasticsearch-${ELASTIC_VERSION}-linux-x86_64.tar.gz"

    download_file \
        "https://artifacts.elastic.co/downloads/logstash/logstash-${ELASTIC_VERSION}-linux-x86_64.tar.gz" \
        "logstash-${ELASTIC_VERSION}-linux-x86_64.tar.gz"

    download_file \
        "https://artifacts.elastic.co/downloads/kibana/kibana-${ELASTIC_VERSION}-linux-x86_64.tar.gz" \
        "kibana-${ELASTIC_VERSION}-linux-x86_64.tar.gz"
}

# Nginx 组件
download_nginx() {
    log_info "=== 下载 Nginx 组件 ==="
    NGINX_VERSION="1.26.0"

    download_file \
        "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
        "nginx-${NGINX_VERSION}.tar.gz"
}

# Keepalived 组件
download_keepalived() {
    log_info "=== 下载 Keepalived 组件 ==="
    KEEPALIVED_VERSION="2.2.8"

    download_file \
        "https://www.keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz" \
        "keepalived-${KEEPALIVED_VERSION}.tar.gz"
}

# 主函数
main() {
    local target_project="${1:-all}"

    log_info "开始下载组件到 $DOWNLOAD_DIR"
    log_info "目标项目: $target_project"

    case "$target_project" in
        all)
            download_kafka
            download_mongodb
            download_mysql
            download_postgresql
            download_rabbitmq
            download_redis
            download_clickhouse
            download_harbor
            download_jenkins
            download_gitlab
            download_consul
            download_victoriametrics
            download_argocd
            download_helm
            download_sonarqube
            download_orchestrator
            download_elk
            download_nginx
            download_keepalived
            ;;
        kafka-cluster|kafka)
            download_kafka
            ;;
        mongodb-replica|mongodb)
            download_mongodb
            ;;
        mysql-mgr|mysql-replication|mysql)
            download_mysql
            download_orchestrator
            ;;
        postgresql-cluster|postgresql)
            download_postgresql
            ;;
        RabbitMQ|rabbitmq)
            download_rabbitmq
            ;;
        redis-cluster|redis)
            download_redis
            ;;
        clickhouse-cluster|clickhouse)
            download_clickhouse
            ;;
        harbor)
            download_harbor
            ;;
        jenkins-gitlab|jenkins)
            download_jenkins
            download_gitlab
            ;;
        consul-cluster|consul)
            download_consul
            ;;
        VictoriaMetrics|victoriametrics)
            download_victoriametrics
            ;;
        gitlab-argocd|argocd)
            download_gitlab
            download_argocd
            ;;
        helm)
            download_helm
            ;;
        sonarqube)
            download_sonarqube
            ;;
        ELK|elk)
            download_elk
            ;;
        Keepalived-Nginx|keepalived|nginx)
            download_nginx
            download_keepalived
            ;;
        *)
            log_error "未知的项目: $target_project"
            log_info "可用项目: all, kafka-cluster, mongodb-replica, mysql-mgr, mysql-replication, postgresql-cluster, RabbitMQ, redis-cluster, clickhouse-cluster, harbor, jenkins-gitlab, consul-cluster, VictoriaMetrics, gitlab-argocd, helm, sonarqube, ELK, Keepalived-Nginx"
            exit 1
            ;;
    esac

    log_info "=== 下载完成 ==="
    log_info "所有组件已保存到: $DOWNLOAD_DIR"
    log_info ""

    # 显示下载的文件列表
    echo "已下载的文件:"
    ls -lh "$DOWNLOAD_DIR/" 2>/dev/null || echo "目录为空"

    # 计算总大小
    local total_size=$(du -sh "$DOWNLOAD_DIR" 2>/dev/null | cut -f1)
    log_info "总大小: $total_size"
}

# 执行主函数
main "$@"