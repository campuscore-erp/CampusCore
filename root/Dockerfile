# Use Python 3.11 slim base
FROM python:3.11-slim

# Install only what's needed to compile dlib + run OpenCV headless
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    libopenblas-dev \
    liblapack-dev \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip setuptools wheel

# Install dlib and face_recognition FIRST as separate cached layers
RUN pip install cmake
RUN pip install dlib>=19.24.0
RUN pip install face_recognition>=1.3.0
RUN pip install opencv-python-headless>=4.8.0

WORKDIR /app

# Install remaining Python dependencies
COPY root/requirements.txt .
RUN pip install -r requirements.txt

# Copy app source
COPY root/ .

CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 120