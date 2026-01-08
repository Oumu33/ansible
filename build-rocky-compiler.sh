#!/bin/bash
# 创建包含编译工具的Rocky Linux镜像

set -e

echo "=== 创建包含编译工具的Rocky Linux镜像 ==="

# 从基础镜像创建新镜像
docker build -t rockylinux-ansible-test-with-compiler:9 - << 'EOF'
FROM rockylinux-ansible-test:9

# 安装编译工具
RUN dnf install -y gcc gcc-c++ make autoconf ncurses-devel openssl-devel \
    && dnf clean all

# 设置工作目录
WORKDIR /root

# 设置环境变量
ENV PATH=/usr/local/bin:$PATH

CMD ["/bin/bash"]
EOF

echo "镜像创建完成"
echo "镜像名称: rockylinux-ansible-test-with-compiler:9"