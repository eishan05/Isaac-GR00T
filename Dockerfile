FROM nvidia/cuda:12.4.1-cudnn-devel-ubuntu22.04 AS flash-attn-builder

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 python3-pip python3-dev python3-venv \
      build-essential cmake ninja-build git git-lfs curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

ENV PIP_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu124

RUN ln -sf /usr/bin/python3 /usr/bin/python && \
    python3 -m pip install --upgrade pip setuptools wheel packaging ninja && \
    python3 -m pip install torch==2.5.1 && \
    python3 -m pip wheel --wheel-dir /tmp/wheels --no-deps flash-attn==2.7.1.post4 && \
    rm -rf /root/.cache/pip


FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 python3-pip python3-venv python3-dev \
      build-essential ca-certificates curl git git-lfs ffmpeg \
      libglib2.0-0 libsm6 libxext6 libxrender1 libgl1 && \
    ln -sf /usr/bin/python3 /usr/local/bin/python

WORKDIR /workspace/Isaac-GR00T

COPY --from=flash-attn-builder /tmp/wheels /opt/wheels

COPY . .

ENV PIP_EXTRA_INDEX_URL=https://download.pytorch.org/whl/cu124

RUN python3 -m pip install --upgrade pip setuptools wheel && \
    python3 -m pip install torch==2.5.1 torchvision==0.20.1 && \
    python3 -m pip install -e .[base] && \
    python3 -m pip install --no-index --find-links=/opt/wheels flash-attn==2.7.1.post4 && \
    python3 -m pip install -e ./roboactions && \
    rm -rf /opt/wheels && \
    python3 -m pip cache purge || true && \
    apt-get purge -y build-essential python3-dev && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

EXPOSE 8000

ENV MODEL_PATH="nvidia/GR00T-N1.5-3B" \
    EMBODIMENT_TAG="gr1" \
    DATA_CONFIG="fourier_gr1_arms_waist" \
    DENOISING_STEPS="4" \
    HOST="0.0.0.0" \
    PORT="8000" \
    LOG_LEVEL="INFO"

CMD ["bash", "-lc", "python scripts/serve_gr00t_websocket.py --model_path \"$MODEL_PATH\" --embodiment_tag \"$EMBODIMENT_TAG\" --data_config \"$DATA_CONFIG\" --denoising_steps \"$DENOISING_STEPS\" --host \"$HOST\" --port \"$PORT\" --log_level \"$LOG_LEVEL\""]
