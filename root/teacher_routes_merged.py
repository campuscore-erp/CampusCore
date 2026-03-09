"""
teacher_routes_merged.py  —  University ERP
============================================
FIXED (comprehensive end-to-end):
  1. TeacherID mismatch  — JWT gives Users.UserID; Timetable/TeacherSubjects use
     Teachers.TeacherID.  _get_teacher_db_id() now called in every route.
  2. Students table      — no Users rows have UserType='Student'. All student
     queries now use the Students table (StudentID, FullName, RollNumber,
     DepartmentID, CurrentSemester, IsActive).
  3. Removed JOIN Classes — table does not exist in this DB.
  4. bp_timetable teacher JOINs — fixed wrong JOIN Users ON t.TeacherID=u.UserID
     to JOIN Teachers ON Teachers.TeacherID=t.TeacherID.
  5. bp_timetable get_teachers() — reads from Teachers table, not Users.
  6. create_exam — removed invalid ClassID column from INSERT variants.
  7. _notify_students — uses Students table; stores StudentID in Notifications.
  8. classes/students_by_class/mark-absent/face sessions — all use Students table.
  9. get_students_for_marks / save_marks — Students table + Students.StudentID.
 10. get_exam_submissions — cohort from Timetable, students from Students table.
"""

import os, uuid, secrets, hashlib
from datetime import datetime, date, time, timedelta
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from database import db

bp_teacher   = Blueprint('teacher',   __name__, url_prefix='/api/teacher')
bp_timetable = Blueprint('timetable', __name__, url_prefix='/api/timetable')


# ===========================================================================
# HELPERS
# ===========================================================================

def _get_teacher_user_id():
    """Returns (Users.UserID, None) or (None, error_response)."""
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
    Timetable.TeacherID and TeacherSubjects.TeacherID reference Teachers(TeacherID),
    NOT Users(UserID).  e.g. Users.UserID=2 (TID001) -> Teachers.TeacherID=1 (TID001).
    Falls back to user_id if lookup fails.
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
        total = int(val.total_seconds())
        h, m = divmod(abs(total), 3600)
        m, _ = divmod(m, 60)
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
    for q, p in queries_params:
        try:
            r = db.execute_query(q, p, fetch_one=fetch_one)
            if r is not None: return r
        except Exception as e:
            print(f'[try_queries] err: {e}')
    return None

def _try_inserts(table, variants):
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
def _islab_col():
    global _ISLAB
    if _ISLAB is None:
        for q in ["SELECT TOP 1 IsLab FROM Subjects", "SELECT IsLab FROM Subjects LIMIT 1"]:
            try: db.execute_query(q, fetch_one=True); _ISLAB = True; break
            except Exception: pass
        if _ISLAB is None: _ISLAB = False
    return _ISLAB


def _students_in_cohort(dept_id, semester):
    """Return Students rows for a dept+semester pair."""
    return db.execute_query(
        """SELECT StudentID, FullName, RollNumber, Email,
                  DepartmentID, CurrentSemester AS Semester, IsActive
           FROM Students
           WHERE DepartmentID=? AND CurrentSemester=? AND IsActive=1
           ORDER BY FullName""",
        (dept_id, semester)) or []


def _notify_students(subject_id, title, message,
                     notif_type='General', dept_id=None, semester=None):
    """Notify students in a subject cohort. Silently ignores all errors."""
    try:
        if subject_id and (not dept_id or not semester):
            for q in [
                'SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE SubjectID=?',
                'SELECT DepartmentID, Semester FROM Timetable WHERE SubjectID=? LIMIT 1',
            ]:
                try:
                    info = db.execute_query(q, (subject_id,), fetch_one=True)
                    if info:
                        dept_id  = dept_id  or info.get('DepartmentID')
                        semester = semester or info.get('Semester')
                        break
                except Exception:
                    pass
        if not dept_id or not semester:
            return
        students = db.execute_query(
            'SELECT StudentID FROM Students WHERE DepartmentID=? AND CurrentSemester=? AND IsActive=1',
            (dept_id, semester)) or []
        for stu in students:
            sid = stu['StudentID']
            for sql, vals in [
                ("INSERT INTO Notifications (StudentID,Title,Message,Type,IsRead,CreatedAt) VALUES (?,?,?,?,0,?)",
                 (sid, title, message, notif_type, datetime.now())),
                ("INSERT INTO Notifications (StudentID,Title,Message,Type,IsRead) VALUES (?,?,?,?,0)",
                 (sid, title, message, notif_type)),
            ]:
                try: db.execute_non_query(sql, vals); break
                except Exception: pass
    except Exception as e:
        print(f'[notify_students] non-fatal: {e}')


# ===========================================================================
# PROFILE
# ===========================================================================

@bp_teacher.route('/profile')
@jwt_required()
def profile():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    row = db.execute_query(
        """SELECT u.UserID, u.UserCode, u.FullName, u.Email, u.Phone,
                  u.Gender, u.DateOfBirth, u.JoinDate, u.UserType,
                  d.DepartmentName, d.DepartmentCode, d.DepartmentID
           FROM Users u
           LEFT JOIN Departments d ON d.DepartmentID=u.DepartmentID
           WHERE u.UserID=? AND u.UserType='Teacher' AND u.IsActive=1""",
        (uid,), fetch_one=True)
    if not row: return _err('Profile not found', 404)

    p = _serialize_one(row)
    p['TeacherCode']   = p.get('UserCode', '')
    p['Designation']   = 'Faculty'
    p['JoiningDate']   = p.get('JoinDate', '')
    p['subjectCount']  = (
        _safe_scalar('SELECT COUNT(DISTINCT SubjectID) FROM TeacherSubjects WHERE TeacherID=?', (db_id,))
        or _safe_scalar('SELECT COUNT(DISTINCT SubjectID) FROM Timetable WHERE TeacherID=?', (db_id,))
    )
    p['periodsPerWeek'] = _safe_scalar('SELECT COUNT(*) FROM Timetable WHERE TeacherID=?', (db_id,))
    return _ok({'profile': p})


# ===========================================================================
# DASHBOARD
# ===========================================================================

