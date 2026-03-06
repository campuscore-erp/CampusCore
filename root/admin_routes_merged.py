"""
admin_routes_merged.py  —  University ERP
==========================================
Blueprint: bp_admin  →  /api/admin/*

UPDATED v2.1.0:
  FIXED:
    - activity-logs: was hardcoded to 'Action' column; SQLite uses 'Activity'.
      Now tries 'Activity' first, falls back to 'Action' (MSSQL). HTTP 500 is gone.
    - activity-logs: LIMIT syntax was MSSQL-incompatible. Now uses multi-fallback.
    - reset-password: was NOT setting IsFirstLogin=1 after reset.
      Fixed: UPDATE now sets IsFirstLogin=1 so user is forced to change password.
    - delete_department: only checked students, not teachers.
      Fixed: also blocks delete if active teachers exist in the department.
    - add_student / add_teacher: no duplicate UserCode check → raw DB exception.
      Fixed: SELECT before INSERT; returns HTTP 409 Conflict on duplicate.
    - dashboard recentStudents/recentTeachers: LIMIT not supported in MSSQL.
      Fixed: multi-fallback with TOP N.
    - dashboard missing totalTimetable + totalFeeStructure counts.
      Fixed: added COUNT queries for both tables.
    - get_departments: TotalSemesters column missing in MySQL schema → HTTP 500.
      Fixed: fallback query uses 8 AS TotalSemesters when column absent.
    - add_department / update_department: TotalSemesters/IsShared missing in MySQL.
      Fixed: fallback INSERT/UPDATE without those columns.
    - get_subjects: IsLab column missing in MySQL Subjects schema → HTTP 500.
      Fixed: fallback query uses 0 AS IsLab when column absent.
    - add_subject: INSERT with IsLab fails on MySQL.
      Fixed: fallback INSERT without IsLab.
    - get_timetable: only tried Classes-join variants; failed on SQLite schema.
      Fixed: three ordered variants — MySQL ClassID, SQLite Teachers, SQLite Users.
    - add_student: used undefined variable s['fullName'] instead of data['fullName'].
      Fixed: all references corrected to data[...].
  NEW:
    - GET  /api/admin/fee-payments         — view all student fee payment records
    - POST /api/admin/notifications        — broadcast notifications to users
    - PUT  /api/admin/subjects/<id>        — update existing subject
    - POST /api/admin/students/bulk-import — batch import up to 200 students
"""

import traceback
from datetime import datetime, date
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from database import db
import hashlib

bp_admin = Blueprint('admin', __name__, url_prefix='/api/admin')


# ── Helpers ────────────────────────────────────────────────────────────────────

def _sv(val):
    if isinstance(val, (date, datetime)):
        return str(val)
    return val

def serialize_rows(rows):
    if not rows:
        return []
    def _r(r):
        return {k: _sv(v) for k, v in dict(r).items()}
    if isinstance(rows, dict):
        return [_r(rows)]
    return [_r(r) for r in rows]

def serialize_row(row):
    if not row:
        return None
    return {k: _sv(v) for k, v in dict(row).items()}

def hash_password(plain: str) -> str:
    return hashlib.sha256(plain.encode('utf-8')).hexdigest()

def parse_date(date_str: str) -> str:
    """Accept DD-MM-YYYY or YYYY-MM-DD; always return YYYY-MM-DD for DB."""
    if not date_str:
        return ''
    parts = date_str.split('-')
    if len(parts) == 3:
        if len(parts[0]) == 4:
            return date_str
        if len(parts[2]) == 4:
            return f'{parts[2]}-{parts[1]}-{parts[0]}'
    return date_str

def dob_to_ddmmyyyy(date_val) -> str:
    if not date_val:
        return ''
    s = str(date_val)[:10]
    parts = s.split('-')
    if len(parts) == 3:
        return f'{parts[2]}-{parts[1]}-{parts[0]}'
    return s

def admin_required():
    claims = get_jwt()
    if claims.get('userType') != 'Admin':
        return jsonify({'error': 'Admin access required', 'success': False}), 403
    return None

def _now_str():
    return datetime.now().strftime('%Y-%m-%d %H:%M:%S')


