FROM aidockorg/python-cuda:3.10-v2-cuda-12.4.1-cudnn-devel-22.04
ENV DEBIAN_FRONTEND=noninteractive
# ENV PYTHONPATH="/app:${PYTHONPATH:-}"

# System dependencies
RUN apt update && \
    apt install -y tzdata && \
    ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
    apt install -y netcat dnsutils && \
    apt-get update && \
    apt-get install -y libgl1-mesa-glx git libvulkan-dev \
    zip unzip wget curl git git-lfs build-essential cmake \
    vim less sudo htop ca-certificates man tmux ffmpeg tensorrt \
    # Add OpenCV system dependencies
    libglib2.0-0 libsm6 libxext6 libxrender-dev

RUN pip install --upgrade pip setuptools

# Create and set working directory
WORKDIR /workspace
COPY gr00t /workspace/gr00t
COPY scripts /workspace/scripts
# Copy pyproject.toml for dependencies
COPY pyproject.toml .
# Install dependencies from pyproject.toml
RUN pip install -e .[base]