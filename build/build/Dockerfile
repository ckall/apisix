FROM openresty/openresty:1.21.4.1-0-jammy
WORKDIR /build
COPY ./ /build/
ENV APT_MIRROR_URL https://mirrors.aliyun.com/ubuntu/
ENV GO111MODULE=on
ENV GOPROXY=https://goproxy.cn,direct
# 安装软件前，更新软件包列表
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y \
    build-essential \
    git \
    curl \
    nano \
    vim \
    sudo \
    software-properties-common \
    wget \
    lsb-release \
    gnupg \
    patch \
    curl  \
    make  \
    gcc \
    g++ \
    cpanminus \
    libpcre3 \
    libpcre3-dev \
    libldap2-dev \
    unzip

# 清理apt缓存以减小镜像体积
RUN apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    make install-runtime\


