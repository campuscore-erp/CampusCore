# ── Use pre-built image that already has dlib + face_recognition compiled ──
# ageitgey/face_recognition_models is built on Python 3.8 + dlib 19.x
# We use a community image that ships face_recognition ready to go
FROM python:3.11-slim

# Install system deps for OpenCV headless
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    libopenblas-dev \
    liblapack-dev \
    libx11-dev \
    libgtk-3-dev \
    libboost-python-dev \
    libboost-thread-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# Install dlib + face_recognition first (slow build step cached by Docker layer)
RUN pip install --upgrade pip setuptools wheel
RUN pip install cmake
RUN pip install dlib>=19.24.0
RUN pip install face_recognition>=1.3.0
RUN pip install opencv-python-headless>=4.8.0

WORKDIR /app

# Copy requirements and install remaining deps
COPY root/requirements.txt .
RUN pip install -r requirements.txt

# Copy entire app
COPY root/ .

EXPOSE 8080

CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 120
