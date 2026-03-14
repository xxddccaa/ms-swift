FROM modelscope-registry.us-west-1.cr.aliyuncs.com/modelscope-repo/modelscope:ubuntu22.04-cuda12.8.1-py311-torch2.10.0-vllm0.17.0-modelscope1.34.0-swift4.0.1

# -----------------------------
# 环境变量配置
# -----------------------------
ENV DEBIAN_FRONTEND=noninteractive
ENV PIP_ROOT_USER_ACTION=ignore
ENV MAX_JOBS=16
ENV VLLM_WORKER_MULTIPROC_METHOD=spawn
ENV TZ=Asia/Shanghai
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 定义镜像源（可配置）
ARG APT_SOURCE=https://mirrors.tuna.tsinghua.edu.cn/ubuntu/
ARG PIP_INDEX=https://mirrors.aliyun.com/pypi/simple/
ARG PIP_TRUSTED_HOST=mirrors.aliyun.com

# -----------------------------
# 安装系统依赖
# -----------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    locales \
    fonts-noto-cjk \
    language-pack-zh-hans \
    zip \
    unzip \
    tree \
    vim \
    tzdata \
    apt-utils \
    htop \
    tmux \
    curl \
    wget \
    git \
    file \
    net-tools \
    libibverbs1 \
    libibverbs-dev \
    build-essential \
    ca-certificates \
    openssh-server openssh-client gh

RUN pip install --no-cache-dir decord msgspec opencv-python megfile math_verify wandb s3fs -i $PIP_INDEX --trusted-host $PIP_TRUSTED_HOST

ENV MODELSCOPE_CACHE=/mnt/data/cache

RUN apt-get update && \
    apt-get install -y --allow-downgrades --allow-change-held-packages --no-install-recommends libnl-3-dev libnl-route-3-dev libnl-3-200 libnl-route-3-200 iproute2 udev dmidecode ethtool

RUN cd /tmp/ && \
    wget http://pythonrun.oss-cn-zhangjiakou.aliyuncs.com/rdma/nic-libs-mellanox-rdma-5.2-2/nic-lib-rdma-core-installer-ubuntu.tar.gz && \
    tar xzvf nic-lib-rdma-core-installer-ubuntu.tar.gz && \
    cd nic-lib-rdma-core-installer-ubuntu && \
    echo Y | /bin/bash install.sh && \
    cd .. && \
    rm -rf nic-lib-rdma-core-installer-ubuntu && \
    rm -f nic-lib-rdma-core-installer-ubuntu.tar.gz

# NVIDIA-SMI 路径
ENV PATH="/usr/local/nvidia/bin:${PATH}"

# CUDA driver 库路径（包含 libcuda.so.1 和 libnvidia-ml.so）
ENV LD_LIBRARY_PATH="/usr/local/nvidia/lib64:${LD_LIBRARY_PATH}"

# CUDA 安装目录
ENV CUDA_HOME="/usr/local/cuda"
ENV PATH="${CUDA_HOME}/bin:${PATH}"
ENV LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"

# vLLM 相关环境变量（可选）
ENV VLLM_USE_CPU=0
ENV VLLM_WORKER_MULTIPROC_METHOD=spawn
ENV CUDA_DEVICE_ORDER=PCI_BUS_ID

# 安装 Node.js 和 npm
RUN apt-get update && apt-get install -y --no-install-recommends nodejs npm

# 安装 opencode-ai
RUN npm install -g opencode-ai@latest

WORKDIR /app

COPY . /app
RUN pip install --no-cache-dir -e . --no-deps

# Expose port 7860 for LLaMA Board
ENV GRADIO_SERVER_PORT=7860
EXPOSE 7860

# Expose port 8000 for API service
ENV API_PORT=8000
EXPOSE 8000

# unset proxy
ENV http_proxy=
ENV https_proxy=


CMD ["/bin/bash"]
# docker build -t kevinchina/deeplearning:swift-v4.0.1-dev-0314 -f Dockerfile .