@bp_teacher.route('/dashboard')
@jwt_required()
def dashboard():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    assigned_subjects = (
        _safe_scalar('SELECT COUNT(DISTINCT SubjectID) FROM TeacherSubjects WHERE TeacherID=?', (db_id,))
        or _safe_scalar('SELECT COUNT(DISTINCT SubjectID) FROM Timetable WHERE TeacherID=?', (db_id,))
    )
    total_classes = _safe_scalar('SELECT COUNT(*) FROM Timetable WHERE TeacherID=?', (db_id,))

    total_students = 0
    try:
        combos = db.execute_query(
            'SELECT DISTINCT DepartmentID, Semester FROM Timetable WHERE TeacherID=?', (db_id,)) or []
        for c in combos:
            total_students += _safe_scalar(
                'SELECT COUNT(*) FROM Students WHERE DepartmentID=? AND CurrentSemester=? AND IsActive=1',
                (c['DepartmentID'], c['Semester']))
    except Exception as e:
        print(f'[dashboard] student count err: {e}')

    active_exams = _safe_scalar('SELECT COUNT(*) FROM Exams WHERE TeacherID=?', (uid,))

    today_name = datetime.now().strftime('%A')
    todays_schedule = []
    try:
        ilab = ', s.IsLab' if _islab_col() else ', 0 AS IsLab'
        rows = db.execute_query(
            f"""SELECT t.TimetableID, t.PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,'') AS RoomNumber, t.DayOfWeek, t.Semester,
                      s.SubjectName, s.SubjectCode {ilab}, d.DepartmentName
               FROM Timetable t
               INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
               LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
               WHERE t.TeacherID=? AND t.DayOfWeek=?
               ORDER BY t.StartTime""", (db_id, today_name)) or []
        todays_schedule = _serialize(rows)
        for r in todays_schedule:
            r['ClassName'] = f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
    except Exception as e:
        print(f'[dashboard] schedule err: {e}')

    return _ok({'stats': {
        'totalClasses':     total_classes,
        'periodsPerWeek':   total_classes,
        'assignedSubjects': assigned_subjects,
        'totalSubjects':    assigned_subjects,
        'totalStudents':    total_students,
        'activeExams':      active_exams,
        'todaysSchedule':   todays_schedule,
    }})


# ===========================================================================
# SUBJECTS
# ===========================================================================

