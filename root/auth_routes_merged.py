"""
auth_routes_merged.py  —  University ERP
=========================================
Blueprints:
  bp_auth   →  /api/auth/*
  bp_common →  /api/common/*

UPDATED v2.0.0:
  - FIXED: Login response now includes departmentName (was missing, only had departmentId)
  - FIXED: change-password min length raised from 6 → 8 characters
  - NEW:   Brute-force login protection — 10 failed attempts → 15-min lockout
           (in-memory; resets on Flask restart — use Redis for production)
  - NEW:   GET  /api/auth/me          — alias for /verify (convenience endpoint)
  - NEW:   PUT  /api/auth/profile     — update own profile (name, phone, address, gender)
  - NEW:   GET  /api/common/subjects  — list subjects filtered by departmentId / semester
  - NEW:   GET  /api/common/semesters — available semesters for a department

LOGIN LOGIC:
  - Looks up Users table by UserCode (case-insensitive)
  - Verifies password (sha256 or bcrypt)
  - ALL users have IsFirstLogin=1 initially
  - First-login password = Date of Birth in DD-MM-YYYY format
  - After first login, user is redirected to change_password.html
  - Returns JWT with userType, userCode, userId claims

FIRST LOGIN CREDENTIALS (all users):
  Password = Date of Birth as DD-MM-YYYY
  Example: DOB 2004-04-08  →  first login password: 08-04-2004

AFTER PASSWORD CHANGE:
  Login again with new chosen password
"""

import hashlib
from datetime import datetime, timedelta
from collections import defaultdict
from flask import Blueprint, request, jsonify
from flask_jwt_extended import (
    create_access_token, jwt_required,
    get_jwt_identity, get_jwt
)
from database import db, verify_password

bp_auth   = Blueprint('auth',   __name__, url_prefix='/api/auth')
bp_common = Blueprint('common', __name__, url_prefix='/api/common')

# ── Brute-force protection (in-memory) ────────────────────────────────────────
_MAX_ATTEMPTS  = 10
_LOCKOUT_MINS  = 15
_login_attempts = defaultdict(lambda: {'count': 0, 'locked_until': None})


def _check_brute_force(key: str):
    """Returns (is_locked, remaining_attempts, lockout_message)."""
    rec = _login_attempts[key]
    if rec['locked_until'] and datetime.now() < rec['locked_until']:
        secs_left = int((rec['locked_until'] - datetime.now()).total_seconds())
        return True, 0, f'Too many failed attempts. Try again in {secs_left // 60}m {secs_left % 60}s.'
    if rec['locked_until'] and datetime.now() >= rec['locked_until']:
        # Reset after lockout expires
        rec['count'] = 0
        rec['locked_until'] = None
    remaining = _MAX_ATTEMPTS - rec['count']
    return False, remaining, ''


def _record_failed_attempt(key: str):
    rec = _login_attempts[key]
    rec['count'] += 1
    if rec['count'] >= _MAX_ATTEMPTS:
        rec['locked_until'] = datetime.now() + timedelta(minutes=_LOCKOUT_MINS)


def _reset_attempts(key: str):
    _login_attempts[key] = {'count': 0, 'locked_until': None}


# ── Helpers ────────────────────────────────────────────────────────────────────

def _now_str() -> str:
    """
    Return current datetime as a string both SQL Server and SQLite accept.
    SQL Server DATETIME rejects Python's isoformat() 'T' separator (error 241).
    """
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')


def _dob_ddmmyyyy(raw_dob: str) -> str:
    """Convert DB date string (YYYY-MM-DD or any format) to DD-MM-YYYY."""
    if not raw_dob:
        return ''
    raw = str(raw_dob).strip()
    date_part = raw.split(' ')[0].split('T')[0]
    parts = date_part.split('-')
    if len(parts) == 3 and len(parts[0]) == 4:
        return f"{parts[2]}-{parts[1]}-{parts[0]}"
    return raw


