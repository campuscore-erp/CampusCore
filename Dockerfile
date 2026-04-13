FROM python:3.11-slim

# System libs needed by OpenCV and dlib-bin
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libjpeg62-turbo \
    libpng16-16 \
    libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel

# dlib-bin 20.x only has a Python 3.12 wheel.
# 19.24.6 has a Python 3.11 wheel — pin it explicitly.
RUN pip install "dlib-bin==19.24.6"

RUN pip install "face_recognition>=1.3.0"

RUN pip install "opencv-python-headless>=4.8.0"

WORKDIR /app
COPY root/requirements.txt .
RUN pip install -r requirements.txt

COPY root/ .

CMD ["gunicorn", "app:app", "--bind", "0.0.0.0:8080", "--workers", "1", "--timeout", "120"]
