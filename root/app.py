"""
app.py  —  University ERP | Flask Application Entry Point
UPDATED v2.0.0:
  - Added traceback.print_exc() to all blueprint load failures (easier debugging)
  - Added GET /api/routes endpoint (dev tool — lists all registered routes)
  - Added 'version' field to /health response
  - Health endpoint shows db_error message on DB failure
"""

import os, sys, traceback
from datetime import timedelta, datetime
from flask import Flask, jsonify
from flask_jwt_extended import JWTManager
from flask_cors import CORS
from dotenv import load_dotenv

load_dotenv()

_ROOT = os.path.dirname(os.path.abspath(__file__))
if _ROOT not in sys.path:
    sys.path.insert(0, _ROOT)

print('=' * 60)
print('  CampusCore University ERP — Startup')
print('=' * 60)

from database import db  # noqa

app = Flask(__name__)
# Railway sets SECRET_KEY in CampusCore service variables — read it properly
_secret = os.getenv('SECRET_KEY') or os.getenv('FLASK_SECRET_KEY') or 'campuscore-secret-2024-xyz'
_jwt_secret = os.getenv('JWT_SECRET_KEY') or _secret + '-jwt'
app.config['SECRET_KEY']               = _secret
app.config['JWT_SECRET_KEY']           = _jwt_secret
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(hours=24)
app.config['MAX_CONTENT_LENGTH']       = 50 * 1024 * 1024

jwt = JWTManager(app)

@jwt.expired_token_loader
def _expired(h, p):
    return jsonify({'error': 'Token has expired', 'code': 'TOKEN_EXPIRED'}), 401

@jwt.invalid_token_loader
def _invalid(e):
    return jsonify({'error': 'Invalid token', 'code': 'INVALID_TOKEN'}), 422

@jwt.unauthorized_loader
def _unauth(e):
    return jsonify({'error': 'Missing authorization header', 'code': 'NO_TOKEN'}), 401

CORS(app, resources={r'/*': {
    'origins': '*',
    'methods': ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
    'allow_headers': ['Content-Type', 'Authorization'],
}})

@app.before_request
def _preflight():
    from flask import request as req, make_response
    if req.method == 'OPTIONS':
        r = make_response('', 204)
        r.headers['Access-Control-Allow-Origin']  = '*'
        r.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
        r.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
        r.headers['Access-Control-Max-Age']       = '3600'
        return r

@app.errorhandler(404)
def _404(e): return jsonify({'error': 'Not found'}), 404

@app.errorhandler(500)
def _500(e): return jsonify({'error': 'Internal server error'}), 500

@app.errorhandler(413)
def _413(e): return jsonify({'error': 'File too large (max 50 MB)'}), 413

print('\n  Loading blueprints:')

try:
    from auth_routes_merged import bp_auth, bp_common
    app.register_blueprint(bp_auth)
    app.register_blueprint(bp_common)
    print('  OK auth_routes_merged    -> /api/auth/* + /api/common/*')
except Exception as e:
    print(f'  FAIL auth_routes_merged: {e}')
    traceback.print_exc()          # ← FIXED: full traceback shown on failure

try:
    from admin_routes_merged import bp_admin
    app.register_blueprint(bp_admin)
    print('  OK admin_routes_merged   -> /api/admin/*')
except Exception as e:
    print(f'  FAIL admin_routes_merged: {e}')
    traceback.print_exc()          # ← FIXED

try:
    from student_routes_merged import bp_student
    app.register_blueprint(bp_student)
    print('  OK student_routes_merged -> /api/student/*')
except Exception as e:
    print(f'  FAIL student_routes_merged: {e}')
    traceback.print_exc()          # ← FIXED

try:
    from teacher_routes_merged import bp_teacher, bp_timetable
    app.register_blueprint(bp_teacher)
    app.register_blueprint(bp_timetable)
    print('  OK teacher_routes_merged -> /api/teacher/* + /api/timetable/*')
except Exception as e:
    print(f'  FAIL teacher_routes_merged: {e}')
    traceback.print_exc()          # ← FIXED

print('=' * 60)

