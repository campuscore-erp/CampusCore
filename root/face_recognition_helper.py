"""
face_recognition_helper.py  —  CampusCore University ERP
=========================================================
Face Recognition Attendance System — complete rewrite v3

PIPELINE:
  Registration (student portal):
    encode_face_from_multiple_images(images_b64) -> bytes (pickle'd numpy)

  Recognition (teacher portal):
    identify_faces_in_classroom(frame_b64, stored_encodings) -> [student_id, ...]

NOTES:
  - Uses dlib-bin (pre-built wheels, no compile) + face_recognition + opencv-headless
  - All encodings: 128-d float64 numpy arrays, pickle-serialised as LONGBLOB
  - Handles memoryview / raw bytes / base64-string blobs from MySQL driver
  - Skips JPEG/PNG thumbnail fallback blobs gracefully
"""

import base64
import pickle
import traceback
from typing import Optional, List, Tuple

import numpy as np


# ── Lazy imports ──────────────────────────────────────────────────────────────

def _cv2():
    try:
        import cv2
        return cv2
    except ImportError:
        raise ImportError("pip install opencv-python-headless")

def _fr():
    try:
        import face_recognition
        return face_recognition
    except ImportError:
        raise ImportError("pip install face_recognition")


# ── Image decoding ────────────────────────────────────────────────────────────

def _decode_image(image_b64: str):
    """Decode base64 image string to RGB numpy array. Returns None on failure."""
    cv2 = _cv2()
    try:
        if ',' in image_b64:
            image_b64 = image_b64.split(',', 1)[1]
        img_bytes = base64.b64decode(image_b64)
        nparr     = np.frombuffer(img_bytes, np.uint8)
        img_bgr   = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        if img_bgr is None:
            return None
        return cv2.cvtColor(img_bgr, cv2.COLOR_BGR2RGB)
    except Exception as e:
        print(f'[FaceHelper] _decode_image error: {e}')
        return None


def _normalise(enc: np.ndarray) -> np.ndarray:
    """Normalise a 128-d encoding to unit length for consistent distance comparison."""
    n = np.linalg.norm(enc)
    return enc / n if n > 1e-10 else enc


# ── Encoding utilities ────────────────────────────────────────────────────────

def encode_face_from_base64(image_b64: str) -> Optional[bytes]:
    """
    Detect and encode a face from a single base64 image.
    Returns pickle'd 128-d numpy array, or None if no face found.
    """
    fr = _fr()
    img_rgb = _decode_image(image_b64)
    if img_rgb is None:
        print('[FaceHelper] encode_face_from_base64: could not decode image')
        return None
    try:
        locations = fr.face_locations(img_rgb, model='hog')
        if not locations:
            print('[FaceHelper] encode_face_from_base64: no face detected')
            return None
        encodings = fr.face_encodings(img_rgb, [locations[0]], num_jitters=1)
        if not encodings:
            print('[FaceHelper] encode_face_from_base64: face_encodings returned empty')
            return None
        return pickle.dumps(encodings[0])
    except Exception as e:
        print(f'[FaceHelper] encode_face_from_base64 error: {e}')
        traceback.print_exc()
        return None


def encode_face_from_multiple_images(images_b64: List[str]) -> Optional[bytes]:
    """
    Encode a face from multiple base64 frames and return the averaged encoding.
    Used during student registration (5 frames captured).
    Returns pickle'd averaged 128-d numpy array, or None if no valid frames.
    """
    valid = []
    for i, img_b64 in enumerate(images_b64):
        b = encode_face_from_base64(img_b64)
        if b:
            valid.append(pickle.loads(b))
            print(f'[FaceHelper] Registration frame {i+1}/{len(images_b64)}: OK')
        else:
            print(f'[FaceHelper] Registration frame {i+1}/{len(images_b64)}: no face')

    if not valid:
        print('[FaceHelper] encode_face_from_multiple_images: no valid frames')
        return None

    avg = np.mean(valid, axis=0)
    print(f'[FaceHelper] Averaged {len(valid)} encodings for registration')
    return pickle.dumps(avg)


# ── Deserialisation ───────────────────────────────────────────────────────────

def deserialise_encoding(blob) -> Optional[np.ndarray]:
    """
    Convert a DB BLOB back to a 128-d numpy array.
    Handles: raw bytes, bytearray, memoryview, base64 string.
    Returns None if blob is a thumbnail fallback or invalid.
    """
    if blob is None:
        return None

    try:
        # memoryview → bytes
        if isinstance(blob, memoryview):
            blob = bytes(blob)

        # base64 string (some Railway MySQL driver versions)
        if isinstance(blob, str):
            try:
                blob = base64.b64decode(blob)
            except Exception:
                try:
                    blob = blob.encode('latin-1')
                except Exception as e:
                    print(f'[FaceHelper] deserialise: str blob unhandled: {e}')
                    return None

        if not isinstance(blob, (bytes, bytearray)):
            print(f'[FaceHelper] deserialise: unexpected type {type(blob)}')
            return None

        # Detect JPEG thumbnail fallback (registered when ML was not ready)
        if len(blob) >= 3 and blob[:3] == b'\xff\xd8\xff':
            print('[FaceHelper] deserialise: JPEG thumbnail — student must re-register')
            return None

        # Detect PNG fallback
        if len(blob) >= 8 and blob[:8] == b'\x89PNG\r\n\x1a\n':
            print('[FaceHelper] deserialise: PNG thumbnail — student must re-register')
            return None

        enc = pickle.loads(blob)

        if not isinstance(enc, np.ndarray):
            print(f'[FaceHelper] deserialise: not ndarray, got {type(enc)}')
            return None
        if enc.shape != (128,):
            print(f'[FaceHelper] deserialise: wrong shape {enc.shape}')
            return None

        return enc

    except Exception as e:
        print(f'[FaceHelper] deserialise error: {e}')
        return None


