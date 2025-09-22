FROM runpod/pytorch:2.4.0-py3.11-cuda12.4.1-devel-ubuntu22.04

# Avoid interactive tzdata prompts during build
ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

# System dependencies (kept minimal). Build tools for flash-attn, and common runtime libs.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates curl git git-lfs \
      build-essential cmake ninja-build \
      ffmpeg libglib2.0-0 libsm6 libxext6 libxrender1 libgl1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace/Isaac-GR00T

# Install Miniforge (conda) to /opt/conda
ENV CONDA_DIR=/opt/conda
ENV PATH=${CONDA_DIR}/bin:${PATH}
SHELL ["/bin/bash", "-lc"]
RUN set -euxo pipefail && \
    curl -fsSL https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh -o /tmp/miniforge.sh && \
    bash /tmp/miniforge.sh -b -p ${CONDA_DIR} && \
    rm -f /tmp/miniforge.sh && \
    conda config --system --set auto_update_conda false && \
    conda clean -afy

# Create Python 3.10 environment named `gr00t`
RUN conda create -y -n gr00t python=3.10 && conda clean -afy

# Copy repo contents (assumes submodules like `roboactions` are present in the build context)
COPY . .

# Python dependencies inside the conda env (mirror the manual steps)
RUN conda run -n gr00t python -m pip install --upgrade pip setuptools && \
    conda run -n gr00t python -m pip install -e .[base] && \
    conda run -n gr00t python -m pip install --no-build-isolation flash-attn==2.7.1.post4 && \
    conda run -n gr00t python -m pip install -e ./roboactions && \
    conda run -n gr00t python -m pip cache purge || true

# Expose the websocket port and default command to launch the server
EXPOSE 8000

CMD [ \
  "conda", "run", "--no-capture-output", "-n", "gr00t", \
  "python", "scripts/serve_gr00t_websocket.py", "--port", "8000" \
]