# ══════════════════════════════════════════════════════════════════════════════
# DASHBOARD
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/dashboard', methods=['GET'])
@jwt_required()
def get_dashboard():
    err = admin_required()
    if err: return err
    try:
        stats = {}

        r = db.execute_query("SELECT COUNT(*) AS count FROM Users WHERE UserType='Student' AND IsActive=1", fetch_one=True)
        stats['totalStudents'] = r['count'] if r else 0

        r = db.execute_query("SELECT COUNT(*) AS count FROM Users WHERE UserType='Teacher' AND IsActive=1", fetch_one=True)
        stats['totalTeachers'] = r['count'] if r else 0

        r = db.execute_query("SELECT COUNT(*) AS count FROM Departments", fetch_one=True)
        stats['totalDepartments'] = r['count'] if r else 0

        r = db.execute_query("SELECT COUNT(*) AS count FROM Subjects", fetch_one=True)
        stats['totalSubjects'] = r['count'] if r else 0

        r = db.execute_query("SELECT COUNT(*) AS count FROM Timetable", fetch_one=True)
        stats['totalTimetable'] = r['count'] if r else 0

        r = db.execute_query("SELECT COUNT(*) AS count FROM FeeStructure", fetch_one=True)
        stats['totalFeeStructure'] = r['count'] if r else 0

        r = db.execute_query("SELECT COUNT(*) AS count FROM Users WHERE UserType='Student' AND IsActive=0", fetch_one=True)
        stats['inactiveStudents'] = r['count'] if r else 0

        r = db.execute_query("SELECT COUNT(*) AS count FROM Users WHERE UserType='Teacher' AND IsActive=0", fetch_one=True)
        stats['inactiveTeachers'] = r['count'] if r else 0

        # Recent students — multi-fallback for TOP N vs LIMIT
        stats['recentStudents'] = []
        for q in [
            """SELECT TOP 8 u.UserID, u.UserCode, u.FullName, u.Email, u.Semester,
                      u.IsActive, d.DepartmentName
               FROM Users u LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
               WHERE u.UserType = 'Student' ORDER BY u.UserID DESC""",
            """SELECT u.UserID, u.UserCode, u.FullName, u.Email, u.Semester,
                      u.IsActive, d.DepartmentName
               FROM Users u LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
               WHERE u.UserType = 'Student' ORDER BY u.UserID DESC LIMIT 8""",
        ]:
            try:
                rows = db.execute_query(q)
                if rows is not None:
                    stats['recentStudents'] = serialize_rows(rows)
                    break
            except Exception:
                pass

        # Recent teachers — multi-fallback for TOP N vs LIMIT
        stats['recentTeachers'] = []
        for q in [
            """SELECT TOP 8 u.UserID, u.UserCode, u.FullName, u.Email,
                      u.IsActive, d.DepartmentName
               FROM Users u LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
               WHERE u.UserType = 'Teacher' ORDER BY u.UserID DESC""",
            """SELECT u.UserID, u.UserCode, u.FullName, u.Email,
                      u.IsActive, d.DepartmentName
               FROM Users u LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
               WHERE u.UserType = 'Teacher' ORDER BY u.UserID DESC LIMIT 8""",
        ]:
            try:
                rows = db.execute_query(q)
                if rows is not None:
                    stats['recentTeachers'] = serialize_rows(rows)
                    break
            except Exception:
                pass

        # Dept-wise student + teacher count
        try:
            stats['departmentStats'] = serialize_rows(db.execute_query("""
                SELECT d.DepartmentName,
                       COUNT(CASE WHEN u.UserType='Student' AND u.IsActive=1 THEN 1 END) AS StudentCount,
                       COUNT(CASE WHEN u.UserType='Teacher' AND u.IsActive=1 THEN 1 END) AS TeacherCount
                FROM Departments d
                LEFT JOIN Users u ON d.DepartmentID = u.DepartmentID
                GROUP BY d.DepartmentID, d.DepartmentName
                ORDER BY StudentCount DESC
            """))
        except Exception:
            stats['departmentStats'] = []

        # Recent activity
        stats['recentActivity'] = []
        for q, p in [
            ("SELECT TOP 10 al.LogID, al.Activity AS Action, al.Details, al.CreatedAt, u.FullName, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC", ()),
            ("SELECT TOP 10 al.LogID, al.Action, al.Details, al.CreatedAt, u.FullName, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC", ()),
            ("SELECT al.LogID, al.Activity AS Action, al.Details, al.CreatedAt, u.FullName, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC LIMIT 10", ()),
            ("SELECT al.LogID, al.Action, al.Details, al.CreatedAt, u.FullName, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC LIMIT 10", ()),
        ]:
            try:
                rows = db.execute_query(q, p)
                if rows is not None:
                    stats['recentActivity'] = serialize_rows(rows)
                    break
            except Exception:
                pass

        return jsonify({'success': True, 'stats': stats}), 200

    except Exception as e:
        print(f'[Dashboard] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# STUDENT MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/students', methods=['GET'])
