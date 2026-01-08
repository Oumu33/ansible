#!/bin/bash
# ELK 简化测试脚本 - 单节点模式以节省内存

set -e

echo "=== ELK 简化测试 ==="
echo "注意: 此测试使用单节点模式，仅用于验证基本功能"
echo "生产环境请使用完整集群配置"

cd /opt/ansible/ELK/Rocky

# 停止不需要的容器
echo "停止不需要的容器..."
docker stop elasticsearch-2 elasticsearch-3 2>/dev/null || true

# 部署 Elasticsearch (单节点)
echo "部署 Elasticsearch (单节点)..."
echo "复制 Elasticsearch 到容器..."
docker cp /opt/ansible/downloads/elasticsearch-9.0.2-linux-x86_64.tar.gz elasticsearch-1:/tmp/elasticsearch.tar.gz
docker exec elasticsearch-1 bash -c "
  # 创建用户和目录
  useradd -r -s /bin/false elasticsearch 2>/dev/null || true
  mkdir -p /usr/share/elasticsearch /etc/elasticsearch /var/log/elasticsearch /usr/share/elasticsearch/data
  chown -R elasticsearch:elasticsearch /usr/share/elasticsearch /etc/elasticsearch /var/log/elasticsearch

  # 复制并解压
  if [ ! -f /usr/share/elasticsearch/bin/elasticsearch ]; then
    tar -xzf /tmp/elasticsearch.tar.gz -C /usr/share/elasticsearch --strip-components=1
    chown -R elasticsearch:elasticsearch /usr/share/elasticsearch
  fi

  # 配置
  cat > /usr/share/elasticsearch/config/elasticsearch.yml << 'EOF'
cluster.name: elk-cluster
node.name: elasticsearch-1
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
path.data: /usr/share/elasticsearch/data
path.logs: /var/log/elasticsearch
xpack.security.enabled: false
EOF

  # JVM 配置 (512MB 以节省内存)
  cat > /usr/share/elasticsearch/config/jvm.options.d/heap.options << 'EOF'