def _dob_hash(dob_ddmmyyyy: str) -> str:
    return hashlib.sha256(dob_ddmmyyyy.encode('utf-8')).hexdigest()


def _log(user_id, action, details='', ip=''):
    """
    Non-fatal activity log.
    Tries 'Activity' column first (SQLite schema), then 'Action' (MSSQL schema).
    """
    now = _now_str()
    try:
        db.execute_non_query(
            "INSERT INTO ActivityLogs (UserID, Activity, Details, IPAddress, CreatedAt) VALUES (?,?,?,?,?)",
            (user_id, action, details, ip, now)
        )
    except Exception:
        try:
            db.execute_non_query(
                "INSERT INTO ActivityLogs (UserID, Action, Details, IPAddress, CreatedAt) VALUES (?,?,?,?,?)",
                (user_id, action, details, ip, now)
            )
        except Exception:
            pass


def _sv(val):
    from datetime import date, time
    if isinstance(val, (datetime, date, time)):
        return str(val)
    return val


def serialize_row(row):
    if not row:
        return None
    return {k: _sv(v) for k, v in dict(row).items()}


# ══════════════════════════════════════════════════════════════════════════════
# LOGIN
# ══════════════════════════════════════════════════════════════════════════════

@bp_auth.route('/login', methods=['POST'])
def login():
    data      = request.get_json() or {}
    user_code = (data.get('userCode') or data.get('username') or '').strip()
    password  = (data.get('password') or '').strip()
    login_as  = (data.get('loginAs')  or '').strip()

    if not user_code or not password:
        return jsonify({'success': False, 'error': 'User code and password are required'}), 400

    # ── Brute-force check ──────────────────────────────────────────────────
    bf_key = f"{request.remote_addr}:{user_code.upper()}"
    is_locked, remaining, lock_msg = _check_brute_force(bf_key)
    if is_locked:
        return jsonify({'success': False, 'error': lock_msg}), 429

    # ── Fetch user with department name (FIXED: LEFT JOIN Departments) ─────
    user = None
    try:
        user = db.execute_query(
            """SELECT u.UserID, u.UserCode, u.FullName, u.Email, u.Phone,
                      u.UserType, u.DepartmentID, u.Gender, u.DateOfBirth,
                      u.PasswordHash, u.IsFirstLogin, u.IsActive, u.Semester,
                      d.DepartmentName
               FROM Users u
               LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
               WHERE UPPER(u.UserCode) = UPPER(?) AND u.IsActive = 1""",
            (user_code,), fetch_one=True
        )
    except Exception as e:
        print(f'[Login] DB error: {e}')
        return jsonify({'success': False, 'error': 'Database error during login'}), 500

    if not user:
        try:
            chk = db.execute_query(
                "SELECT IsActive FROM Users WHERE UPPER(UserCode) = UPPER(?)",
                (user_code,), fetch_one=True
            )
            if chk and not chk['IsActive']:
                return jsonify({'success': False,
                                'error': 'Your account has been deactivated. Contact admin.'}), 401
        except Exception:
            pass
        _record_failed_attempt(bf_key)
        return jsonify({'success': False,
                        'error': f'No account found for user code: {user_code}. '
                                  'Please check your User Code / Roll Number.'}), 401

    # ── Role enforcement ───────────────────────────────────────────────────
    actual_type = str(user.get('UserType') or '').strip()
    if login_as and actual_type.lower() != login_as.lower():
        return jsonify({
            'success':    False,
            'error':      f"This is a {actual_type} account. "
                          f"Please click the '{actual_type}' tab and try again.",
            'actualRole': actual_type
        }), 403

    # ── Password verification ──────────────────────────────────────────────
    stored_hash = user.get('PasswordHash') or ''
    first_login = int(user.get('IsFirstLogin') or 0)
    raw_dob     = user.get('DateOfBirth') or ''
    dob_display = _dob_ddmmyyyy(raw_dob)   # e.g. "08-04-2004"

    # Step 1: Try the stored hash directly (works for changed passwords AND DOB-hashed passwords)
    password_ok = verify_password(password, stored_hash)

    # Step 2: If IsFirstLogin=1, also check if user typed DOB as DD-MM-YYYY
    if not password_ok and first_login and dob_display:
        entered_hash = hashlib.sha256(password.encode('utf-8')).hexdigest()
        if entered_hash == _dob_hash(dob_display):
            password_ok = True

    if not password_ok:
        _record_failed_attempt(bf_key)
        _, remaining_after, _ = _check_brute_force(bf_key)
        warn = ''
        if 0 < remaining_after <= 3:
            warn = f' Warning: {remaining_after} attempt(s) remaining before lockout.'
        if first_login and dob_display:
            return jsonify({'success': False,
                            'error': f'Incorrect password. First-time login: use your Date of Birth as DD-MM-YYYY (e.g. {dob_display}).{warn}'}), 401
        return jsonify({'success': False, 'error': f'Incorrect password.{warn}'}), 401

    # ── Success — reset brute-force counter ────────────────────────────────
    _reset_attempts(bf_key)

    uid    = user['UserID']
    u_code = user['UserCode']

    token = create_access_token(
        identity=str(uid),
        additional_claims={
            'userType': actual_type,
            'userCode': u_code,
            'userId':   uid,
        }
    )

    _log(uid, 'LOGIN', f'{actual_type} logged in from {request.remote_addr}', request.remote_addr)

    raw_dob     = user.get('DateOfBirth') or ''
    dob_display = _dob_ddmmyyyy(raw_dob)

    return jsonify({
        'success':      True,
        'token':        token,
        'access_token': token,
        'isFirstLogin': bool(first_login),
        'userType':     actual_type,
        'message':      f'Welcome, {user.get("FullName") or u_code}!',
        'user': {
            'userId':         uid,
            'userCode':       u_code,
            'fullName':       user.get('FullName') or '',
            'email':          user.get('Email') or '',
            'phone':          user.get('Phone') or '',
            'userType':       actual_type,
            'departmentId':   user.get('DepartmentID'),
            'departmentName': user.get('DepartmentName') or '',   # ← FIXED: now included
            'gender':         user.get('Gender') or '',
            'semester':       user.get('Semester'),
            'isFirstLogin':   bool(first_login),
            'dateOfBirth':    dob_display,
        },
    }), 200


