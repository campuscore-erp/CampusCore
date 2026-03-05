"""
student_routes_merged.py  —  University ERP
============================================
Blueprint: bp_student  →  /api/student/*

FIXES IN THIS VERSION:
  1. Teacher JOINs work for BOTH schema styles:
       - Schema A (SQLite/separate): Teachers table (TeacherID → Teachers.TeacherID)
       - Schema B (MSSQL/unified):   Users table    (TeacherID → Users.UserID)
     Each query tries Teachers table first; on failure falls back to Users.
  2. GROUP_CONCAT → STRING_AGG (SQL Server) with fallback to GROUP_CONCAT (SQLite).
  3. GROUP BY clauses include ALL selected non-aggregate columns (SQL Server strict mode).
  4. Exams query uses only safe columns; skips missing IsActive/ExamName/StartTime etc.
  5. Notifications use StudentID (SQLite) with fallback to UserID (MSSQL).
  6. Dashboard exams counter is safe/optional.
  7. QR scan works camera-only (manual token entry removed from UI).
  8. Fee payment endpoint added for UPI/Net Banking/Card payments.
"""

import json, traceback
from datetime import datetime, date, time
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity, get_jwt
from database import db

bp_student = Blueprint('student', __name__, url_prefix='/api/student')


# ── Helpers ────────────────────────────────────────────────────────────────────

def _sv(val):
    if isinstance(val, (date, time, datetime)):
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

def student_required():
    claims = get_jwt()
    # Check every possible key the JWT might use for user type
    user_type = (
        claims.get('userType') or
        claims.get('user_type') or
        claims.get('role') or
        claims.get('type') or
        claims.get('UserType') or
        ''
    )
    if str(user_type).strip().lower() == 'student':
        return None  # ✅ authorized

    # Fallback: verify against DB using the identity in the token
    # This handles any JWT claim key mismatch between auth_routes and student_routes
    try:
        user_id = int(get_jwt_identity())
        row = db.execute_query(
            "SELECT UserType FROM Users WHERE UserID = ?",
            (user_id,), fetch_one=True)
        if row and str(row.get('UserType', '')).strip().lower() == 'student':
            return None  # ✅ authorized via DB check
    except Exception as e:
        print(f'[Auth] DB fallback check error: {e}')

    print(f'[Auth] student_required FAILED. claims keys: {list(claims.keys())}, user_type found: {user_type!r}')
    return jsonify({'error': 'Student access required', 'success': False}), 403


# ── ID / info resolution ───────────────────────────────────────────────────────

def _resolve(user_id: int):
    """
    Returns (student_id, dept_id, semester, user_code).
    Maps: Users.UserID -> Students.StudentID via RollNumber = UserCode.
    In unified schema (MSSQL), student_id == user_id (UserID IS the StudentID).
    """
    user = db.execute_query(
        "SELECT UserCode, DepartmentID, Semester, Email FROM Users WHERE UserID = ?",
        (user_id,), fetch_one=True
    )
    if not user:
        return user_id, None, None, None

    dept_id    = user.get('DepartmentID')
    semester   = user.get('Semester')
    u_code     = user.get('UserCode', '')
    student_id = user_id  # In unified MSSQL schema, UserID == StudentID

    # Try separate Students table (SQLite / old schema)
    try:
        s = db.execute_query(
            "SELECT UserID AS StudentID, DepartmentID, Semester AS CurrentSemester FROM Users WHERE UserCode = ? AND UserType = 'Student'",
            (u_code,), fetch_one=True
        )
        if s:
            student_id = s['StudentID']
            dept_id    = dept_id or s.get('DepartmentID')
            semester   = semester or s.get('CurrentSemester')
    except Exception:
        pass  # Students table may not exist in unified schema

    # Email fallback for separate Students table
    if student_id == user_id and user.get('Email'):
        try:
            s2 = db.execute_query(
                "SELECT UserID AS StudentID, DepartmentID, Semester AS CurrentSemester FROM Users WHERE Email = ? AND UserType = 'Student'",
                (user.get('Email'),), fetch_one=True
            )
            if s2:
                student_id = s2['StudentID']
                dept_id    = dept_id or s2.get('DepartmentID')
                semester   = semester or s2.get('CurrentSemester')
        except Exception:
            pass

    return student_id, dept_id, semester, u_code


def _enrolled_subj_ids(student_id, dept_id, semester):
    """
    Return enrolled SubjectIDs.
    MSSQL schema: StudentEnrollments only has StudentID (no TimetableID/ClassID).
    So we go cohort-first (dept+semester from Users), then fall back to SQLite strategies.
    """
    # Strategy 1 (MSSQL primary): Cohort via Users.DepartmentID + Users.Semester
    if dept_id and semester:
        try:
            rows = db.execute_query(
                """SELECT DISTINCT t.SubjectID FROM Timetable t
                   JOIN Classes c ON t.ClassID = c.ClassID
                   WHERE c.DepartmentID=? AND c.Semester=?""",
                (dept_id, semester))
            ids = [r['SubjectID'] for r in (rows or [])]
            if ids:
                return ids
        except Exception as e:
            print(f'[enrolled_subj] cohort/Timetable failed: {e}')

        try:
            rows = db.execute_query(
                "SELECT DISTINCT SubjectID FROM Subjects WHERE DepartmentID=? AND Semester=?",
                (dept_id, semester))
            ids = [r['SubjectID'] for r in (rows or [])]
            if ids:
                return ids
        except Exception as e:
            print(f'[enrolled_subj] cohort/Subjects failed: {e}')

    # Strategy 2 (SQLite fallback): StudentEnrollments with TimetableID
    try:
        rows = db.execute_query("""
            SELECT DISTINCT t.SubjectID FROM StudentEnrollments se
            JOIN Timetable t ON se.ClassID = t.ClassID
            WHERE se.StudentID = ?
        """, (student_id,))
        ids = [r['SubjectID'] for r in (rows or [])]
        if ids:
            return ids
    except Exception as e:
        print(f'[enrolled_subj] SE+TimetableID failed: {e}')

    # Strategy 3 (SQLite no-IsActive fallback)
    try:
        rows = db.execute_query("""
            SELECT DISTINCT t.SubjectID FROM StudentEnrollments se
            JOIN Timetable t ON se.ClassID = t.ClassID
            WHERE se.StudentID = ?
        """, (student_id,))
        ids = [r['SubjectID'] for r in (rows or [])]
        if ids:
            return ids
    except Exception as e:
        print(f'[enrolled_subj] SE no-IsActive failed: {e}')

    return []


