FROM aidockorg/python-cuda:3.10-v2-cuda-12.4.1-cudnn-devel-22.04
ENV DEBIAN_FRONTEND=noninteractive
# ENV PYTHONPATH="/app:${PYTHONPATH:-}"

# System dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      tzdata ca-certificates \
      netcat-openbsd dnsutils \
      libgl1-mesa-glx libvulkan-dev \
      zip unzip wget curl git git-lfs build-essential cmake \
      vim less sudo htop man tmux ffmpeg \
      libglib2.0-0 libsm6 libxext6 libxrender1 && \
    ln -fs /usr/share/zoneinfo/$TZ /etc/localtime && dpkg-reconfigure -f noninteractive tzdata && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools

# Create and set working directory
WORKDIR /workspace
# Copy pyproject.toml for dependencies
COPY pyproject.toml .
# Install dependencies from pyproject.toml
RUN pip install -e .[base]

COPY gr00t /workspace/gr00t
COPY Makefile /workspace/Makefile
RUN pip3 install -e .