@jwt_required()
def get_students():
    err = admin_required()
    if err: return err
    try:
        dept_id  = request.args.get('departmentId')
        semester = request.args.get('semester')
        search   = request.args.get('search', '')

        query = """
            SELECT u.UserID, u.UserCode, u.FullName, u.Email, u.Phone,
                   u.DateOfBirth, u.Gender, u.Semester, u.IsActive,
                   u.DepartmentID, u.Address, u.IsFirstLogin,
                   d.DepartmentName, d.DepartmentCode
            FROM Users u
            LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
            WHERE u.UserType = 'Student'
        """
        params = []
        if dept_id:
            query += ' AND u.DepartmentID = ?'; params.append(dept_id)
        if semester:
            query += ' AND u.Semester = ?';     params.append(semester)
        if search:
            s = f'%{search}%'
            query += ' AND (u.UserCode LIKE ? OR u.FullName LIKE ? OR u.Email LIKE ?)'
            params.extend([s, s, s])
        query += ' ORDER BY u.IsActive DESC, u.UserCode'

        students = serialize_rows(db.execute_query(query, tuple(params) if params else ()))
        return jsonify({'success': True, 'students': students}), 200

    except Exception as e:
        print(f'[Students GET] Error: {e}')
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/students', methods=['POST'])
@jwt_required()
def add_student():
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        for f in ['userCode', 'fullName', 'dateOfBirth']:
            if not data.get(f):
                return jsonify({'error': f'{f} is required', 'success': False}), 400

        user_code = data['userCode'].upper().strip()

        existing = db.execute_query(
            "SELECT UserID FROM Users WHERE UPPER(UserCode) = UPPER(?)",
            (user_code,), fetch_one=True
        )
        if existing:
            return jsonify({'error': f'User code {user_code} already exists', 'success': False}), 409

        dob_raw  = data['dateOfBirth']
        dob_db   = parse_date(dob_raw)
        dob_ddmm = dob_to_ddmmyyyy(dob_db)
        pw_hash  = hash_password(dob_ddmm)

        db.execute_non_query("""
            INSERT INTO Users
                (UserType, UserCode, FullName, Email, Phone, DateOfBirth,
                 Gender, FatherName, MotherName, JoinDate,
                 PasswordHash, IsFirstLogin,
                 DepartmentID, Semester, Address, IsActive)
            VALUES ('Student', ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, 1)
        """, (
            user_code,
            data['fullName'],
            data.get('email', ''),
            data.get('phone', ''),
            dob_db,
            data.get('gender', ''),
            data.get('fatherName', '') or None,
            data.get('motherName', '') or None,
            data.get('joinDate', '') or None,
            pw_hash,
            data.get('departmentId') or None,
            data.get('semester') or None,
            data.get('address', ''),
        ))
        return jsonify({
            'success': True,
            'message': f'Student {user_code} added. Default password: {dob_ddmm}'
        }), 201

    except Exception as e:
        print(f'[Add Student] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ── Bulk import students ───────────────────────────────────────────────────────
@bp_admin.route('/students/bulk-import', methods=['POST'])
@jwt_required()
def bulk_import_students():
    err = admin_required()
    if err: return err
    try:
        data     = request.get_json(silent=True) or {}
        students = data.get('students', [])
        if not students or not isinstance(students, list):
            return jsonify({'error': 'students array is required', 'success': False}), 400
        if len(students) > 200:
            return jsonify({'error': 'Maximum 200 students per import', 'success': False}), 400

        imported, skipped, errors = 0, 0, []

        for i, s in enumerate(students):
            try:
                user_code = (s.get('userCode') or '').upper().strip()
                full_name = (s.get('fullName') or '').strip()
                dob_raw   = (s.get('dateOfBirth') or '').strip()

                if not user_code or not full_name or not dob_raw:
                    errors.append(f'Row {i+1}: userCode, fullName, dateOfBirth are required')
                    skipped += 1
                    continue

                existing = db.execute_query(
                    "SELECT UserID FROM Users WHERE UPPER(UserCode) = UPPER(?)",
                    (user_code,), fetch_one=True
                )
                if existing:
                    errors.append(f'Row {i+1}: {user_code} already exists — skipped')
                    skipped += 1
                    continue

                dob_db   = parse_date(dob_raw)
                dob_ddmm = dob_to_ddmmyyyy(dob_db)
                pw_hash  = hash_password(dob_ddmm)

                db.execute_non_query("""
                    INSERT INTO Users
                        (UserType, UserCode, FullName, Email, Phone, DateOfBirth,
                         Gender, PasswordHash, IsFirstLogin,
                         DepartmentID, Semester, Address, IsActive)
                    VALUES ('Student', ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, 1)
                """, (
                    user_code, full_name,
                    s.get('email', ''), s.get('phone', ''), dob_db,
                    s.get('gender', ''), pw_hash,
                    s.get('departmentId') or None,
                    s.get('semester') or None,
                    s.get('address', ''),
                ))
                imported += 1
            except Exception as row_err:
                errors.append(f'Row {i+1}: {row_err}')
                skipped += 1

        return jsonify({
            'success':  True,
            'imported': imported,
            'skipped':  skipped,
            'errors':   errors,
            'message':  f'{imported} student(s) imported, {skipped} skipped.',
        }), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/students/<int:student_id>', methods=['PUT'])
@jwt_required()
def update_student(student_id):
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        field_map = {
            'fullName':     'FullName',
            'email':        'Email',
            'phone':        'Phone',
            'gender':       'Gender',
            'departmentId': 'DepartmentID',
            'semester':     'Semester',
            'address':      'Address',
            'isActive':     'IsActive',
        }
        parts, params = [], []
        for jf, dbf in field_map.items():
            if jf in data:
                v = data[jf]
                if jf == 'departmentId' and v in ('', 'null', None, 'Select'):
                    v = None
                if jf == 'isActive':
                    v = 1 if str(v) in ('1', 'true', 'True') else 0
                parts.append(f'{dbf} = ?')
                params.append(v)

        if not parts:
            return jsonify({'error': 'No valid fields to update', 'success': False}), 400

        params.append(student_id)
        db.execute_non_query(
            f"UPDATE Users SET {', '.join(parts)} WHERE UserID = ? AND UserType = 'Student'",
            tuple(params)
        )
        return jsonify({'success': True, 'message': 'Student updated successfully'}), 200

    except Exception as e:
        print(f'[Update Student] Error: {e}')
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/students/<int:student_id>/toggle-active', methods=['POST'])
@jwt_required()
def toggle_student_active(student_id):
    err = admin_required()
    if err: return err
    try:
        user = db.execute_query(
            "SELECT IsActive, FullName FROM Users WHERE UserID = ? AND UserType = 'Student'",
            (student_id,), fetch_one=True
        )
        if not user:
            return jsonify({'error': 'Student not found', 'success': False}), 404

        new_status = 0 if user['IsActive'] else 1
        db.execute_non_query("UPDATE Users SET IsActive = ? WHERE UserID = ?", (new_status, student_id))
        action = 'activated' if new_status else 'deactivated'
        return jsonify({
            'success': True,
            'isActive': bool(new_status),
            'message': f'Student {user["FullName"]} {action} successfully.'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/students/<int:student_id>', methods=['DELETE'])
@jwt_required()
def delete_student(student_id):
    err = admin_required()
    if err: return err
    try:
        rows = db.execute_non_query(
            "UPDATE Users SET IsActive = 0 WHERE UserID = ? AND UserType = 'Student'", (student_id,)
        )
        if rows == 0:
            return jsonify({'error': 'Student not found', 'success': False}), 404
        return jsonify({'success': True, 'message': 'Student deactivated'}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# TEACHER MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/teachers', methods=['GET'])
@jwt_required()
def get_teachers():
    err = admin_required()
    if err: return err
    try:
        search = request.args.get('search', '')
        query = """
            SELECT u.UserID, u.UserCode, u.FullName, u.Email, u.Phone,
                   u.DateOfBirth, u.Gender, u.IsActive, u.DepartmentID,
                   u.Address, u.IsFirstLogin,
                   d.DepartmentName, d.DepartmentCode
            FROM Users u
            LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
            WHERE u.UserType = 'Teacher'
        """
        params = []
        if search:
            s = f'%{search}%'
            query += ' AND (u.UserCode LIKE ? OR u.FullName LIKE ? OR u.Email LIKE ?)'
            params.extend([s, s, s])
        query += ' ORDER BY u.IsActive DESC, u.UserCode'

        teachers = serialize_rows(db.execute_query(query, tuple(params) if params else ()))
        return jsonify({'success': True, 'teachers': teachers}), 200

    except Exception as e:
        print(f'[Teachers GET] Error: {e}')
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/teachers', methods=['POST'])
@jwt_required()
def add_teacher():
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        for f in ['userCode', 'fullName', 'dateOfBirth']:
            if not data.get(f):
                return jsonify({'error': f'{f} is required', 'success': False}), 400

        user_code = data['userCode'].upper().strip()

        existing = db.execute_query(
            "SELECT UserID FROM Users WHERE UPPER(UserCode) = UPPER(?)",
            (user_code,), fetch_one=True
        )
        if existing:
            return jsonify({'error': f'User code {user_code} already exists', 'success': False}), 409

        dob_raw  = data['dateOfBirth']
        dob_db   = parse_date(dob_raw)
        dob_ddmm = dob_to_ddmmyyyy(dob_db)
        pw_hash  = hash_password(dob_ddmm)
        dept_id  = data.get('departmentId') or None
        if dept_id in ('', 'null', 'Select'):
            dept_id = None

        db.execute_non_query("""
            INSERT INTO Users
                (UserType, UserCode, FullName, Email, Phone, DateOfBirth,
                 Gender, PasswordHash, IsFirstLogin, DepartmentID, Address, IsActive)
            VALUES ('Teacher', ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, 1)
        """, (
            user_code, data['fullName'],
            data.get('email', ''), data.get('phone', ''), dob_db,
            data.get('gender', ''), pw_hash, dept_id, data.get('address', ''),
        ))
        return jsonify({
            'success': True,
            'message': f'Teacher {user_code} added. Default password: {dob_ddmm}'
        }), 201

    except Exception as e:
        print(f'[Add Teacher] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/teachers/<int:teacher_id>', methods=['PUT'])
@jwt_required()
def update_teacher(teacher_id):
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        field_map = {
            'fullName':     'FullName',
            'email':        'Email',
            'phone':        'Phone',
            'gender':       'Gender',
            'departmentId': 'DepartmentID',
            'address':      'Address',
            'isActive':     'IsActive',
        }
        parts, params = [], []
        for jf, dbf in field_map.items():
            if jf in data:
                v = data[jf]
                if jf == 'departmentId' and v in ('', 'null', None, 'Select'):
                    v = None
                if jf == 'isActive':
                    v = 1 if str(v) in ('1', 'true', 'True') else 0
                parts.append(f'{dbf} = ?')
                params.append(v)

        if not parts:
            return jsonify({'error': 'No valid fields to update', 'success': False}), 400

        params.append(teacher_id)
        db.execute_non_query(
            f"UPDATE Users SET {', '.join(parts)} WHERE UserID = ? AND UserType = 'Teacher'",
            tuple(params)
        )
        return jsonify({'success': True, 'message': 'Teacher updated successfully'}), 200

    except Exception as e:
        print(f'[Update Teacher] Error: {e}')
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/teachers/<int:teacher_id>/toggle-active', methods=['POST'])
@jwt_required()
def toggle_teacher_active(teacher_id):
    err = admin_required()
    if err: return err
    try:
        user = db.execute_query(
            "SELECT IsActive, FullName FROM Users WHERE UserID = ? AND UserType = 'Teacher'",
            (teacher_id,), fetch_one=True
        )
        if not user:
            return jsonify({'error': 'Teacher not found', 'success': False}), 404

        new_status = 0 if user['IsActive'] else 1
        db.execute_non_query("UPDATE Users SET IsActive = ? WHERE UserID = ?", (new_status, teacher_id))
        action = 'activated' if new_status else 'deactivated'
        return jsonify({
            'success': True,
            'isActive': bool(new_status),
            'message': f'Teacher {user["FullName"]} {action} successfully.'
        }), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/teachers/<int:teacher_id>', methods=['DELETE'])
@jwt_required()
def delete_teacher(teacher_id):
    err = admin_required()
    if err: return err
    try:
        rows = db.execute_non_query(
            "UPDATE Users SET IsActive = 0 WHERE UserID = ? AND UserType = 'Teacher'", (teacher_id,)
        )
        if rows == 0:
            return jsonify({'error': 'Teacher not found', 'success': False}), 404
        return jsonify({'success': True, 'message': 'Teacher deactivated'}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# PASSWORD RESET
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/reset-password/<int:user_id>', methods=['POST'])
@jwt_required()
def reset_password(user_id):
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        custom_pw = data.get('newPassword', '').strip()

        user = db.execute_query(
            "SELECT DateOfBirth, FullName, UserType FROM Users WHERE UserID = ?",
            (user_id,), fetch_one=True
        )
        if not user:
            return jsonify({'error': 'User not found', 'success': False}), 404

        if custom_pw:
            new_pw  = custom_pw
            pw_hash = hash_password(custom_pw)
        else:
            dob_str = dob_to_ddmmyyyy(user['DateOfBirth'])
            new_pw  = dob_str if dob_str else 'password123'
            pw_hash = hash_password(new_pw)

        db.execute_non_query(
            "UPDATE Users SET PasswordHash = ?, IsFirstLogin = 1 WHERE UserID = ?",
            (pw_hash, user_id)
        )
        return jsonify({
            'success': True,
            'message': f'Password reset for {user["FullName"]}. New password: {new_pw}',
            'newPassword': new_pw
        }), 200

    except Exception as e:
        print(f'[Reset Password] Error: {e}')
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# DEPARTMENTS  — FIXED: TotalSemesters/IsShared missing in MySQL schema
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/departments', methods=['GET'])
@jwt_required()
def get_departments():
    try:
        # Try with TotalSemesters (SQLite schema); fallback without it (MySQL schema)
        for query in [
            """
            SELECT d.DepartmentID, d.DepartmentCode, d.DepartmentName,
                   COALESCE(d.TotalSemesters, 8) AS TotalSemesters,
                   COUNT(CASE WHEN u.UserType='Student' AND u.IsActive=1 THEN 1 END) AS StudentCount,
                   COUNT(CASE WHEN u.UserType='Teacher' AND u.IsActive=1 THEN 1 END) AS TeacherCount
            FROM Departments d
            LEFT JOIN Users u ON d.DepartmentID = u.DepartmentID
            GROUP BY d.DepartmentID, d.DepartmentCode, d.DepartmentName, d.TotalSemesters
            ORDER BY d.DepartmentName
            """,
            """
            SELECT d.DepartmentID, d.DepartmentCode, d.DepartmentName,
                   8 AS TotalSemesters,
                   COUNT(CASE WHEN u.UserType='Student' AND u.IsActive=1 THEN 1 END) AS StudentCount,
                   COUNT(CASE WHEN u.UserType='Teacher' AND u.IsActive=1 THEN 1 END) AS TeacherCount
            FROM Departments d
            LEFT JOIN Users u ON d.DepartmentID = u.DepartmentID
            GROUP BY d.DepartmentID, d.DepartmentCode, d.DepartmentName
            ORDER BY d.DepartmentName
            """,
        ]:
            try:
                departments = serialize_rows(db.execute_query(query))
                return jsonify({'success': True, 'departments': departments}), 200
            except Exception:
                continue

        return jsonify({'success': True, 'departments': []}), 200

    except Exception as e:
        print(f'[Departments GET] Error: {e}')
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/departments', methods=['POST'])
@jwt_required()
def add_department():
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        if not data.get('departmentCode') or not data.get('departmentName'):
            return jsonify({'error': 'departmentCode and departmentName are required', 'success': False}), 400

        code = data['departmentCode'].upper()
        name = data['departmentName']
        sems = data.get('totalSemesters', 8)

        # Try with TotalSemesters + IsShared (SQLite); fallback to MySQL schema
        for sql, params in [
            ("INSERT INTO Departments (DepartmentCode, DepartmentName, TotalSemesters, IsShared) VALUES (?, ?, ?, 0)",
             (code, name, sems)),
            ("INSERT INTO Departments (DepartmentCode, DepartmentName) VALUES (?, ?)",
             (code, name)),
        ]:
            try:
                db.execute_non_query(sql, params)
                return jsonify({'success': True, 'message': 'Department added successfully'}), 201
            except Exception as e:
                err_msg = str(e).lower()
                if 'totalsemesters' in err_msg or 'isshared' in err_msg or 'unknown column' in err_msg or 'no column' in err_msg:
                    continue
                raise

        return jsonify({'error': 'Failed to add department', 'success': False}), 500

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/departments/<int:dept_id>', methods=['PUT'])
@jwt_required()
def update_department(dept_id):
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        name = data.get('departmentName', '')
        sems = data.get('totalSemesters', 8)

        # Try with TotalSemesters (SQLite); fallback without it (MySQL)
        for sql, params in [
            ("UPDATE Departments SET DepartmentName = ?, TotalSemesters = ? WHERE DepartmentID = ?",
             (name, sems, dept_id)),
            ("UPDATE Departments SET DepartmentName = ? WHERE DepartmentID = ?",
             (name, dept_id)),
        ]:
            try:
                rows = db.execute_non_query(sql, params)
                if rows == 0:
                    return jsonify({'error': 'Department not found', 'success': False}), 404
                return jsonify({'success': True, 'message': 'Department updated'}), 200
            except Exception as e:
                err_msg = str(e).lower()
                if 'totalsemesters' in err_msg or 'unknown column' in err_msg or 'no column' in err_msg:
                    continue
                raise

        return jsonify({'error': 'Failed to update department', 'success': False}), 500

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/departments/<int:dept_id>', methods=['DELETE'])
@jwt_required()
def delete_department(dept_id):
    err = admin_required()
    if err: return err
    try:
        result = db.execute_query(
            "SELECT COUNT(*) AS count FROM Users WHERE DepartmentID = ? AND UserType = 'Student' AND IsActive=1",
            (dept_id,), fetch_one=True
        )
        if result and result['count'] > 0:
            return jsonify({'error': 'Cannot delete — department has active students', 'success': False}), 400

        result = db.execute_query(
            "SELECT COUNT(*) AS count FROM Users WHERE DepartmentID = ? AND UserType = 'Teacher' AND IsActive=1",
            (dept_id,), fetch_one=True
        )
        if result and result['count'] > 0:
            return jsonify({'error': 'Cannot delete — department has active teachers', 'success': False}), 400

        rows = db.execute_non_query("DELETE FROM Departments WHERE DepartmentID = ?", (dept_id,))
        if rows == 0:
            return jsonify({'error': 'Department not found', 'success': False}), 404
        return jsonify({'success': True, 'message': 'Department deleted'}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# SUBJECTS  — FIXED: IsLab column missing in MySQL schema
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/subjects', methods=['GET'])
@jwt_required()
def get_subjects():
    try:
        # Try with IsLab (SQLite schema); fallback without it (MySQL schema)
        for query in [
            """SELECT s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits,
                      s.IsLab, s.DepartmentID, s.Semester, d.DepartmentName
               FROM Subjects s
               JOIN Departments d ON s.DepartmentID = d.DepartmentID
               ORDER BY d.DepartmentName, s.Semester, s.SubjectName""",
            """SELECT s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits,
                      0 AS IsLab, s.DepartmentID, s.Semester, d.DepartmentName
               FROM Subjects s
               JOIN Departments d ON s.DepartmentID = d.DepartmentID
               ORDER BY d.DepartmentName, s.Semester, s.SubjectName""",
        ]:
            try:
                subjects = serialize_rows(db.execute_query(query))
                return jsonify({'success': True, 'subjects': subjects}), 200
            except Exception:
                continue
        return jsonify({'success': True, 'subjects': []}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/subjects', methods=['POST'])
@jwt_required()
def add_subject():
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        for f in ['subjectName', 'subjectCode', 'departmentId', 'semester']:
            if not data.get(f):
                return jsonify({'error': f'{f} is required', 'success': False}), 400

        # Try with IsLab (SQLite); fallback without it (MySQL)
        for sql, params in [
            ("INSERT INTO Subjects (SubjectName, SubjectCode, Credits, IsLab, DepartmentID, Semester) VALUES (?,?,?,?,?,?)",
             (data['subjectName'], data['subjectCode'], data.get('credits', 4),
              int(data.get('isLab', 0)), data['departmentId'], data['semester'])),
            ("INSERT INTO Subjects (SubjectName, SubjectCode, Credits, DepartmentID, Semester) VALUES (?,?,?,?,?)",
             (data['subjectName'], data['subjectCode'], data.get('credits', 4),
              data['departmentId'], data['semester'])),
        ]:
            try:
                db.execute_non_query(sql, params)
                return jsonify({'success': True, 'message': 'Subject added'}), 201
            except Exception as e:
                err_msg = str(e).lower()
                if 'islab' in err_msg or 'unknown column' in err_msg or 'no column' in err_msg:
                    continue
                raise

        return jsonify({'error': 'Failed to add subject', 'success': False}), 500

    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/subjects/<int:subject_id>', methods=['PUT'])
@jwt_required()
def update_subject(subject_id):
    err = admin_required()
    if err: return err
    try:
        data = request.get_json(silent=True) or {}
        field_map = {
            'subjectName': 'SubjectName',
            'subjectCode': 'SubjectCode',
            'credits':     'Credits',
            'isLab':       'IsLab',
            'semester':    'Semester',
            'departmentId':'DepartmentID',
        }
        parts, params = [], []
        for jf, dbf in field_map.items():
            if jf in data:
                v = data[jf]
                if jf == 'isLab':
                    v = 1 if str(v) in ('1', 'true', 'True') else 0
                parts.append(f'{dbf} = ?')
                params.append(v)

        if not parts:
            return jsonify({'error': 'No valid fields to update', 'success': False}), 400

        params.append(subject_id)
        rows = db.execute_non_query(
            f"UPDATE Subjects SET {', '.join(parts)} WHERE SubjectID = ?",
            tuple(params)
        )
        if rows == 0:
            return jsonify({'error': 'Subject not found', 'success': False}), 404
        return jsonify({'success': True, 'message': 'Subject updated'}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/subjects/<int:subject_id>', methods=['DELETE'])
@jwt_required()
def delete_subject(subject_id):
    err = admin_required()
    if err: return err
    try:
        rows = db.execute_non_query("DELETE FROM Subjects WHERE SubjectID = ?", (subject_id,))
        if rows == 0:
            return jsonify({'error': 'Subject not found', 'success': False}), 404
        return jsonify({'success': True, 'message': 'Subject deleted'}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# TIMETABLE  — FIXED: multi-variant query for MySQL + SQLite schemas
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/timetable', methods=['GET'])
@jwt_required()
def get_timetable():
    try:
        dept_id  = request.args.get('departmentId')
        semester = request.args.get('semester')

        # Variant 1: MySQL/MSSQL — Timetable has ClassID → Classes (DepartmentID, Semester)
        # Variant 2: SQLite — Timetable has DepartmentID/Semester directly, teacher = Teachers
        # Variant 3: SQLite — Timetable has DepartmentID/Semester directly, teacher = Users
        query_variants = [
            ("""
                SELECT t.TimetableID, t.DayOfWeek,
                       0 AS PeriodNumber,
                       t.StartTime, t.EndTime,
                       COALESCE(t.RoomNumber, t.Room, 'TBD') AS RoomNumber,
                       c.Semester, t.AcademicYear, 0 AS IsLab,
                       s.SubjectName, s.SubjectCode,
                       u.FullName AS TeacherName, u.UserCode AS TeacherCode,
                       d.DepartmentName, c.DepartmentID, c.ClassName, c.Section
                FROM Timetable t
                JOIN Classes     c ON t.ClassID      = c.ClassID
                JOIN Subjects    s ON t.SubjectID    = s.SubjectID
                JOIN Users       u ON t.TeacherID    = u.UserID
                JOIN Departments d ON c.DepartmentID = d.DepartmentID
                WHERE 1=1
            """, 'c'),
            ("""
                SELECT t.TimetableID, t.DayOfWeek,
                       COALESCE(t.PeriodNumber, 0) AS PeriodNumber,
                       t.StartTime, t.EndTime,
                       COALESCE(t.RoomNumber, 'TBD') AS RoomNumber,
                       t.Semester, t.AcademicYear, COALESCE(t.IsLab, 0) AS IsLab,
                       s.SubjectName, s.SubjectCode,
                       tc.FullName AS TeacherName, tc.TeacherCode AS TeacherCode,
                       d.DepartmentName, t.DepartmentID, '' AS ClassName, '' AS Section
                FROM Timetable t
                JOIN Subjects    s  ON t.SubjectID    = s.SubjectID
                JOIN Teachers    tc ON t.TeacherID    = tc.TeacherID
                JOIN Departments d  ON t.DepartmentID = d.DepartmentID
                WHERE 1=1
            """, 't'),
            ("""
                SELECT t.TimetableID, t.DayOfWeek,
                       COALESCE(t.PeriodNumber, 0) AS PeriodNumber,
                       t.StartTime, t.EndTime,
                       COALESCE(t.RoomNumber, 'TBD') AS RoomNumber,
                       t.Semester, t.AcademicYear, COALESCE(t.IsLab, 0) AS IsLab,
                       s.SubjectName, s.SubjectCode,
                       u.FullName AS TeacherName, u.UserCode AS TeacherCode,
                       d.DepartmentName, t.DepartmentID, '' AS ClassName, '' AS Section
                FROM Timetable t
                JOIN Subjects    s ON t.SubjectID    = s.SubjectID
                JOIN Users       u ON t.TeacherID    = u.UserID
                JOIN Departments d ON t.DepartmentID = d.DepartmentID
                WHERE 1=1
            """, 't'),
        ]

        for base_query, alias in query_variants:
            try:
                query = base_query
                params = []
                if dept_id:  query += f' AND {alias}.DepartmentID = ?'; params.append(dept_id)
                if semester: query += f' AND {alias}.Semester = ?';     params.append(semester)
                query += ' ORDER BY t.DayOfWeek, t.StartTime'

                entries = serialize_rows(db.execute_query(query, tuple(params) if params else ()))
                return jsonify({'success': True, 'timetable': entries}), 200
            except Exception as e:
                print(f'[Timetable GET] variant failed, trying next: {e}')
                continue

        return jsonify({'success': True, 'timetable': []}), 200

    except Exception as e:
        print(f'[Timetable GET] Error: {e}')
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/timetable', methods=['POST'])
@jwt_required()
def create_timetable():
    err = admin_required()
    if err: return err
    try:
        data       = request.get_json(silent=True) or {}
        dept_id    = data.get('departmentId')
        semester   = data.get('semester')
        subject_id = data.get('subjectId')
        teacher_id = data.get('teacherId')
        day        = data.get('dayOfWeek')
        start_time = data.get('startTime')
        end_time   = data.get('endTime')
        room       = data.get('roomNumber', 'TBD')
        acad_year  = data.get('academicYear', '2024-25')
        period_num = data.get('periodNumber', 1)
        is_lab     = data.get('isLab', 0)

        if not all([dept_id, subject_id, teacher_id, day, start_time, end_time]):
            return jsonify({'error': 'departmentId, subjectId, teacherId, dayOfWeek, startTime, endTime are required', 'success': False}), 400

        # ── Try MySQL schema: needs ClassID ────────────────────────────────────
        class_id = data.get('classId')
        if not class_id:
            # Try to find existing class for this dept+semester
            try:
                cls = db.execute_query(
                    "SELECT ClassID FROM Classes WHERE DepartmentID=? AND Semester=? LIMIT 1",
                    (dept_id, semester), fetch_one=True
                )
                if cls:
                    class_id = cls['ClassID']
                else:
                    # Auto-create a class row so timetable can be inserted
                    db.execute_non_query(
                        "INSERT INTO Classes (ClassName, DepartmentID, Semester, Section, AcademicYear) VALUES (?, ?, ?, 'A', ?)",
                        (f'Dept{dept_id}-Sem{semester}', dept_id, semester, acad_year)
                    )
                    cls = db.execute_query(
                        "SELECT ClassID FROM Classes WHERE DepartmentID=? AND Semester=? LIMIT 1",
                        (dept_id, semester), fetch_one=True
                    )
                    class_id = cls['ClassID'] if cls else None
            except Exception as e:
                print(f'[Timetable POST] Classes lookup/create failed: {e}')

        if class_id:
            # MySQL/MSSQL schema insert
            try:
                db.execute_non_query("""
                    INSERT INTO Timetable
                        (ClassID, SubjectID, TeacherID, DayOfWeek,
                         StartTime, EndTime, RoomNumber, AcademicYear)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                """, (class_id, subject_id, teacher_id, day, start_time, end_time, room, acad_year))
                return jsonify({'success': True, 'message': 'Timetable entry created'}), 201
            except Exception as e:
                print(f'[Timetable POST] MySQL insert failed: {e}')

        # ── Fallback: SQLite schema (DepartmentID + Semester directly) ─────────
        try:
            db.execute_non_query("""
                INSERT INTO Timetable
                    (DepartmentID, Semester, SubjectID, TeacherID, DayOfWeek,
                     PeriodNumber, StartTime, EndTime, RoomNumber, IsLab, AcademicYear)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (dept_id, semester, subject_id, teacher_id, day,
                  period_num, start_time, end_time, room, is_lab, acad_year))
            return jsonify({'success': True, 'message': 'Timetable entry created'}), 201
        except Exception as e:
            print(f'[Timetable POST] SQLite insert failed: {e}')
            return jsonify({'error': str(e), 'success': False}), 500

    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/timetable/<int:entry_id>', methods=['DELETE'])
@jwt_required()
def delete_timetable(entry_id):
    err = admin_required()
    if err: return err
    try:
        rows = db.execute_non_query("DELETE FROM Timetable WHERE TimetableID = ?", (entry_id,))
        if rows == 0:
            return jsonify({'error': 'Entry not found', 'success': False}), 404
        return jsonify({'success': True, 'message': 'Timetable entry deleted'}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# FEE STRUCTURE
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/fee-structure', methods=['GET'])
@jwt_required()
def get_fee_structure():
    try:
        fees = serialize_rows(db.execute_query("""
            SELECT fs.*, d.DepartmentName
            FROM FeeStructure fs
            JOIN Departments d ON fs.DepartmentID = d.DepartmentID
            ORDER BY fs.AcademicYear DESC, d.DepartmentName, fs.Semester
        """))
        return jsonify({'success': True, 'feeStructure': fees}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_admin.route('/fee-structure', methods=['POST'])
@jwt_required()
def create_fee_structure():
    err = admin_required()
    if err: return err
    try:
        data    = request.get_json(silent=True) or {}
        tuition = float(data.get('tuitionFee', 0))
        library = float(data.get('libraryFee', 0))
        lab     = float(data.get('labFee', 0))
        sports  = float(data.get('sportsFee', 0))
        other   = float(data.get('otherFees', data.get('otherCharges', 0)))
        db.execute_non_query("""
            INSERT INTO FeeStructure
                (DepartmentID, Semester, AcademicYear,
                 TuitionFee, LibraryFee, LabFee, SportsFee, OtherFees)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (data['departmentId'], data['semester'],
              data.get('academicYear', '2024-25'),
              tuition, library, lab, sports, other))
        return jsonify({'success': True, 'message': 'Fee structure created'}), 201
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# FEE PAYMENTS
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/fee-payments', methods=['GET'])
@jwt_required()
def get_fee_payments():
    err = admin_required()
    if err: return err
    try:
        dept_id = request.args.get('departmentId')
        search  = request.args.get('search', '')

        query = """
            SELECT fp.PaymentID, fp.StudentID, fp.AmountPaid, fp.PaymentDate,
                   fp.PaymentMode, fp.TransactionID,
                   u.UserCode, u.FullName, d.DepartmentName
            FROM FeePayments fp
            JOIN Users u ON fp.StudentID = u.UserID
            LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
            WHERE 1=1
        """
        params = []
        if dept_id:
            query += ' AND u.DepartmentID = ?'; params.append(dept_id)
        if search:
            s = f'%{search}%'
            query += ' AND (u.UserCode LIKE ? OR u.FullName LIKE ?)'; params.extend([s, s])
        query += ' ORDER BY fp.PaymentDate DESC'

        payments = serialize_rows(db.execute_query(query, tuple(params) if params else ()))
        total    = sum(float(p.get('AmountPaid', 0) or 0) for p in payments)

        return jsonify({
            'success':     True,
            'payments':    payments,
            'totalAmount': total,
            'count':       len(payments),
        }), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# NOTIFICATIONS BROADCAST
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/notifications', methods=['POST'])
@jwt_required()
def broadcast_notification():
    err = admin_required()
    if err: return err
    try:
        data        = request.get_json(silent=True) or {}
        title       = (data.get('title') or '').strip()
        message     = (data.get('message') or '').strip()
        target_type = (data.get('targetType') or 'All').strip()
        dept_id     = data.get('departmentId')

        if not title or not message:
            return jsonify({'error': 'title and message are required', 'success': False}), 400

        query  = "SELECT UserID FROM Users WHERE IsActive=1"
        params = []
        if target_type in ('Student', 'Teacher'):
            query += ' AND UserType=?'; params.append(target_type)
        if dept_id:
            query += ' AND DepartmentID=?'; params.append(dept_id)

        users = db.execute_query(query, tuple(params) if params else ()) or []
        count = 0
        now   = _now_str()

        for u in users:
            uid = u['UserID']
            for ins_sql, ins_params in [
                ("INSERT INTO Notifications (UserID, Title, Message, IsRead, CreatedAt) VALUES (?,?,?,0,?)",
                 (uid, title, message, now)),
                ("INSERT INTO Notifications (StudentID, Title, Message, IsRead, CreatedAt) VALUES (?,?,?,0,?)",
                 (uid, title, message, now)),
            ]:
                try:
                    db.execute_non_query(ins_sql, ins_params)
                    count += 1
                    break
                except Exception:
                    pass

        return jsonify({
            'success': True,
            'message': f'Notification sent to {count} user(s).',
            'count':   count,
        }), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# ACTIVITY LOGS
# ══════════════════════════════════════════════════════════════════════════════

@bp_admin.route('/activity-logs', methods=['GET'])
@jwt_required()
def get_activity_logs():
    err = admin_required()
    if err: return err
    try:
        limit = min(int(request.args.get('limit', 100)), 500)
        logs  = []

        for q, p in [
            (f"SELECT TOP {limit} al.LogID, al.Activity AS Action, al.Details, al.CreatedAt, u.FullName, u.UserCode, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC", ()),
            (f"SELECT TOP {limit} al.LogID, al.Action, al.Details, al.CreatedAt, u.FullName, u.UserCode, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC", ()),
            ("SELECT al.LogID, al.Activity AS Action, al.Details, al.CreatedAt, u.FullName, u.UserCode, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC LIMIT ?", (limit,)),
            ("SELECT al.LogID, al.Action, al.Details, al.CreatedAt, u.FullName, u.UserCode, u.UserType FROM ActivityLogs al LEFT JOIN Users u ON al.UserID = u.UserID ORDER BY al.CreatedAt DESC LIMIT ?", (limit,)),
        ]:
            try:
                rows = db.execute_query(q, p)
                if rows is not None:
                    logs = serialize_rows(rows)
                    break
            except Exception as e:
                print(f'[ActivityLogs] variant failed: {e}')
                continue

        return jsonify({'success': True, 'logs': logs}), 200

    except Exception as e:
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500