-Xms512m
-Xmx512m
EOF

  # 启动
  rm -rf /usr/share/elasticsearch/data/*
  cd /usr/share/elasticsearch
  su - elasticsearch -s /bin/bash -c 'nohup ./bin/elasticsearch > /tmp/es-startup.log 2>&1 &'
"

echo "等待 Elasticsearch 启动..."
sleep 40

# 检查 Elasticsearch 状态
echo "检查 Elasticsearch 状态..."
docker exec elasticsearch-1 bash -c "curl -s http://localhost:9200 | head -20"
echo ""

# 部署 Logstash
echo "部署 Logstash..."
echo "复制 Logstash 到容器..."
docker cp /opt/ansible/downloads/logstash-9.0.2-linux-x86_64.tar.gz logstash-1:/tmp/logstash.tar.gz
docker exec logstash-1 bash -c "
  # 创建用户和目录
  useradd -r -s /bin/false logstash 2>/dev/null || true
  mkdir -p /usr/share/logstash /etc/logstash /var/log/logstash /usr/share/logstash/data /etc/logstash/conf.d
  chown -R logstash:logstash /usr/share/logstash /etc/logstash /var/log/logstash

  # 复制并解压
  if [ ! -f /usr/share/logstash/bin/logstash ]; then
    tar -xzf /tmp/logstash.tar.gz -C /usr/share/logstash --strip-components=1
    chown -R logstash:logstash /usr/share/logstash
  fi

  # 配置
  cat > /etc/logstash/logstash.yml << 'EOF'
http.host: 0.0.0.0
http.port: 9600
path.data: /usr/share/logstash/data
path.logs: /var/log/logstash
EOF

  cat > /etc/logstash/conf.d/pipeline.conf << 'EOF'
input {
  http {
    port => 8080
    codec => json
  }
}

output {
  elasticsearch {
    hosts => [\"http://172.21.0.10:9200\"]
    index => \"logstash-%{+YYYY.MM.dd}\"
  }
}
EOF

  cat > /usr/share/logstash/config/pipelines.yml << 'EOF'
- pipeline.id: main
  path.config: \"/etc/logstash/conf.d/pipeline.conf\"
EOF

  # JVM 配置 (512MB 以节省内存)
  cat > /usr/share/logstash/config/jvm.options.d/heap.options << 'EOF'
-Xms512m
-Xmx512m
EOF

  # 启动
  rm -rf /usr/share/logstash/data/*
  cd /usr/share/logstash
  su - logstash -s /bin/bash -c 'nohup ./bin/logstash > /var/log/logstash/logstash.log 2>&1 &'
"

echo "等待 Logstash 启动..."
sleep 30

# 检查 Logstash 状态
echo "检查 Logstash 状态..."
docker exec logstash-1 bash -c "curl -s http://localhost:9600 | head -20"
echo ""

# 部署 Kibana
echo "部署 Kibana..."
echo "复制 Kibana 到容器..."
docker cp /opt/ansible/downloads/kibana-9.0.2-linux-x86_64.tar.gz kibana-1:/tmp/kibana.tar.gz
docker exec kibana-1 bash -c "
  # 创建用户和目录
  useradd -r -s /bin/false kibana 2>/dev/null || true
  mkdir -p /usr/share/kibana /etc/kibana /var/log/kibana /usr/share/kibana/data
  chown -R kibana:kibana /usr/share/kibana /etc/kibana /var/log/kibana

  # 复制并解压
  if [ ! -f /usr/share/kibana/bin/kibana ]; then
    tar -xzf /tmp/kibana.tar.gz -C /usr/share/kibana --strip-components=1
    chown -R kibana:kibana /usr/share/kibana
  fi

  # 配置
  cat > /usr/share/kibana/config/kibana.yml << 'EOF'
server.host: 0.0.0.0
server.port: 5601
elasticsearch.hosts: [\"http://172.21.0.10:9200\"]
EOF

  # 启动
  cd /usr/share/kibana
  su - kibana -s /bin/bash -c 'nohup ./bin/kibana > /var/log/kibana/kibana.log 2>&1 &'
"

echo "等待 Kibana 启动..."
sleep 40

# 检查 Kibana 状态
echo "检查 Kibana 状态..."
docker exec kibana-1 bash -c "curl -s http://localhost:5601/api/status | head -50"
echo ""

# 部署 Filebeat
echo "部署 Filebeat..."
echo "复制 Filebeat 到容器..."
docker cp /opt/ansible/downloads/filebeat-9.0.2-linux-x86_64.tar.gz filebeat-1:/tmp/filebeat.tar.gz
docker exec filebeat-1 bash -c "
  # 创建用户和目录
  useradd -r -s /bin/false filebeat 2>/dev/null || true
  mkdir -p /usr/share/filebeat /etc/filebeat /var/log/filebeat /var/lib/filebeat
  chown -R filebeat:filebeat /usr/share/filebeat /etc/filebeat /var/log/filebeat /var/lib/filebeat

  # 复制并解压
  if [ ! -f /usr/share/filebeat/filebeat ]; then
    tar -xzf /tmp/filebeat.tar.gz -C /usr/share/filebeat --strip-components=1
    chown -R filebeat:filebeat /usr/share/filebeat
  fi

  # 配置
  cat > /etc/filebeat/filebeat.yml << 'EOF'
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log

output.elasticsearch:
  hosts: [\"http://172.21.0.10:9200\"]
  index: \"filebeat-%{[agent.version]}-%{+yyyy.MM.dd}\"

setup.ilm.enabled: false
setup.template.enabled: false
EOF

  # 启动
  cd /usr/share/filebeat
  su - filebeat -s /bin/bash -c './filebeat -e -c /etc/filebeat/filebeat.yml > /var/log/filebeat/filebeat.log 2>&1 &'
"

echo "等待 Filebeat 启动..."
sleep 20

# 检查 Filebeat 状态
echo "检查 Filebeat 状态..."
docker exec filebeat-1 bash -c "tail -30 /var/log/filebeat/filebeat.log | grep -E '(started|connected|ERROR)' || echo 'Filebeat running'"
echo ""

echo "=== ELK 测试完成 ==="
echo "测试环境信息:"
echo "- Elasticsearch: http://172.21.0.10:9200"
echo "- Logstash: http://172.21.0.13:9600"
echo "- Kibana: http://172.21.0.14:5601"
echo "- Filebeat: 运行在 filebeat-1 容器"
echo ""
echo "注意: 此为单节点测试配置，生产环境请使用完整集群配置"