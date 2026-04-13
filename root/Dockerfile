FROM python:3.11-slim

# System libraries needed by OpenCV and dlib-bin
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libjpeg62-turbo \
    libpng16-16 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip/wheel tools
RUN pip install --upgrade pip setuptools wheel

# FIX: Use dlib-bin (pre-built wheel) — no cmake / C++ compiler needed.
# The old Dockerfile used "pip install dlib>=19.24.0" which compiles
# dlib from source (~5 min), often times out, and fails in slim images
# that lack cmake/boost/lapack.
RUN pip install dlib-bin

# Install face_recognition after dlib is already present
RUN pip install face_recognition>=1.3.0

# Install OpenCV headless
RUN pip install opencv-python-headless>=4.8.0

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .

CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 120
