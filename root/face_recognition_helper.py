"""
face_recognition_helper.py  —  CampusCore University ERP
=========================================================
Face Recognition Attendance System Helper Module

WHAT THIS DOES:
  - Provides utilities to encode face images and compare against stored encodings
  - Uses OpenCV for image preprocessing and face_recognition for 128-d face encodings
  - All encodings are stored as BLOB (numpy array bytes) in MySQL student_face_data table
  - Designed to work in Railway deployment — no GUI, no display required
  - Works with images sent as base64 from browser webcam captures

DEPENDENCIES (add to requirements.txt):
  face_recognition>=1.3.0
  opencv-python-headless>=4.8.0   # headless = no display needed for Railway
  numpy>=1.24.0

NOTE:
  face_recognition uses dlib under the hood. On Railway (Linux), ensure the
  buildpack includes cmake and dlib build dependencies, or use a pre-built wheel.
  See nixpacks.toml section in README for configuration.
"""

import base64
import io
import pickle
import traceback
from typing import Optional, List, Tuple

import numpy as np

# ── Lazy imports — fail gracefully if libraries not installed ─────────────────

def _import_cv2():
    try:
        import cv2
        return cv2
    except ImportError:
        raise ImportError(
            "OpenCV is required: pip install opencv-python-headless"
        )

def _import_face_recognition():
    try:
        import face_recognition  # type: ignore[import]
        return face_recognition
    except ImportError:
        raise ImportError(
            "face_recognition is required: pip install face_recognition"
        )


# =============================================================================
# ENCODING UTILITIES
# =============================================================================

def encode_face_from_base64(image_b64: str) -> Optional[bytes]:
    """
    Given a base64-encoded image (from browser webcam), detect a face and
    return the 128-d face encoding serialised as bytes (pickle) for DB storage.

    Returns:
        bytes  — serialised numpy array (store as LONGBLOB in MySQL)
        None   — if no face detected or on error
    """
    cv2 = _import_cv2()
    fr  = _import_face_recognition()

    try:
        # Decode base64 → numpy image array
        if ',' in image_b64:
            image_b64 = image_b64.split(',', 1)[1]      # strip "data:image/jpeg;base64,"

        img_bytes = base64.b64decode(image_b64)
        nparr     = np.frombuffer(img_bytes, np.uint8)
        img_bgr   = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img_bgr is None:
            print('[FaceHelper] cv2.imdecode returned None — bad image data')
            return None

        # Convert BGR (OpenCV default) → RGB (face_recognition requirement)
        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

        # Detect face locations using HOG model (fast, CPU-friendly)
        face_locations = fr.face_locations(img_rgb, model='hog')
        if not face_locations:
            print('[FaceHelper] No faces detected in image')
            return None

        # Use the first (largest) face
        encodings = fr.face_encodings(img_rgb, face_locations)
        if not encodings:
            print('[FaceHelper] face_encodings returned empty list')
            return None

        encoding = encodings[0]   # 128-d numpy float64 array

        # Serialise with pickle for LONGBLOB storage
        return pickle.dumps(encoding)

    except Exception as e:
        print(f'[FaceHelper] encode_face_from_base64 error: {e}')
        traceback.print_exc()
        return None


def encode_face_from_multiple_images(images_b64: List[str]) -> Optional[bytes]:
    """
    Encode face from multiple base64 images and average the encodings for
    improved accuracy. Used during student face registration (captures 5 frames).

    Returns:
        bytes  — serialised averaged numpy encoding
        None   — if fewer than 1 valid encoding found
    """
    fr = _import_face_recognition()

    valid_encodings = []
    for idx, img_b64 in enumerate(images_b64):
        enc_bytes = encode_face_from_base64(img_b64)
        if enc_bytes:
            enc_array = pickle.loads(enc_bytes)
            valid_encodings.append(enc_array)
            print(f'[FaceHelper] Image {idx+1}/{len(images_b64)}: face encoded OK')
        else:
            print(f'[FaceHelper] Image {idx+1}/{len(images_b64)}: no face detected')

    if not valid_encodings:
        return None

    # Average all valid encodings — reduces noise from lighting variations
    averaged = np.mean(valid_encodings, axis=0)
    return pickle.dumps(averaged)


