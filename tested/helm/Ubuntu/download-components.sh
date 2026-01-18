#!/bin/bash
# Helm 组件下载脚本

set -e

DOWNLOAD_DIR="/opt/ansible/helm/downloads"
mkdir -p "$DOWNLOAD_DIR"

echo "开始下载 Helm 组件..."

# 下载 Helm
HELM_VERSION="v3.15.0"
HELM_URL="https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz"
echo "下载 Helm ${HELM_VERSION}..."
wget -c -t 3 -T 1800 "$HELM_URL" -O "$DOWNLOAD_DIR/helm-${HELM_VERSION}-linux-amd64.tar.gz"

# 下载 kubectl
KUBECTL_VERSION="v1.29.0"
KUBECTL_URL="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
echo "下载 kubectl ${KUBECTL_VERSION}..."
wget -c -t 3 -T 1800 "$KUBECTL_URL" -O "$DOWNLOAD_DIR/kubectl"

echo "下载完成！所有组件已保存到 $DOWNLOAD_DIR"
ls -lh "$DOWNLOAD_DIR"