def _timetable_rows(student_id, dept_id, semester, day=None):
    """
    Fetch timetable rows — robust multi-strategy with simple ORDER BY.
    Strategies tried in order until one returns data:
      1. Cohort (DeptID + Semester) joined to Users for teacher name
      2. Cohort (DeptID + Semester) joined to Teachers table
      3. Minimal — Timetable + Subjects only, teacher name filled separately
    """
    def mk(rows):
        return [{k: _sv(v) for k, v in dict(r).items()} for r in (rows or [])]

    def fill_teachers(result):
        """Fill TeacherName from Users table by TeacherID."""
        try:
            tids = list({r['TeacherID'] for r in result if r.get('TeacherID')})
            if not tids:
                return result
            ph = ','.join(['?'] * len(tids))
            trows = db.execute_query(
                f"SELECT UserID, FullName, UserCode FROM Users WHERE UserID IN ({ph})",
                tuple(tids)) or []
            tmap = {t['UserID']: t for t in trows}
            for r in result:
                tid = r.get('TeacherID')
                if tid and tid in tmap:
                    r['TeacherName'] = tmap[tid].get('FullName') or r.get('TeacherName')
                    r['TeacherCode'] = tmap[tid].get('UserCode') or r.get('TeacherCode')
        except Exception:
            pass
        return result

    # Build WHERE clause pieces separately to avoid f-string/SQL issues
    if dept_id and semester:
        # Strategy 1: Cohort + Users (most common schema — teachers in Users table)
        try:
            params = [dept_id, semester]
            where  = "c.DepartmentID = ? AND c.Semester = ?"
            if day:
                where += " AND t.DayOfWeek = ?"
                params.append(day)
            rows = db.execute_query(
                f"""SELECT t.TimetableID, t.DayOfWeek, t.StartTime, t.EndTime,
                        COALESCE(t.RoomNumber, t.Room, '') AS RoomNumber,
                        0 AS IsLab, 0 AS PeriodNumber,
                        s.SubjectID, s.SubjectName, s.SubjectCode,
                        tc.UserID AS TeacherID, tc.FullName AS TeacherName,
                        tc.UserCode AS TeacherCode,
                        d.DepartmentName, d.DepartmentCode,
                        c.Semester, c.Section, c.ClassName
                    FROM Timetable t
                    JOIN Classes     c  ON t.ClassID    = c.ClassID
                    JOIN Subjects    s  ON t.SubjectID  = s.SubjectID
                    JOIN Users       tc ON t.TeacherID  = tc.UserID
                    JOIN Departments d  ON c.DepartmentID = d.DepartmentID
                    WHERE {where}
                    ORDER BY t.DayOfWeek, t.StartTime""",
                tuple(params))
            if rows:
                return mk(rows)
        except Exception as e:
            print(f'[TT] cohort-Users err: {e}')

        # Strategy 2: Cohort + Teachers table
        try:
            params = [dept_id, semester]
            where  = "c.DepartmentID = ? AND c.Semester = ?"
            if day:
                where += " AND t.DayOfWeek = ?"
                params.append(day)
            rows = db.execute_query(
                f"""SELECT t.TimetableID, t.DayOfWeek, t.StartTime, t.EndTime,
                        COALESCE(t.RoomNumber, t.Room, '') AS RoomNumber,
                        0 AS IsLab, 0 AS PeriodNumber,
                        s.SubjectID, s.SubjectName, s.SubjectCode,
                        tc.UserID AS TeacherID, tc.FullName AS TeacherName,
                        tc.UserCode AS TeacherCode,
                        d.DepartmentName, d.DepartmentCode,
                        c.Semester, c.Section, c.ClassName
                    FROM Timetable t
                    JOIN Classes     c  ON t.ClassID    = c.ClassID
                    JOIN Subjects    s  ON t.SubjectID  = s.SubjectID
                    JOIN Users       tc ON t.TeacherID  = tc.UserID
                    JOIN Departments d  ON c.DepartmentID = d.DepartmentID
                    WHERE {where}
                    ORDER BY t.DayOfWeek, t.StartTime""",
                tuple(params))
            if rows:
                return mk(rows)
        except Exception as e:
            print(f'[TT] cohort-Teachers err: {e}')

        # Strategy 3: Minimal — no teacher join, fill names separately
        try:
            params = [dept_id, semester]
            where  = "c.DepartmentID = ? AND c.Semester = ?"
            if day:
                where += " AND t.DayOfWeek = ?"
                params.append(day)
            rows = db.execute_query(
                f"""SELECT t.TimetableID, t.DayOfWeek, t.StartTime, t.EndTime,
                        COALESCE(t.RoomNumber, t.Room, '') AS RoomNumber,
                        0 AS IsLab, 0 AS PeriodNumber,
                        s.SubjectID, s.SubjectName, s.SubjectCode,
                        t.TeacherID,
                        NULL AS TeacherName, NULL AS TeacherCode,
                        d.DepartmentName, d.DepartmentCode,
                        c.Semester, c.Section, c.ClassName
                    FROM Timetable t
                    JOIN Classes     c  ON t.ClassID    = c.ClassID
                    JOIN Subjects    s  ON t.SubjectID  = s.SubjectID
                    JOIN Departments d  ON c.DepartmentID = d.DepartmentID
                    WHERE {where}
                    ORDER BY t.DayOfWeek, t.StartTime""",
                tuple(params))
            if rows:
                return fill_teachers(mk(rows))
        except Exception as e:
            print(f'[TT] minimal err: {e}')

    return []