def deserialise_encoding(blob: bytes) -> Optional[np.ndarray]:
    """
    Deserialise a LONGBLOB from MySQL back into a numpy array for comparison.
    Handles multiple formats:
      - raw bytes (normal pymysql)
      - memoryview (some MySQL drivers)
      - base64 string (some Railway MySQL driver versions return BLOB as str)

    Also detects and skips JPEG/PNG thumbnail fallback blobs stored when
    ML libs were unavailable during student face registration.
    """
    if blob is None:
        return None
    try:
        # Handle memoryview from some MySQL drivers
        if isinstance(blob, memoryview):
            blob = bytes(blob)

        # Handle base64 string — some Railway MySQL driver versions return
        # LONGBLOB columns as base64-encoded strings instead of raw bytes.
        # Error seen: "a bytes-like object is required, not 'str'"
        if isinstance(blob, str):
            import base64 as _b64
            try:
                blob = _b64.b64decode(blob)
            except Exception:
                # Not valid base64 — try encoding as latin-1 bytes directly
                try:
                    blob = blob.encode('latin-1')
                except Exception as e:
                    print(f'[FaceHelper] deserialise_encoding: could not convert str blob: {e}')
                    return None

        # Ensure we have bytes at this point
        if not isinstance(blob, (bytes, bytearray)):
            print(f'[FaceHelper] deserialise_encoding: unexpected blob type {type(blob)} — skipping.')
            return None

        # Detect JPEG thumbnail fallback: starts with FF D8 FF (JPEG magic bytes)
        # These are raw JPEG frames stored when ML libs were unavailable during
        # student face registration — not valid face encodings, skip them.
        if len(blob) >= 3 and blob[:3] == b'\xff\xd8\xff':
            print('[FaceHelper] deserialise_encoding: blob is a JPEG thumbnail fallback '
                  '— student must re-register face with ML libs active.')
            return None

        # Detect PNG fallback: starts with PNG magic bytes
        if len(blob) >= 8 and blob[:8] == b'\x89PNG\r\n\x1a\n':
            print('[FaceHelper] deserialise_encoding: blob is a PNG thumbnail — skipping.')
            return None

        enc = pickle.loads(blob)

        # Validate it is actually a 128-d face encoding numpy array
        if not isinstance(enc, np.ndarray):
            print(f'[FaceHelper] deserialise_encoding: unpickled object is {type(enc)}, not ndarray — skipping.')
            return None
        if enc.shape != (128,):
            print(f'[FaceHelper] deserialise_encoding: wrong shape {enc.shape}, expected (128,) — skipping.')
            return None

        return enc

    except Exception as e:
        print(f'[FaceHelper] deserialise_encoding error: {e}')
        return None


# =============================================================================
# COMPARISON UTILITIES
# =============================================================================

def compare_face_to_stored(
    live_encoding_b64: str,
    stored_blobs: List[Tuple[int, bytes]],
    tolerance: float = 0.5
) -> Optional[int]:
    """
    Compare a live webcam image against all stored face encodings.

    Args:
        live_encoding_b64: base64 image from webcam (single frame)
        stored_blobs: list of (student_id, face_encoding_blob) tuples
        tolerance: match threshold — lower = stricter (default 0.5 is standard)

    Returns:
        int   — matched student_id
        None  — no match found
    """
    fr = _import_face_recognition()

    live_bytes = encode_face_from_base64(live_encoding_b64)
    if live_bytes is None:
        return None

    live_enc = pickle.loads(live_bytes)

    for student_id, blob in stored_blobs:
        stored_enc = deserialise_encoding(blob)
        if stored_enc is None:
            continue
        matches = fr.compare_faces([stored_enc], live_enc, tolerance=tolerance)
        if matches and matches[0]:
            print(f'[FaceHelper] MATCH: student_id={student_id}')
            return student_id

    return None