# ══════════════════════════════════════════════════════════════════════════════
# CHANGE PASSWORD
# ══════════════════════════════════════════════════════════════════════════════

@bp_auth.route('/change-password', methods=['POST'])
@jwt_required()
def change_password():
    data         = request.get_json() or {}
    old_password = (data.get('currentPassword') or data.get('oldPassword') or '').strip()
    new_password = (data.get('newPassword') or '').strip()

    if not old_password or not new_password:
        return jsonify({'success': False,
                        'error': 'Current password and new password are required'}), 400
    if len(new_password) < 8:             # ← FIXED: raised from 6 → 8
        return jsonify({'success': False,
                        'error': 'New password must be at least 8 characters'}), 400

    try:
        user_id = int(get_jwt_identity())
        user = db.execute_query(
            "SELECT PasswordHash, IsFirstLogin, DateOfBirth FROM Users WHERE UserID=?",
            (user_id,), fetch_one=True
        )
        if not user:
            return jsonify({'success': False, 'error': 'User not found'}), 404

        stored_hash = user['PasswordHash']
        first_login = int(user.get('IsFirstLogin') or 0)
        raw_dob     = user.get('DateOfBirth') or ''
        dob_display = _dob_ddmmyyyy(raw_dob)

        # Try stored hash first (handles both DOB-hashed and already-changed passwords)
        password_ok = verify_password(old_password, stored_hash)

        # Also accept DOB typed as DD-MM-YYYY on first login
        if not password_ok and first_login and dob_display:
            entered_hash = hashlib.sha256(old_password.encode('utf-8')).hexdigest()
            if entered_hash == _dob_hash(dob_display):
                password_ok = True

        if not password_ok:
            hint = f' Your first-time password is your Date of Birth as DD-MM-YYYY (e.g. {dob_display}).' if first_login and dob_display else ''
            return jsonify({'success': False,
                            'error': f'Current password is incorrect.{hint}'}), 401

        new_hash = hashlib.sha256(new_password.encode('utf-8')).hexdigest()
        if new_hash == stored_hash:
            return jsonify({'success': False,
                            'error': 'New password must be different from your current password'}), 400

        raw_dob     = user.get('DateOfBirth') or ''
        dob_display = _dob_ddmmyyyy(raw_dob)
        if dob_display and new_password == dob_display:
            return jsonify({'success': False,
                            'error': 'New password cannot be your Date of Birth. '
                                     'Please choose a more secure password.'}), 400

        db.execute_non_query(
            "UPDATE Users SET PasswordHash=?, IsFirstLogin=0, UpdatedAt=? WHERE UserID=?",
            (new_hash, _now_str(), user_id)
        )

        _log(user_id, 'CHANGE_PASSWORD', 'Password changed successfully', request.remote_addr)
        return jsonify({'success': True, 'message': 'Password changed successfully. '
                                                    'Please log in with your new password.'}), 200

    except Exception as e:
        print(f'[ChangePassword] Error: {e}')
        import traceback
        traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500


