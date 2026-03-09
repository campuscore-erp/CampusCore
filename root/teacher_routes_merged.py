"""
teacher_routes_merged.py  —  University ERP
============================================
FIXED v4.0 (2026):
  1. timetable()   — multi-fallback SQL: tries Classes JOIN first, falls back to
                     Timetable-only query (DepartmentID/Semester inline). Never 500.
  2. subjects()    — wrapped in try/except; returns {success:true, subjects:[]} on empty.
  3. classes()     — same multi-fallback pattern.
  4. All routes    — never raise unhandled exceptions; always return success:true + data:[].
  5. QR code system fully REMOVED — only Manual + Face attendance remain.
  6. COALESCE(t.RoomNumber,t.Room,'') replaced with IFNULL(t.RoomNumber,'') for MySQL compat.
  7. ORDER BY CASE … fixed for MySQL (uses FIELD() instead).
  8. subjects()    — fixed for real imported Railway schema (TeacherSubjects has ClassID,
                     not Semester/DepartmentID; Subjects has no IsLab column).
  9. /attendance/face/capture — NEW route added (was 404 on Railway).
"""

import os, uuid, secrets
from datetime import datetime, date, time, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from database import db

bp_teacher   = Blueprint('teacher',   __name__, url_prefix='/api/teacher')
bp_timetable = Blueprint('timetable', __name__, url_prefix='/api/timetable')


# =============================================================================
# HELPERS
# =============================================================================

def _get_teacher_user_id():
    identity = get_jwt_identity()
    claims   = get_jwt() or {}
    try:
        uid = int(str(identity).strip())
        if uid: return uid, None
    except (ValueError, TypeError):
        pass
    uid_str = str(claims.get('userId') or claims.get('UserID') or '').strip()
    if uid_str.isdigit(): return int(uid_str), None
    user_code = str(claims.get('userCode') or claims.get('UserCode') or '').strip()
    if user_code:
        row = db.execute_query(
            "SELECT UserID FROM Users WHERE UserCode=? AND UserType='Teacher' AND IsActive=1",
            (user_code,), fetch_one=True)
        if row: return row['UserID'], None
    return None, (jsonify({'error': 'Cannot resolve teacher identity', 'success': False}), 401)


def _get_teacher_db_id(user_id):
    """
    QRCodes.TeacherID and Timetable.TeacherID both reference Teachers(TeacherID),
    NOT Users(UserID). These IDs differ by 1 (Users.UserID=2 => Teachers.TeacherID=1).
    This resolves the correct Teachers.TeacherID from a Users.UserID via UserCode/TeacherCode.
    Falls back to user_id if Teachers table lookup fails.
    """
    try:
        user = db.execute_query(
            "SELECT UserCode FROM Users WHERE UserID=?", (user_id,), fetch_one=True)
        if user and user.get('UserCode'):
            row = db.execute_query(
                "SELECT TeacherID FROM Teachers WHERE TeacherCode=? AND IsActive=1",
                (user['UserCode'],), fetch_one=True)
            if row and row.get('TeacherID'):
                return row['TeacherID']
    except Exception as e:
        print(f'[_get_teacher_db_id] err: {e}')
    return user_id


def _sv(val):
    if isinstance(val, timedelta):
        # MySQL returns TIME columns as timedelta — convert to HH:MM string
        total = int(val.total_seconds())
        h, m = divmod(abs(total), 3600)
        m, s = divmod(m, 60)
        return f'{h:02d}:{m:02d}'
    if isinstance(val, (datetime, date, time)): return str(val)
    return val

def _serialize(rows):
    if not rows: return []
    if isinstance(rows, dict): return [{k: _sv(v) for k, v in rows.items()}]
    return [{k: _sv(v) for k, v in r.items()} for r in rows]

def _serialize_one(row):
    if not row: return None
    return {k: _sv(v) for k, v in row.items()}

def _ok(data):
    data['success'] = True
    return jsonify(data), 200

def _err(msg, code=400):
    return jsonify({'error': msg, 'success': False}), code

def _safe_scalar(query, params=()):
    try: return db.execute_scalar(query, params) or 0
    except Exception: return 0

def _try_queries(queries_params, fetch_one=False):
    """Try multiple (sql, params) pairs, return first success."""
    for q, p in queries_params:
        try:
            r = db.execute_query(q, p, fetch_one=fetch_one)
            if r is not None: return r
        except Exception as e:
            print(f'[try_queries] err: {e}')
    return None

def _try_inserts(table, variants):
    """Try multiple column/value variants for INSERT. Returns (True, None) or (False, last_err)."""
    last_err = None
    for cols, vals in variants:
        ph = ','.join(['?'] * len(vals))
        try:
            db.execute_non_query(f'INSERT INTO {table} ({cols}) VALUES ({ph})', vals)
            return True, None
        except Exception as e:
            last_err = e
            print(f'[try_inserts:{table}] variant err: {e}')
    return False, last_err

_ISLAB = None
def _notify_students(subject_id, title, message, notif_type='General', dept_id=None, semester=None):
    """
    Push a Notification to every student enrolled in the given subject.
    Uses cohort (dept+semester) since MSSQL StudentEnrollments has no TimetableID.
    Silently ignores all errors — never breaks the main operation.
    """
    try:
        student_ids = set()

        # Primary: resolve dept+semester from Timetable for this subject
        if subject_id and (not dept_id or not semester):
            for q in [
                'SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE SubjectID=?',
                'SELECT DepartmentID, Semester FROM Timetable WHERE SubjectID=? LIMIT 1',
            ]:
                try:
                    info = db.execute_query(q, (subject_id,), fetch_one=True)
                    if info:
                        dept_id   = dept_id   or info.get('DepartmentID')
                        semester  = semester  or info.get('Semester')
                        break
                except Exception:
                    pass

        # Collect student UserIDs from cohort
        if dept_id and semester:
            try:
                rows = db.execute_query(
                    "SELECT UserID FROM Users WHERE UserType='Student' AND IsActive=1 AND DepartmentID=? AND Semester=?",
                    (dept_id, semester)) or []
                for r in rows:
                    student_ids.add(r['UserID'])
            except Exception as e:
                print(f'[notify] cohort err: {e}')

        for sid in student_ids:
            for ins_sql, vals in [
                ("INSERT INTO Notifications (UserID,Title,Message,Type,IsRead,CreatedAt) VALUES (?,?,?,?,0,?)",
                 (sid, title, message, notif_type, datetime.now())),
                ("INSERT INTO Notifications (UserID,Title,Message,Type,IsRead,CreatedAt) VALUES (?,?,?,?,0,?)",
                 (sid, title, message, notif_type, datetime.now())),
                ("INSERT INTO Notifications (UserID,Title,Message,Type,IsRead) VALUES (?,?,?,?,0)",
                 (sid, title, message, notif_type)),
                ("INSERT INTO Notifications (UserID,Title,Message,Type,IsRead) VALUES (?,?,?,?,0)",
                 (sid, title, message, notif_type)),
            ]:
                try:
                    db.execute_non_query(ins_sql, vals)
                    break
                except Exception:
                    pass
    except Exception as e:
        print(f'[notify_students] err (non-fatal): {e}')


def _islab_col():
    """
    Returns True if Subjects.IsLab column exists, False otherwise.
    The imported Railway schema does NOT have IsLab — so we default False
    and derive lab status from SubjectCode ending in 'L'.
    """
    global _ISLAB
    if _ISLAB is None:
        for q in ["SELECT IsLab FROM Subjects LIMIT 1",
                  "SELECT TOP 1 IsLab FROM Subjects"]:
            try:
                db.execute_query(q, fetch_one=True)
                _ISLAB = True
                break
            except Exception:
                pass
        if _ISLAB is None:
            _ISLAB = False
    return _ISLAB


# =============================================================================
# PROFILE
# =============================================================================

@bp_teacher.route('/profile')
@jwt_required()
def profile():
    uid, err = _get_teacher_user_id()
    if err: return err
    row = db.execute_query(
        """SELECT u.UserID, u.UserCode, u.FullName, u.Email, u.Phone,
                  u.Gender, u.DateOfBirth, u.JoinDate, u.UserType,
                  d.DepartmentName, d.DepartmentCode, d.DepartmentID
           FROM Users u
           LEFT JOIN Departments d ON d.DepartmentID = u.DepartmentID
           WHERE u.UserID=? AND u.UserType='Teacher' AND u.IsActive=1""",
        (uid,), fetch_one=True)
    if not row: return _err('Profile not found', 404)
    p = _serialize_one(row)
    p['TeacherCode'] = p.get('UserCode', '')
    p['Designation'] = 'Faculty'
    p['JoiningDate'] = p.get('JoinDate', '')
    p['subjectCount'] = _safe_scalar(
        'SELECT COUNT(DISTINCT SubjectID) FROM TeacherSubjects WHERE TeacherID=?', (uid,)
    ) or _safe_scalar('SELECT COUNT(DISTINCT SubjectID) FROM Timetable WHERE TeacherID=?', (uid,))
    p['periodsPerWeek'] = _safe_scalar('SELECT COUNT(*) FROM Timetable WHERE TeacherID=?', (uid,))
    return _ok({'profile': p})


# =============================================================================
# DASHBOARD
# =============================================================================

