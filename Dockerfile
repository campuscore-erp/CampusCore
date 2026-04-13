FROM python:3.11-slim

# ── System libs required by OpenCV and dlib-bin ───────────────────────────────
RUN apt-get update && apt-get install -y --no-install-recommends \
    libgl1 \
    libglib2.0-0 \
    libjpeg62-turbo \
    libpng16-16 \
    libgomp1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip setuptools wheel

# ── Step 1: Install dlib-bin (pre-built binary wheel — zero C++ compile) ──────
RUN pip install "dlib-bin==19.24.6"

# ── Step 2: Install face_recognition's other deps manually ────────────────────
RUN pip install "face-recognition-models>=0.3.0" "Click>=6.0" "Pillow>=9.0" "numpy"

# ── Step 3: Install face_recognition WITHOUT deps so pip never replaces ────────
#    dlib-bin with a source-compiled dlib from PyPI
RUN pip install "face_recognition==1.3.0" --no-deps

# ── Step 4: Verify both are importable at BUILD time (fail fast, not runtime) ──
RUN python -c "import dlib; print('dlib OK:', dlib.__version__)"
RUN python -c "import face_recognition; print('face_recognition OK')"

RUN pip install "opencv-python-headless>=4.8.0"

WORKDIR /app

# ── Step 5: Install app deps — strip dlib/face_recognition lines if present ───
COPY root/requirements.txt .
RUN grep -vE "dlib|face.recognition|face_recognition" requirements.txt > /tmp/reqs_clean.txt \
    && pip install -r /tmp/reqs_clean.txt

COPY root/ .

# ── Step 6: Final runtime sanity check ────────────────────────────────────────
RUN python -c "import dlib, face_recognition, cv2; print('ALL ML DEPS OK')"

CMD gunicorn app:app --bind 0.0.0.0:${PORT:-8080} --workers 1 --timeout 120