# ── Classroom recognition ─────────────────────────────────────────────────────

def identify_faces_in_classroom(
    frame_b64: str,
    stored_encodings: List[Tuple[int, bytes]],
    tolerance: float = 0.6
) -> List[int]:
    """
    Identify all registered students visible in a single classroom webcam frame.

    Args:
        frame_b64:        base64 JPEG from teacher's webcam
        stored_encodings: [(student_id, encoding_blob), ...]  from StudentFaceData
        tolerance:        L2 distance threshold — 0.6 works well for averaged
                          registration encodings vs single live frames

    Returns:
        List of matched student_ids (deduplicated, may be empty)

    Algorithm:
        1. Decode frame → RGB
        2. Resize to 50% for fast HOG detection (50% keeps faces ~100px, above HOG floor)
        3. Scale locations back to full resolution (×2)
        4. Encode detected faces at full resolution with num_jitters=1
        5. Normalise both live and stored encodings to unit vectors
        6. Use face_distance() to find best match per detected face
        7. Accept match if distance <= tolerance
    """
    cv2 = _cv2()
    fr  = _fr()

    identified = []

    try:
        img_rgb = _decode_image(frame_b64)
        if img_rgb is None:
            print('[FaceHelper] identify_faces: could not decode frame')
            return []

        # Step 2: Detect faces at 50% resolution
        # 50% keeps a typical 200px-tall webcam face at ~100px — above HOG's ~80px floor
        # 25% (old value) shrank faces to ~50px causing systematic missed detections
        h, w = img_rgb.shape[:2]
        small = cv2.resize(img_rgb, (w // 2, h // 2))
        locations_half = fr.face_locations(small, model='hog')

        if not locations_half:
            print('[FaceHelper] identify_faces: no faces detected in frame')
            return []

        print(f'[FaceHelper] Detected {len(locations_half)} face(s)')

        # Step 3: Scale locations back to full resolution (×2)
        locations_full = [
            (top * 2, right * 2, bottom * 2, left * 2)
            for top, right, bottom, left in locations_half
        ]

        # Step 4: Encode at full resolution
        live_encs = fr.face_encodings(img_rgb, locations_full, num_jitters=1)
        if not live_encs:
            print('[FaceHelper] identify_faces: face_encodings returned empty')
            return []

        # Step 5: Deserialise stored encodings
        stored = []
        for sid, blob in stored_encodings:
            enc = deserialise_encoding(blob)
            if enc is not None:
                stored.append((sid, _normalise(enc)))

        if not stored:
            print('[FaceHelper] identify_faces: no valid stored encodings to compare')
            return []

        stored_ids  = [s[0] for s in stored]
        stored_arrs = [s[1] for s in stored]

        # Step 6+7: Match each detected face
        for live_enc in live_encs:
            live_norm = _normalise(live_enc)
            dists     = fr.face_distance(stored_arrs, live_norm)
            best_idx  = int(np.argmin(dists))
            best_dist = float(dists[best_idx])

            if best_dist <= tolerance:
                sid = stored_ids[best_idx]
                if sid not in identified:
                    identified.append(sid)
                    print(f'[FaceHelper] MATCH student_id={sid} dist={best_dist:.3f}')
            else:
                print(f'[FaceHelper] No match (best dist={best_dist:.3f} > {tolerance})')

    except Exception as e:
        print(f'[FaceHelper] identify_faces_in_classroom error: {e}')
        traceback.print_exc()

    return identified


# ── Health check ──────────────────────────────────────────────────────────────

def check_dependencies() -> dict:
    """
    Check whether all face recognition dependencies are installed.
    Returns dict with 'ready': True/False and version info.
    """
    status = {'opencv': False, 'face_recognition': False, 'numpy': True}
    try:
        import cv2
        status['opencv']         = True
        status['opencv_version'] = cv2.__version__
    except ImportError as e:
        status['opencv_error'] = str(e)

    try:
        import face_recognition
        status['face_recognition'] = True
    except ImportError as e:
        status['face_recognition_error'] = str(e)

    try:
        import numpy as np
        status['numpy_version'] = np.__version__
    except ImportError:
        status['numpy'] = False

    status['ready'] = (
        status['opencv'] and
        status['face_recognition'] and
        status['numpy']
    )
    return status