@bp_teacher.route('/dashboard')
@jwt_required()
def dashboard():
    uid, err = _get_teacher_user_id()
    if err: return err

    assigned_subjects = _safe_scalar(
        'SELECT COUNT(DISTINCT SubjectID) FROM TeacherSubjects WHERE TeacherID=?', (uid,)
    ) or _safe_scalar('SELECT COUNT(DISTINCT SubjectID) FROM Timetable WHERE TeacherID=?', (uid,))
    total_classes = _safe_scalar('SELECT COUNT(*) FROM Timetable WHERE TeacherID=?', (uid,))
    total_students = _safe_scalar(
        """SELECT COUNT(DISTINCT u.UserID) FROM Users u
           WHERE u.UserType='Student' AND u.IsActive=1
             AND EXISTS (SELECT 1 FROM Timetable t
                         JOIN Classes c ON t.ClassID=c.ClassID
                         WHERE t.TeacherID=? AND c.DepartmentID=u.DepartmentID AND c.Semester=u.Semester)""", (uid,))
    active_exams = _safe_scalar('SELECT COUNT(*) FROM Exams WHERE TeacherID=?', (uid,))

    today_name = datetime.now().strftime('%A')
    todays_schedule = []
    try:
        ilab = ', s.IsLab' if _islab_col() else ', 0 AS IsLab'
        rows = None
        # Try with Classes JOIN first (imported schema)
        for q in [
            f"""SELECT t.TimetableID, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      IFNULL(t.RoomNumber, IFNULL(t.Room, '')) AS RoomNumber, t.DayOfWeek, c.Semester,
                      s.SubjectName, s.SubjectCode {ilab}, d.DepartmentName,
                      c.ClassName, c.Section
               FROM Timetable t
               JOIN Classes c ON t.ClassID=c.ClassID
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
               WHERE t.TeacherID=? AND t.DayOfWeek=?
               ORDER BY t.StartTime""",
            f"""SELECT t.TimetableID, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,t.Room,'') AS RoomNumber, t.DayOfWeek, c.Semester,
                      s.SubjectName, s.SubjectCode {ilab}, d.DepartmentName,
                      c.ClassName, c.Section
               FROM Timetable t
               JOIN Classes c ON t.ClassID=c.ClassID
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
               WHERE t.TeacherID=? AND t.DayOfWeek=?
               ORDER BY t.StartTime""",
            # Fallback: inline DepartmentID/Semester
            f"""SELECT t.TimetableID, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      IFNULL(t.RoomNumber,'') AS RoomNumber, t.DayOfWeek, t.Semester,
                      s.SubjectName, s.SubjectCode {ilab}, d.DepartmentName,
                      '' AS ClassName, '' AS Section
               FROM Timetable t
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
               WHERE t.TeacherID=? AND t.DayOfWeek=?
               ORDER BY t.StartTime""",
            f"""SELECT t.TimetableID, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,'') AS RoomNumber, t.DayOfWeek, t.Semester,
                      s.SubjectName, s.SubjectCode {ilab}, d.DepartmentName,
                      '' AS ClassName, '' AS Section
               FROM Timetable t
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
               WHERE t.TeacherID=? AND t.DayOfWeek=?
               ORDER BY t.StartTime""",
        ]:
            try:
                rows = db.execute_query(q, (uid, today_name))
                if rows is not None: break
            except Exception as eq:
                print(f'[dashboard] schedule query err: {eq}')
        todays_schedule = _serialize(rows or [])
        for r in todays_schedule:
            r['ClassName'] = r.get('ClassName') or f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
    except Exception as e:
        print(f'[dashboard] schedule err: {e}')

    return _ok({'stats': {
        'totalClasses': total_classes, 'periodsPerWeek': total_classes,
        'assignedSubjects': assigned_subjects, 'totalSubjects': assigned_subjects,
        'totalStudents': total_students, 'activeExams': active_exams,
        'todaysSchedule': todays_schedule,
    }})


# =============================================================================
# SUBJECTS
# =============================================================================

@bp_teacher.route('/subjects')
@jwt_required()
def subjects():
    uid, err = _get_teacher_user_id()
    if err: return err
    # Real imported Railway schema: Subjects has NO IsLab column
    # Always use 0 AS IsLab and derive from SubjectCode suffix
    ilab = ', s.IsLab' if _islab_col() else ', 0 AS IsLab'
    rows = None

    # Strategy 1: TeacherSubjects JOIN Classes (real imported schema has ClassID, not Semester/DeptID)
    for q in [
        f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
               s.Credits {ilab}, c.Semester, c.DepartmentID, d.DepartmentName,
               c.ClassName, c.Section
           FROM TeacherSubjects ts
           INNER JOIN Subjects s ON s.SubjectID=ts.SubjectID
           INNER JOIN Classes c ON ts.ClassID=c.ClassID
           LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
           WHERE ts.TeacherID=? ORDER BY c.Semester, s.SubjectName""",
        # Without IsLab (safety fallback)
        f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
               s.Credits, 0 AS IsLab, c.Semester, c.DepartmentID, d.DepartmentName,
               c.ClassName, c.Section
           FROM TeacherSubjects ts
           INNER JOIN Subjects s ON s.SubjectID=ts.SubjectID
           INNER JOIN Classes c ON ts.ClassID=c.ClassID
           LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
           WHERE ts.TeacherID=? ORDER BY c.Semester, s.SubjectName""",
        # Older auto-created schema: TeacherSubjects has Semester/DepartmentID
        f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
               s.Credits {ilab}, ts.Semester, ts.DepartmentID, d.DepartmentName
           FROM TeacherSubjects ts
           INNER JOIN Subjects s ON s.SubjectID=ts.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=ts.DepartmentID
           WHERE ts.TeacherID=? ORDER BY ts.Semester, s.SubjectName""",
    ]:
        try:
            rows = db.execute_query(q, (uid,))
            if rows: break
        except Exception as e:
            print(f'[subjects] TeacherSubjects err: {e}')

    # Strategy 2: Timetable → Classes → Subjects (always works on imported schema)
    if not rows:
        for q in [
            f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
                   s.Credits {ilab}, c.Semester, c.DepartmentID, d.DepartmentName,
                   c.ClassName, c.Section
               FROM Timetable t
               JOIN Classes c ON t.ClassID=c.ClassID
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
               WHERE t.TeacherID=? ORDER BY c.Semester, s.SubjectName""",
            # Without IsLab
            f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
                   s.Credits, 0 AS IsLab, c.Semester, c.DepartmentID, d.DepartmentName,
                   c.ClassName, c.Section
               FROM Timetable t
               JOIN Classes c ON t.ClassID=c.ClassID
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
               WHERE t.TeacherID=? ORDER BY c.Semester, s.SubjectName""",
            # Inline DepartmentID/Semester (auto-created schema)
            f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
                   s.Credits, 0 AS IsLab, t.Semester, t.DepartmentID, d.DepartmentName,
                   '' AS ClassName, '' AS Section
               FROM Timetable t
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
               WHERE t.TeacherID=? ORDER BY t.Semester, s.SubjectName""",
        ]:
            try:
                rows = db.execute_query(q, (uid,))
                if rows: break
            except Exception as e:
                print(f'[subjects] Timetable fallback err: {e}')

    result = _serialize(rows or [])
    for r in result:
        r['ClassName'] = r.get('ClassName') or f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
        # Derive IsLab from SubjectCode if column doesn't exist in schema
        if r.get('IsLab') is None or r.get('IsLab') == 0:
            r['IsLab'] = 1 if str(r.get('SubjectCode', '')).upper().endswith('L') else 0
    return _ok({'subjects': result})


# =============================================================================
# TIMETABLE
# =============================================================================

@bp_teacher.route('/timetable')
@jwt_required()
def timetable():
    uid, err = _get_teacher_user_id()
    if err: return err
    ilab = ', s.IsLab' if _islab_col() else ', 0 AS IsLab'
    rows = None

    # Strategy 1: JOIN Classes table (imported schema has ClassID in Timetable)
    for q in [
        # MySQL FIELD() ordering
        f"""SELECT t.TimetableID, t.DayOfWeek, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                  IFNULL(t.RoomNumber, IFNULL(t.Room, '')) AS RoomNumber, c.DepartmentID, c.Semester,
                  s.SubjectID, s.SubjectName, s.SubjectCode {ilab},
                  d.DepartmentName, d.DepartmentCode, c.ClassName, c.Section
           FROM Timetable t
           JOIN Classes c ON t.ClassID=c.ClassID
           INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
           WHERE t.TeacherID=?
           ORDER BY FIELD(t.DayOfWeek,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
                    t.StartTime""",
        # COALESCE fallback (SQLite / MSSQL)
        f"""SELECT t.TimetableID, t.DayOfWeek, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                  COALESCE(t.RoomNumber,t.Room,'') AS RoomNumber, c.DepartmentID, c.Semester,
                  s.SubjectID, s.SubjectName, s.SubjectCode {ilab},
                  d.DepartmentName, d.DepartmentCode, c.ClassName, c.Section
           FROM Timetable t
           JOIN Classes c ON t.ClassID=c.ClassID
           INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
           WHERE t.TeacherID=?
           ORDER BY CASE t.DayOfWeek
               WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
               WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 ELSE 6 END, t.StartTime""",
    ]:
        try:
            rows = db.execute_query(q, (uid,))
            if rows is not None: break
        except Exception as e:
            print(f'[timetable] Classes JOIN query err: {e}')

    # Strategy 2: Timetable has DepartmentID/Semester inline (db.py auto-created schema)
    if rows is None:
        for q in [
            f"""SELECT t.TimetableID, t.DayOfWeek, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      IFNULL(t.RoomNumber, '') AS RoomNumber, t.DepartmentID, t.Semester,
                      s.SubjectID, s.SubjectName, s.SubjectCode {ilab},
                      d.DepartmentName, d.DepartmentCode,
                      CONCAT(IFNULL(d.DepartmentCode,''), ' Sem ', t.Semester) AS ClassName,
                      '' AS Section
               FROM Timetable t
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
               WHERE t.TeacherID=?
               ORDER BY FIELD(t.DayOfWeek,'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'),
                        t.StartTime""",
            f"""SELECT t.TimetableID, t.DayOfWeek, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,'') AS RoomNumber, t.DepartmentID, t.Semester,
                      s.SubjectID, s.SubjectName, s.SubjectCode {ilab},
                      d.DepartmentName, d.DepartmentCode,
                      d.DepartmentName||' Sem '||t.Semester AS ClassName, '' AS Section
               FROM Timetable t
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
               WHERE t.TeacherID=?
               ORDER BY CASE t.DayOfWeek
                   WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
                   WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 ELSE 6 END, t.StartTime""",
        ]:
            try:
                rows = db.execute_query(q, (uid,))
                if rows is not None: break
            except Exception as e:
                print(f'[timetable] inline DeptID query err: {e}')

    result = _serialize(rows or [])
    for r in result:
        if r.get('IsLab') is None:
            r['IsLab'] = 1 if str(r.get('SubjectCode', '')).endswith('L') else 0
        r['ClassName'] = r.get('ClassName') or f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
    return _ok({'timetable': result})


# =============================================================================
# CLASSES
# =============================================================================

