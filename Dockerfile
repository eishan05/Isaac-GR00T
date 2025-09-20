FROM pytorch/pytorch:2.6.0-cuda12.4-cudnn9-devel
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
RUN pip install gpustat wandb==0.19.0
# Create and set working directory
WORKDIR /workspace
# Copy pyproject.toml for dependencies
COPY pyproject.toml .
# Install dependencies from pyproject.toml
RUN pip install -e .[base]
# There's a conflict in the native python, so we have to resolve it by
RUN pip uninstall -y transformer-engine
RUN pip install flash_attn==2.7.1.post4 -U --force-reinstall
# Clean any existing OpenCV installations
RUN pip uninstall -y opencv-python opencv-python-headless || true
RUN rm -rf /usr/local/lib/python3.10/dist-packages/cv2 || true
RUN pip install opencv-python==4.8.0.74
RUN pip install --force-reinstall torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 numpy==1.26.4
COPY getting_started /workspace/getting_started
COPY scripts /workspace/scripts
COPY demo_data /workspace/demo_data
RUN pip install -e . --no-deps
# need to install accelerate explicitly to avoid version conflicts
RUN pip install accelerate>=0.26.0
COPY gr00t /workspace/gr00t
COPY Makefile /workspace/Makefile
RUN pip3 install -e .