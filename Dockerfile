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

# Install dlib-bin FIRST (pre-built wheel, no C++ compile needed).
# Then install face_recognition with --no-deps so pip does NOT
# pull/compile a newer dlib from source to satisfy its dlib>=19.7 dep.
RUN pip install "dlib-bin==19.24.6"
RUN pip install "face_recognition==1.3.0" --no-deps
RUN pip install "face-recognition-models>=0.3.0" "Click>=6.0" "Pillow" "numpy"

RUN pip install "opencv-python-headless>=4.8.0"

WORKDIR /app
COPY root/requirements.txt .
RUN pip install -r requirements.txt

COPY root/ .

CMD gunicorn app:app --bind 0.0.0.0:${PORT:-8080} --workers 1 --timeout 120