@app.route('/uploads/<path:filename>')
def serve_upload(filename):
    from flask import send_from_directory
    import mimetypes
    upload_dir = os.path.join(_ROOT, 'uploads')
    mime_type, _ = mimetypes.guess_type(filename)
    response = send_from_directory(upload_dir, filename, mimetype=mime_type or 'application/octet-stream')
    response.headers['Access-Control-Allow-Origin'] = '*'
    return response

# ── Serve HTML files directly from Flask ─────────────────────────────────────
@app.route('/')
@app.route('/auth.html')
def index():
    from flask import send_from_directory
    return send_from_directory(_ROOT, 'auth.html')

@app.route('/admin.html')
def admin_page():
    from flask import send_from_directory
    return send_from_directory(_ROOT, 'admin.html')

@app.route('/student.html')
def student_page():
    from flask import send_from_directory
    return send_from_directory(_ROOT, 'student.html')

@app.route('/teacher.html')
def teacher_page():
    from flask import send_from_directory
    return send_from_directory(_ROOT, 'teacher.html')

@app.route('/change_password.html')
def change_password_page():
    from flask import send_from_directory
    return send_from_directory(_ROOT, 'change_password.html')

@app.route('/favicon.ico')
def favicon():
    """Serve an inline SVG favicon — no file needed, eliminates 404 error."""
    from flask import Response
    svg = (
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">'
        '<rect width="32" height="32" rx="8" fill="#2563eb"/>'
        '<text x="16" y="23" font-size="20" text-anchor="middle" '
        'font-family="Arial,sans-serif" font-weight="bold" fill="#ffffff">C</text>'
        '</svg>'
    )
    return Response(svg, mimetype='image/svg+xml',
                    headers={'Cache-Control': 'public, max-age=86400'})

@app.route('/timetable.html')
def timetable_page():
    from flask import send_from_directory
    return send_from_directory(_ROOT, 'timetable.html')

# ── Health check ──────────────────────────────────────────────────────────────
@app.route('/health')
def health():
    db_status, backend, err_msg = 'error', 'unknown', ''
    try:
        result    = db.execute_query('SELECT 1 AS test', fetch_one=True)
        db_status = 'connected' if result else 'disconnected'
        backend   = getattr(db, '_backend', 'unknown')
    except Exception as ex:
        err_msg = str(ex)                      # ← FIXED: expose error detail
    resp = {
        'status':     'healthy',
        'version':    '2.0.0',                 # ← NEW: version field
        'database':   db_status,
        'db_backend': backend,
        'time':       datetime.now().isoformat(),
    }
    if err_msg:
        resp['db_error'] = err_msg
    return jsonify(resp)

@app.route('/api/test-auth')
def test_auth():
    return jsonify({'success': True, 'message': 'API is working', 'time': datetime.now().isoformat()})

# ── NEW: Dev tool — list all registered routes ────────────────────────────────
@app.route('/api/routes')
def list_routes():
    """Lists every registered URL rule with its HTTP methods. Dev use only."""
    routes = []
    for rule in sorted(app.url_map.iter_rules(), key=lambda r: r.rule):
        routes.append({
            'endpoint': rule.endpoint,
            'methods':  sorted(m for m in rule.methods if m not in ('HEAD', 'OPTIONS')),
            'url':      rule.rule,
        })
    return jsonify({'success': True, 'count': len(routes), 'routes': routes})

if __name__ == '__main__':
    host  = os.getenv('HOST', '0.0.0.0')
    port  = int(os.getenv('PORT', 5000))
    # On Railway, always disable debug mode for production stability
    debug = os.getenv('FLASK_DEBUG', 'False').lower() in ('true', '1')
    print(f'\n  ✅ CampusCore is running!')
    print(f'  Open in browser: http://127.0.0.1:{port}/auth.html')
    print(f'  (Do NOT use VS Code Live Server — open via Flask URL above)')
    print(f'\n  Default first-login passwords (use Date of Birth as DD-MM-YYYY):')
    print(f'    Admin:   ADMIN001  →  15-05-1980')
    print(f'    Teacher: TID001    →  12-03-1975')
    print(f'    Student: D1S1N01   →  15-08-2006\n')
    app.run(host=host, port=port, debug=debug)