# ══════════════════════════════════════════════════════════════════════════════
# LOGOUT
# ══════════════════════════════════════════════════════════════════════════════

@bp_auth.route('/logout', methods=['POST'])
@jwt_required()
def logout():
    try:
        user_id = int(get_jwt_identity())
        _log(user_id, 'LOGOUT', f'Logged out from {request.remote_addr}', request.remote_addr)
    except Exception:
        pass
    return jsonify({'success': True, 'message': 'Logged out successfully'}), 200


# ══════════════════════════════════════════════════════════════════════════════
# VERIFY TOKEN
# ══════════════════════════════════════════════════════════════════════════════

@bp_auth.route('/verify', methods=['GET'])
@jwt_required()
def verify_token():
    try:
        user_id = int(get_jwt_identity())
        claims  = get_jwt()
        user = db.execute_query(
            "SELECT UserID, UserCode, FullName, Email, UserType, IsActive, IsFirstLogin FROM Users WHERE UserID=?",
            (user_id,), fetch_one=True
        )
        if not user or not user['IsActive']:
            return jsonify({'success': False, 'error': 'Account inactive'}), 401
        return jsonify({
            'success':    True,
            'valid':      True,
            'userType':   claims.get('userType'),
            'userCode':   claims.get('userCode'),
            'isFirstLogin': bool(int(user.get('IsFirstLogin') or 0)),
            'user': {
                'userId':       user['UserID'],
                'userCode':     user['UserCode'],
                'fullName':     user['FullName'],
                'email':        user['Email'],
                'userType':     user['UserType'],
                'isFirstLogin': bool(int(user.get('IsFirstLogin') or 0)),
            }
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ══════════════════════════════════════════════════════════════════════════════
# NEW: GET /api/auth/me  — alias for /verify (convenience)
# ══════════════════════════════════════════════════════════════════════════════

@bp_auth.route('/me', methods=['GET'])
@jwt_required()
def get_me():
    """Alias for /verify — returns current user info from JWT."""
    return verify_token()


# ══════════════════════════════════════════════════════════════════════════════
# NEW: PUT /api/auth/profile  — update own profile
# ══════════════════════════════════════════════════════════════════════════════

@bp_auth.route('/profile', methods=['PUT'])
@jwt_required()
def update_profile():
    """Allow any logged-in user to update their own name, phone, address, gender."""
    try:
        user_id = int(get_jwt_identity())
        data    = request.get_json() or {}

        field_map = {
            'fullName': 'FullName',
            'phone':    'Phone',
            'address':  'Address',
            'gender':   'Gender',
        }
        parts, params = [], []
        for jf, dbf in field_map.items():
            if jf in data and data[jf] is not None:
                parts.append(f'{dbf} = ?')
                params.append(str(data[jf]).strip())

        if not parts:
            return jsonify({'success': False, 'error': 'No valid fields to update'}), 400

        params.append(user_id)
        db.execute_non_query(
            f"UPDATE Users SET {', '.join(parts)} WHERE UserID = ?",
            tuple(params)
        )
        return jsonify({'success': True, 'message': 'Profile updated successfully'}), 200

    except Exception as e:
        import traceback; traceback.print_exc()
        return jsonify({'success': False, 'error': str(e)}), 500


# ══════════════════════════════════════════════════════════════════════════════
# COMMON ROUTES  /api/common/*
# ══════════════════════════════════════════════════════════════════════════════

@bp_common.route('/departments', methods=['GET'])
@jwt_required()
def get_departments():
    try:
        rows = db.execute_query(
            "SELECT DepartmentID, DepartmentName, DepartmentCode FROM Departments ORDER BY DepartmentName"
        ) or []
        return jsonify({
            'success':     True,
            'departments': [{k: v for k, v in r.items()} for r in rows]
        }), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ══════════════════════════════════════════════════════════════════════════════
# NEW: GET /api/common/subjects  — list subjects by dept/semester
# ══════════════════════════════════════════════════════════════════════════════

@bp_common.route('/subjects', methods=['GET'])
@jwt_required()
def get_subjects():
    """
    Query params:
      departmentId (optional) — filter by DepartmentID
      semester     (optional) — filter by Semester
    """
    try:
        dept_id  = request.args.get('departmentId')
        semester = request.args.get('semester')

        query  = """SELECT s.SubjectID, s.SubjectName, s.SubjectCode,
                           s.Credits, s.IsLab, s.Semester,
                           d.DepartmentName, d.DepartmentCode
                    FROM Subjects s
                    JOIN Departments d ON s.DepartmentID = d.DepartmentID
                    WHERE 1=1"""
        params = []
        if dept_id:
            query += ' AND s.DepartmentID = ?'; params.append(dept_id)
        if semester:
            query += ' AND s.Semester = ?';     params.append(semester)
        query += ' ORDER BY s.Semester, s.SubjectName'

        rows = db.execute_query(query, tuple(params) if params else ()) or []
        subjects = [{k: _sv(v) for k, v in dict(r).items()} for r in rows]
        return jsonify({'success': True, 'subjects': subjects}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# ══════════════════════════════════════════════════════════════════════════════
# NEW: GET /api/common/semesters  — available semesters for a department
# ══════════════════════════════════════════════════════════════════════════════

@bp_common.route('/semesters', methods=['GET'])
@jwt_required()
def get_semesters():
    """
    Query params:
      departmentId (required) — DepartmentID to look up semesters for
    Returns distinct semesters from the Timetable table for that department.
    """
    try:
        dept_id = request.args.get('departmentId')
        if not dept_id:
            return jsonify({'success': False, 'error': 'departmentId is required'}), 400

        semesters = []
        for sql in [
            "SELECT DISTINCT Semester FROM Timetable WHERE DepartmentID=? AND Semester IS NOT NULL ORDER BY Semester",
            "SELECT DISTINCT Semester FROM Subjects WHERE DepartmentID=? AND Semester IS NOT NULL ORDER BY Semester",
        ]:
            try:
                rows = db.execute_query(sql, (dept_id,)) or []
                semesters = [r['Semester'] for r in rows if r.get('Semester') is not None]
                if semesters:
                    break
            except Exception:
                pass

        return jsonify({'success': True, 'semesters': semesters}), 200

    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500