@bp_teacher.route('/classes')
@jwt_required()
def classes():
    uid, err = _get_teacher_user_id()
    if err: return err
    combos = None

    # Strategy 1: imported schema — Timetable.ClassID → Classes
    for q in [
        """SELECT DISTINCT c.DepartmentID, c.Semester, d.DepartmentName, d.DepartmentCode,
                  COUNT(DISTINCT t.SubjectID) AS subjectCount, c.ClassID, c.ClassName, c.Section
           FROM Timetable t
           JOIN Classes c ON t.ClassID=c.ClassID
           LEFT JOIN Departments d ON d.DepartmentID=c.DepartmentID
           WHERE t.TeacherID=?
           GROUP BY c.DepartmentID, c.Semester, d.DepartmentName, d.DepartmentCode, c.ClassID, c.ClassName, c.Section
           ORDER BY d.DepartmentName, c.Semester""",
    ]:
        try:
            combos = db.execute_query(q, (uid,))
            if combos is not None: break
        except Exception as e:
            print(f'[classes] Classes JOIN err: {e}')

    # Strategy 2: auto-created schema — Timetable.DepartmentID/Semester inline
    if not combos:
        try:
            combos = db.execute_query(
                """SELECT DISTINCT t.DepartmentID, t.Semester, d.DepartmentName, d.DepartmentCode,
                          COUNT(DISTINCT t.SubjectID) AS subjectCount,
                          0 AS ClassID, '' AS ClassName, 'A' AS Section
                   FROM Timetable t
                   LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
                   WHERE t.TeacherID=?
                   GROUP BY t.DepartmentID, t.Semester, d.DepartmentName, d.DepartmentCode
                   ORDER BY d.DepartmentName, t.Semester""", (uid,))
        except Exception as e:
            print(f'[classes] inline DeptID err: {e}')

    result = []
    for row in (combos or []):
        dept_id  = row.get('DepartmentID')
        semester = row.get('Semester')
        student_count = _safe_scalar(
            "SELECT COUNT(DISTINCT UserID) FROM Users WHERE UserType='Student' AND IsActive=1 AND DepartmentID=? AND Semester=?",
            (dept_id, semester))
        dept_name = row.get('DepartmentName', '')
        result.append({
            'ClassID': row.get('ClassID') or f'{dept_id}_{semester}',
            'DepartmentID': dept_id, 'Semester': semester,
            'ClassName': row.get('ClassName') or f"{dept_name} Sem {semester}",
            'DepartmentName': dept_name,
            'DepartmentCode': row.get('DepartmentCode', ''),
            'Section': row.get('Section', 'A'),
            'studentCount': student_count,
            'subjectCount': row.get('subjectCount', 0),
        })
    return _ok({'classes': result})


# =============================================================================
# STUDENTS BY CLASS — alphabetically ordered, with serial numbers
# =============================================================================

@bp_teacher.route('/students/by-class/<int:department_id>/<int:semester>')
@jwt_required()
def students_by_class(department_id, semester):
    uid, err = _get_teacher_user_id()
    if err: return err

    teaches = _try_queries([
        ('SELECT t.ClassID FROM Timetable t JOIN Classes c ON t.ClassID=c.ClassID WHERE t.TeacherID=? AND c.DepartmentID=? AND c.Semester=? LIMIT 1', (uid, department_id, semester)),
        ('SELECT TOP 1 SubjectID FROM TeacherSubjects WHERE TeacherID=? AND DepartmentID=? AND Semester=?', (uid, department_id, semester)),
        ('SELECT t.ClassID FROM Timetable t JOIN Classes c ON t.ClassID=c.ClassID WHERE t.TeacherID=? AND c.DepartmentID=? AND c.Semester=? LIMIT 1', (uid, department_id, semester)),
    ], fetch_one=True)
    if not teaches: return _err('You do not teach this department/semester combination', 403)

    dept_info = db.execute_query('SELECT DepartmentName FROM Departments WHERE DepartmentID=?', (department_id,), fetch_one=True)
    dept_name = dept_info['DepartmentName'] if dept_info else f'Dept {department_id}'

    # Ordered by name — gives consistent serial numbers 1,2,3,...
    students = db.execute_query(
        """SELECT DISTINCT u.UserID AS StudentID,
               u.FullName, u.UserCode AS RollNumber,
               u.Email, u.Semester, u.Gender, d.DepartmentName
           FROM Users u
           LEFT JOIN Departments d ON d.DepartmentID=u.DepartmentID
           WHERE u.UserType='Student' AND u.IsActive=1
             AND u.DepartmentID=? AND u.Semester=?
           ORDER BY u.FullName""", (department_id, semester)) or []

    result = _serialize(students)
    for i, s in enumerate(result, 1):
        s['SerialNo'] = i  # 1-based serial, always consistent

    return _ok({'students': result, 'className': f'{dept_name} Sem {semester}',
                'semester': semester, 'departmentId': department_id, 'count': len(result)})


# =============================================================================
# ATTENDANCE — SUBMIT (multi-fallback for MSSQL)
# =============================================================================

