#!/bin/bash
# Jenkins + GitLab 组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/jenkins-gitlab/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 Jenkins + GitLab 组件..."

# 下载 Jenkins
JENKINS_VERSION="2.452.3"
JENKINS_URL="https://get.jenkins.io/war/${JENKINS_VERSION}/jenkins.war"
echo "下载 Jenkins ${JENKINS_VERSION}..."
wget -c -t 3 -T 1800 "$JENKINS_URL" -O "$DOWNLOAD_DIR/jenkins.war"

# 下载 GitLab
GITLAB_VERSION="17.1.0"
GITLAB_URL="https://packages.gitlab.com/gitlab/gitlab-ce/packages/ubuntu/focal/gitlab-ce_${GITLAB_VERSION}-ce.0_amd64.deb/download.deb"
echo "下载 GitLab ${GITLAB_VERSION}..."
wget -c -t 3 -T 1800 "$GITLAB_URL" -O "$DOWNLOAD_DIR/gitlab-ce_${GITLAB_VERSION}-ce.0_amd64.deb"

# 下载 GitLab Runner
GITLAB_RUNNER_VERSION="17.1.0"
GITLAB_RUNNER_URL="https://gitlab-runner-downloads.s3.amazonaws.com/latest/binaries/gitlab-runner-linux-amd64"
echo "下载 GitLab Runner ${GITLAB_RUNNER_VERSION}..."
wget -c -t 3 -T 1800 "$GITLAB_RUNNER_URL" -O "$DOWNLOAD_DIR/gitlab-runner"

# 下载 PostgreSQL
POSTGRESQL_VERSION="16"
POSTGRESQL_URL="https://get.enterprisedb.com/postgresql/postgresql-${POSTGRESQL_VERSION}-1-linux-x64-binaries.tar.gz"
echo "下载 PostgreSQL ${POSTGRESQL_VERSION}..."
wget -c -t 3 -T 1800 "$POSTGRESQL_URL" -O "$DOWNLOAD_DIR/postgresql-${POSTGRESQL_VERSION}-linux-x64-binaries.tar.gz"

# 下载 Redis
REDIS_VERSION="7.2"
REDIS_URL="https://download.redis.io/releases/redis-${REDIS_VERSION}.tar.gz"
echo "下载 Redis ${REDIS_VERSION}..."
wget -c -t 3 -T 1800 "$REDIS_URL" -O "$DOWNLOAD_DIR/redis-${REDIS_VERSION}.tar.gz"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"