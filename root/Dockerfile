FROM python:3.11-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libjpeg62-turbo \
    libpng16-16 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel
RUN pip install dlib-bin
RUN pip install face_recognition>=1.3.0
RUN pip install opencv-python-headless>=4.8.0

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

CMD gunicorn app:app --bind 0.0.0.0:$PORT --workers 1 --timeout 120