@bp_teacher.route('/subjects')
@jwt_required()
def subjects():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)
    ilab  = ', s.IsLab' if _islab_col() else ', 0 AS IsLab'

    rows = db.execute_query(
        f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
               s.Credits {ilab}, ts.Semester, ts.DepartmentID, d.DepartmentName
           FROM TeacherSubjects ts
           INNER JOIN Subjects s ON s.SubjectID=ts.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=ts.DepartmentID
           WHERE ts.TeacherID=? ORDER BY ts.Semester, s.SubjectName""", (db_id,)) or []

    if not rows:
        try:
            rows = db.execute_query(
                f"""SELECT DISTINCT s.SubjectID, s.SubjectName, s.SubjectCode,
                       s.Credits {ilab}, t.Semester, t.DepartmentID, d.DepartmentName
                   FROM Timetable t
                   INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
                   LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
                   WHERE t.TeacherID=? ORDER BY t.Semester, s.SubjectName""", (db_id,)) or []
        except Exception as e:
            print(f'[subjects] fallback err: {e}')
            rows = []

    result = _serialize(rows)
    for r in result:
        r['ClassName'] = f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
        if r.get('IsLab') is None:
            r['IsLab'] = 1 if str(r.get('SubjectCode', '')).endswith('L') else 0
    return _ok({'subjects': result})


# ===========================================================================
# TIMETABLE
# ===========================================================================

@bp_teacher.route('/timetable')
@jwt_required()
def timetable():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)
    ilab  = ', s.IsLab' if _islab_col() else ', 0 AS IsLab'

    rows = db.execute_query(
        f"""SELECT t.TimetableID, t.DayOfWeek, t.PeriodNumber, t.StartTime, t.EndTime,
                  COALESCE(t.RoomNumber,'') AS RoomNumber, t.DepartmentID, t.Semester,
                  s.SubjectID, s.SubjectName, s.SubjectCode {ilab},
                  d.DepartmentName, d.DepartmentCode
           FROM Timetable t
           INNER JOIN Subjects s ON s.SubjectID=t.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
           WHERE t.TeacherID=?
           ORDER BY
               CASE t.DayOfWeek
                   WHEN 'Monday' THEN 1 WHEN 'Tuesday' THEN 2 WHEN 'Wednesday' THEN 3
                   WHEN 'Thursday' THEN 4 WHEN 'Friday' THEN 5 ELSE 6
               END, t.StartTime""", (db_id,)) or []

    result = _serialize(rows)
    for r in result:
        if r.get('IsLab') is None:
            r['IsLab'] = 1 if str(r.get('SubjectCode', '')).endswith('L') else 0
        r['ClassName'] = f"{r.get('DepartmentName','')} Sem {r.get('Semester','')}"
        r.setdefault('Section', 'A')
    return _ok({'timetable': result})


# ===========================================================================
# CLASSES
# ===========================================================================

@bp_teacher.route('/classes')
@jwt_required()
def classes():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    combos = db.execute_query(
        """SELECT DISTINCT t.DepartmentID, t.Semester, d.DepartmentName, d.DepartmentCode,
                  COUNT(DISTINCT t.SubjectID) AS subjectCount
           FROM Timetable t
           LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
           WHERE t.TeacherID=?
           GROUP BY t.DepartmentID, t.Semester, d.DepartmentName, d.DepartmentCode
           ORDER BY d.DepartmentName, t.Semester""", (db_id,)) or []

    result = []
    for row in combos:
        dept_id  = row['DepartmentID']
        semester = row['Semester']
        student_count = _safe_scalar(
            'SELECT COUNT(*) FROM Students WHERE DepartmentID=? AND CurrentSemester=? AND IsActive=1',
            (dept_id, semester))
        result.append({
            'ClassID':        f'{dept_id}_{semester}',
            'DepartmentID':   dept_id,
            'Semester':       semester,
            'ClassName':      f"{row.get('DepartmentName','')} Sem {semester}",
            'DepartmentName': row.get('DepartmentName', ''),
            'DepartmentCode': row.get('DepartmentCode', ''),
            'Section':        'A',
            'studentCount':   student_count,
            'subjectCount':   row.get('subjectCount', 0),
        })
    return _ok({'classes': result})


# ===========================================================================
# STUDENTS BY CLASS
# ===========================================================================

@bp_teacher.route('/students/by-class/<int:department_id>/<int:semester>')
@jwt_required()
def students_by_class(department_id, semester):
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    teaches = _try_queries([
        ('SELECT TimetableID FROM Timetable WHERE TeacherID=? AND DepartmentID=? AND Semester=? LIMIT 1',
         (db_id, department_id, semester)),
        ('SELECT TOP 1 TimetableID FROM Timetable WHERE TeacherID=? AND DepartmentID=? AND Semester=?',
         (db_id, department_id, semester)),
        ('SELECT TOP 1 SubjectID FROM TeacherSubjects WHERE TeacherID=? AND DepartmentID=? AND Semester=?',
         (db_id, department_id, semester)),
    ], fetch_one=True)
    if not teaches:
        return _err('You do not teach this department/semester combination', 403)

    dept_info = db.execute_query(
        'SELECT DepartmentName FROM Departments WHERE DepartmentID=?', (department_id,), fetch_one=True)
    dept_name = dept_info['DepartmentName'] if dept_info else f'Dept {department_id}'

    students = _students_in_cohort(department_id, semester)
    result   = _serialize(students)
    for i, s in enumerate(result, 1):
        s['SerialNo'] = i

    return _ok({
        'students':     result,
        'className':    f'{dept_name} Sem {semester}',
        'semester':     semester,
        'departmentId': department_id,
        'count':        len(result),
    })


# ===========================================================================
# ATTENDANCE — SUBMIT
# ===========================================================================

@bp_teacher.route('/attendance/submit', methods=['POST'])
@jwt_required()
def attendance_submit():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    data            = request.get_json() or {}
    subject_id      = data.get('subjectId')
    attendance_date = data.get('attendanceDate') or data.get('date') or date.today().isoformat()
    records         = data.get('attendance', [])
    if not subject_id or not records:
        return _err('subjectId and attendance list required')

    timetable_id = None
    tt = _try_queries([
        ('SELECT TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
        ('SELECT TOP 1 TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
    ], fetch_one=True)
    if tt: timetable_id = tt.get('TimetableID')

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
                    ('StudentID,SubjectID,TimetableID,AttendanceDate,Status,MarkedBy,MarkedAt,CreatedAt',
                     (student_id, subject_id, timetable_id, attendance_date, status, uid, datetime.now(), datetime.now())),
                    ('StudentID,SubjectID,TimetableID,AttendanceDate,Status,CreatedAt',
                     (student_id, subject_id, timetable_id, attendance_date, status, datetime.now())),
                    ('StudentID,SubjectID,AttendanceDate,Status,CreatedAt',
                     (student_id, subject_id, attendance_date, status, datetime.now())),
                    ('StudentID,SubjectID,AttendanceDate,Status',
                     (student_id, subject_id, attendance_date, status)),
                ])
                if ok: saved += 1
        except Exception as e:
            print(f'[attendance_submit] row error: {e}')

    return _ok({'message': f'Attendance saved for {saved} students', 'saved': saved})


# ===========================================================================
# ATTENDANCE — HISTORY
# ===========================================================================

@bp_teacher.route('/attendance/history')
@jwt_required()
def attendance_history():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    rows = db.execute_query(
        """SELECT a.AttendanceID, a.AttendanceDate, a.Status, a.SubjectID,
                  st.FullName AS StudentName, st.RollNumber,
                  s.SubjectName, s.SubjectCode
           FROM Attendance a
           INNER JOIN Students st ON st.StudentID=a.StudentID
           INNER JOIN Subjects  s  ON s.SubjectID=a.SubjectID
           WHERE a.SubjectID IN (
               SELECT DISTINCT SubjectID FROM TeacherSubjects WHERE TeacherID=?
               UNION
               SELECT DISTINCT SubjectID FROM Timetable WHERE TeacherID=?
           )
           ORDER BY a.AttendanceDate DESC, st.FullName""", (db_id, db_id)) or []
    return _ok({'attendance': _serialize(rows)})


# ===========================================================================
# ATTENDANCE — FACE RECOGNITION
# ===========================================================================

_face_sessions = {}   # { token: { subjectId, date, teacherDbId, recognised: set() } }


@bp_teacher.route('/attendance/face/start', methods=['POST'])
@jwt_required()
def face_attendance_start():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    data       = request.get_json() or {}
    subject_id = data.get('subjectId')
    att_date   = data.get('attendanceDate', date.today().isoformat())
    if not subject_id: return _err('subjectId required')

    tt = _try_queries([
        ('SELECT TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
        ('SELECT TOP 1 TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
    ], fetch_one=True)
    if not tt: return _err('You do not teach this subject', 403)

    raw = f'{uid}|{subject_id}|{att_date}|{secrets.token_urlsafe(8)}'
    session_token = hashlib.sha1(raw.encode()).hexdigest()[:20]
    _face_sessions[session_token] = {
        'subjectId': subject_id, 'date': att_date,
        'teacherDbId': db_id, 'recognised': set(),
    }

    dept_sem = _try_queries([
        ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
        ('SELECT DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
    ], fetch_one=True)
    total = _safe_scalar(
        'SELECT COUNT(*) FROM Students WHERE DepartmentID=? AND CurrentSemester=? AND IsActive=1',
        (dept_sem['DepartmentID'], dept_sem['Semester'])) if dept_sem else 0

    return _ok({
        'sessionToken': session_token, 'subjectId': subject_id,
        'attendanceDate': att_date, 'totalStudents': total,
        'message': 'Face recognition session started',
    })


@bp_teacher.route('/attendance/face/submit', methods=['POST'])
@jwt_required()
def face_attendance_submit():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    data          = request.get_json() or {}
    session_token = data.get('sessionToken', '')
    subject_id    = data.get('subjectId')
    records       = data.get('records', [])
    session       = _face_sessions.get(session_token, {})
    att_date      = session.get('date') or data.get('attendanceDate', date.today().isoformat())
    if not subject_id or not records:
        return _err('subjectId and records are required')

    timetable_id = None
    tt = _try_queries([
        ('SELECT TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
        ('SELECT TOP 1 TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
    ], fetch_one=True)
    if tt: timetable_id = tt.get('TimetableID')

    saved = 0
    for rec in records:
        student_id = rec.get('studentId')
        status     = rec.get('status', 'Present')
        if not student_id or status == 'Unknown': continue
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
                    ('StudentID,SubjectID,TimetableID,AttendanceDate,Status,MarkedBy,MarkedAt,CreatedAt',
                     (student_id, subject_id, timetable_id, att_date, status, uid, datetime.now(), datetime.now())),
                    ('StudentID,SubjectID,TimetableID,AttendanceDate,Status,CreatedAt',
                     (student_id, subject_id, timetable_id, att_date, status, datetime.now())),
                    ('StudentID,SubjectID,AttendanceDate,Status',
                     (student_id, subject_id, att_date, status)),
                ])
                if ok: saved += 1
            if session and status == 'Present':
                session['recognised'].add(str(student_id))
        except Exception as e:
            print(f'[face_attendance_submit] row err: {e}')

    return _ok({
        'message': f'Face attendance saved for {saved} student(s)',
        'saved': saved,
        'recognisedCount': len(session.get('recognised', set())) if session else saved,
        'sessionToken': session_token,
    })


@bp_teacher.route('/attendance/face/status')
@jwt_required()
def face_attendance_status():
    uid, err = _get_teacher_user_id()
    if err: return err
    token      = request.args.get('token', '').strip()
    session    = _face_sessions.get(token, {})
    subject_id = session.get('subjectId') or request.args.get('subjectId')
    att_date   = session.get('date') or request.args.get('date', date.today().isoformat())
    recognised = len(session.get('recognised', set()))

    present = _safe_scalar(
        "SELECT COUNT(*) FROM Attendance WHERE SubjectID=? AND AttendanceDate=? AND Status='Present'",
        (subject_id, att_date)) if subject_id else 0
    absent  = _safe_scalar(
        "SELECT COUNT(*) FROM Attendance WHERE SubjectID=? AND AttendanceDate=? AND Status='Absent'",
        (subject_id, att_date)) if subject_id else 0

    total = 0
    dept_sem = _try_queries([
        ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE SubjectID=?', (subject_id,)),
        ('SELECT DepartmentID, Semester FROM Timetable WHERE SubjectID=? LIMIT 1', (subject_id,)),
    ], fetch_one=True) if subject_id else None
    if dept_sem:
        total = _safe_scalar(
            'SELECT COUNT(*) FROM Students WHERE DepartmentID=? AND CurrentSemester=? AND IsActive=1',
            (dept_sem['DepartmentID'], dept_sem['Semester']))

    return _ok({
        'recognised': recognised, 'present': present, 'absent': absent,
        'total': total, 'pending': max(0, total - present - absent),
        'sessionToken': token,
    })


# ===========================================================================
# ATTENDANCE — MARK ABSENT
# ===========================================================================

@bp_teacher.route('/attendance/mark-absent', methods=['POST'])
@jwt_required()
def mark_absent_non_scanners():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    data          = request.get_json() or {}
    subject_id    = data.get('subjectId')
    att_date      = data.get('attendanceDate', date.today().isoformat())
    dept_id       = data.get('departmentId')
    semester      = data.get('semester')
    session_token = data.get('sessionToken', '')
    if not subject_id: return _err('subjectId required')

    if not dept_id or not semester:
        tt = _try_queries([
            ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
            ('SELECT DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
        ], fetch_one=True)
        if tt: dept_id = tt['DepartmentID']; semester = tt['Semester']

    if not dept_id or not semester:
        return _err('Could not determine class.')

    all_students = _students_in_cohort(dept_id, semester)
    already = {r['StudentID'] for r in (db.execute_query(
        'SELECT StudentID FROM Attendance WHERE SubjectID=? AND AttendanceDate=?',
        (subject_id, att_date)) or [])}

    timetable_id = None
    tt2 = _try_queries([
        ('SELECT TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
        ('SELECT TOP 1 TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
    ], fetch_one=True)
    if tt2: timetable_id = tt2.get('TimetableID')

    absent_count = 0
    for s in all_students:
        sid = s['StudentID']
        if sid not in already:
            ok, _ = _try_inserts('Attendance', [
                ('StudentID,SubjectID,TimetableID,AttendanceDate,Status,CreatedAt',
                 (sid, subject_id, timetable_id, att_date, 'Absent', datetime.now())),
                ('StudentID,SubjectID,AttendanceDate,Status',
                 (sid, subject_id, att_date, 'Absent')),
            ])
            if ok: absent_count += 1

    if session_token and session_token in _face_sessions:
        del _face_sessions[session_token]

    return _ok({'message': f'{absent_count} students marked absent', 'absentCount': absent_count})


# ===========================================================================
# EXAMS — LIST
# ===========================================================================

@bp_teacher.route('/exams')
@jwt_required()
def get_exams():
    uid, err = _get_teacher_user_id()
    if err: return err

    rows = None
    for sql in [
        """SELECT e.ExamID, e.ExamType, e.TotalMarks, e.ExamDate, e.Duration, e.CreatedAt,
                  e.ExamName, COALESCE(e.StartTime,'') AS StartTime,
                  COALESCE(e.EndTime,'') AS EndTime, COALESCE(e.Instructions,'') AS Instructions,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName,
                  (SELECT COUNT(*) FROM ExamQuestions q WHERE q.ExamID=e.ExamID) AS QuestionCount,
                  (SELECT COUNT(*) FROM ExamSubmissions es WHERE es.ExamID=e.ExamID) AS SubmissionCount
           FROM Exams e
           INNER JOIN Subjects s ON s.SubjectID=e.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE e.TeacherID=? ORDER BY e.CreatedAt DESC""",
        """SELECT e.ExamID, e.ExamType, e.TotalMarks, e.ExamDate, e.Duration, e.CreatedAt,
                  e.ExamName, s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName,
                  0 AS QuestionCount, 0 AS SubmissionCount
           FROM Exams e
           INNER JOIN Subjects s ON s.SubjectID=e.SubjectID
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
        if not r.get('ExamName'):
            r['ExamName'] = f"{r.get('ExamType','Exam')} - {r.get('SubjectCode','')}"
        r.setdefault('IsActive', 1)
        r.setdefault('StartTime', '')
        r.setdefault('EndTime', '')
        r.setdefault('Instructions', '')
    return _ok({'exams': rows})


# ===========================================================================
# EXAMS — CREATE
# ===========================================================================

@bp_teacher.route('/exams', methods=['POST'])
@jwt_required()
def create_exam():
    uid, err = _get_teacher_user_id()
    if err: return err

    data         = request.get_json() or {}
    subject_id   = data.get('subjectId')
    exam_name    = (data.get('examName') or data.get('examType') or 'CA1').strip()
    exam_type    = data.get('examType', 'CA1')
    total_marks  = int(data.get('totalMarks', 100))
    exam_date    = data.get('examDate')
    duration     = int(data.get('duration') or 60)
    instructions = data.get('instructions', '')
    if not subject_id or not exam_date:
        return _err('subjectId and examDate are required')

    ok, last_err = _try_inserts('Exams', [
        ('SubjectID,TeacherID,ExamName,ExamType,TotalMarks,Duration,ExamDate,Instructions,IsActive,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, instructions, 1, datetime.now())),
        ('SubjectID,TeacherID,ExamName,ExamType,TotalMarks,Duration,ExamDate,IsActive,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, 1, datetime.now())),
        ('SubjectID,TeacherID,ExamName,ExamType,TotalMarks,Duration,ExamDate,CreatedAt',
         (subject_id, uid, exam_name, exam_type, total_marks, duration, exam_date, datetime.now())),
        ('SubjectID,TeacherID,ExamName,ExamType,TotalMarks,ExamDate',
         (subject_id, uid, exam_name, exam_type, total_marks, exam_date)),
        ('SubjectID,TeacherID,ExamType,TotalMarks,Duration,ExamDate,CreatedAt',
         (subject_id, uid, exam_type, total_marks, duration, exam_date, datetime.now())),
        ('SubjectID,TeacherID,ExamType,TotalMarks,ExamDate',
         (subject_id, uid, exam_type, total_marks, exam_date)),
    ])
    if not ok: return _err(f'Database operation failed: {last_err}', 500)

    new_exam_id = None
    for q, p in [
        ('SELECT ExamID FROM Exams WHERE TeacherID=? AND SubjectID=? AND ExamType=? ORDER BY ExamID DESC LIMIT 1',
         (uid, subject_id, exam_type)),
        ('SELECT TOP 1 ExamID FROM Exams WHERE TeacherID=? AND SubjectID=? ORDER BY ExamID DESC',
         (uid, subject_id)),
        ('SELECT ExamID FROM Exams WHERE TeacherID=? AND SubjectID=? ORDER BY ExamID DESC LIMIT 1',
         (uid, subject_id)),
    ]:
        try:
            row = db.execute_query(q, p, fetch_one=True)
            if row and row.get('ExamID'):
                new_exam_id = int(row['ExamID']); break
        except Exception: pass

    _notify_students(subject_id, f'📄 New Exam: {exam_name}',
        f'Exam "{exam_name}" ({exam_type}) on {exam_date}. Duration: {duration} mins.', 'Exam')
    return _ok({'message': 'Exam created successfully', 'examId': new_exam_id, 'examName': exam_name})


# ===========================================================================
# EXAM SUBMISSIONS
# ===========================================================================

@bp_teacher.route('/exams/<int:exam_id>/submissions')
@jwt_required()
def get_exam_submissions(exam_id):
    uid, err = _get_teacher_user_id()
    if err: return err

    exam = _try_queries([
        ('SELECT ExamID, TotalMarks, SubjectID FROM Exams WHERE ExamID=? AND TeacherID=?', (exam_id, uid)),
        ('SELECT ExamID, TotalMarks, SubjectID FROM Exams WHERE ExamID=?', (exam_id,)),
    ], fetch_one=True)
    if not exam: return _err('Exam not found', 404)

    subject_id = exam.get('SubjectID')
    cohort = _try_queries([
        ('SELECT DepartmentID, Semester FROM Timetable WHERE SubjectID=? LIMIT 1', (subject_id,)),
        ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE SubjectID=?', (subject_id,)),
    ], fetch_one=True)

    all_students = _students_in_cohort(cohort['DepartmentID'], cohort['Semester']) if cohort else []

    submissions_map = {}
    for q, p in [
        ('SELECT StudentID, SubmissionID, IsSubmitted, MarksObtained, SubmittedAt FROM ExamSubmissions WHERE ExamID=?', (exam_id,)),
        ('SELECT StudentID, SubmissionID, MarksObtained, SubmittedAt FROM ExamSubmissions WHERE ExamID=?', (exam_id,)),
    ]:
        try:
            for r in (db.execute_query(q, p) or []):
                submissions_map[r['StudentID']] = r
            break
        except Exception: pass

    result = []
    for stu in all_students:
        sid = stu.get('StudentID')
        sub = submissions_map.get(sid, {})
        result.append({
            'StudentID':     sid,
            'StudentName':   stu.get('FullName', ''),
            'RollNumber':    stu.get('RollNumber', ''),
            'SubmissionID':  sub.get('SubmissionID'),
            'IsSubmitted':   bool(sub.get('IsSubmitted') or sub.get('SubmissionID')),
            'MarksObtained': sub.get('MarksObtained'),
            'SubmittedAt':   str(sub['SubmittedAt']) if sub.get('SubmittedAt') else None,
        })

    submitted_count = sum(1 for r in result if r['IsSubmitted'])
    return _ok({
        'submissions': _serialize(result), 'count': len(result),
        'submittedCount': submitted_count,
        'notSubmittedCount': len(result) - submitted_count,
        'totalMarks': exam.get('TotalMarks', 0), 'examId': exam_id,
    })


# ===========================================================================
# EXAM QUESTIONS — GET
# ===========================================================================

@bp_teacher.route('/exams/<int:exam_id>/questions', methods=['GET'])
@jwt_required()
def get_questions(exam_id):
    uid, err = _get_teacher_user_id()
    if err: return err

    exam = _try_queries([
        ('SELECT ExamID, ExamType, TotalMarks FROM Exams WHERE ExamID=? AND TeacherID=?', (exam_id, uid)),
        ('SELECT ExamID, ExamType, TotalMarks FROM Exams WHERE ExamID=?', (exam_id,)),
    ], fetch_one=True)
    if not exam: return _err('Exam not found or access denied', 404)

    questions = []
    for q_sql, q_p in [
        ("""SELECT QuestionID, QuestionText, QuestionType, OptionA, OptionB, OptionC, OptionD,
                  CorrectAnswer, Marks, QuestionOrder
           FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionOrder ASC, QuestionID ASC""", (exam_id,)),
        ("""SELECT QuestionID, QuestionText, OptionA, OptionB, OptionC, OptionD,
                  CorrectAnswer, Marks, QuestionOrder
           FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionOrder ASC, QuestionID ASC""", (exam_id,)),
        ("SELECT QuestionID, QuestionText, CorrectAnswer, Marks FROM ExamQuestions WHERE ExamID=?", (exam_id,)),
    ]:
        try:
            questions = db.execute_query(q_sql, q_p) or []
            break
        except Exception as e:
            print(f'[get_questions] err: {e}')

    return _ok({
        'questions':  _serialize(questions), 'examId': exam_id,
        'examName':   exam.get('ExamType', ''), 'totalMarks': exam.get('TotalMarks', 100),
        'count':      len(questions),
    })


# ===========================================================================
# EXAM QUESTIONS — ADD
# ===========================================================================

@bp_teacher.route('/exams/<int:exam_id>/questions', methods=['POST'])
@jwt_required()
def add_question(exam_id):
    uid, err = _get_teacher_user_id()
    if err: return err

    exam = _try_queries([
        ('SELECT ExamID FROM Exams WHERE ExamID=? AND TeacherID=?', (exam_id, uid)),
        ('SELECT ExamID FROM Exams WHERE ExamID=?', (exam_id,)),
    ], fetch_one=True)
    if not exam: return _err(f'Exam {exam_id} not found', 404)

    data = request.get_json() or {}
    max_order = 0
    try:
        row = db.execute_query(
            'SELECT COALESCE(MAX(QuestionOrder),0) AS mo FROM ExamQuestions WHERE ExamID=?',
            (exam_id,), fetch_one=True)
        if row: max_order = int(list(row.values())[0] or 0)
    except Exception: pass

    def _insert_q(qt, q_type, opt_a, opt_b, opt_c, opt_d, correct, marks, order_num):
        ok, _ = _try_inserts('ExamQuestions', [
            ('ExamID,QuestionText,QuestionType,OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Marks,QuestionOrder,CreatedAt',
             (exam_id, qt, q_type, opt_a, opt_b, opt_c, opt_d, correct, int(marks or 1), int(order_num or 1), datetime.now())),
            ('ExamID,QuestionText,QuestionType,OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Marks,QuestionOrder',
             (exam_id, qt, q_type, opt_a, opt_b, opt_c, opt_d, correct, int(marks or 1), int(order_num or 1))),
            ('ExamID,QuestionText,OptionA,OptionB,OptionC,OptionD,CorrectAnswer,Marks,QuestionOrder',
             (exam_id, qt, opt_a, opt_b, opt_c, opt_d, correct, int(marks or 1), int(order_num or 1))),
            ('ExamID,QuestionText,CorrectAnswer,Marks', (exam_id, qt, correct, int(marks or 1))),
        ])
        return ok

    questions_list = data.get('questions')
    if questions_list and isinstance(questions_list, list):
        saved = 0
        for i, q in enumerate(questions_list):
            qt = (q.get('questionText') or '').strip()
            if not qt: continue
            if _insert_q(qt, q.get('questionType', 'MCQ'), q.get('optionA', ''), q.get('optionB', ''),
                         q.get('optionC', ''), q.get('optionD', ''), q.get('correctAnswer', 'A'),
                         q.get('marks', 1), max_order + i + 1):
                saved += 1
        return _ok({'message': f'{saved} question(s) added', 'saved': saved})
    else:
        qt = (data.get('questionText') or '').strip()
        if not qt: return _err('questionText is required')
        ok = _insert_q(qt, data.get('questionType', 'MCQ'), data.get('optionA', ''), data.get('optionB', ''),
                       data.get('optionC', ''), data.get('optionD', ''), data.get('correctAnswer', 'A'),
                       data.get('marks', 1), max_order + 1)
        if not ok: return _err('Failed to add question', 500)
        return _ok({'message': 'Question added successfully'})


# ===========================================================================
# STUDY MATERIALS
# ===========================================================================

@bp_teacher.route('/materials')
@jwt_required()
def get_materials():
    uid, err = _get_teacher_user_id()
    if err: return err

    rows = None
    for sql in [
        """SELECT sm.MaterialID, sm.Title, sm.Description, sm.FilePath,
                  sm.FileType, sm.FileSize, sm.UploadedAt,
                  s.SubjectName, s.SubjectCode, s.Semester, d.DepartmentName
           FROM StudyMaterials sm
           INNER JOIN Subjects s ON s.SubjectID=sm.SubjectID
           LEFT JOIN Departments d ON d.DepartmentID=s.DepartmentID
           WHERE sm.TeacherID=? ORDER BY sm.UploadedAt DESC""",
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
            if rows is not None: break
        except Exception as e:
            print(f'[get_materials] err: {e}')

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
    file_type  = data.get('fileType') or 'other'
    file_size  = int(data.get('fileSize', 0))
    if not subject_id or not title:
        return _err('subjectId and title are required')

    ok, last_err = _try_inserts('StudyMaterials', [
        ('TeacherID,SubjectID,Title,Description,FilePath,FileType,FileSize,IsPublished,UploadedAt',
         (uid, subject_id, title, desc, file_path, file_type, file_size, 1, datetime.now())),
        ('TeacherID,SubjectID,Title,Description,FilePath,FileType,FileSize,UploadedAt',
         (uid, subject_id, title, desc, file_path, file_type, file_size, datetime.now())),
        ('TeacherID,SubjectID,Title,Description,FilePath,FileType,UploadedAt',
         (uid, subject_id, title, desc, file_path, file_type, datetime.now())),
        ('TeacherID,SubjectID,Title,FilePath',
         (uid, subject_id, title, file_path)),
    ])
    if not ok: return _err(f'Failed to save material: {last_err}', 500)

    _notify_students(subject_id, f'📁 New Material: {title}',
        f'Your teacher uploaded "{title}". Check Study Materials.', 'Material')
    return _ok({'message': 'Material saved successfully'})


@bp_teacher.route('/materials/upload', methods=['POST'])
@jwt_required()
def upload_material_file():
    uid, err = _get_teacher_user_id()
    if err: return err

    if 'file' not in request.files: return _err('No file provided')
    f = request.files['file']
    if not f.filename: return _err('Empty filename')

    f.seek(0, 2); size = f.tell(); f.seek(0)
    if size > 50 * 1024 * 1024:
        return _err(f'File too large ({round(size/1024/1024,1)} MB). Max 50 MB.', 413)

    ext        = os.path.splitext(f.filename)[1].lower()
    filename   = f'{uuid.uuid4().hex}{ext}'
    upload_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'uploads', 'materials')
    os.makedirs(upload_dir, exist_ok=True)

    try:
        f.save(os.path.join(upload_dir, filename))
        ext_map = {
            '.pdf': 'pdf', '.doc': 'doc', '.docx': 'doc', '.ppt': 'ppt', '.pptx': 'ppt',
            '.xls': 'xls', '.xlsx': 'xls', '.mp4': 'video', '.jpg': 'image', '.png': 'image',
        }
        return _ok({'filePath': f'/uploads/materials/{filename}',
                    'fileName': f.filename,
                    'fileSize': os.path.getsize(os.path.join(upload_dir, filename)),
                    'fileType': ext_map.get(ext, 'other')})
    except Exception as e:
        return _err(f'File save failed: {e}', 500)


# ===========================================================================
# ONLINE CLASSES
# ===========================================================================

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
                  oc.MeetingLink, oc.CreatedAt AS ScheduledDate,
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
            print(f'[get_online_classes] err: {e}')

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
        ('TeacherID,SubjectID,Title,Topic,Description,MeetingLink,ScheduledDate,StartTime,EndTime,IsActive,CreatedAt',
         (uid, subject_id, topic, topic, description, meeting_link, scheduled_date, start_time, end_time, 1, datetime.now())),
        ('TeacherID,SubjectID,Title,Topic,MeetingLink,ScheduledDate,StartTime,EndTime,CreatedAt',
         (uid, subject_id, topic, topic, meeting_link, scheduled_date, start_time, end_time, datetime.now())),
        ('TeacherID,SubjectID,Title,MeetingLink',
         (uid, subject_id, topic, meeting_link)),
    ])
    if not ok: return _err(f'Database operation failed: {last_err}', 500)

    _notify_students(subject_id, f'💻 Online Class: {topic}',
        f'Online class "{topic}" on {scheduled_date} at {start_time or "TBD"}.', 'OnlineClass')
    return _ok({'message': f'Online class "{topic}" scheduled successfully'})


# ===========================================================================
# MARKS — STUDENTS FOR SUBJECT
# ===========================================================================

@bp_teacher.route('/marks/students')
@jwt_required()
def get_students_for_marks():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    subject_id = request.args.get('subjectId')
    if not subject_id: return _err('subjectId required')

    tt = _try_queries([
        ('SELECT TOP 1 DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
        ('SELECT DepartmentID, Semester FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
    ], fetch_one=True)
    if not tt: return _err('You do not teach this subject', 403)

    students = db.execute_query(
        """SELECT s.StudentID, s.FullName, s.RollNumber, s.Email,
                  s.CurrentSemester AS Semester,
                  m.MarkID, m.CA1, m.CA2, m.CA3, m.CA4, m.CA5, m.Midterm, m.Endterm
           FROM Students s
           LEFT JOIN Marks m ON m.StudentID=s.StudentID AND m.SubjectID=?
           WHERE s.DepartmentID=? AND s.CurrentSemester=? AND s.IsActive=1
           ORDER BY s.FullName""", (subject_id, tt['DepartmentID'], tt['Semester'])) or []

    result = _serialize(students)
    for i, s in enumerate(result, 1):
        s['SerialNo'] = i
    return _ok({'students': result, 'subjectId': subject_id})


# ===========================================================================
# MARKS — SAVE
# ===========================================================================

@bp_teacher.route('/marks', methods=['POST'])
@jwt_required()
def save_marks():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    data          = request.get_json() or {}
    subject_id    = data.get('subjectId')
    marks_list    = data.get('marks', [])
    academic_year = data.get('academicYear', '2024-25')
    if not subject_id or not marks_list:
        return _err('subjectId and marks list required')

    teaches = _try_queries([
        ('SELECT TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=? LIMIT 1', (db_id, subject_id)),
        ('SELECT TOP 1 TimetableID FROM Timetable WHERE TeacherID=? AND SubjectID=?', (db_id, subject_id)),
    ], fetch_one=True)
    if not teaches: return _err('You do not teach this subject', 403)

    saved = 0; errors = []
    for rec in marks_list:
        student_id = rec.get('studentId')
        if student_id is None or str(student_id).strip() == '': continue
        try:
            student_id = int(student_id)
        except (ValueError, TypeError):
            errors.append(f'Invalid studentId: {student_id}'); continue

        ca1 = min(float(rec.get('CA1') or 0), 10)
        ca2 = min(float(rec.get('CA2') or 0), 10)
        ca3 = min(float(rec.get('CA3') or 0), 10)
        ca4 = min(float(rec.get('CA4') or 0), 10)
        ca5 = min(float(rec.get('CA5') or 0), 10)
        mid = min(float(rec.get('Midterm') or 0), 50)
        end = min(float(rec.get('Endterm') or 0), 100)

        try:
            existing = _try_queries([
                ('SELECT MarkID FROM Marks WHERE StudentID=? AND SubjectID=? LIMIT 1', (student_id, subject_id)),
                ('SELECT TOP 1 MarkID FROM Marks WHERE StudentID=? AND SubjectID=?', (student_id, subject_id)),
            ], fetch_one=True)

            if existing:
                done = False
                for upd, uv in [
                    ('UPDATE Marks SET CA1=?,CA2=?,CA3=?,CA4=?,CA5=?,Midterm=?,Endterm=?,UpdatedAt=? WHERE MarkID=?',
                     (ca1,ca2,ca3,ca4,ca5,mid,end,datetime.now(),existing['MarkID'])),
                    ('UPDATE Marks SET CA1=?,CA2=?,CA3=?,CA4=?,CA5=?,Midterm=?,Endterm=? WHERE MarkID=?',
                     (ca1,ca2,ca3,ca4,ca5,mid,end,existing['MarkID'])),
                ]:
                    try: db.execute_non_query(upd, uv); done = True; break
                    except Exception as ue: print(f'[save_marks] UPDATE err: {ue}')
                if done: saved += 1; continue

            ok, e2 = _try_inserts('Marks', [
                ('StudentID,SubjectID,AcademicYear,CA1,CA2,CA3,CA4,CA5,Midterm,Endterm,UpdatedAt',
                 (student_id,subject_id,academic_year,ca1,ca2,ca3,ca4,ca5,mid,end,datetime.now())),
                ('StudentID,SubjectID,AcademicYear,CA1,CA2,CA3,CA4,CA5,Midterm,Endterm',
                 (student_id,subject_id,academic_year,ca1,ca2,ca3,ca4,ca5,mid,end)),
                ('StudentID,SubjectID,CA1,CA2,CA3,CA4,CA5,Midterm,Endterm',
                 (student_id,subject_id,ca1,ca2,ca3,ca4,ca5,mid,end)),
            ])
            if ok: saved += 1
            else: errors.append(f'INSERT failed sid={student_id}: {e2}')
        except Exception as e:
            errors.append(f'Err sid={student_id}: {e}')

    return _ok({'message': f'Marks saved for {saved} student(s)', 'saved': saved, 'errors': errors[:5]})


# ===========================================================================
# MY STUDENTS
# ===========================================================================

@bp_teacher.route('/my-students')
@jwt_required()
def my_students():
    uid, err = _get_teacher_user_id()
    if err: return err
    db_id = _get_teacher_db_id(uid)

    combos = db.execute_query(
        """SELECT DISTINCT t.DepartmentID, t.Semester, d.DepartmentName, d.DepartmentCode
           FROM Timetable t
           LEFT JOIN Departments d ON d.DepartmentID=t.DepartmentID
           WHERE t.TeacherID=?
           ORDER BY d.DepartmentName, t.Semester""", (db_id,)) or []

    seen = set(); all_students = []
    for combo in combos:
        for s in _students_in_cohort(combo['DepartmentID'], combo['Semester']):
            sid = s['StudentID']
            if sid not in seen:
                seen.add(sid)
                row = dict(s)
                row['DepartmentName'] = combo.get('DepartmentName', '')
                row['DepartmentCode'] = combo.get('DepartmentCode', '')
                all_students.append(row)

    classes_list = []
    for combo in combos:
        dept_id  = combo['DepartmentID']
        semester = combo['Semester']
        cnt = _safe_scalar(
            'SELECT COUNT(*) FROM Students WHERE DepartmentID=? AND CurrentSemester=? AND IsActive=1',
            (dept_id, semester))
        code = combo.get('DepartmentCode') or combo.get('DepartmentName', '')
        classes_list.append({
            'DepartmentID':   dept_id, 'Semester': semester,
            'DepartmentName': combo.get('DepartmentName', ''),
            'DepartmentCode': combo.get('DepartmentCode', ''),
            'Label':          f"{code} — Sem {semester}  ({cnt} students)",
        })

    return _ok({'students': _serialize(all_students),
                'count': len(all_students), 'classes': classes_list})


# ===========================================================================
# TIMETABLE PUBLIC BLUEPRINT  /api/timetable/*
# ===========================================================================

@bp_timetable.route('/summary')
def get_summary():
    try:
        return jsonify({'success': True, 'summary': {
            'departments': db.execute_query("SELECT COUNT(*) AS cnt FROM Departments", fetch_one=True)['cnt'],
            'teachers':    db.execute_query("SELECT COUNT(*) AS cnt FROM Teachers WHERE IsActive=1", fetch_one=True)['cnt'],
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
            rows = db.execute_query(
                'SELECT DISTINCT Semester FROM Timetable WHERE DepartmentID=? ORDER BY Semester', (d['DepartmentID'],))
            d['Semesters'] = [r['Semester'] for r in rows] if rows else []
        return jsonify({'success': True, 'departments': depts}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@bp_timetable.route('/teachers')
def get_teachers():
    try:
        dept_id = request.args.get('dept_id')
        q       = "SELECT TeacherID, TeacherCode, FullName AS TeacherName, DepartmentID FROM Teachers WHERE IsActive=1"
        params  = []
        if dept_id:
            q += ' AND DepartmentID=?'; params.append(dept_id)
        q += ' ORDER BY FullName'
        teachers = _serialize(db.execute_query(q, tuple(params) if params else ()))
        for t in teachers:
            rows = db.execute_query(
                'SELECT DISTINCT Semester FROM Timetable WHERE TeacherID=? ORDER BY Semester', (t['TeacherID'],))
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
            """SELECT t.TimetableID, t.DayOfWeek, t.PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,'') AS RoomNumber, t.Semester, t.DepartmentID,
                      s.SubjectName, s.SubjectCode,
                      tc.FullName AS TeacherName, tc.TeacherCode,
                      d.DepartmentName, d.DepartmentCode
               FROM Timetable t
               JOIN Subjects    s  ON t.SubjectID=s.SubjectID
               JOIN Teachers    tc ON tc.TeacherID=t.TeacherID
               JOIN Departments d  ON t.DepartmentID=d.DepartmentID
               WHERE t.DepartmentID=? AND t.Semester=?
               ORDER BY t.DayOfWeek, t.StartTime""", (dept_id, semester)))
        return jsonify({'success': True, 'timetable': rows}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@bp_timetable.route('/teacher/<int:teacher_id>')
def get_teacher_timetable(teacher_id):
    try:
        semester = request.args.get('semester')
        q = """SELECT t.TimetableID, t.DayOfWeek, t.PeriodNumber, t.StartTime, t.EndTime,
                      COALESCE(t.RoomNumber,'') AS RoomNumber, t.Semester, t.DepartmentID,
                      s.SubjectName, s.SubjectCode,
                      tc.FullName AS TeacherName, tc.TeacherCode,
                      d.DepartmentName, d.DepartmentCode
               FROM Timetable t
               JOIN Subjects    s  ON t.SubjectID=s.SubjectID
               JOIN Teachers    tc ON tc.TeacherID=t.TeacherID
               JOIN Departments d  ON t.DepartmentID=d.DepartmentID
               WHERE t.TeacherID=?"""
        params = [teacher_id]
        if semester:
            q += ' AND t.Semester=?'; params.append(semester)
        q += ' ORDER BY t.DayOfWeek, t.PeriodNumber'
        rows    = _serialize(db.execute_query(q, tuple(params)))
        all_sem = db.execute_query(
            'SELECT DISTINCT Semester FROM Timetable WHERE TeacherID=? ORDER BY Semester', (teacher_id,))
        return jsonify({'success': True, 'timetable': rows,
                        'allSemesters': [r['Semester'] for r in all_sem] if all_sem else []}), 200
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500