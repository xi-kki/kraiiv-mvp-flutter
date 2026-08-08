# Kraiiv Food Recognition API — Hugging Face Spaces build.
#
# Size discipline:
#   - CPU-only PyTorch wheels (~1.6 GB image vs ~5 GB with CUDA layers).
#   - The food model (~80 MB) is downloaded at runtime from Hugging Face
#     (pinned revision + sha256 in main.py) — never committed here.
#   - --no-cache-dir everywhere; base image is python:3.11-slim.
FROM python:3.11-slim

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HOME=/home/user/.cache/huggingface

# opencv-python (non-headless wheel) needs libGL + libglib at import time.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
# torch/torchvision from the CPU wheel index (version-matched pair),
# then the remaining deps from PyPI. requirements.txt's loose constraints
# (torch>=2.0) are satisfied by what we already installed.
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
    torch \
    torchvision \
    && pip install --no-cache-dir -r requirements.txt

COPY . .

# Non-root user avoids HF cache/permission quirks inside the Space.
RUN useradd -m -u 1000 user && chown -R user:user /app /home/user
USER 1000

EXPOSE 7860
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "7860"]