def identify_faces_in_classroom(
    frame_b64: str,
    stored_encodings: List[Tuple[int, bytes]],
    tolerance: float = 0.5
) -> List[int]:
    """
    Identify ALL faces visible in a single classroom frame.
    Used by the teacher portal Face Recognition Attendance feature.

    Args:
        frame_b64: base64-encoded classroom image (may contain multiple faces)
        stored_encodings: list of (student_id, face_encoding_blob) tuples
        tolerance: match threshold

    Returns:
        List of identified student_ids (may be empty if no matches)
    """
    cv2 = _import_cv2()
    fr  = _import_face_recognition()

    identified_students = []

    try:
        # Decode classroom frame
        if ',' in frame_b64:
            frame_b64 = frame_b64.split(',', 1)[1]

        img_bytes = base64.b64decode(frame_b64)
        nparr     = np.frombuffer(img_bytes, np.uint8)
        img_bgr   = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if img_bgr is None:
            print('[FaceHelper] identify_faces: cv2.imdecode returned None')
            return []

        img_rgb = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)

        # Detect all faces in the frame (scale down for speed — 1/4 resolution)
        small_rgb  = cv2.resize(img_rgb, (0, 0), fx=0.25, fy=0.25)
        locations  = fr.face_locations(small_rgb, model='hog')

        if not locations:
            print('[FaceHelper] No faces found in classroom frame')
            return []

        print(f'[FaceHelper] Found {len(locations)} face(s) in classroom frame')

        # Scale locations back to original size
        locations_full = [(
            top    * 4,
            right  * 4,
            bottom * 4,
            left   * 4
        ) for (top, right, bottom, left) in locations]

        # Encode all detected faces
        live_encodings = fr.face_encodings(img_rgb, locations_full)

        # Deserialise all stored encodings once
        stored_deserialized = []
        for sid, blob in stored_encodings:
            enc = deserialise_encoding(blob)
            if enc is not None:
                stored_deserialized.append((sid, enc))

        if not stored_deserialized:
            print('[FaceHelper] No valid stored encodings to compare against')
            return []

        # For each detected face, find best match in stored encodings
        stored_enc_arrays = [enc for _, enc in stored_deserialized]
        stored_ids        = [sid for sid, _ in stored_deserialized]

        for live_enc in live_encodings:
            distances = fr.face_distance(stored_enc_arrays, live_enc)
            best_idx  = int(np.argmin(distances))

            if distances[best_idx] <= tolerance:
                matched_sid = stored_ids[best_idx]
                if matched_sid not in identified_students:
                    identified_students.append(matched_sid)
                    print(f'[FaceHelper] Classroom match: student_id={matched_sid} (dist={distances[best_idx]:.3f})')
            else:
                print(f'[FaceHelper] No match for face (best dist={distances[best_idx]:.3f})')

    except Exception as e:
        print(f'[FaceHelper] identify_faces_in_classroom error: {e}')
        traceback.print_exc()

    return identified_students


# =============================================================================
# HEALTH CHECK
# =============================================================================

def check_dependencies() -> dict:
    """
    Check if all face recognition dependencies are installed.
    Called at startup and exposed via /api/face/health endpoint.
    """
    status = {'opencv': False, 'face_recognition': False, 'numpy': True}
    try:
        import cv2
        status['opencv'] = True
        status['opencv_version'] = cv2.__version__
    except ImportError:
        status['opencv_error'] = 'opencv-python-headless not installed'

    try:
        import face_recognition  # type: ignore[import]
        status['face_recognition'] = True
    except ImportError:
        status['face_recognition_error'] = 'face_recognition not installed'

    try:
        import numpy as np
        status['numpy_version'] = np.__version__
    except ImportError:
        status['numpy'] = False

    status['ready'] = status['opencv'] and status['face_recognition'] and status['numpy']
    return status