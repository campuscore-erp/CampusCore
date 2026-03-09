FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    libopenblas-dev \
    liblapack-dev \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel
RUN pip install cmake
RUN pip install dlib>=19.24.0
RUN pip install face_recognition>=1.3.0
RUN pip install opencv-python-headless>=4.8.0

WORKDIR /app

COPY root/requirements.txt .
RUN pip install -r requirements.txt

COPY root/ .

CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 120