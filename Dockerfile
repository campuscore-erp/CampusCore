FROM python:3.11-slim

# System libs needed by OpenCV and dlib-bin
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libjpeg62-turbo \
    libpng16-16 \
    libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade pip
RUN pip install --upgrade pip setuptools wheel

# Install dlib-bin first (pre-built wheel, no cmake needed)
RUN pip install dlib-bin

# Install face_recognition (depends on dlib)
RUN pip install face_recognition>=1.3.0

# Install OpenCV headless
RUN pip install opencv-python-headless>=4.8.0

WORKDIR /app
COPY root/requirements.txt .
RUN pip install -r requirements.txt

COPY root/ .

CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 120