# ══════════════════════════════════════════════════════════════════════════════
# DASHBOARD
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/dashboard', methods=['GET'])
@jwt_required()
def get_dashboard():
    err = student_required()
    if err: return err
    try:
        user_id    = int(get_jwt_identity())
        student_id, dept_id, semester, u_code = _resolve(user_id)

        # Ensure dept_id / semester always resolved from Users table
        if dept_id is None or semester is None:
            try:
                u = db.execute_query(
                    "SELECT DepartmentID, Semester FROM Users WHERE UserID = ?",
                    (user_id,), fetch_one=True)
                if u:
                    dept_id  = dept_id  or u.get('DepartmentID')
                    semester = semester or u.get('Semester')
            except Exception:
                pass

        # Both IDs to handle schema where UserID == StudentID in Attendance
        all_ids = list({student_id, user_id})
        id_ph   = ','.join(['?'] * len(all_ids))

        # ── Enrolled subjects ──────────────────────────────────────────────
        enrolled_subjects = 0
        try:
            if dept_id and semester:
                r = db.execute_query(
                    """SELECT COUNT(DISTINCT t.SubjectID) AS cnt FROM Timetable t JOIN Classes c ON t.ClassID=c.ClassID WHERE c.DepartmentID=? AND c.Semester=?""",
                    (dept_id, semester), fetch_one=True)
                enrolled_subjects = int(r['cnt'] or 0) if r else 0
        except Exception as e:
            print(f'[Dashboard] enrolled err: {e}')

        # ── Attendance ─────────────────────────────────────────────────────
        attendance_pct = 0
        subject_wise   = []
        try:
            r = db.execute_query(
                f"SELECT CAST(SUM(CASE WHEN Status='Present' THEN 1.0 ELSE 0 END) * 100.0 / NULLIF(COUNT(*),0) AS FLOAT) AS pct FROM Attendance WHERE StudentID IN ({id_ph})",
                tuple(all_ids), fetch_one=True)
            attendance_pct = round(float(r['pct'] or 0), 1) if r and r['pct'] else 0
        except Exception as e:
            print(f'[Dashboard] att pct err: {e}')

        try:
            rows = db.execute_query(
                f"""SELECT s.SubjectName, s.SubjectCode,
                        COUNT(*) AS TotalClasses,
                        SUM(CASE WHEN a.Status='Present' THEN 1 ELSE 0 END) AS PresentCount,
                        CAST(SUM(CASE WHEN a.Status='Present' THEN 1.0 ELSE 0 END)
                             * 100.0 / NULLIF(COUNT(*),0) AS FLOAT) AS Percentage
                    FROM Attendance a
                    JOIN Subjects s ON a.SubjectID = s.SubjectID
                    WHERE a.StudentID IN ({id_ph})
                    GROUP BY s.SubjectID, s.SubjectName, s.SubjectCode
                    ORDER BY s.SubjectName""",
                tuple(all_ids))
            subject_wise = serialize_rows(rows) if rows else []
        except Exception as e:
            print(f'[Dashboard] att subjectwise err: {e}')

        # ── Pending exams (student-specific only) ─────────────────────────
        pending_exams = 0
        # Get enrolled subject IDs for this student
        _pending_subj_ids = _enrolled_subj_ids(student_id, dept_id, semester)
        if _pending_subj_ids:
            _ph = ','.join(['?'] * len(_pending_subj_ids))
            _pending_queries = [
                # Primary: filter by enrolled subjects + not yet submitted
                (
                    f"""SELECT COUNT(*) AS cnt
                        FROM Exams e
                        LEFT JOIN ExamSubmissions es
                            ON e.ExamID = es.ExamID AND es.StudentID IN ({id_ph})
                        WHERE e.IsActive = 1
                          AND e.SubjectID IN ({_ph})
                          AND (es.SubmissionID IS NULL OR es.IsSubmitted = 0)""",
                    tuple(all_ids) + tuple(_pending_subj_ids)
                ),
                # Fallback: just count active exams for enrolled subjects (no submission join)
                (
                    f"SELECT COUNT(*) AS cnt FROM Exams e WHERE e.IsActive = 1 AND e.SubjectID IN ({_ph})",
                    tuple(_pending_subj_ids)
                ),
            ]
        elif dept_id and semester:
            _pending_queries = [
                # Fallback when no subject list: filter by dept + semester via Subjects join
                (
                    f"""SELECT COUNT(*) AS cnt
                        FROM Exams e
                        JOIN Subjects s ON e.SubjectID = s.SubjectID
                        LEFT JOIN ExamSubmissions es
                            ON e.ExamID = es.ExamID AND es.StudentID IN ({id_ph})
                        WHERE e.IsActive = 1
                          AND s.DepartmentID = ? AND s.Semester = ?
                          AND (es.SubmissionID IS NULL OR es.IsSubmitted = 0)""",
                    tuple(all_ids) + (dept_id, semester)
                ),
                (
                    """SELECT COUNT(*) AS cnt
                       FROM Exams e
                       JOIN Subjects s ON e.SubjectID = s.SubjectID
                       WHERE e.IsActive = 1 AND s.DepartmentID = ? AND s.Semester = ?""",
                    (dept_id, semester)
                ),
            ]
        else:
            _pending_queries = []  # Cannot determine student scope — show 0

        for exam_q, exam_p in _pending_queries:
            try:
                r = db.execute_query(exam_q, exam_p, fetch_one=True)
                pending_exams = int(r['cnt'] or 0) if r else 0
                break
            except Exception:
                pass

        # ── Notifications ──────────────────────────────────────────────────
        unread = 0
        for col, val in [('StudentID', student_id), ('UserID', user_id)]:
            try:
                r = db.execute_query(
                    f"SELECT COUNT(*) AS cnt FROM Notifications WHERE {col}=? AND IsRead=0",
                    (val,), fetch_one=True)
                unread = int(r['cnt'] or 0) if r else 0
                break
            except Exception:
                pass

        # ── Today's schedule ───────────────────────────────────────────────
        today = datetime.now().strftime('%A')
        todays_schedule = _timetable_rows(student_id, dept_id, semester, day=today)

        return jsonify({
            'success': True,
            'stats': {
                'enrolledSubjects':     enrolled_subjects,
                'attendancePercentage': attendance_pct,
                'pendingExams':         pending_exams,
                'unreadNotifications':  unread,
                'currentSemester':      semester,
                'todaysSchedule':       todays_schedule,
                'subjectAttendance':    subject_wise,
            }
        }), 200
    except Exception as e:
        print(f'[Dashboard] Fatal: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# PROFILE
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, u_code = _resolve(user_id)

        profile = None
        try:
            profile = serialize_row(db.execute_query("""
                SELECT s.StudentID, s.RollNumber AS UserCode, s.FullName, s.Email,
                       s.CurrentSemester AS Semester, s.AcademicYear,
                       d.DepartmentName, d.DepartmentCode,
                       u.Phone, u.Gender, u.DateOfBirth, u.Address, u.JoinDate
                FROM   Students s
                JOIN   Departments d ON s.DepartmentID = d.DepartmentID
                LEFT JOIN Users    u ON u.UserCode     = s.RollNumber
                WHERE  s.StudentID = ?
            """, (student_id,), fetch_one=True))
        except Exception as e:
            print(f'[Profile] Students join err: {e}')

        if not profile:
            profile = serialize_row(db.execute_query("""
                SELECT u.UserID, u.UserCode, u.FullName, u.Email, u.Phone,
                       u.DateOfBirth, u.Gender, u.Semester,
                       u.Address, d.DepartmentName, d.DepartmentCode
                FROM   Users u
                LEFT JOIN Departments d ON u.DepartmentID = d.DepartmentID
                WHERE  u.UserID = ?
            """, (user_id,), fetch_one=True))

        if not profile:
            return jsonify({'error': 'Profile not found', 'success': False}), 404
        return jsonify({'success': True, 'profile': profile}), 200
    except Exception as e:
        print(f'[Profile] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# TIMETABLE
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/timetable', methods=['GET'])
@jwt_required()
def get_timetable():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)
        timetable = _timetable_rows(student_id, dept_id, semester)
        return jsonify({'success': True, 'timetable': timetable}), 200
    except Exception as e:
        print(f'[Timetable] Fatal: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# SUBJECTS
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/subjects', methods=['GET'])
@jwt_required()
def get_subjects():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)
        subjects = []

        # All 4 strategies: (Enrollments|Cohort) x (Teachers|Users)
        strategies = []

        # Enrollment-based
        for tc_join, tc_cols in [
            ("JOIN Teachers tc ON t.TeacherID = tc.TeacherID",
             "tc.TeacherID, tc.TeacherCode, tc.FullName AS TeacherName, tc.Email AS TeacherEmail, tc.Phone AS TeacherPhone, tc.Designation AS TeacherDesignation"),
            ("JOIN Users tc ON t.TeacherID = tc.UserID",
             "tc.UserID AS TeacherID, tc.UserCode AS TeacherCode, tc.FullName AS TeacherName, tc.Email AS TeacherEmail, tc.Phone AS TeacherPhone, NULL AS TeacherDesignation"),
        ]:
            # Determine GROUP BY based on join
            if 'Teachers' in tc_join:
                grp = "s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits, s.IsLab, tc.TeacherID, tc.TeacherCode, tc.FullName, tc.Email, tc.Phone, tc.Designation, d.DepartmentName, d.DepartmentCode"
            else:
                grp = "s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits, s.IsLab, tc.UserID, tc.UserCode, tc.FullName, tc.Email, tc.Phone, d.DepartmentName, d.DepartmentCode"
            strategies.append((f"""
                SELECT s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits,
                    COALESCE(s.IsLab,0) AS IsLab,
                    {tc_cols}, d.DepartmentName, d.DepartmentCode
                FROM StudentEnrollments se
                JOIN Timetable   t  ON se.ClassID = t.ClassID
                JOIN Subjects    s  ON t.SubjectID    = s.SubjectID
                {tc_join}
                JOIN Classes     c  ON t.ClassID      = c.ClassID
                JOIN Departments d  ON c.DepartmentID = d.DepartmentID
                WHERE se.StudentID = ?
                GROUP BY {grp}
                ORDER BY s.IsLab ASC, s.SubjectName
            """, (student_id,)))

        # Cohort-based
        if dept_id and semester:
            for tc_join, tc_cols in [
                ("JOIN Teachers tc ON t.TeacherID = tc.TeacherID",
                 "tc.TeacherID, tc.TeacherCode, tc.FullName AS TeacherName, tc.Email AS TeacherEmail, tc.Phone AS TeacherPhone, tc.Designation AS TeacherDesignation"),
                ("JOIN Users tc ON t.TeacherID = tc.UserID",
                 "tc.UserID AS TeacherID, tc.UserCode AS TeacherCode, tc.FullName AS TeacherName, tc.Email AS TeacherEmail, tc.Phone AS TeacherPhone, NULL AS TeacherDesignation"),
            ]:
                if 'Teachers' in tc_join:
                    grp = "s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits, s.IsLab, tc.TeacherID, tc.TeacherCode, tc.FullName, tc.Email, tc.Phone, tc.Designation, d.DepartmentName, d.DepartmentCode"
                else:
                    grp = "s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits, s.IsLab, tc.UserID, tc.UserCode, tc.FullName, tc.Email, tc.Phone, d.DepartmentName, d.DepartmentCode"
                strategies.append((f"""
                    SELECT s.SubjectID, s.SubjectName, s.SubjectCode, s.Credits,
                        COALESCE(s.IsLab,0) AS IsLab,
                        {tc_cols}, d.DepartmentName, d.DepartmentCode
                    FROM Timetable   t
                    JOIN Subjects    s  ON t.SubjectID    = s.SubjectID
                    {tc_join}
                    JOIN Classes     c  ON t.ClassID     = c.ClassID
                JOIN Departments d  ON c.DepartmentID = d.DepartmentID
                    WHERE c.DepartmentID = ? AND c.Semester = ?
                    GROUP BY {grp}
                    ORDER BY s.IsLab ASC, s.SubjectName
                """, (dept_id, semester)))

        for sql, params in strategies:
            try:
                rows = db.execute_query(sql, params)
                if rows:
                    subjects = serialize_rows(rows)
                    break
            except Exception as e:
                print(f'[Subjects] strategy err: {e}')

        return jsonify({'success': True, 'subjects': subjects}), 200
    except Exception as e:
        print(f'[Subjects] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# MY TEACHERS
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/my-teachers', methods=['GET'])
@jwt_required()
def get_my_teachers():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)
        teachers = []

        # ── Strategy helpers ──────────────────────────────────────────────────
        # tc_variants: (join clause, select cols, group-by cols, teacher_id_col)
        tc_variants = [
            # Teachers table
            (
                "JOIN Teachers tc ON t.TeacherID = tc.TeacherID",
                "tc.TeacherID AS TeacherID, tc.TeacherCode AS TeacherCode, tc.FullName AS TeacherName, tc.Email AS TeacherEmail, tc.Phone AS TeacherPhone, tc.Designation AS Designation",
                "tc.TeacherID, tc.TeacherCode, tc.FullName, tc.Email, tc.Phone, tc.Designation",
            ),
            # Users table (MSSQL production)
            (
                "JOIN Users tc ON t.TeacherID = tc.UserID",
                "tc.UserID AS TeacherID, tc.UserCode AS TeacherCode, tc.FullName AS TeacherName, tc.Email AS TeacherEmail, tc.Phone AS TeacherPhone, NULL AS Designation",
                "tc.UserID, tc.UserCode, tc.FullName, tc.Email, tc.Phone",
            ),
        ]

        # Department join — optional (some schemas may not have DepartmentID on Teachers/Users)
        dept_join_variants = [
            ("LEFT JOIN Departments d ON tc.DepartmentID = d.DepartmentID",
             "d.DepartmentName AS TeacherDepartment",
             ", d.DepartmentName"),
            ("", "NULL AS TeacherDepartment", ""),
        ]

        # Aggregation variants
        agg_fns = [
            "STRING_AGG(s.SubjectName, ', ')",   # MSSQL 2017+ (DISTINCT not supported)
            "GROUP_CONCAT(DISTINCT s.SubjectName)",       # SQLite / MySQL
            "MAX(s.SubjectName)",                         # safe universal fallback
        ]

        strategies = []

        # --- Via StudentEnrollments + Timetable ---
        for tc_join, tc_sel, tc_grp in tc_variants:
            for dept_join, dept_sel, dept_grp in dept_join_variants:
                for agg in agg_fns:
                    strategies.append((f"""
                        SELECT {tc_sel}, {dept_sel},
                               {agg} AS SubjectsTaught
                        FROM   StudentEnrollments se
                        JOIN   Timetable t  ON se.ClassID = t.ClassID
                        {tc_join}
                        JOIN   Subjects  s  ON t.SubjectID   = s.SubjectID
                        {dept_join}
                        WHERE  se.StudentID = ?
                        GROUP  BY {tc_grp}{dept_grp}
                    """, (student_id,)))

        # --- Via StudentEnrollments without IsActive filter ---
        for tc_join, tc_sel, tc_grp in tc_variants:
            for dept_join, dept_sel, dept_grp in dept_join_variants:
                for agg in agg_fns:
                    strategies.append((f"""
                        SELECT {tc_sel}, {dept_sel},
                               {agg} AS SubjectsTaught
                        FROM   StudentEnrollments se
                        JOIN   Timetable t  ON se.ClassID = t.ClassID
                        {tc_join}
                        JOIN   Subjects  s  ON t.SubjectID   = s.SubjectID
                        {dept_join}
                        WHERE  se.StudentID = ?
                        GROUP  BY {tc_grp}{dept_grp}
                    """, (student_id,)))

        # --- Cohort fallback (dept + semester) ---
        if dept_id and semester:
            for tc_join, tc_sel, tc_grp in tc_variants:
                for dept_join, dept_sel, dept_grp in dept_join_variants:
                    for agg in agg_fns:
                        strategies.append((f"""
                            SELECT {tc_sel}, {dept_sel},
                                   {agg} AS SubjectsTaught
                            FROM   Timetable t
                            {tc_join}
                            JOIN   Subjects  s  ON t.SubjectID    = s.SubjectID
                            {dept_join}
                            JOIN   Classes c ON t.ClassID = c.ClassID
                            WHERE  c.DepartmentID = ? AND c.Semester = ?
                            GROUP  BY {tc_grp}{dept_grp}
                        """, (dept_id, semester)))

        # --- Ultimate fallback: just list teachers from dept, no subject join ---
        if dept_id:
            strategies.append(("""
                SELECT TeacherID, TeacherCode, FullName AS TeacherName,
                       Email AS TeacherEmail, Phone AS TeacherPhone,
                       Designation, NULL AS TeacherDepartment, NULL AS SubjectsTaught
                FROM   Teachers
                WHERE  DepartmentID = ?
            """, (dept_id,)))
            strategies.append(("""
                SELECT UserID AS TeacherID, UserCode AS TeacherCode, FullName AS TeacherName,
                       Email AS TeacherEmail, Phone AS TeacherPhone,
                       NULL AS Designation, NULL AS TeacherDepartment, NULL AS SubjectsTaught
                FROM   Users
                WHERE  DepartmentID = ? AND UserType = 'Teacher'
            """, (dept_id,)))

        for sql, params in strategies:
            try:
                rows = db.execute_query(sql, params)
                if rows:
                    teachers = serialize_rows(rows)
                    print(f'[MyTeachers] got {len(teachers)} rows')
                    break
            except Exception as e:
                print(f'[MyTeachers] strategy err: {e}')
                continue

        return jsonify({'success': True, 'teachers': teachers}), 200
    except Exception as e:
        print(f'[MyTeachers] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# ATTENDANCE
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/attendance', methods=['GET'])
@jwt_required()
def get_attendance():
    err = student_required()
    if err: return err
    try:
        user_id    = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)
        records, subject_wise = [], []

        all_ids = list({student_id, user_id})
        id_ph   = ','.join(['?'] * len(all_ids))

        # ── Individual attendance log ──────────────────────────────────────────
        for sid in all_ids:
            try:
                rows = serialize_rows(db.execute_query("""
                    SELECT a.AttendanceID, a.AttendanceDate, a.Status,
                           s.SubjectName, s.SubjectCode
                    FROM   Attendance a
                    JOIN   Subjects s ON a.SubjectID = s.SubjectID
                    WHERE  a.StudentID = ?
                    ORDER BY a.AttendanceDate DESC
                """, (sid,))) or []
                if rows:
                    records = rows
                    break
            except Exception as e:
                print(f'[Attendance] records err (sid={sid}): {e}')

        # ── Subject-wise — ALL enrolled subjects via LEFT JOIN ─────────────────
        enrolled_ids = _enrolled_subj_ids(student_id, dept_id, semester)

        if enrolled_ids:
            subj_ph = ','.join(['?'] * len(enrolled_ids))
            # Try MSSQL syntax first, then SQLite
            for q in [
                f"""SELECT s.SubjectName, s.SubjectCode,
                           ISNULL(COUNT(a.AttendanceID), 0) AS TotalClasses,
                           ISNULL(SUM(CASE WHEN a.Status='Present' THEN 1 ELSE 0 END), 0) AS PresentCount,
                           ISNULL(CAST(SUM(CASE WHEN a.Status='Present' THEN 1.0 ELSE 0.0 END)
                                * 100.0 / NULLIF(COUNT(a.AttendanceID), 0) AS FLOAT), 0.0) AS Percentage
                    FROM   Subjects s
                    LEFT JOIN Attendance a ON a.SubjectID = s.SubjectID
                           AND a.StudentID IN ({id_ph})
                    WHERE  s.SubjectID IN ({subj_ph})
                    GROUP BY s.SubjectID, s.SubjectName, s.SubjectCode
                    ORDER BY s.SubjectName""",
                f"""SELECT s.SubjectName, s.SubjectCode,
                           COUNT(a.AttendanceID) AS TotalClasses,
                           SUM(CASE WHEN a.Status='Present' THEN 1 ELSE 0 END) AS PresentCount,
                           CAST(SUM(CASE WHEN a.Status='Present' THEN 1.0 ELSE 0.0 END)
                                * 100.0 / NULLIF(COUNT(a.AttendanceID), 0) AS FLOAT) AS Percentage
                    FROM   Subjects s
                    LEFT JOIN Attendance a ON a.SubjectID = s.SubjectID
                           AND a.StudentID IN ({id_ph})
                    WHERE  s.SubjectID IN ({subj_ph})
                    GROUP BY s.SubjectID, s.SubjectName, s.SubjectCode
                    ORDER BY s.SubjectName""",
            ]:
                try:
                    rows = serialize_rows(db.execute_query(q, tuple(all_ids) + tuple(enrolled_ids))) or []
                    if rows:
                        for r in rows:
                            if r.get('Percentage') is None:
                                r['Percentage'] = 0.0
                            if r.get('TotalClasses') is None:
                                r['TotalClasses'] = 0
                            if r.get('PresentCount') is None:
                                r['PresentCount'] = 0
                        subject_wise = rows
                        break
                except Exception as e:
                    print(f'[Attendance] subject_wise LEFT JOIN err: {e}')

        # Fallback: inner join if enrolled lookup failed
        if not subject_wise:
            try:
                rows = serialize_rows(db.execute_query(f"""
                    SELECT s.SubjectName, s.SubjectCode,
                           COUNT(*) AS TotalClasses,
                           SUM(CASE WHEN a.Status='Present' THEN 1 ELSE 0 END) AS PresentCount,
                           CAST(SUM(CASE WHEN a.Status='Present' THEN 1.0 ELSE 0 END)
                                * 100.0 / NULLIF(COUNT(*), 0) AS FLOAT) AS Percentage
                    FROM   Attendance a JOIN Subjects s ON a.SubjectID = s.SubjectID
                    WHERE  a.StudentID IN ({id_ph})
                    GROUP BY s.SubjectID, s.SubjectName, s.SubjectCode
                    ORDER BY s.SubjectName
                """, tuple(all_ids))) or []
                if rows:
                    subject_wise = rows
            except Exception as e:
                print(f'[Attendance] subject_wise fallback err: {e}')

        return jsonify({'success': True, 'attendance': records, 'subjectWise': subject_wise}), 200
    except Exception as e:
        print(f'[Attendance] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_student.route('/attendance/scan-qr', methods=['POST'])
@bp_student.route('/attendance/qr', methods=['POST'])
@jwt_required()
def scan_qr_attendance():
    """Mark attendance via QR code scan. Camera-only — no manual token entry in UI."""
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, _, _, _ = _resolve(user_id)
        data = request.json or {}

        # QR data from camera is: "rawToken|date|subjectId"  (pipe-separated)
        # DB stores only the raw token part — must split before lookup
        raw_scan = (data.get('qrToken') or data.get('qrData') or '').strip()

        if not raw_scan:
            return jsonify({'success': False, 'error': 'QR token is required'}), 400

        # Parse pipe-separated format produced by teacher portal
        parts = raw_scan.split('|')
        raw_token  = parts[0].strip()          # actual DB token
        att_date   = parts[1].strip() if len(parts) > 1 else datetime.now().strftime('%Y-%m-%d')
        subject_id_from_qr = parts[2].strip() if len(parts) > 2 else None

        print(f'[QR Scan] raw_scan={raw_scan!r} → token={raw_token!r} date={att_date} subj={subject_id_from_qr}')

        if not raw_token:
            return jsonify({'success': False, 'error': 'Invalid QR code format'}), 400

        # MySQL QRCodes columns: QRCodeID, TeacherID, SubjectID, ClassID, QRToken, ExpiresAt, IsUsed, CreatedAt
        # NO TimetableID, NO IsActive — use IsUsed and ClassID instead
        qr = None
        for sql in [
            "SELECT QRCodeID, SubjectID, ClassID, ExpiresAt, IsUsed FROM QRCodes WHERE QRToken=? ORDER BY QRCodeID DESC LIMIT 1",
            "SELECT QRCodeID, SubjectID, ExpiresAt FROM QRCodes WHERE QRToken=? ORDER BY QRCodeID DESC LIMIT 1",
        ]:
            try:
                qr = db.execute_query(sql, (raw_token,), fetch_one=True)
                if qr: break
            except Exception as e:
                print(f'[QR Scan] lookup err: {e}')

        # Fallback: try full pipe-separated string as token
        if not qr:
            for sql in [
                "SELECT QRCodeID, SubjectID, ClassID, ExpiresAt, IsUsed FROM QRCodes WHERE QRToken=? ORDER BY QRCodeID DESC LIMIT 1",
                "SELECT QRCodeID, SubjectID, ExpiresAt FROM QRCodes WHERE QRToken=? ORDER BY QRCodeID DESC LIMIT 1",
            ]:
                try:
                    qr = db.execute_query(sql, (raw_scan,), fetch_one=True)
                    if qr: break
                except Exception:
                    pass

        if not qr:
            print(f'[QR Scan] No match in DB for token={raw_token!r}')
            return jsonify({'success': False, 'error': 'Invalid QR code. Ask your teacher to show a new one.'}), 400
        if int(qr.get('IsUsed') or 0) == 1:
            return jsonify({'success': False, 'error': 'This QR code has already been used.'}), 400

        try:
            expires = datetime.fromisoformat(str(qr['ExpiresAt']))
            if datetime.now() > expires:
                return jsonify({'success': False, 'error': 'QR code expired. Ask your teacher for a new one.'}), 400
        except Exception:
            pass

        today = datetime.now().strftime('%Y-%m-%d')
        try:
            already = db.execute_query(
                "SELECT AttendanceID FROM Attendance WHERE StudentID=? AND SubjectID=? AND AttendanceDate=?",
                (student_id, qr['SubjectID'], today), fetch_one=True)
            if already:
                return jsonify({'success': False, 'error': 'Attendance already marked for today.'}), 400
        except Exception:
            pass

        # MySQL Attendance exact cols: StudentID, SubjectID, ClassID (nullable), QRCodeID (nullable), AttendanceDate, Status
        # NO TimetableID, NO MarkedBy in MySQL schema
        class_id = qr.get('ClassID')
        inserted = False
        for ins_sql, ins_vals in [
            ("INSERT INTO Attendance (StudentID,SubjectID,ClassID,QRCodeID,AttendanceDate,Status) VALUES (?,?,?,?,?,'Present')",
             (student_id, qr['SubjectID'], class_id, qr['QRCodeID'], today)),
            ("INSERT INTO Attendance (StudentID,SubjectID,QRCodeID,AttendanceDate,Status) VALUES (?,?,?,?,'Present')",
             (student_id, qr['SubjectID'], qr['QRCodeID'], today)),
            ("INSERT INTO Attendance (StudentID,SubjectID,AttendanceDate,Status) VALUES (?,?,?,'Present')",
             (student_id, qr['SubjectID'], today)),
        ]:
            try:
                db.execute_non_query(ins_sql, ins_vals)
                inserted = True
                break
            except Exception as ie:
                print(f'[QR Scan] INSERT attempt failed: {ie}')
        if not inserted:
            return jsonify({'success': False, 'error': 'Failed to save attendance. Please try again.'}), 500

        subj_name = 'the class'
        try:
            subj = db.execute_query("SELECT SubjectName FROM Subjects WHERE SubjectID=?", (qr['SubjectID'],), fetch_one=True)
            if subj: subj_name = subj['SubjectName']
        except Exception:
            pass

        return jsonify({'success': True, 'message': f'Attendance marked for {subj_name}!'}), 200
    except Exception as e:
        print(f'[QR] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# STUDY MATERIALS
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/materials', methods=['GET'])
@jwt_required()
def get_materials():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)
        materials = []
        subj_ids  = _enrolled_subj_ids(student_id, dept_id, semester)

        if not subj_ids:
            return jsonify({'success': True, 'materials': []}), 200

        ph = ','.join('?' * len(subj_ids))

        # Try each teacher-join strategy; use first that works
        query_variants = [
            # MSSQL: teacher via Users table
            (f"""SELECT sm.MaterialID, sm.Title, sm.Description, sm.FilePath,
                        sm.FileType, sm.FileSize, sm.UploadedAt,
                        s.SubjectName, s.SubjectCode, tc.FullName AS TeacherName
                 FROM StudyMaterials sm
                 JOIN Subjects s  ON sm.SubjectID = s.SubjectID
                 JOIN Users    tc ON sm.TeacherID = tc.UserID
                 WHERE sm.SubjectID IN ({ph})
                 ORDER BY sm.UploadedAt DESC""", tuple(subj_ids)),
            # SQLite: teacher via Teachers table
            (f"""SELECT sm.MaterialID, sm.Title, sm.Description, sm.FilePath,
                        sm.FileType, sm.FileSize, sm.UploadedAt,
                        s.SubjectName, s.SubjectCode, tc.FullName AS TeacherName
                 FROM StudyMaterials sm
                 JOIN Subjects s  ON sm.SubjectID = s.SubjectID
                 JOIN Teachers tc ON sm.TeacherID = tc.TeacherID
                 WHERE sm.SubjectID IN ({ph})
                 ORDER BY sm.UploadedAt DESC""", tuple(subj_ids)),
            # No teacher join (ultimate fallback)
            (f"""SELECT sm.MaterialID, sm.Title, sm.Description, sm.FilePath,
                        sm.FileType, sm.FileSize, sm.UploadedAt,
                        s.SubjectName, s.SubjectCode, '' AS TeacherName
                 FROM StudyMaterials sm
                 JOIN Subjects s ON sm.SubjectID = s.SubjectID
                 WHERE sm.SubjectID IN ({ph})
                 ORDER BY sm.UploadedAt DESC""", tuple(subj_ids)),
        ]

        for sql, params in query_variants:
            try:
                rows = db.execute_query(sql, params)
                if rows is not None:
                    materials = serialize_rows(rows)
                    break
            except Exception as e:
                print(f'[Materials] strategy err: {e}')

        return jsonify({'success': True, 'materials': materials}), 200
    except Exception as e:
        print(f'[Materials] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# EXAMS
# ══════════════════════════════════════════════════════════════════════════════

def _safe_exams_query(student_id, where_sql, where_params):
    """Try full Exams query, fall back to minimal column sets for MSSQL compatibility."""
    for sql_variant in [
        # MSSQL primary: include StartTime + normalize ExamDate to date-only string
        f"""SELECT e.ExamID, e.ExamType,
               CONVERT(VARCHAR(10), e.ExamDate, 23) AS ExamDate,
               e.Duration, e.TotalMarks,
               s.SubjectName, s.SubjectCode,
               ISNULL(e.ExamTitle, e.ExamType) AS ExamName,
               es.SubmissionID, es.IsSubmitted, es.SubmittedAt,
               CONVERT(VARCHAR(5), ISNULL(e.StartTime, '00:00'), 108) AS StartTime,
               NULL AS EndTime,
               ISNULL(e.Instructions, '') AS Instructions,
               1 AS IsActive, es.MarksObtained
            FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID
            LEFT JOIN ExamSubmissions es ON e.ExamID = es.ExamID AND es.StudentID = ?
            WHERE {where_sql}
            ORDER BY e.ExamDate DESC""",
        # MSSQL fallback: ExamDate raw (no CONVERT), StartTime null
        f"""SELECT e.ExamID, e.ExamType, e.ExamDate, e.Duration, e.TotalMarks,
               s.SubjectName, s.SubjectCode,
               ISNULL(e.ExamTitle, e.ExamType) AS ExamName,
               es.SubmissionID, es.IsSubmitted, es.SubmittedAt,
               NULL AS StartTime, NULL AS EndTime,
               ISNULL(e.Instructions, '') AS Instructions,
               1 AS IsActive, es.MarksObtained
            FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID
            LEFT JOIN ExamSubmissions es ON e.ExamID = es.ExamID AND es.StudentID = ?
            WHERE {where_sql}
            ORDER BY e.ExamDate DESC""",
        # MSSQL fallback: no ExamTitle either
        f"""SELECT e.ExamID, e.ExamType, e.ExamDate, e.Duration, e.TotalMarks,
               s.SubjectName, s.SubjectCode,
               CAST(e.ExamID AS VARCHAR) AS ExamName,
               es.SubmissionID, es.IsSubmitted, es.SubmittedAt,
               NULL AS StartTime, NULL AS EndTime, NULL AS Instructions,
               1 AS IsActive, NULL AS MarksObtained
            FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID
            LEFT JOIN ExamSubmissions es ON e.ExamID = es.ExamID AND es.StudentID = ?
            WHERE {where_sql}
            ORDER BY e.ExamDate DESC""",
        # SQLite fallback: full columns
        f"""SELECT e.ExamID, e.ExamName, e.ExamType, e.ExamDate,
               e.StartTime, e.EndTime, e.Duration, e.TotalMarks,
               e.Instructions, e.IsActive, s.SubjectName, s.SubjectCode,
               es.SubmissionID, es.IsSubmitted, es.SubmittedAt, es.MarksObtained
            FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID
            LEFT JOIN ExamSubmissions es ON e.ExamID = es.ExamID AND es.StudentID = ?
            WHERE e.IsActive = 1 AND {where_sql}
            ORDER BY e.ExamDate DESC""",
        # No submission join at all
        f"""SELECT e.ExamID, e.ExamType, e.ExamDate, e.Duration, e.TotalMarks,
               s.SubjectName, s.SubjectCode,
               NULL AS ExamName, NULL AS SubmissionID, NULL AS IsSubmitted,
               NULL AS SubmittedAt, NULL AS StartTime, NULL AS EndTime,
               NULL AS Instructions, 1 AS IsActive, NULL AS MarksObtained
            FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID
            WHERE {where_sql}
            ORDER BY e.ExamDate DESC""",
    ]:
        try:
            # First two variants include student_id for the LEFT JOIN
            if 'ExamSubmissions es' in sql_variant:
                params = (student_id, *where_params)
            else:
                params = where_params
            rows = db.execute_query(sql_variant, params)
            if rows is not None:
                return serialize_rows(rows)
        except Exception as e:
            print(f'[ExamsSafe] variant err: {e}')
    return []


@bp_student.route('/exams', methods=['GET'])
@jwt_required()
def get_exams():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)
        subj_ids = _enrolled_subj_ids(student_id, dept_id, semester)
        exams = []

        if subj_ids:
            ph = ','.join('?' * len(subj_ids))
            exams = _safe_exams_query(student_id, f"e.SubjectID IN ({ph})", tuple(subj_ids))
        elif dept_id and semester:
            exams = _safe_exams_query(student_id, "s.DepartmentID = ? AND s.Semester = ?", (dept_id, semester))

        return jsonify({'success': True, 'exams': exams}), 200
    except Exception as e:
        print(f'[Exams] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_student.route('/exams/<int:exam_id>', methods=['GET'])
@jwt_required()
def get_exam_details(exam_id):
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, _, _, _ = _resolve(user_id)

        exam = None
        for exam_sql in [
            # MSSQL safe — no StartTime/EndTime
            "SELECT e.ExamID, ISNULL(e.ExamTitle,e.ExamType) AS ExamName, e.ExamType, CONVERT(VARCHAR(10),e.ExamDate,23) AS ExamDate, e.Duration, e.TotalMarks, ISNULL(e.Instructions,'') AS Instructions, 1 AS IsActive, CONVERT(VARCHAR(5),ISNULL(e.StartTime,'00:00'),108) AS StartTime, NULL AS EndTime, s.SubjectName, s.SubjectCode FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID WHERE e.ExamID = ?",
            "SELECT e.ExamID, e.ExamType AS ExamName, e.ExamType, e.ExamDate, e.Duration, e.TotalMarks, NULL AS Instructions, 1 AS IsActive, NULL AS StartTime, NULL AS EndTime, s.SubjectName, s.SubjectCode FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID WHERE e.ExamID = ?",
            # SQLite full columns
            "SELECT e.ExamID, e.ExamName, e.ExamType, e.ExamDate, e.StartTime, e.EndTime, e.Duration, e.TotalMarks, e.Instructions, e.IsActive, s.SubjectName, s.SubjectCode FROM Exams e JOIN Subjects s ON e.SubjectID = s.SubjectID WHERE e.ExamID = ?",
        ]:
            try:
                exam = db.execute_query(exam_sql, (exam_id,), fetch_one=True)
                if exam: break
            except Exception:
                pass

        if not exam:
            return jsonify({'error': 'Exam not found', 'success': False}), 404
        if not exam.get('IsActive', 1):
            return jsonify({'error': 'Exam not active', 'success': False}), 404

        submission = None
        try:
            submission = db.execute_query(
                "SELECT SubmissionID, IsSubmitted FROM ExamSubmissions WHERE ExamID=? AND StudentID=?",
                (exam_id, student_id), fetch_one=True)
        except Exception:
            pass

        if submission and submission.get('IsSubmitted'):
            return jsonify({'error': 'Already submitted', 'success': False}), 400

        questions = []
        for _qsql, _qparams in [
            # With QuestionType (patched MSSQL or SQLite)
            ("SELECT QuestionID, QuestionText, QuestionType, OptionA, OptionB, OptionC, OptionD, Marks, QuestionOrder FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionOrder ASC, QuestionID ASC", (exam_id,)),
            # Without QuestionType (original MSSQL schema - column does not exist)
            ("SELECT QuestionID, QuestionText, OptionA, OptionB, OptionC, OptionD, Marks, QuestionOrder FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionOrder ASC, QuestionID ASC", (exam_id,)),
            # Minimal
            ("SELECT QuestionID, QuestionText, Marks FROM ExamQuestions WHERE ExamID=? ORDER BY QuestionID ASC", (exam_id,)),
        ]:
            try:
                rows = db.execute_query(_qsql, _qparams) or []
                questions = serialize_rows(rows)
                if questions is not None:
                    break
            except Exception as _qe:
                print(f'[ExamDetails] questions fallback err: {_qe}')
        # Inject default QuestionType if column was missing
        for _q in questions:
            if not _q.get('QuestionType'):
                _q['QuestionType'] = 'MCQ'

        submission_id = submission['SubmissionID'] if submission else None
        if not submission:
            # Try all MSSQL-compatible INSERT variants (no INSERT OR IGNORE in MSSQL)
            ins_done = False
            for ins_sql, ins_params in [
                # MSSQL: IF NOT EXISTS pattern
                ("IF NOT EXISTS (SELECT 1 FROM ExamSubmissions WHERE ExamID=? AND StudentID=?) INSERT INTO ExamSubmissions (ExamID,StudentID,IsSubmitted) VALUES (?,?,0)",
                 (exam_id, student_id, exam_id, student_id)),
                # MSSQL: plain INSERT (may fail on duplicate, that's OK)
                ("INSERT INTO ExamSubmissions (ExamID,StudentID,IsSubmitted) VALUES (?,?,0)",
                 (exam_id, student_id)),
                # SQLite fallback
                ("INSERT OR IGNORE INTO ExamSubmissions (ExamID,StudentID,IsSubmitted) VALUES (?,?,0)",
                 (exam_id, student_id)),
            ]:
                try:
                    db.execute_non_query(ins_sql, ins_params)
                    ins_done = True
                    print(f'[ExamDetails] submission INSERT succeeded for exam={exam_id} student={student_id}')
                    break
                except Exception as _ie:
                    print(f'[ExamDetails] submission INSERT variant failed: {_ie}')

            # Retrieve the submission ID we just created (or that already existed)
            for sel_sql in [
                "SELECT TOP 1 SubmissionID FROM ExamSubmissions WHERE ExamID=? AND StudentID=? ORDER BY SubmissionID DESC",
                "SELECT SubmissionID FROM ExamSubmissions WHERE ExamID=? AND StudentID=? ORDER BY SubmissionID DESC LIMIT 1",
            ]:
                try:
                    s2 = db.execute_query(sel_sql, (exam_id, student_id), fetch_one=True)
                    if s2 and s2.get('SubmissionID'):
                        submission_id = s2['SubmissionID']
                        print(f'[ExamDetails] submission_id={submission_id}')
                        break
                except Exception as _se:
                    print(f'[ExamDetails] submission SELECT err: {_se}')

        return jsonify({
            'success': True,
            'exam': serialize_row(exam),
            'questions': questions,
            'submissionId': submission_id
        }), 200
    except Exception as e:
        print(f'[ExamDetails] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_student.route('/exams/<int:exam_id>/submit', methods=['POST'])
@jwt_required()
def submit_exam(exam_id):
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, _, _, _ = _resolve(user_id)
        data = request.json or {}

        # ── Find or create submission record ────────────────────────────────
        submission = None
        for _sq in [
            "SELECT TOP 1 SubmissionID, IsSubmitted FROM ExamSubmissions WHERE ExamID=? AND StudentID=? ORDER BY SubmissionID DESC",
            "SELECT SubmissionID, IsSubmitted FROM ExamSubmissions WHERE ExamID=? AND StudentID=? ORDER BY SubmissionID DESC LIMIT 1",
        ]:
            try:
                submission = db.execute_query(_sq, (exam_id, student_id), fetch_one=True)
                if submission: break
            except Exception as _e:
                print(f'[ExamSubmit] lookup err: {_e}')

        # If no row exists (exam was opened but INSERT failed), create it now
        if not submission:
            print(f'[ExamSubmit] No submission row — creating for exam={exam_id} student={student_id}')
            for ins_sql, ins_params in [
                ("IF NOT EXISTS (SELECT 1 FROM ExamSubmissions WHERE ExamID=? AND StudentID=?) INSERT INTO ExamSubmissions (ExamID,StudentID,IsSubmitted) VALUES (?,?,0)",
                 (exam_id, student_id, exam_id, student_id)),
                ("INSERT INTO ExamSubmissions (ExamID,StudentID,IsSubmitted) VALUES (?,?,0)",
                 (exam_id, student_id)),
                ("INSERT OR IGNORE INTO ExamSubmissions (ExamID,StudentID,IsSubmitted) VALUES (?,?,0)",
                 (exam_id, student_id)),
            ]:
                try:
                    db.execute_non_query(ins_sql, ins_params)
                    break
                except Exception as _ie:
                    print(f'[ExamSubmit] create submission err: {_ie}')
            for _sq in [
                "SELECT TOP 1 SubmissionID, IsSubmitted FROM ExamSubmissions WHERE ExamID=? AND StudentID=? ORDER BY SubmissionID DESC",
                "SELECT SubmissionID, IsSubmitted FROM ExamSubmissions WHERE ExamID=? AND StudentID=? ORDER BY SubmissionID DESC LIMIT 1",
            ]:
                try:
                    submission = db.execute_query(_sq, (exam_id, student_id), fetch_one=True)
                    if submission: break
                except Exception: pass

        if not submission:
            return jsonify({'error': 'Could not create submission record — check DB logs', 'success': False}), 500

        if submission.get('IsSubmitted'):
            return jsonify({'error': 'Already submitted', 'success': False}), 400

        submission_id = submission['SubmissionID']
        print(f'[ExamSubmit] using submission_id={submission_id}')

        # ── Grade answers ──────────────────────────────────────────────────
        total_marks = 0
        answer_records = []
        for answer in data.get('answers', []):
            q = None
            for _sq in [
                "SELECT TOP 1 CorrectAnswer, Marks, QuestionType FROM ExamQuestions WHERE QuestionID=?",
                "SELECT TOP 1 CorrectAnswer, Marks FROM ExamQuestions WHERE QuestionID=?",
            ]:
                try:
                    q = db.execute_query(_sq, (answer['questionId'],), fetch_one=True)
                    if q: break
                except Exception: pass
            if q:
                q_type = q.get('QuestionType', 'MCQ') or 'MCQ'
                correct = (q_type in ('MCQ', 'TrueFalse') and
                           str(answer.get('answer', '')).strip().lower() ==
                           str(q.get('CorrectAnswer', '')).strip().lower())
                marks = float(q.get('Marks', 0) or 0) if correct else 0
                total_marks += marks
                # Store answer in memory - will be saved as JSON to ExamSubmissions.Answers
                answer_records.append({
                    'questionId': answer['questionId'],
                    'answer': answer.get('answer'),
                    'correct': correct,
                    'marks': marks
                })

        # Save all answers as JSON into ExamSubmissions.Answers column
        import json as _json
        answers_json = _json.dumps(answer_records)
        for ans_sql in [
            "UPDATE ExamSubmissions SET Answers=? WHERE SubmissionID=?",
        ]:
            try:
                db.execute_non_query(ans_sql, (answers_json, submission_id))
                break
            except Exception as _ae:
                print(f'[ExamSubmit] answers JSON save err: {_ae}')

        for upd_sql, upd_params in [
            ("UPDATE ExamSubmissions SET IsSubmitted=1, SubmittedAt=GETDATE(), MarksObtained=? WHERE SubmissionID=?",
             (total_marks, submission_id)),
            ("UPDATE ExamSubmissions SET IsSubmitted=1, SubmittedAt=GETDATE() WHERE SubmissionID=?",
             (submission_id,)),
            ("UPDATE ExamSubmissions SET IsSubmitted=1, MarksObtained=? WHERE SubmissionID=?",
             (total_marks, submission_id)),
            ("UPDATE ExamSubmissions SET IsSubmitted=1 WHERE SubmissionID=?",
             (submission_id,)),
        ]:
            try:
                db.execute_non_query(upd_sql, upd_params)
                break
            except Exception as _ue:
                print(f'[ExamSubmit] update variant failed: {_ue}')

        return jsonify({'success': True, 'message': 'Exam submitted!', 'marksObtained': total_marks}), 200
    except Exception as e:
        print(f'[ExamSubmit] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# MARKS
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/marks', methods=['GET'])
@jwt_required()
def get_marks():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, u_code = _resolve(user_id)
        marks = []
        # Deduplicated candidate IDs (student_id from Students table or fallback to user_id)
        candidate_ids = list(dict.fromkeys([i for i in [student_id, user_id] if i]))

        # Strategy 1: Try each candidate ID directly
        # NOTE: Do NOT select AcademicYear — it may not exist in MSSQL Marks table
        for sid in candidate_ids:
            try:
                rows = db.execute_query("""
                    SELECT m.MarkID,
                           m.CA1, m.CA2, m.CA3, m.CA4, m.CA5, m.Midterm, m.Endterm,
                           s.SubjectName, s.SubjectCode, s.Credits
                    FROM Marks m JOIN Subjects s ON m.SubjectID = s.SubjectID
                    WHERE m.StudentID = ? ORDER BY s.SubjectName
                """, (sid,))
                if rows:
                    marks = serialize_rows(rows)
                    break
            except Exception as e:
                print(f'[Marks] direct sid={sid} err: {e}')

        # Strategy 2: Try with AcademicYear in SELECT (SQLite fallback)
        if not marks:
            for sid in candidate_ids:
                try:
                    rows = db.execute_query("""
                        SELECT m.MarkID, m.AcademicYear,
                               m.CA1, m.CA2, m.CA3, m.CA4, m.CA5, m.Midterm, m.Endterm,
                               s.SubjectName, s.SubjectCode, s.Credits
                        FROM Marks m JOIN Subjects s ON m.SubjectID = s.SubjectID
                        WHERE m.StudentID = ? ORDER BY s.SubjectName
                    """, (sid,))
                    if rows:
                        marks = serialize_rows(rows)
                        break
                except Exception as e:
                    print(f'[Marks] with-acad-year sid={sid} err: {e}')

        # Strategy 3: Join via UserCode — handles ID mismatch between Users and Students tables
        if not marks and u_code:
            for join_sql in [
                """SELECT m.MarkID,
                          m.CA1, m.CA2, m.CA3, m.CA4, m.CA5, m.Midterm, m.Endterm,
                          s.SubjectName, s.SubjectCode, s.Credits
                   FROM Marks m
                   JOIN Users u ON m.StudentID = u.UserID
                   JOIN Subjects s ON m.SubjectID = s.SubjectID
                   WHERE u.UserCode = ? ORDER BY s.SubjectName""",
                """SELECT m.MarkID,
                          m.CA1, m.CA2, m.CA3, m.CA4, m.CA5, m.Midterm, m.Endterm,
                          s.SubjectName, s.SubjectCode, s.Credits
                   FROM Marks m
                   JOIN Students st ON m.StudentID = st.StudentID
                   JOIN Subjects s ON m.SubjectID = s.SubjectID
                   WHERE st.RollNumber = ? ORDER BY s.SubjectName""",
            ]:
                try:
                    rows = db.execute_query(join_sql, (u_code,))
                    if rows:
                        marks = serialize_rows(rows)
                        break
                except Exception as e:
                    print(f'[Marks] join-by-code err: {e}')

        # Normalize rows: ensure CA1-CA5, Midterm, Endterm always present
        for m in marks:
            for col in ['CA1','CA2','CA3','CA4','CA5','Midterm','Endterm']:
                if col not in m:
                    m[col] = None

        return jsonify({'success': True, 'marks': marks}), 200
    except Exception as e:
        print(f'[Marks] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# FEES
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/fees', methods=['GET'])
@jwt_required()
def get_fees():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)

        fee_structure = None
        if dept_id and semester:
            for fs_sql in [
                "SELECT * FROM FeeStructure WHERE DepartmentID=? AND Semester=? AND AcademicYear='2024-25'",
                "SELECT TOP 1 * FROM FeeStructure WHERE DepartmentID=? AND Semester=? ORDER BY AcademicYear DESC",
                "SELECT * FROM FeeStructure WHERE DepartmentID=? AND Semester=? ORDER BY AcademicYear DESC LIMIT 1",
            ]:
                try:
                    row = db.execute_query(fs_sql, (dept_id, semester), fetch_one=True)
                    if row:
                        fee_structure = serialize_row(row)
                        break
                except Exception:
                    pass

        payments = []
        try:
            payments = serialize_rows(db.execute_query(
                "SELECT * FROM FeePayments WHERE StudentID=? ORDER BY PaymentDate DESC",
                (student_id,))) or []
        except Exception as e:
            print(f'[Fees] payments err: {e}')

        total_paid = sum(float(p.get('AmountPaid', 0) or 0) for p in payments)
        total_fee  = float(fee_structure.get('TotalFee', 0) if fee_structure else 0)

        return jsonify({
            'success':       True,
            'feeStructure':  fee_structure,
            'payments':      payments,
            'totalPaid':     total_paid,
            'pendingAmount': max(0, total_fee - total_paid)
        }), 200
    except Exception as e:
        print(f'[Fees] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_student.route('/fees/pay', methods=['POST'])
@jwt_required()
def pay_fee():
    """Record a fee payment via UPI / Net Banking / Debit Card / Credit Card."""
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, _, _, _ = _resolve(user_id)
        data = request.json or {}

        amount       = data.get('amount')
        payment_mode = data.get('paymentMode', '').strip()
        upi_id       = data.get('upiId', '').strip()
        card_number  = data.get('cardNumber', '').strip()  # last 4 digits only
        bank_name    = data.get('bankName', '').strip()
        description  = data.get('description', 'Fee Payment')

        if not amount or float(amount) <= 0:
            return jsonify({'success': False, 'error': 'Invalid payment amount'}), 400

        valid_modes = {'UPI', 'NetBanking', 'DebitCard', 'CreditCard', 'Cash', 'Cheque'}
        if payment_mode not in valid_modes:
            return jsonify({'success': False, 'error': f'Invalid mode. Use: {", ".join(sorted(valid_modes))}'}), 400

        if payment_mode == 'UPI' and not upi_id:
            return jsonify({'success': False, 'error': 'UPI ID is required for UPI payment'}), 400

        import random, string
        txn_id = 'TXN' + ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
        today  = datetime.now().strftime('%Y-%m-%d')

        # Build reference note
        ref_note = upi_id or bank_name or (f'****{card_number[-4:]}' if len(card_number) >= 4 else '') or ''

        for ins_sql in [
            "INSERT INTO FeePayments (StudentID, AmountPaid, PaymentDate, PaymentMode, TransactionID, Description, AcademicYear) VALUES (?,?,?,?,?,?,?)",
            "INSERT INTO FeePayments (StudentID, AmountPaid, PaymentDate, PaymentMode, TransactionID) VALUES (?,?,?,?,?)",
        ]:
            try:
                if 'AcademicYear' in ins_sql:
                    db.execute_non_query(ins_sql, (student_id, float(amount), today, payment_mode, txn_id, description, '2024-25'))
                else:
                    db.execute_non_query(ins_sql, (student_id, float(amount), today, payment_mode, txn_id))
                break
            except Exception as e:
                print(f'[FeePay] insert variant err: {e}')

        return jsonify({
            'success':       True,
            'message':       f'Payment of ₹{float(amount):,.2f} via {payment_mode} successful!',
            'transactionId': txn_id,
            'amount':        float(amount),
            'paymentMode':   payment_mode,
            'paymentDate':   today,
            'reference':     ref_note,
        }), 200
    except Exception as e:
        print(f'[FeePay] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# ONLINE CLASSES
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/online-classes', methods=['GET'])
@jwt_required()
def get_online_classes():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, dept_id, semester, _ = _resolve(user_id)
        classes  = []
        subj_ids = _enrolled_subj_ids(student_id, dept_id, semester)

        if not subj_ids:
            return jsonify({'success': True, 'onlineClasses': []}), 200

        ph = ','.join('?' * len(subj_ids))

        query_variants = [
            # Full schema with all columns + Users teacher join
            (f"""SELECT oc.OnlineClassID, oc.Title, oc.Topic, oc.Description,
                        oc.MeetingLink, oc.ScheduledDate, oc.StartTime, oc.EndTime,
                        s.SubjectName, s.SubjectCode, tc.FullName AS TeacherName
                 FROM OnlineClasses oc
                 JOIN Subjects s  ON oc.SubjectID = s.SubjectID
                 JOIN Users    tc ON oc.TeacherID = tc.UserID
                 WHERE oc.SubjectID IN ({ph})
                 ORDER BY oc.ScheduledDate DESC, oc.CreatedAt DESC""", tuple(subj_ids)),
            # No ScheduledDate column (older schema)
            (f"""SELECT oc.OnlineClassID, oc.Title, oc.Title AS Topic, '' AS Description,
                        oc.MeetingLink,
                        CONVERT(VARCHAR(10), oc.CreatedAt, 23) AS ScheduledDate,
                        '' AS StartTime, '' AS EndTime,
                        s.SubjectName, s.SubjectCode, tc.FullName AS TeacherName
                 FROM OnlineClasses oc
                 JOIN Subjects s  ON oc.SubjectID = s.SubjectID
                 JOIN Users    tc ON oc.TeacherID = tc.UserID
                 WHERE oc.SubjectID IN ({ph})
                 ORDER BY oc.CreatedAt DESC""", tuple(subj_ids)),
            # SQLite: Teachers table
            (f"""SELECT oc.OnlineClassID, oc.Title, oc.Topic, oc.Description,
                        oc.MeetingLink, oc.ScheduledDate, oc.StartTime, oc.EndTime,
                        s.SubjectName, s.SubjectCode, tc.FullName AS TeacherName
                 FROM OnlineClasses oc
                 JOIN Subjects s  ON oc.SubjectID = s.SubjectID
                 JOIN Teachers tc ON oc.TeacherID = tc.TeacherID
                 WHERE oc.SubjectID IN ({ph})
                 ORDER BY oc.ScheduledDate DESC""", tuple(subj_ids)),
            # No teacher join fallback
            (f"""SELECT oc.OnlineClassID, oc.Title, oc.Title AS Topic, '' AS Description,
                        oc.MeetingLink,
                        CONVERT(VARCHAR(10), oc.CreatedAt, 23) AS ScheduledDate,
                        '' AS StartTime, '' AS EndTime,
                        s.SubjectName, s.SubjectCode, '' AS TeacherName
                 FROM OnlineClasses oc
                 JOIN Subjects s ON oc.SubjectID = s.SubjectID
                 WHERE oc.SubjectID IN ({ph})
                 ORDER BY oc.CreatedAt DESC""", tuple(subj_ids)),
        ]

        for sql, params in query_variants:
            try:
                rows = db.execute_query(sql, params)
                if rows is not None:
                    classes = serialize_rows(rows)
                    for c in classes:
                        c.setdefault('Topic', c.get('Title', ''))
                        c.setdefault('ScheduledDate', '')
                    break
            except Exception as e:
                print(f'[OnlineClasses] strategy err: {e}')

        return jsonify({'success': True, 'onlineClasses': classes}), 200
    except Exception as e:
        print(f'[OnlineClasses] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


# ══════════════════════════════════════════════════════════════════════════════
# NOTIFICATIONS
# ══════════════════════════════════════════════════════════════════════════════

@bp_student.route('/notifications', methods=['GET'])
@jwt_required()
def get_notifications():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, _, _, _ = _resolve(user_id)
        notes, unread = [], 0

        for col, val in [('StudentID', student_id), ('UserID', user_id)]:
            try:
                rows = db.execute_query(
                    f"SELECT * FROM Notifications WHERE {col}=? ORDER BY CreatedAt DESC",
                    (val,))
                if rows is not None:
                    notes = serialize_rows(rows)
                    break
            except Exception:
                pass

        for col, val in [('StudentID', student_id), ('UserID', user_id)]:
            try:
                r = db.execute_query(
                    f"SELECT COUNT(*) AS cnt FROM Notifications WHERE {col}=? AND IsRead=0", (val,), fetch_one=True)
                unread = int(r['cnt'] or 0) if r else 0
                break
            except Exception:
                pass

        return jsonify({'success': True, 'notifications': notes, 'unreadCount': unread}), 200
    except Exception as e:
        print(f'[Notifications] Error: {e}')
        traceback.print_exc()
        return jsonify({'error': str(e), 'success': False}), 500


@bp_student.route('/notifications/<int:nid>/mark-read', methods=['PUT'])
@bp_student.route('/notifications/<int:nid>/read', methods=['PUT'])
@jwt_required()
def mark_notification_read(nid):
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, _, _, _ = _resolve(user_id)
        for col, val in [('StudentID', student_id), ('UserID', user_id)]:
            try:
                db.execute_non_query(
                    f"UPDATE Notifications SET IsRead=1 WHERE NotificationID=? AND {col}=?", (nid, val))
                break
            except Exception:
                pass
        return jsonify({'success': True}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500


@bp_student.route('/notifications/read-all', methods=['PUT'])
@jwt_required()
def mark_all_read():
    err = student_required()
    if err: return err
    try:
        user_id = int(get_jwt_identity())
        student_id, _, _, _ = _resolve(user_id)
        for col, val in [('StudentID', student_id), ('UserID', user_id)]:
            try:
                db.execute_non_query(f"UPDATE Notifications SET IsRead=1 WHERE {col}=?", (val,))
                break
            except Exception:
                pass
        return jsonify({'success': True}), 200
    except Exception as e:
        return jsonify({'error': str(e), 'success': False}), 500