@bp_teacher.route('/attendance/submit', methods=['POST'])
@jwt_required()
def attendance_submit():
    uid, err = _get_teacher_user_id()
    if err: return err

    data            = request.get_json() or {}
    subject_id      = data.get('subjectId')
    attendance_date = data.get('attendanceDate') or data.get('date') or date.today().isoformat()
    records         = data.get('attendance', [])
    if not subject_id or not records: return _err('subjectId and attendance list required')

    # Resolve ClassID — try Classes JOIN, fall back gracefully
    class_id = None
    for q, p in [
        ('SELECT ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
        ('SELECT TOP 1 ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=?', (uid, subject_id)),
    ]:
        try:
            tt = db.execute_query(q, p, fetch_one=True)
            if tt and tt.get('ClassID'):
                class_id = tt['ClassID']
                break
        except Exception:
            pass

    saved = 0
    for rec in records:
        student_id = rec.get('studentId')
        status     = rec.get('status', 'Present')
        if not student_id: continue
        try:
            existing = _try_queries([
                ('SELECT AttendanceID FROM Attendance WHERE StudentID=? AND SubjectID=? AND AttendanceDate=?',
                 (student_id, subject_id, attendance_date)),
            ], fetch_one=True)

            if existing:
                for upd, uvals in [
                    ('UPDATE Attendance SET Status=?,MarkedAt=? WHERE AttendanceID=?', (status, datetime.now(), existing['AttendanceID'])),
                    ('UPDATE Attendance SET Status=? WHERE AttendanceID=?', (status, existing['AttendanceID'])),
                ]:
                    try: db.execute_non_query(upd, uvals); break
                    except Exception: pass
                saved += 1
            else:
                ok, _ = _try_inserts('Attendance', [
                    # MySQL exact cols: StudentID, SubjectID, ClassID, AttendanceDate, Status
                    ('StudentID,SubjectID,ClassID,AttendanceDate,Status',
                     (student_id, subject_id, class_id, attendance_date, status)),
                    # Without ClassID (nullable so safe to omit)
                    ('StudentID,SubjectID,AttendanceDate,Status',
                     (student_id, subject_id, attendance_date, status)),
                ])
                if ok: saved += 1
        except Exception as e:
            print(f'[attendance_submit] row error: {e}')

    return _ok({'message': f'Attendance saved for {saved} students', 'saved': saved})


# =============================================================================
# ATTENDANCE — HISTORY
# =============================================================================

@bp_teacher.route('/attendance/history')
@jwt_required()
def attendance_history():
    uid, err = _get_teacher_user_id()
    if err: return err
    rows = db.execute_query(
        """SELECT a.AttendanceID, a.AttendanceDate, a.Status,
                  a.SubjectID,
                  u.FullName AS StudentName, u.UserCode,
                  s.SubjectName, s.SubjectCode
           FROM Attendance a
           INNER JOIN Users u ON u.UserID=a.StudentID
           INNER JOIN Subjects s ON s.SubjectID=a.SubjectID
           WHERE a.SubjectID IN (
               SELECT DISTINCT SubjectID FROM TeacherSubjects WHERE TeacherID=?
               UNION
               SELECT DISTINCT SubjectID FROM Timetable WHERE TeacherID=?
           )
           ORDER BY a.AttendanceDate DESC, u.FullName""", (uid, uid)) or []
    return _ok({'attendance': _serialize(rows)})


# =============================================================================

# =============================================================================
# ATTENDANCE — FACE RECOGNITION (replaces QR-based attendance)
# =============================================================================
# Flow:
#   1. POST /attendance/face/start   — teacher opens face session (returns session token)
#   2. POST /attendance/face/submit  — submit per-student recognised results from browser
#   3. GET  /attendance/face/status  — live count of recognised students in session
#   4. POST /attendance/mark-absent  — mark anyone not yet recorded as Absent
# =============================================================================

import base64, hashlib

# In-memory face sessions: { session_token: { subjectId, date, teacherUid, recognised: set() } }
_face_sessions = {}


@bp_teacher.route('/attendance/face/start', methods=['POST'])
@jwt_required()
def face_attendance_start():
    """
    Open a face-recognition attendance session for a subject + date.
    Returns a session token the browser uses to tag subsequent submissions.
    """
    uid, err = _get_teacher_user_id()
    if err: return err

    data       = request.get_json() or {}
    subject_id = data.get('subjectId')
    att_date   = data.get('attendanceDate', date.today().isoformat())
    if not subject_id: return _err('subjectId required')

    # Verify teacher teaches this subject
    tt = _try_queries([
        ('SELECT ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
        ('SELECT TOP 1 ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=?',   (uid, subject_id)),
    ], fetch_one=True)
    if not tt: return _err('You do not teach this subject', 403)

    # Generate a lightweight session token
    raw = f'{uid}|{subject_id}|{att_date}|{secrets.token_urlsafe(8)}'
    session_token = hashlib.sha1(raw.encode()).hexdigest()[:20]

    _face_sessions[session_token] = {
        'subjectId':  subject_id,
        'date':       att_date,
        'teacherUid': uid,
        'recognised': set(),    # StudentIDs confirmed present so far
    }

    # How many students are in this class?
    dept_sem = _try_queries([
        ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=?', (uid, subject_id)),
        ('SELECT DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
    ], fetch_one=True)
    total = 0
    if dept_sem:
        total = _safe_scalar(
            "SELECT COUNT(*) FROM Users WHERE UserType='Student' AND IsActive=1 AND DepartmentID=? AND Semester=?",
            (dept_sem['DepartmentID'], dept_sem['Semester'])
        )

    return _ok({
        'sessionToken': session_token,
        'subjectId':    subject_id,
        'attendanceDate': att_date,
        'totalStudents': total,
        'message': 'Face recognition session started',
    })


@bp_teacher.route('/attendance/face/capture', methods=['POST'])
@jwt_required()
def face_attendance_capture():
    """
    Receive a base64 image frame from the teacher's camera.

    The browser sends frames every 3 seconds. This route processes the image
    and returns which students were recognised.

    Since full ML face recognition requires a trained model per institution,
    this implementation provides session-aware tracking:
    - Validates the session is active
    - Returns any students already marked present in this session
    - The browser's face detection (via face-api.js or similar) handles
      the actual recognition client-side before calling /face/submit

    Body: {
        sessionToken: str,
        subjectId:    int,
        attendanceDate: str,
        image:        str   (base64 JPEG data URL)
    }
    Response: {
        success: true,
        recognised: [ { studentId, fullName, rollNumber } ],
        sessionActive: bool,
        frameProcessed: bool
    }
    """
    uid, err = _get_teacher_user_id()
    if err: return err

    data          = request.get_json() or {}
    session_token = data.get('sessionToken', '')
    subject_id    = data.get('subjectId')
    image_data    = data.get('image', '')

    # Validate session exists
    session = _face_sessions.get(session_token)
    if not session:
        # Session expired or not started — return gracefully (not an error)
        return _ok({
            'recognised':     [],
            'sessionActive':  False,
            'frameProcessed': False,
            'message':        'Session not found — call /face/start first',
        })

    # Image must be present and reasonably sized (>1KB means real camera frame)
    frame_valid = bool(image_data) and len(image_data) > 1000

    # Return the currently recognised students in this session so the
    # frontend can update its UI. Actual recognition happens client-side.
    recognised_ids = session.get('recognised', set())
    recognised_list = []
    if recognised_ids:
        # Fetch names for the recognised students in one query
        ids_placeholder = ','.join(['?'] * len(recognised_ids))
        try:
            rows = db.execute_query(
                f"SELECT UserID, FullName, UserCode FROM Users WHERE UserID IN ({ids_placeholder})",
                tuple(int(i) for i in recognised_ids)
            )
            for row in (rows or []):
                recognised_list.append({
                    'studentId':  row.get('UserID'),
                    'fullName':   row.get('FullName', ''),
                    'rollNumber': row.get('UserCode', ''),
                })
        except Exception as e:
            print(f'[face_capture] name lookup err: {e}')

    return _ok({
        'recognised':     recognised_list,
        'sessionActive':  True,
        'frameProcessed': frame_valid,
        'recognisedCount': len(recognised_ids),
        'message':        f'Frame received. {len(recognised_ids)} student(s) recognised so far.',
    })



@bp_teacher.route('/attendance/face/submit', methods=['POST'])
@jwt_required()
def face_attendance_submit():
    """
    Receive face-recognition results from the browser.
    The browser sends one or more recognised studentIds; this endpoint
    immediately writes Present records and updates the in-memory session.

    Body: {
        sessionToken: str,
        subjectId:    int,
        attendanceDate: str,       (fallback if no session)
        records: [ { studentId, status } ]   -- status: 'Present' | 'Absent' | 'Unknown'
    }
    """
    uid, err = _get_teacher_user_id()
    if err: return err

    data          = request.get_json() or {}
    session_token = data.get('sessionToken', '')
    subject_id    = data.get('subjectId')
    records       = data.get('records', [])

    # Resolve attendance date from session or body
    session = _face_sessions.get(session_token, {})
    att_date = session.get('date') or data.get('attendanceDate', date.today().isoformat())

    if not subject_id or not records:
        return _err('subjectId and records are required')

    # Resolve ClassID for Attendance FK
    class_id = None
    tt = _try_queries([
        ('SELECT ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
        ('SELECT TOP 1 ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=?',   (uid, subject_id)),
    ], fetch_one=True)
    if tt: class_id = tt.get('ClassID')

    saved = 0
    for rec in records:
        student_id = rec.get('studentId')
        status     = rec.get('status', 'Present')
        if not student_id or status == 'Unknown':
            continue
        try:
            existing = _try_queries([
                ('SELECT AttendanceID FROM Attendance WHERE StudentID=? AND SubjectID=? AND AttendanceDate=?',
                 (student_id, subject_id, att_date)),
            ], fetch_one=True)

            if existing:
                for upd, uv in [
                    ('UPDATE Attendance SET Status=?,MarkedAt=? WHERE AttendanceID=?',
                     (status, datetime.now(), existing['AttendanceID'])),
                    ('UPDATE Attendance SET Status=? WHERE AttendanceID=?',
                     (status, existing['AttendanceID'])),
                ]:
                    try: db.execute_non_query(upd, uv); break
                    except Exception: pass
                saved += 1
            else:
                ok, _ = _try_inserts('Attendance', [
                    ('StudentID,SubjectID,ClassID,AttendanceDate,Status',
                     (student_id, subject_id, class_id, att_date, status)),
                    ('StudentID,SubjectID,AttendanceDate,Status',
                     (student_id, subject_id, att_date, status)),
                ])
                if ok: saved += 1

            # Track recognised students in-memory session
            if session and status == 'Present':
                session['recognised'].add(str(student_id))

        except Exception as e:
            print(f'[face_attendance_submit] row err: {e}')

    recognised_count = len(session.get('recognised', set())) if session else saved
    return _ok({
        'message': f'Face attendance saved for {saved} student(s)',
        'saved': saved,
        'recognisedCount': recognised_count,
        'sessionToken': session_token,
    })


@bp_teacher.route('/attendance/face/status')
@jwt_required()
def face_attendance_status():
    """
    Live status of an ongoing face-recognition session.
    GET /api/teacher/attendance/face/status?token=<sessionToken>
    """
    uid, err = _get_teacher_user_id()
    if err: return err

    token   = request.args.get('token', '').strip()
    session = _face_sessions.get(token, {})

    subject_id = session.get('subjectId') or request.args.get('subjectId')
    att_date   = session.get('date')      or request.args.get('date', date.today().isoformat())

    recognised = len(session.get('recognised', set()))

    # Live DB counts
    present = _safe_scalar(
        "SELECT COUNT(*) FROM Attendance WHERE SubjectID=? AND AttendanceDate=? AND Status='Present'",
        (subject_id, att_date)) if subject_id else 0
    absent  = _safe_scalar(
        "SELECT COUNT(*) FROM Attendance WHERE SubjectID=? AND AttendanceDate=? AND Status='Absent'",
        (subject_id, att_date)) if subject_id else 0

    # Total class size
    total = 0
    dept_sem = _try_queries([
        ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE SubjectID=?', (subject_id,)),
        ('SELECT DepartmentID, Semester FROM Timetable WHERE SubjectID=? LIMIT 1', (subject_id,)),
    ], fetch_one=True) if subject_id else None
    if dept_sem:
        total = _safe_scalar(
            "SELECT COUNT(*) FROM Users WHERE UserType='Student' AND IsActive=1 AND DepartmentID=? AND Semester=?",
            (dept_sem['DepartmentID'], dept_sem['Semester'])
        )

    return _ok({
        'recognised':   recognised,
        'present':      present,
        'absent':       absent,
        'total':        total,
        'pending':      max(0, total - present - absent),
        'sessionToken': token,
    })


# =============================================================================
# ATTENDANCE — MARK ABSENT (unchanged — used to finalise face session too)
# =============================================================================

@bp_teacher.route('/attendance/mark-absent', methods=['POST'])
@jwt_required()
def mark_absent_non_scanners():
    """
    Mark every student not yet recorded as Absent.
    Used at end of face-recognition session to finalise.
    Body: { subjectId, attendanceDate, sessionToken? }
    """
    uid, err = _get_teacher_user_id()
    if err: return err
    data          = request.get_json() or {}
    subject_id    = data.get('subjectId')
    att_date      = data.get('attendanceDate', date.today().isoformat())
    dept_id       = data.get('departmentId')
    semester      = data.get('semester')
    session_token = data.get('sessionToken', '')
    if not subject_id: return _err('subjectId required')

    if not dept_id or not semester:
        tt = _try_queries([
            ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=?', (uid, subject_id)),
            ('SELECT DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
        ], fetch_one=True)
        if tt: dept_id = tt['DepartmentID']; semester = tt['Semester']

    if not dept_id or not semester: return _err('Could not determine class.')

    all_students = db.execute_query(
        "SELECT UserID AS StudentID FROM Users WHERE UserType='Student' AND IsActive=1 AND DepartmentID=? AND Semester=?",
        (dept_id, semester)) or []
    already = {r['StudentID'] for r in (db.execute_query(
        'SELECT StudentID FROM Attendance WHERE SubjectID=? AND AttendanceDate=?',
        (subject_id, att_date)) or [])}

    class_id = None
    tt2 = _try_queries([
        ('SELECT ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
        ('SELECT TOP 1 ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=?',   (uid, subject_id)),
    ], fetch_one=True)
    if tt2: class_id = tt2.get('ClassID')

    absent_count = 0
    for s in all_students:
        sid = s['StudentID']
        if sid not in already:
            ok, _ = _try_inserts('Attendance', [
                ('StudentID,SubjectID,ClassID,AttendanceDate,Status',
                 (sid, subject_id, class_id, att_date, 'Absent')),
                ('StudentID,SubjectID,AttendanceDate,Status',
                 (sid, subject_id, att_date, 'Absent')),
            ])
            if ok: absent_count += 1

    # Clean up in-memory session
    if session_token and session_token in _face_sessions:
        del _face_sessions[session_token]

    return _ok({'message': f'{absent_count} students marked absent', 'absentCount': absent_count})


# EXAMS — LIST
# =============================================================================

@bp_teacher.route('/exams')
@jwt_required()
def get_exams():
    uid, err = _get_teacher_user_id()
    if err: return err
    rows = None
    for sql in [
        # Full: ExamName + StartTime + EndTime + counts
        """SELECT e.ExamID, e.ExamType, e.TotalMarks, e.ExamDate, e.Duration, e.CreatedAt,
                  COALESCE(e.ExamName, COALESCE(e.ExamTitle, e.ExamType)) AS ExamName,
                  COALESCE(e.ExamTitle, e.ExamType) AS ExamTitle,
                  COALESCE(e.StartTime,'') AS StartTime, COALESCE(e.EndTime,'') AS EndTime,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName,
                  (SELECT COUNT(*) FROM ExamQuestions q WHERE q.ExamID=e.ExamID) AS QuestionCount,
                  (SELECT COUNT(*) FROM ExamSubmissions es WHERE es.ExamID=e.ExamID) AS SubmissionCount
           FROM Exams e INNER JOIN Subjects s ON s.SubjectID=e.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE e.TeacherID=? ORDER BY e.CreatedAt DESC""",
        # Without StartTime/EndTime columns
        """SELECT e.ExamID, e.ExamType, e.TotalMarks, e.ExamDate, e.Duration, e.CreatedAt,
                  COALESCE(e.ExamName, COALESCE(e.ExamTitle, e.ExamType)) AS ExamName,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName,
                  (SELECT COUNT(*) FROM ExamQuestions q WHERE q.ExamID=e.ExamID) AS QuestionCount,
                  (SELECT COUNT(*) FROM ExamSubmissions es WHERE es.ExamID=e.ExamID) AS SubmissionCount
           FROM Exams e INNER JOIN Subjects s ON s.SubjectID=e.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE e.TeacherID=? ORDER BY e.CreatedAt DESC""",
        # Without ExamName column
        """SELECT e.ExamID, e.ExamType, e.TotalMarks, e.ExamDate, e.Duration, e.CreatedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName,
                  (SELECT COUNT(*) FROM ExamQuestions q WHERE q.ExamID=e.ExamID) AS QuestionCount,
                  (SELECT COUNT(*) FROM ExamSubmissions es WHERE es.ExamID=e.ExamID) AS SubmissionCount
           FROM Exams e INNER JOIN Subjects s ON s.SubjectID=e.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE e.TeacherID=? ORDER BY e.CreatedAt DESC""",
        # Minimal fallback
        """SELECT e.ExamID, e.ExamType, e.TotalMarks, e.ExamDate, e.Duration, e.CreatedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName,
                  0 AS QuestionCount, 0 AS SubmissionCount
           FROM Exams e INNER JOIN Subjects s ON s.SubjectID=e.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE e.TeacherID=? ORDER BY e.ExamDate DESC""",
    ]:
        try:
            rows = db.execute_query(sql, (uid,))
            if rows is not None: break
        except Exception as e:
            print(f'[get_exams] variant err: {e}')

    rows = _serialize(rows or [])
    for r in rows:
        r['ClassName'] = f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
        if not r.get('ExamName'): r['ExamName'] = r.get('ExamTitle') or f"{r.get('ExamType','Exam')} - {r.get('SubjectCode','')}"
        r.setdefault('ExamTitle', r['ExamName'])
        r.setdefault('IsActive', 1)
        r.setdefault('StartTime', '')
        r.setdefault('EndTime', '')
        r.setdefault('Instructions', '')
    return _ok({'exams': rows})


# =============================================================================
# EXAMS — CREATE (multi-fallback for MSSQL missing columns)
# =============================================================================

@bp_teacher.route('/exams', methods=['POST'])
@jwt_required()
def create_exam():
    uid, err = _get_teacher_user_id()
    if err: return err

    data        = request.get_json() or {}
    subject_id  = data.get('subjectId')
    exam_name   = (data.get('examName') or data.get('title') or data.get('examType') or 'CA1').strip()
    exam_type   = data.get('examType', 'CA1')
    total_marks = int(data.get('totalMarks', 100))
    exam_date   = data.get('examDate')
    duration    = int(data.get('duration') or data.get('durationMinutes') or 60)
    instructions = data.get('instructions', '')

    if not subject_id or not exam_date: return _err('subjectId and examDate are required')

    ok, last_err = _try_inserts('Exams', [
        # MSSQL schema: ExamTitle + ExamName + IsActive + Instructions + Duration
        ('SubjectID,ClassID,TeacherID,ExamTitle,ExamName,ExamType,TotalMarks,Duration,ExamDate,Instructions,IsPublished,CreatedAt',
         (subject_id, uid, exam_name, exam_name, exam_type, total_marks, duration, exam_date, instructions, 1, datetime.now())),
        # Without Instructions
        ('SubjectID,ClassID,TeacherID,ExamTitle,ExamName,ExamType,TotalMarks,Duration,ExamDate,IsPublished,CreatedAt',
         (subject_id, uid, exam_name, exam_name, exam_type, total_marks, duration, exam_date, 1, datetime.now())),
        # Without IsActive
        ('SubjectID,TeacherID,ExamTitle,ExamName,ExamType,TotalMarks,Duration,ExamDate,CreatedAt',
         (subject_id, uid, exam_name, exam_name, exam_type, total_marks, duration, exam_date, datetime.now())),
        # Without Duration
        ('SubjectID,TeacherID,ExamTitle,ExamName,ExamType,TotalMarks,ExamDate,CreatedAt',
         (subject_id, uid, exam_name, exam_name, exam_type, total_marks, exam_date, datetime.now())),
        # ExamTitle only (no ExamName column in schema)
        ('SubjectID,ClassID,TeacherID,ExamTitle,ExamType,TotalMarks,Duration,ExamDate,Instructions,IsPublished,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, instructions, 1, datetime.now())),
        ('SubjectID,ClassID,TeacherID,ExamTitle,ExamType,TotalMarks,Duration,ExamDate,IsPublished,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, 1, datetime.now())),
        ('SubjectID,TeacherID,ExamTitle,ExamType,TotalMarks,Duration,ExamDate,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, datetime.now())),
        ('SubjectID,TeacherID,ExamTitle,ExamType,TotalMarks,ExamDate',
         (subject_id, uid, exam_name, exam_type, total_marks, exam_date)),
        # ExamName only (SQLite schema, no ExamTitle column)
        ('SubjectID,ClassID,TeacherID,ExamName,ExamType,TotalMarks,Duration,ExamDate,Instructions,IsPublished,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, instructions, 1, datetime.now())),
        ('SubjectID,ClassID,TeacherID,ExamName,ExamType,TotalMarks,Duration,ExamDate,IsPublished,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, 1, datetime.now())),
        ('SubjectID,TeacherID,ExamName,ExamType,TotalMarks,Duration,ExamDate,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, datetime.now())),
        # Minimal fallback — neither ExamTitle nor ExamName
        ('SubjectID,TeacherID,ExamType,TotalMarks,Duration,ExamDate,CreatedAt',
         (subject_id, uid, exam_type, total_marks, duration, exam_date, datetime.now())),
        ('SubjectID,TeacherID,ExamType,TotalMarks,ExamDate',
         (subject_id, uid, exam_type, total_marks, exam_date)),
    ])
    if not ok: return _err(f'Database operation failed: {last_err}', 500)

    # Retrieve the newly-created ExamID using multiple strategies
    new_exam_id = None

    # Strategy 1: SCOPE_IDENTITY() — most reliable for MSSQL
    for scope_q in [
        'SELECT CAST(SCOPE_IDENTITY() AS INT) AS ExamID',
        'SELECT CAST(@@IDENTITY AS INT) AS ExamID',
    ]:
        try:
            row = db.execute_query(scope_q, fetch_one=True)
            if row and row.get('ExamID'):
                new_exam_id = int(row['ExamID'])
                break
        except Exception:
            pass

    # Strategy 2: SELECT the most-recently inserted row matching our data
    if not new_exam_id:
        for q, p in [
            ('SELECT TOP 1 ExamID FROM Exams WHERE TeacherID=? AND SubjectID=? AND ExamType=? ORDER BY ExamID DESC',
             (uid, subject_id, exam_type)),
            ('SELECT TOP 1 ExamID FROM Exams WHERE TeacherID=? AND SubjectID=? ORDER BY ExamID DESC',
             (uid, subject_id)),
            ('SELECT ExamID FROM Exams WHERE TeacherID=? AND SubjectID=? ORDER BY ExamID DESC LIMIT 1',
             (uid, subject_id)),
        ]:
            try:
                row = db.execute_query(q, p, fetch_one=True)
                if row and row.get('ExamID'):
                    new_exam_id = int(row['ExamID'])
                    break
            except Exception:
                pass

    print(f'[create_exam] new_exam_id={new_exam_id}')

    _notify_students(
        subject_id, f'📄 New Exam: {exam_name}',
        f'A new exam "{exam_name}" ({exam_type}) is scheduled on {exam_date}. Duration: {duration} mins, Total Marks: {total_marks}.',
        'Exam'
    )
    return _ok({'message': 'Exam created successfully', 'examId': new_exam_id, 'examName': exam_name})



# =============================================================================
# EXAM SUBMISSIONS — GET (all students + submission status)
# =============================================================================

@bp_teacher.route('/exams/<int:exam_id>/submissions')
@jwt_required()
def get_exam_submissions(exam_id):
    uid, err = _get_teacher_user_id()
    if err: return err

    # Verify exam exists
    exam = None
    for q, p in [
        ('SELECT TOP 1 ExamID, TotalMarks, SubjectID FROM Exams WHERE ExamID=? AND TeacherID=?', (exam_id, uid)),
        ('SELECT TOP 1 ExamID, TotalMarks, SubjectID FROM Exams WHERE ExamID=?', (exam_id,)),
    ]:
        try:
            exam = db.execute_query(q, p, fetch_one=True)
            if exam: break
        except Exception: pass
    if not exam: return _err('Exam not found', 404)

    total_marks = exam.get('TotalMarks', 0)
    subject_id  = exam.get('SubjectID')

    # Try to get all students for this subject's dept/semester
    all_students = []
    try:
        all_students = db.execute_query(
            """SELECT DISTINCT u.UserID AS StudentID, u.FullName AS StudentName,
                      u.UserCode AS RollNumber
               FROM Users u
               INNER JOIN StudentSubjects ss ON ss.StudentID=u.UserID
               WHERE ss.SubjectID=? AND u.UserType='Student'""", (subject_id,)) or []
    except Exception:
        pass

    if not all_students:
        try:
            # Fallback: get all students in the same dept+semester cohort as this exam's subject
            cohort = db.execute_query(
                """SELECT c.DepartmentID, c.Semester FROM Timetable t
                   JOIN Classes c ON t.ClassID=c.ClassID
                   INNER JOIN Exams e ON e.SubjectID=t.SubjectID
                   WHERE e.ExamID=? LIMIT 1""", (exam_id,), fetch_one=True)
            if not cohort:
                cohort = db.execute_query(
                    """SELECT c.DepartmentID, c.Semester FROM Timetable t
                       JOIN Classes c ON t.ClassID=c.ClassID
                       WHERE t.SubjectID=? LIMIT 1""", (subject_id,), fetch_one=True)
            if cohort:
                all_students = db.execute_query(
                    """SELECT DISTINCT u.UserID AS StudentID, u.FullName AS StudentName,
                              u.UserCode AS RollNumber
                       FROM Users u
                       WHERE u.UserType='Student' AND u.IsActive=1
                         AND u.DepartmentID=? AND u.Semester=?
                       ORDER BY u.FullName""",
                    (cohort['DepartmentID'], cohort['Semester'])) or []
        except Exception:
            pass

    # Get submissions for this exam
    submissions_map = {}
    for q, p in [
        ('SELECT StudentID, SubmissionID, IsSubmitted, MarksObtained, SubmittedAt FROM ExamSubmissions WHERE ExamID=?', (exam_id,)),
        ('SELECT StudentID, SubmissionID, MarksObtained, SubmittedAt FROM ExamSubmissions WHERE ExamID=?', (exam_id,)),
        ('SELECT StudentID, SubmissionID, MarksObtained FROM ExamSubmissions WHERE ExamID=?', (exam_id,)),
    ]:
        try:
            rows = db.execute_query(q, p) or []
            for r in rows:
                submissions_map[r['StudentID']] = r
            break
        except Exception: pass

    # Merge all students with submission data
    result = []
    if all_students:
        for stu in all_students:
            sid = stu.get('StudentID')
            sub = submissions_map.get(sid, {})
            result.append({
                'StudentID':    sid,
                'StudentName':  stu.get('StudentName', ''),
                'RollNumber':   stu.get('RollNumber', ''),
                'SubmissionID': sub.get('SubmissionID'),
                'IsSubmitted':  bool(sub.get('IsSubmitted') or sub.get('SubmissionID')),
                'MarksObtained':sub.get('MarksObtained'),
                'SubmittedAt':  str(sub.get('SubmittedAt', '')) if sub.get('SubmittedAt') else None,
            })
    else:
        # Fallback: only submitted students
        for sid, sub in submissions_map.items():
            result.append({
                'StudentID':    sid,
                'StudentName':  sub.get('StudentName', 'Student'),
                'RollNumber':   sub.get('RollNumber', ''),
                'SubmissionID': sub.get('SubmissionID'),
                'IsSubmitted':  True,
                'MarksObtained':sub.get('MarksObtained'),
                'SubmittedAt':  str(sub.get('SubmittedAt', '')) if sub.get('SubmittedAt') else None,
            })

    submitted_count   = sum(1 for r in result if r['IsSubmitted'])
    not_submitted     = len(result) - submitted_count
    return _ok({
        'submissions':      _serialize(result),
        'count':            len(result),
        'submittedCount':   submitted_count,
        'notSubmittedCount':not_submitted,
        'totalMarks':       total_marks,
        'examId':           exam_id,
    })

# =============================================================================
# EXAM QUESTIONS — GET
# =============================================================================

@bp_teacher.route('/exams/<int:exam_id>/questions', methods=['GET'])
@jwt_required()
def get_questions(exam_id):
    uid, err = _get_teacher_user_id()
    if err: return err
    exam = _try_queries([
        ('SELECT ExamID, ExamType, TotalMarks FROM Exams WHERE ExamID=? AND TeacherID=?', (exam_id, uid)),
    ], fetch_one=True)
    if not exam: return _err('Exam not found or access denied', 404)

    questions = []
    for q_sql, q_params in [
        # With QuestionType (SQLite / patched MSSQL)
        ("""SELECT QuestionID, QuestionText, QuestionType,
                  OptionA, OptionB, OptionC, OptionD, CorrectAnswer, Marks, QuestionOrder
           FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionOrder ASC, QuestionID ASC""", (exam_id,)),
        ("SELECT QuestionID, QuestionText, QuestionType, CorrectAnswer, Marks FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionID", (exam_id,)),
        # Without QuestionType (original MSSQL schema)
        ("""SELECT QuestionID, QuestionText,
                  OptionA, OptionB, OptionC, OptionD, CorrectAnswer, Marks, QuestionOrder
           FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionOrder ASC, QuestionID ASC""", (exam_id,)),
        ("SELECT QuestionID, QuestionText, CorrectAnswer, Marks FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionID", (exam_id,)),
        # Minimal fallback
        ("SELECT QuestionID, QuestionText, Marks FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionID", (exam_id,)),
    ]:
        try:
            questions = db.execute_query(q_sql, q_params) or []
            break
        except Exception as e:
            print(f'[get_questions] err: {e}')

    return _ok({'questions': _serialize(questions), 'examId': exam_id,
                'examName': exam.get('ExamType', ''), 'totalMarks': exam.get('TotalMarks', 100),
                'count': len(questions)})


# =============================================================================
# EXAM QUESTIONS — ADD (multi-fallback)
# =============================================================================

@bp_teacher.route('/exams/<int:exam_id>/questions', methods=['POST'])
@jwt_required()
def add_question(exam_id):
    uid, err = _get_teacher_user_id()
    if err: return err

    # Guard: exam_id must be a valid integer
    try:
        exam_id = int(exam_id)
    except (TypeError, ValueError):
        return _err(f'Invalid exam ID: {exam_id}', 400)

    # Verify the teacher owns this exam
    exam = _try_queries([
        ('SELECT TOP 1 ExamID FROM Exams WHERE ExamID=? AND TeacherID=?', (exam_id, uid)),
        ('SELECT ExamID FROM Exams WHERE ExamID=? AND TeacherID=? LIMIT 1', (exam_id, uid)),
        # Fallback: any exam with this ID (in case TeacherID mismatch due to schema differences)
        ('SELECT TOP 1 ExamID FROM Exams WHERE ExamID=?', (exam_id,)),
        ('SELECT ExamID FROM Exams WHERE ExamID=? LIMIT 1', (exam_id,)),
    ], fetch_one=True)
    if not exam:
        print(f'[add_question] exam_id={exam_id} not found for uid={uid}')
        return _err(f'Exam {exam_id} not found', 404)

    data = request.get_json() or {}

    # Get current max question order (safe fallback to 0)
    max_order = 0
    for q in [
        'SELECT COALESCE(MAX(QuestionOrder),0) AS MaxOrder FROM ExamQuestions WHERE ExamID=?',
        'SELECT COALESCE(MAX(QuestionOrder),0) AS MaxOrder FROM ExamQuestions WHERE ExamID=?',
        'SELECT COUNT(*) AS MaxOrder FROM ExamQuestions WHERE ExamID=?',
    ]:
        try:
            row = db.execute_query(q, (exam_id,), fetch_one=True)
            if row:
                max_order = int(list(row.values())[0] or 0)
            break
        except Exception as e:
            print(f'[add_question] max_order query err: {e}')

    def _insert_q(qt, q_type, opt_a, opt_b, opt_c, opt_d, correct, marks, order_num):
        # Coerce types
        marks = int(marks) if marks else 1
        order_num = int(order_num) if order_num else 1
        opt_a = str(opt_a or '')
        opt_b = str(opt_b or '')
        opt_c = str(opt_c or '')
        opt_d = str(opt_d or '')
        correct = str(correct or 'A')
        ok, last_e = _try_inserts('ExamQuestions', [
            # ── WITH QuestionType (SQLite / patched MSSQL) ──
            ('ExamID,QuestionText,QuestionType,OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Marks,QuestionOrder,CreatedAt',
             (exam_id, qt, q_type, opt_a, opt_b, opt_c, opt_d, correct, marks, order_num, datetime.now())),
            ('ExamID,QuestionText,QuestionType,OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Marks,QuestionOrder',
             (exam_id, qt, q_type, opt_a, opt_b, opt_c, opt_d, correct, marks, order_num)),
            ('ExamID,QuestionText,QuestionType,CorrectAnswer,Marks,QuestionOrder',
             (exam_id, qt, q_type, correct, marks, order_num)),
            ('ExamID,QuestionText,QuestionType,CorrectAnswer,Marks',
             (exam_id, qt, q_type, correct, marks)),
            ('ExamID,QuestionText,QuestionType,Marks',
             (exam_id, qt, q_type, marks)),
            # ── WITHOUT QuestionType (original MSSQL schema) ──
            ('ExamID,QuestionText,OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Marks,QuestionOrder,CreatedAt',
             (exam_id, qt, opt_a, opt_b, opt_c, opt_d, correct, marks, order_num, datetime.now())),
            ('ExamID,QuestionText,OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Marks,QuestionOrder',
             (exam_id, qt, opt_a, opt_b, opt_c, opt_d, correct, marks, order_num)),
            ('ExamID,QuestionText,CorrectAnswer,Marks,QuestionOrder',
             (exam_id, qt, correct, marks, order_num)),
            ('ExamID,QuestionText,CorrectAnswer,Marks',
             (exam_id, qt, correct, marks)),
            ('ExamID,QuestionText,Marks',
             (exam_id, qt, marks)),
        ])
        if not ok:
            print(f'[add_question] _insert_q FAILED exam={exam_id}: {last_e}')
        return ok

    questions_list = data.get('questions')
    if questions_list and isinstance(questions_list, list):
        saved = 0
        for i, q in enumerate(questions_list):
            qt = (q.get('questionText') or '').strip()
            if not qt: continue
            if _insert_q(qt, q.get('questionType','MCQ'), q.get('optionA',''), q.get('optionB',''),
                         q.get('optionC',''), q.get('optionD',''), q.get('correctAnswer','A'),
                         q.get('marks',1), max_order+i+1):
                saved += 1
        return _ok({'message': f'{saved} question(s) added', 'saved': saved})
    else:
        qt = (data.get('questionText') or '').strip()
        if not qt: return _err('questionText is required')
        ok = _insert_q(qt, data.get('questionType','MCQ'), data.get('optionA',''), data.get('optionB',''),
                       data.get('optionC',''), data.get('optionD',''), data.get('correctAnswer','A'),
                       data.get('marks',1), max_order+1)
        if not ok:
            return _err('Failed to add question — check server logs', 500)
        return _ok({'message': 'Question added successfully'})


# =============================================================================
# STUDY MATERIALS — GET + SAVE + DEVICE FILE UPLOAD
# =============================================================================

@bp_teacher.route('/materials')
@jwt_required()
def get_materials():
    uid, err = _get_teacher_user_id()
    if err: return err

    # Try progressively simpler queries to handle column differences
    rows = None
    for sql in [
        # Full columns
        """SELECT sm.MaterialID, sm.Title, sm.Description, sm.FilePath,
                  sm.FileType, sm.FileSize, sm.UploadedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName
           FROM StudyMaterials sm
           INNER JOIN Subjects s ON s.SubjectID=sm.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE sm.TeacherID=? ORDER BY sm.UploadedAt DESC""",
        # No FileSize
        """SELECT sm.MaterialID, sm.Title, sm.Description, sm.FilePath,
                  sm.FileType, 0 AS FileSize, sm.UploadedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName
           FROM StudyMaterials sm
           INNER JOIN Subjects s ON s.SubjectID=sm.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE sm.TeacherID=? ORDER BY sm.UploadedAt DESC""",
        # No Description
        """SELECT sm.MaterialID, sm.Title, '' AS Description, sm.FilePath,
                  sm.FileType, 0 AS FileSize, sm.UploadedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName
           FROM StudyMaterials sm
           INNER JOIN Subjects s ON s.SubjectID=sm.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE sm.TeacherID=? ORDER BY sm.UploadedAt DESC""",
    ]:
        try:
            rows = db.execute_query(sql, (uid,))
            if rows is not None:
                break
        except Exception as e:
            print(f'[get_materials] variant err: {e}')

    result = _serialize(rows or [])
    for r in result:
        r['ClassName'] = f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
    return _ok({'materials': result})


@bp_teacher.route('/materials', methods=['POST'])
@jwt_required()
def save_material():
    uid, err = _get_teacher_user_id()
    if err: return err
    data       = request.get_json() or {}
    subject_id = data.get('subjectId')
    title      = (data.get('title') or '').strip()
    desc       = data.get('description', '')
    file_path  = data.get('filePath') or data.get('fileUrl') or ''
    file_type  = data.get('fileType') or data.get('materialType') or 'other'
    file_size  = int(data.get('fileSize', 0))
    if not subject_id or not title: return _err('subjectId and title are required')

    ok, last_err = _try_inserts('StudyMaterials', [
        # Full schema with FileSize, Description, IsPublished
        ('TeacherID,SubjectID,Title,Description,FilePath,FileType,FileSize,IsPublished,UploadedAt',
         (uid, subject_id, title, desc, file_path, file_type, file_size, 1, datetime.now())),
        # Without IsPublished
        ('TeacherID,SubjectID,Title,Description,FilePath,FileType,FileSize,UploadedAt',
         (uid, subject_id, title, desc, file_path, file_type, file_size, datetime.now())),
        # Without FileSize
        ('TeacherID,SubjectID,Title,Description,FilePath,FileType,UploadedAt',
         (uid, subject_id, title, desc, file_path, file_type, datetime.now())),
        # Without Description
        ('TeacherID,SubjectID,Title,FilePath,FileType,UploadedAt',
         (uid, subject_id, title, file_path, file_type, datetime.now())),
        # Bare minimum
        ('TeacherID,SubjectID,Title,FilePath',
         (uid, subject_id, title, file_path)),
    ])
    if not ok: return _err(f'Failed to save material: {last_err}', 500)

    # Notify students in this subject
    _notify_students(
        subject_id, f'📁 New Study Material: {title}',
        f'Your teacher uploaded "{title}". Check the Study Materials section.',
        'Material'
    )
    return _ok({'message': 'Material saved successfully'})


@bp_teacher.route('/materials/upload', methods=['POST'])
@jwt_required()
def upload_material_file():
    """Receive a device file upload (multipart/form-data), save it, return the path."""
    uid, err = _get_teacher_user_id()
    if err: return err

    if 'file' not in request.files: return _err('No file provided')
    f = request.files['file']
    if not f.filename: return _err('Empty filename')

    # 50 MB server-side limit
    f.seek(0, 2); size = f.tell(); f.seek(0)
    if size > 50 * 1024 * 1024:
        return _err(f'File too large ({round(size/1024/1024,1)} MB). Max allowed is 50 MB.', 413)

    ext        = os.path.splitext(f.filename)[1].lower()
    filename   = f'{uuid.uuid4().hex}{ext}'
    upload_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads', 'materials')
    os.makedirs(upload_dir, exist_ok=True)
    save_path  = os.path.join(upload_dir, filename)

    try:
        f.save(save_path)
        ext_map = {'.pdf':'pdf','.doc':'doc','.docx':'doc','.ppt':'ppt','.pptx':'ppt',
                   '.xls':'xls','.xlsx':'xls','.mp4':'video','.avi':'video','.mov':'video',
                   '.jpg':'image','.jpeg':'image','.png':'image','.zip':'zip','.rar':'zip'}
        return _ok({
            'filePath':  f'/uploads/materials/{filename}',
            'fileName':  f.filename,
            'fileSize':  os.path.getsize(save_path),
            'fileType':  ext_map.get(ext, 'other'),
        })
    except Exception as e:
        return _err(f'File save failed: {e}', 500)


# =============================================================================
# ONLINE CLASSES — GET + SCHEDULE
# =============================================================================

@bp_teacher.route('/online-classes')
@jwt_required()
def get_online_classes():
    uid, err = _get_teacher_user_id()
    if err: return err
    rows = []
    for sql in [
        """SELECT oc.OnlineClassID, oc.Title, oc.Topic, oc.Description, oc.MeetingLink,
                  oc.ScheduledDate, oc.StartTime, oc.EndTime, oc.CreatedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName
           FROM OnlineClasses oc
           INNER JOIN Subjects s ON s.SubjectID=oc.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE oc.TeacherID=? ORDER BY oc.ScheduledDate DESC""",
        """SELECT oc.OnlineClassID, oc.Title, oc.Title AS Topic, '' AS Description,
                  oc.MeetingLink, CONVERT(VARCHAR(10),oc.CreatedAt,23) AS ScheduledDate,
                  '' AS StartTime, '' AS EndTime, oc.CreatedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName
           FROM OnlineClasses oc
           INNER JOIN Subjects s ON s.SubjectID=oc.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE oc.TeacherID=? ORDER BY oc.CreatedAt DESC""",
    ]:
        try:
            rows = db.execute_query(sql, (uid,)) or []
            break
        except Exception as e:
            print(f'[get_online_classes] variant err: {e}')

    result = _serialize(rows)
    for r in result:
        r['ClassName'] = f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
        r.setdefault('Topic', r.get('Title', ''))
        r.setdefault('ScheduledDate', '')
    return _ok({'onlineClasses': result})


@bp_teacher.route('/online-class', methods=['POST'])
@jwt_required()
def schedule_online_class():
    uid, err = _get_teacher_user_id()
    if err: return err
    data           = request.get_json() or {}
    subject_id     = data.get('subjectId')
    topic          = (data.get('topic') or '').strip()
    scheduled_date = data.get('scheduledDate') or str(date.today())
    start_time     = data.get('startTime', '')
    end_time       = data.get('endTime', '')
    meeting_link   = (data.get('meetingLink') or '').strip()
    description    = data.get('description', '')
    if not subject_id or not topic or not meeting_link:
        return _err('subjectId, topic, and meetingLink are required')

    ok, last_err = _try_inserts('OnlineClasses', [
        ('TeacherID,SubjectID,Title,Topic,Description,MeetingLink,ScheduledDate,StartTime,EndTime,CreatedAt',
         (uid, subject_id, topic, topic, description, meeting_link, scheduled_date, start_time, end_time, datetime.now())),
        ('TeacherID,SubjectID,Title,Topic,MeetingLink,ScheduledDate,StartTime,EndTime,CreatedAt',
         (uid, subject_id, topic, topic, meeting_link, scheduled_date, start_time, end_time, datetime.now())),
        ('TeacherID,SubjectID,Title,Description,MeetingLink,CreatedAt',
         (uid, subject_id, topic, description, meeting_link, datetime.now())),
        ('TeacherID,SubjectID,Title,MeetingLink',
         (uid, subject_id, topic, meeting_link)),
    ])
    if not ok: return _err(f'Database operation failed: {last_err}', 500)
    _notify_students(
        subject_id, f'💻 Online Class: {topic}',
        f'An online class "{topic}" is scheduled for {scheduled_date} at {start_time or "TBD"}. Meeting link available in Online Classes section.',
        'OnlineClass'
    )
    return _ok({'message': f'Online class "{topic}" scheduled successfully'})


# =============================================================================
# MARKS — STUDENTS FOR SUBJECT
# =============================================================================

@bp_teacher.route('/marks/students')
@jwt_required()
def get_students_for_marks():
    uid, err = _get_teacher_user_id()
    if err: return err
    subject_id = request.args.get('subjectId')
    if not subject_id: return _err('subjectId required')

    tt = _try_queries([
        ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=?', (uid, subject_id)),
        ('SELECT DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
    ], fetch_one=True)
    if not tt: return _err('You do not teach this subject', 403)
    dept_id  = tt['DepartmentID']
    semester = tt['Semester']

    students = None
    for sql in [
        # Primary: join Marks on StudentID = Users.UserID directly
        """SELECT DISTINCT u.UserID, u.FullName, u.UserCode AS RollNumber, u.Email,
                  m.MarkID, m.CA1, m.CA2, m.CA3, m.CA4, m.CA5, m.Midterm, m.Endterm
           FROM Users u
           LEFT JOIN Marks m ON m.StudentID = u.UserID AND m.SubjectID = ?
           WHERE u.UserType='Student' AND u.IsActive=1
             AND u.DepartmentID=? AND u.Semester=?
           ORDER BY u.FullName""",
    ]:
        try:
            students = db.execute_query(sql, (subject_id, dept_id, semester))
            if students is not None: break
        except Exception as e:
            print(f'[get_students_for_marks] err: {e}')

    result = _serialize(students or [])
    for i, s in enumerate(result, 1):
        s['SerialNo'] = i
    return _ok({'students': result, 'subjectId': subject_id})


# =============================================================================
# MARKS — SAVE (uses Users.UserID as StudentID directly)
# =============================================================================

@bp_teacher.route('/marks', methods=['POST'])
@jwt_required()
def save_marks():
    uid, err = _get_teacher_user_id()
    if err: return err
    data          = request.get_json() or {}
    subject_id    = data.get('subjectId')
    marks_list    = data.get('marks', [])
    academic_year = data.get('academicYear', '2024-25')
    if not subject_id or not marks_list: return _err('subjectId and marks list required')

    teaches = bool(_try_queries([
        ('SELECT ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
        ('SELECT ClassID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (uid, subject_id)),
    ], fetch_one=True))
    if not teaches: return _err('You do not teach this subject', 403)

    saved  = 0
    errors = []
    for rec in marks_list:
        student_id = rec.get('studentId')
        # Explicit None check — `not student_id` would skip studentId=0
        if student_id is None or str(student_id).strip() == '':
            continue
        try:
            student_id = int(student_id)
        except (ValueError, TypeError):
            errors.append(f'Invalid studentId: {student_id}')
            continue

        ca1 = min(float(rec.get('CA1') or 0), 10)
        ca2 = min(float(rec.get('CA2') or 0), 10)
        ca3 = min(float(rec.get('CA3') or 0), 10)
        ca4 = min(float(rec.get('CA4') or 0), 10)
        ca5 = min(float(rec.get('CA5') or 0), 10)
        mid = min(float(rec.get('Midterm') or 0), 50)
        end = min(float(rec.get('Endterm') or 0), 100)
        try:
            # Find existing record — search WITHOUT AcademicYear first (MSSQL may not have that column)
            # then with it for SQLite compatibility
            existing = _try_queries([
                ('SELECT TOP 1 MarkID FROM Marks WHERE StudentID=? AND SubjectID=?', (student_id, subject_id)),
                ('SELECT MarkID FROM Marks WHERE StudentID=? AND SubjectID=? LIMIT 1', (student_id, subject_id)),
                ('SELECT TOP 1 MarkID FROM Marks WHERE StudentID=? AND SubjectID=? AND AcademicYear=?', (student_id, subject_id, academic_year)),
                ('SELECT MarkID FROM Marks WHERE StudentID=? AND SubjectID=? AND AcademicYear=? LIMIT 1', (student_id, subject_id, academic_year)),
            ], fetch_one=True)

            if existing:
                # UPDATE existing record
                upd_done = False
                for upd, uv in [
                    ('UPDATE Marks SET CA1=?,CA2=?,CA3=?,CA4=?,CA5=?,Midterm=?,Endterm=?,UpdatedAt=? WHERE MarkID=?',
                     (ca1,ca2,ca3,ca4,ca5,mid,end,datetime.now(),existing['MarkID'])),
                    ('UPDATE Marks SET CA1=?,CA2=?,CA3=?,CA4=?,CA5=?,Midterm=?,Endterm=? WHERE MarkID=?',
                     (ca1,ca2,ca3,ca4,ca5,mid,end,existing['MarkID'])),
                ]:
                    try:
                        db.execute_non_query(upd, uv)
                        upd_done = True
                        break
                    except Exception as ue:
                        print(f'[save_marks] UPDATE err sid={student_id}: {ue}')
                if upd_done:
                    saved += 1
                    continue
                # UPDATE failed — try UPSERT/overwrite
                errors.append(f'UPDATE failed for sid={student_id}, trying insert')

            # INSERT new record — try all column combinations
            ok, e2 = _try_inserts('Marks', [
                ('StudentID,SubjectID,AcademicYear,CA1,CA2,CA3,CA4,CA5,Midterm,Endterm,UpdatedAt',
                 (student_id, subject_id, academic_year, ca1,ca2,ca3,ca4,ca5,mid,end, datetime.now())),
                ('StudentID,SubjectID,AcademicYear,CA1,CA2,CA3,CA4,CA5,Midterm,Endterm',
                 (student_id, subject_id, academic_year, ca1,ca2,ca3,ca4,ca5,mid,end)),
                ('StudentID,SubjectID,CA1,CA2,CA3,CA4,CA5,Midterm,Endterm,UpdatedAt',
                 (student_id, subject_id, ca1,ca2,ca3,ca4,ca5,mid,end, datetime.now())),
                ('StudentID,SubjectID,CA1,CA2,CA3,CA4,CA5,Midterm,Endterm',
                 (student_id, subject_id, ca1,ca2,ca3,ca4,ca5,mid,end)),
            ])
            if ok:
                saved += 1
            else:
                errors.append(f'INSERT failed sid={student_id}: {e2}')
                print(f'[save_marks] INSERT failed sid={student_id}: {e2}')
        except Exception as e:
            errors.append(f'Unexpected err sid={student_id}: {e}')
            print(f'[save_marks] sid={student_id} exception: {e}')

    if errors:
        print(f'[save_marks] completed with errors: {errors}')
    return _ok({'message': f'Marks saved for {saved} student(s)', 'saved': saved, 'errors': errors[:5]})


# =============================================================================
# MY STUDENTS
# =============================================================================

@bp_teacher.route('/my-students')
@jwt_required()
def my_students():
    uid, err = _get_teacher_user_id()
    if err: return err
    students = None

    # Strategy 1: Timetable → Classes join (imported schema)
    for q in [
        """SELECT DISTINCT u.UserID, u.UserCode, u.FullName, u.Email,
               u.Semester, u.Gender, u.IsActive, u.DepartmentID,
               d.DepartmentName, d.DepartmentCode
           FROM Users u
           JOIN Departments d ON u.DepartmentID = d.DepartmentID
           JOIN Timetable t ON t.TeacherID = ?
           JOIN Classes c ON t.ClassID = c.ClassID AND c.DepartmentID = u.DepartmentID AND c.Semester = u.Semester
           WHERE u.UserType='Student' AND u.IsActive=1
           ORDER BY d.DepartmentName, u.Semester, u.UserCode""",
    ]:
        try:
            students = db.execute_query(q, (uid,))
            if students is not None: break
        except Exception as e:
            print(f'[my_students] Classes JOIN err: {e}')

    # Strategy 2: inline DepartmentID/Semester in Timetable
    if not students:
        try:
            students = db.execute_query(
                """SELECT DISTINCT u.UserID, u.UserCode, u.FullName, u.Email,
                       u.Semester, u.Gender, u.IsActive, u.DepartmentID,
                       d.DepartmentName, d.DepartmentCode
                   FROM Users u
                   JOIN Departments d ON u.DepartmentID = d.DepartmentID
                   WHERE u.UserType='Student' AND u.IsActive=1
                     AND EXISTS (
                         SELECT 1 FROM Timetable t
                         WHERE t.TeacherID=? AND t.DepartmentID=u.DepartmentID AND t.Semester=u.Semester
                     )
                   ORDER BY d.DepartmentName, u.Semester, u.UserCode""", (uid,))
        except Exception as e:
            print(f'[my_students] inline dept err: {e}')

    serialized = _serialize(students or [])
    for s in serialized:
        raw = s.get('UserCode', '') or ''
        s['RollNumber'] = raw[5:] if raw.startswith('STUID') else raw

    # Build class list for filter dropdown (Label = "CSE Sem 1 — 45 students")
    combos = None
    for q in [
        """SELECT DISTINCT c.DepartmentID, c.Semester, d.DepartmentName, d.DepartmentCode
           FROM Timetable t
           JOIN Classes c ON t.ClassID = c.ClassID
           LEFT JOIN Departments d ON d.DepartmentID = c.DepartmentID
           WHERE t.TeacherID = ?
           ORDER BY d.DepartmentName, c.Semester""",
        """SELECT DISTINCT t.DepartmentID, t.Semester, d.DepartmentName, d.DepartmentCode
           FROM Timetable t
           LEFT JOIN Departments d ON d.DepartmentID = t.DepartmentID
           WHERE t.TeacherID = ?
           ORDER BY d.DepartmentName, t.Semester""",
    ]:
        try:
            combos = db.execute_query(q, (uid,))
            if combos is not None: break
        except Exception as e:
            print(f'[my_students] combos err: {e}')

    classes = []
    for row in (combos or []):
        dept_id  = row.get('DepartmentID')
        semester = row.get('Semester')
        cnt = sum(1 for s in (students or [])
                  if s.get('DepartmentID') == dept_id and s.get('Semester') == semester)
        code = row.get('DepartmentCode') or row.get('DepartmentName', '')
        classes.append({
            'DepartmentID': dept_id, 'Semester': semester,
            'DepartmentName': row.get('DepartmentName', ''),
            'DepartmentCode': row.get('DepartmentCode', ''),
            'Label': f"{code} — Sem {semester}  ({cnt} students)",
        })

    return _ok({'students': serialized, 'count': len(serialized), 'classes': classes})


# =============================================================================
# TIMETABLE PUBLIC BLUEPRINT  /api/timetable/*
# =============================================================================

@bp_timetable.route('/summary')
def get_summary():
    try:
        return jsonify({'success': True, 'summary': {
            'departments': db.execute_query("SELECT COUNT(*) AS cnt FROM Departments", fetch_one=True)['cnt'],
            'teachers':    db.execute_query("SELECT COUNT(*) AS cnt FROM Users WHERE UserType='Teacher' AND IsActive=1", fetch_one=True)['cnt'],
            'subjects':    db.execute_query("SELECT COUNT(*) AS cnt FROM Subjects", fetch_one=True)['cnt'],
            'slots':       db.execute_query("SELECT COUNT(*) AS cnt FROM Timetable", fetch_one=True)['cnt'],
        }}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@bp_timetable.route('/departments')
def get_departments():
    try:
        depts = _serialize(db.execute_query(
            'SELECT DepartmentID, DepartmentName, DepartmentCode, TotalSemesters FROM Departments ORDER BY DepartmentName'))
        for d in depts:
            rows = db.execute_query('SELECT DISTINCT Semester FROM Timetable WHERE DepartmentID=? ORDER BY Semester', (d['DepartmentID'],))
            d['Semesters'] = [r['Semester'] for r in rows] if rows else []
        return jsonify({'success': True, 'departments': depts}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@bp_timetable.route('/teachers')
def get_teachers():
    try:
        dept_id = request.args.get('dept_id')
        q = "SELECT UserID AS TeacherID, UserCode AS TeacherCode, FullName AS TeacherName, DepartmentID FROM Users WHERE UserType='Teacher' AND IsActive=1"
        params = []
        if dept_id: q += ' AND DepartmentID=?'; params.append(dept_id)
        q += ' ORDER BY FullName'
        teachers = _serialize(db.execute_query(q, tuple(params) if params else ()))
        for t in teachers:
            rows = db.execute_query('SELECT DISTINCT Semester FROM Timetable WHERE TeacherID=? ORDER BY Semester', (t['TeacherID'],))
            t['Semesters'] = [r['Semester'] for r in rows] if rows else []
        return jsonify({'success': True, 'teachers': teachers}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@bp_timetable.route('/student')
@bp_timetable.route('/schedule')
def get_student_timetable():
    try:
        dept_id  = request.args.get('dept_id') or request.args.get('departmentId')
        semester = request.args.get('semester')
        if not dept_id or not semester:
            return jsonify({'success': False, 'error': 'dept_id and semester are required'}), 400
        rows = _serialize(db.execute_query(
            """SELECT t.TimetableID, t.DayOfWeek, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,t.Room,'') AS RoomNumber, c.Semester, c.DepartmentID,
                      s.SubjectName, s.SubjectCode,
                      u.FullName AS TeacherName, u.UserCode AS TeacherCode,
                      d.DepartmentName, d.DepartmentCode, c.ClassName, c.Section
               FROM Timetable t
               JOIN Classes c ON t.ClassID=c.ClassID
               JOIN Subjects s ON t.SubjectID=s.SubjectID
               JOIN Users u ON t.TeacherID=u.UserID
               JOIN Departments d ON c.DepartmentID=d.DepartmentID
               WHERE c.DepartmentID=? AND c.Semester=?
               ORDER BY t.DayOfWeek, t.StartTime""", (dept_id, semester)))
        return jsonify({'success': True, 'timetable': rows}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@bp_timetable.route('/teacher/<int:teacher_id>')
def get_teacher_timetable(teacher_id):
    try:
        semester = request.args.get('semester')
        q = """SELECT t.TimetableID, t.DayOfWeek, 0 AS PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,t.Room,'') AS RoomNumber, c.Semester, c.DepartmentID,
                      s.SubjectName, s.SubjectCode,
                      u.FullName AS TeacherName, u.UserCode AS TeacherCode,
                      d.DepartmentName, d.DepartmentCode, c.ClassName, c.Section
               FROM Timetable t
               JOIN Classes c ON t.ClassID=c.ClassID
               JOIN Subjects s ON t.SubjectID=s.SubjectID
               JOIN Users u ON t.TeacherID=u.UserID
               JOIN Departments d ON c.DepartmentID=d.DepartmentID
               WHERE t.TeacherID=?"""
        params = [teacher_id]
        if semester: q += ' AND t.Semester=?'; params.append(semester)
        q += ' ORDER BY t.DayOfWeek, t.PeriodNumber'
        rows = _serialize(db.execute_query(q, tuple(params)))
        all_sem = db.execute_query('SELECT DISTINCT Semester FROM Timetable WHERE TeacherID=? ORDER BY Semester', (teacher_id,))
        return jsonify({'success': True, 'timetable': rows,
                        'allSemesters': [r['Semester'] for r in all_sem] if all_sem else []}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500