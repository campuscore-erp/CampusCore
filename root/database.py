"""
database.py  —  University ERP  |  Database Layer
==================================================

SCHEMA: Matches Time Table v9 SQL exactly.
  • Departments  (DepartmentID, DepartmentName, DepartmentCode, TotalSemesters, IsShared)
  • Subjects     (SubjectID, SubjectName, SubjectCode, Credits, IsLab, DepartmentID, Semester)
  • Teachers     (TeacherID, FullName, TeacherCode, Email, Phone, DepartmentID, Designation, JoiningDate, IsActive)
  • TeacherSubjects (ID, TeacherID, SubjectID, DepartmentID, Semester, AcademicYear)
  • Students     (StudentID, FullName, RollNumber, Email, DepartmentID, CurrentSemester, AcademicYear, IsActive)
  • Timetable    (TimetableID, DepartmentID, Semester, SubjectID, TeacherID, DayOfWeek, PeriodNumber,
                  StartTime, EndTime, RoomNumber, IsLab, AcademicYear)
  • StudentEnrollments (EnrollmentID, StudentID, TimetableID, EnrollmentDate, IsActive)
  • Users        (UserID, UserCode, FullName, Email, Phone, PasswordHash, UserType, DepartmentID,
                  Gender, DateOfBirth, Address, JoinDate, IsActive)
      → Admin and Teacher login accounts live here
  • Attendance, Exams, ExamSubmissions, ExamQuestions, ExamAnswers, Marks,
    StudyMaterials, OnlineClasses, QRCodes, Notifications, FeeStructure, FeePayments

FIXES vs original database.py:
  FIX-A  SQLite schema now exactly mirrors Time Table v9 SQL:
         - Students table (separate from Users)
         - Teachers table (separate from Users)
         - StudentEnrollments references Students + Timetable (TimetableID)
         - TeacherSubjects references Teachers + Subjects
  FIX-B  Seed data includes 8 teachers, CSE subjects, and 10 students
         enrolled via TimetableID so every query works out-of-the-box.
  FIX-C  _to_sqlite_sql() improvements for GROUP_CONCAT, CONVERT, TOP N.
  FIX-D  verify_password() supports both bcrypt and sha256.
  FIX-E  _detect_backend() always calls _ensure_sqlite_schema() on fallback.
  FIX-F  execute_*() pass () instead of None for params (pyodbc fix).
"""

import os
import re
import sqlite3
import hashlib
import sys
from datetime import date, datetime, time
from decimal import Decimal
from typing import Optional, List, Any, Tuple

from dotenv import load_dotenv

load_dotenv()

# ── Railway MySQL Environment Variables ────────────────────────────────────────
MYSQL_HOST     = os.environ.get('MYSQLHOST',     None)
MYSQL_PORT     = int(os.environ.get('MYSQLPORT', 3306))
MYSQL_USER     = os.environ.get('MYSQLUSER',     'root')
MYSQL_PASSWORD = os.environ.get('MYSQLPASSWORD', '')
MYSQL_DB       = os.environ.get('MYSQLDATABASE', 'railway')

# If Railway MySQL variables are set, force DB_BACKEND=mysql immediately
if MYSQL_HOST:
    print(f'✅ [DB] Railway MySQL detected: {MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}')
    os.environ['DB_BACKEND'] = 'mysql'
    print(f'✅ [DB] DB_BACKEND forced to mysql')

try:
    import pymysql
    PYMYSQL_AVAILABLE = True
except ImportError:
    PYMYSQL_AVAILABLE = False

try:
    import pyodbc
    PYODBC_AVAILABLE = True
except ImportError:
    PYODBC_AVAILABLE = False

try:
    import bcrypt as _bcrypt
    BCRYPT_AVAILABLE = True
except ImportError:
    BCRYPT_AVAILABLE = False
    print('⚠️  [DB] bcrypt not installed — run: pip install bcrypt')

try:
    if hasattr(sys.stdout, 'reconfigure'):
        sys.stdout.reconfigure(errors='replace')
    if hasattr(sys.stderr, 'reconfigure'):
        sys.stderr.reconfigure(errors='replace')
except Exception:
    pass


# ── Helpers ────────────────────────────────────────────────────────────────────

def _hash(password: str) -> str:
    """SHA-256 hash used for SQLite dev seeds."""
    return hashlib.sha256(password.encode()).hexdigest()


def verify_password(plain: str, stored_hash: str) -> bool:
    """Verify plain text password against stored hash (bcrypt or sha256)."""
    if not plain or not stored_hash:
        return False
    stored = stored_hash.strip()
    if stored.startswith(('$2b$', '$2a$', '$2y$')):
        if BCRYPT_AVAILABLE:
            try:
                return _bcrypt.checkpw(plain.encode('utf-8'), stored.encode('utf-8'))
            except Exception as e:
                print(f'[verify_password] bcrypt error: {e}')
                return False
        else:
            print('[verify_password] bcrypt hash in DB but bcrypt not installed!')
            return False
    return _hash(plain) == stored


def _to_sqlite_sql(sql: str) -> str:
    """Translate MSSQL-specific syntax to SQLite equivalents."""

    sql = re.sub(r'\bGETDATE\(\)', "datetime('now')", sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bCAST\s*\(GETDATE\(\)\s+AS\s+DATE\)', "date('now')", sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bNVARCHAR\s*\(\s*(?:MAX|\d+)\s*\)', 'TEXT', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bNVARCHAR\b', 'TEXT', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bBIT\b', 'INTEGER', sql, flags=re.IGNORECASE)
    sql = re.sub(r'\bDATETIME2?\b', 'TEXT', sql, flags=re.IGNORECASE)
    sql = re.sub(r'^\s*GO\s*$', '', sql, flags=re.IGNORECASE | re.MULTILINE)

    # CONVERT(VARCHAR(n), col, 108) → strftime('%H:%M', col)
    sql = re.sub(
        r"CONVERT\s*\(\s*VARCHAR\s*\(\s*\d+\s*\)\s*,\s*([^,]+?)\s*,\s*108\s*\)",
        lambda m: f"strftime('%H:%M', {m.group(1).strip()})",
        sql, flags=re.IGNORECASE,
    )

    # STUFF(…FOR XML PATH('')) → GROUP_CONCAT
    def _rewrite_stuff(m: re.Match) -> str:
        inner = m.group(1)
        inner = re.sub(r",?\s*TYPE\s*\)\s*\.value\s*\([^)]*\)", '', inner, flags=re.IGNORECASE)
        inner = re.sub(r"\s+FOR\s+XML\s+PATH\s*\(\s*''\s*\)", '', inner, flags=re.IGNORECASE)
        inner = re.sub(
            r"'[,\s]*'\s*\+\s*CAST\s*\((.+?)\s+AS\s+\w+(?:\s*\(\s*\d+\s*\))?\s*\)",
            r'\1', inner, flags=re.IGNORECASE,
        )
        inner = re.sub(r"'[,\s]*'\s*\+\s*", '', inner, flags=re.IGNORECASE)
        inner = inner.rstrip().rstrip(')')
        inner = re.sub(r'\bSELECT\s+DISTINCT\s+(\S+)', r'SELECT GROUP_CONCAT(DISTINCT \1)', inner, flags=re.IGNORECASE)
        inner = re.sub(r'\bSELECT\s+(?!GROUP_CONCAT)(\S+)', r'SELECT GROUP_CONCAT(\1)', inner, flags=re.IGNORECASE)
        return f'({inner})'

    sql = re.sub(
        r"STUFF\s*\(\s*(\(SELECT\b.+?(?:FOR\s+XML\s+PATH\s*\(\s*''\s*\)|TYPE\s*\)\s*\.value\s*\([^)]*\)))\s*,\s*1\s*,\s*1\s*,\s*''\s*\)",
        _rewrite_stuff, sql, flags=re.IGNORECASE | re.DOTALL,
    )

    # TOP N → LIMIT N
    top_match = re.search(r'\bSELECT\s+TOP\s*\(?\s*(\d+)\s*\)?\s+', sql, flags=re.IGNORECASE)
    if top_match:
        n = top_match.group(1)
        sql = re.sub(r'\bSELECT\s+TOP\s*\(?\s*\d+\s*\)?\s+', 'SELECT ', sql, flags=re.IGNORECASE)
        if not re.search(r'\bLIMIT\b', sql, flags=re.IGNORECASE):
            sql = sql.rstrip().rstrip(';') + f' LIMIT {n}'

    # CONCAT(a, b, c) → (a || b || c) for SQLite
    def _rewrite_concat(m):
        args = [a.strip() for a in m.group(1).split(',')]
        return '(' + ' || '.join(args) + ')'
    sql = re.sub(r'\bCONCAT\s*\(([^)]+)\)', _rewrite_concat, sql, flags=re.IGNORECASE)

    # FIELD(col, 'v1','v2',...) → CASE col WHEN 'v1' THEN 1 WHEN 'v2' THEN 2 ... END
    def _rewrite_field(m):
        parts = [p.strip() for p in m.group(1).split(',')]
        col = parts[0]
        cases = ' '.join(f"WHEN {v} THEN {i+1}" for i, v in enumerate(parts[1:]))
        return f'CASE {col} {cases} ELSE {len(parts)} END'
    sql = re.sub(r'\bFIELD\s*\(([^)]+)\)', _rewrite_field, sql, flags=re.IGNORECASE)

    sql = sql.replace('%s', '?')
    return sql


def _to_mssql_sql(sql: str) -> str:
    """
    Translate small SQLite-isms that may appear in route queries to SQL Server.
    Currently supports trailing LIMIT n on SELECT statements.
    """
    m = re.search(r'\bLIMIT\s+(\d+)\s*;?\s*$', sql, flags=re.IGNORECASE)
    if not m:
        return sql

    limit_n = m.group(1)
    without_limit = re.sub(r'\s+LIMIT\s+\d+\s*;?\s*$', '', sql, flags=re.IGNORECASE)

    # SELECT DISTINCT ... -> SELECT DISTINCT TOP n ...
    if re.match(r'^\s*SELECT\s+DISTINCT\b', without_limit, flags=re.IGNORECASE):
        return re.sub(
            r'^\s*SELECT\s+DISTINCT\s+',
            f'SELECT DISTINCT TOP {limit_n} ',
            without_limit,
            count=1,
            flags=re.IGNORECASE
        )

    # SELECT ... -> SELECT TOP n ...
    if re.match(r'^\s*SELECT\b', without_limit, flags=re.IGNORECASE):
        return re.sub(
            r'^\s*SELECT\s+',
            f'SELECT TOP {limit_n} ',
            without_limit,
            count=1,
            flags=re.IGNORECASE
        )

    return without_limit



def _to_mysql_sql(sql: str) -> str:
    """Translate MSSQL/SQLite SQL to MySQL. Called for every MySQL query."""
    import re as _re

    # ISNULL -> IFNULL
    sql = _re.sub(r'\bISNULL\s*\(', 'IFNULL(', sql, flags=_re.IGNORECASE)

    # CONVERT(VARCHAR(n), col, 23) -> DATE_FORMAT(col, '%Y-%m-%d')
    sql = _re.sub(
        r"CONVERT\s*\(\s*VARCHAR\s*\(\s*\d+\s*\)\s*,\s*([^,]+?)\s*,\s*23\s*\)",
        lambda m: f"DATE_FORMAT({m.group(1).strip()}, '%Y-%m-%d')",
        sql, flags=_re.IGNORECASE)

    # CONVERT(VARCHAR(n), col, 108) -> TIME_FORMAT(col, '%H:%i')
    sql = _re.sub(
        r"CONVERT\s*\(\s*VARCHAR\s*\(\s*\d+\s*\)\s*,\s*([^,]+?)\s*,\s*108\s*\)",
        lambda m: f"TIME_FORMAT({m.group(1).strip()}, '%H:%i')",
        sql, flags=_re.IGNORECASE)

    # CONVERT(VARCHAR(n), expr) -> CAST(expr AS CHAR)
    sql = _re.sub(
        r"CONVERT\s*\(\s*VARCHAR\s*\(\s*\d+\s*\)\s*,\s*([^)]+?)\s*\)",
        lambda m: f"CAST({m.group(1).strip()} AS CHAR)",
        sql, flags=_re.IGNORECASE)

    # STRING_AGG -> GROUP_CONCAT SEPARATOR
    sql = _re.sub(
        r"STRING_AGG\s*\(\s*([^,]+?)\s*,\s*'([^']*)'\s*\)",
        lambda m: f"GROUP_CONCAT({m.group(1).strip()} SEPARATOR '{m.group(2)}')",
        sql, flags=_re.IGNORECASE)

    # CAST AS VARCHAR/NVARCHAR -> CHAR
    sql = _re.sub(
        r'\bCAST\s*\((.+?)\s+AS\s+N?VARCHAR(?:\s*\(\s*\d+\s*\))?\s*\)',
        lambda m: f'CAST({m.group(1)} AS CHAR)', sql, flags=_re.IGNORECASE)

    # CAST AS FLOAT -> DECIMAL
    sql = _re.sub(
        r'\bCAST\s*\((.+?)\s+AS\s+FLOAT\s*\)',
        lambda m: f'CAST({m.group(1)} AS DECIMAL(10,4))', sql, flags=_re.IGNORECASE)

    # SELECT TOP N -> SELECT ... LIMIT N
    top_m = _re.search(r'\bSELECT\s+TOP\s*\(?\s*(\d+)\s*\)?\s+', sql, flags=_re.IGNORECASE)
    if top_m:
        n = top_m.group(1)
        sql = _re.sub(r'\bSELECT\s+TOP\s*\(?\s*\d+\s*\)?\s+', 'SELECT ', sql, flags=_re.IGNORECASE)
        if not _re.search(r'\bLIMIT\b', sql, flags=_re.IGNORECASE):
            sql = sql.rstrip().rstrip(';') + f' LIMIT {n}'

    # IF NOT EXISTS INSERT -> INSERT IGNORE
    sql = _re.sub(
        r"IF\s+NOT\s+EXISTS\s*\(\s*SELECT\s+1\s+FROM\s+(\w+)\s+WHERE\s+([^)]+)\)\s+INSERT\s+INTO\s+\1\s*(\([^)]+\))\s*VALUES\s*(\([^)]+\))",
        lambda m: f"INSERT IGNORE INTO {m.group(1)} {m.group(3)} VALUES {m.group(4)}",
        sql, flags=_re.IGNORECASE | _re.DOTALL)

    # INSERT OR IGNORE -> INSERT IGNORE
    sql = _re.sub(r'\bINSERT\s+OR\s+IGNORE\b', 'INSERT IGNORE', sql, flags=_re.IGNORECASE)

    # COALESCE(t.RoomNumber, t.Room, '') -> IFNULL(t.RoomNumber, '')
    sql = _re.sub(
        r"COALESCE\s*\(\s*t\.RoomNumber\s*,\s*t\.Room\s*,\s*''\s*\)",
        "IFNULL(t.RoomNumber, '')", sql, flags=_re.IGNORECASE)

    # IFNULL(x, IFNULL(y, '')) — already valid MySQL, leave as is

    # General 3-arg COALESCE(a, b, '') → IFNULL(IFNULL(a, b), '')
    # (MySQL COALESCE supports N args but this helps with t.Room style patterns)
    sql = _re.sub(
        r"COALESCE\s*\(\s*([^,]+?)\s*,\s*([^,]+?)\s*,\s*''\s*\)",
        lambda m: f"IFNULL(IFNULL({m.group(1).strip()}, {m.group(2).strip()}), '')",
        sql, flags=_re.IGNORECASE)

    # CASE ... WHEN 'Monday' THEN 1 ... END style ordering — leave as is, MySQL supports it
    # But also translate FIELD() usage (already MySQL-native)

    # Escape % in format strings so pymysql doesn't treat as Python format specifiers
    # Must happen BEFORE replacing ? with %s
    sql = sql.replace('%', '%%')

    # ? -> %s  (LAST step)
    sql = sql.replace('?', '%s')

    return sql

def _serialize_db_value(v: Any) -> Any:
    """Convert DB-specific scalar types to JSON-safe primitives."""
    if isinstance(v, datetime):
        return v.isoformat()
    if isinstance(v, date):
        return v.isoformat()
    if isinstance(v, time):
        return v.strftime('%H:%M:%S')
    if isinstance(v, Decimal):
        return float(v)
    if isinstance(v, bytes):
        return v.decode('utf-8', errors='replace')
    return v


# ── Database class ─────────────────────────────────────────────────────────────

class Database:
    """
    Unified database handler.
    Priority: Railway MySQL → SQL Server (pyodbc) → SQLite fallback.
    All connections are per-operation — open / execute / close.
    """

    def __init__(self):
        self.server   = os.getenv('DB_SERVER',   r'localhost\SQLEXPRESS')
        self.database = os.getenv('DB_NAME',      'UniversityERP')
        self.username = os.getenv('DB_USER',      '')
        self.password = os.getenv('DB_PASSWORD',  '')
        self.driver   = os.getenv('DB_DRIVER',    '{ODBC Driver 17 for SQL Server}')
        self._backend = None
        # Eagerly connect at startup when Railway MySQL is available
        if MYSQL_HOST and PYMYSQL_AVAILABLE:
            try:
                conn = self._mysql_connect()
                conn.close()
                self._backend = 'mysql'
                print(f'✅ [DB] Railway MySQL connected at startup: {MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}')
                self._ensure_mysql_schema()
            except Exception as e:
                print(f'❌ [DB] Railway MySQL startup FAILED: {e}')
                self._backend = None

        base_dir = os.path.dirname(os.path.abspath(__file__))
        self.sqlite_path = os.getenv(
            'SQLITE_PATH', os.path.join(base_dir, 'university_erp.db'))

        # NOTE: Do NOT reset self._backend here — it may already be set to 'mysql'
        # from the eager connection above. The type annotation below is informational only.
        # self._backend: Optional[str] = None  ← REMOVED (was resetting mysql to None!)

    # ── Backend detection ──────────────────────────────────────────────────────

    def _detect_backend(self) -> str:
        if self._backend:
            return self._backend
        # If MySQL host available, always use MySQL (don't fall to SQLite)
        if MYSQL_HOST and PYMYSQL_AVAILABLE:
            try:
                conn = self._mysql_connect()
                conn.close()
                self._backend = 'mysql'
                print(f'✅ [DB] Railway MySQL connected.')
                self._ensure_mysql_schema()
                return self._backend
            except Exception as e:
                print(f'❌ [DB] MySQL connection failed: {e}')

        forced = os.getenv('DB_BACKEND', '').lower()
        if forced in ('mssql', 'sqlserver'):
            self._backend = 'mssql'
            return self._backend
        if forced == 'sqlite':
            self._backend = 'sqlite'
            self._ensure_sqlite_schema()
            return self._backend
        if forced == 'mysql':
            # DB_BACKEND=mysql set explicitly - connect directly to MySQL
            if PYMYSQL_AVAILABLE and MYSQL_HOST:
                try:
                    c = self._mysql_connect()
                    c.close()
                    self._backend = 'mysql'
                    print(f'✅ [DB] Forced MySQL connected: {MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}')
                    self._ensure_mysql_schema()
                    return self._backend
                except Exception as e:
                    print(f'❌ [DB] Forced MySQL FAILED: {e}')
            self._backend = 'mysql'
            return self._backend

        # Try Railway MySQL first
        if PYMYSQL_AVAILABLE and MYSQL_HOST:
            try:
                print(f'[DB] Trying Railway MySQL: {MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB} …')
                c = self._mysql_connect()
                c.close()
                self._backend = 'mysql'
                print('✅ [DB] Railway MySQL connected.')
                self._ensure_mysql_schema()
                return self._backend
            except Exception as e:
                print(f'⚠️  [DB] Railway MySQL failed ({e}). Trying SQL Server …')

        # Try SQL Server
        if PYODBC_AVAILABLE:
            try:
                print(f'[DB] Trying SQL Server: {self.server}/{self.database} …')
                c = pyodbc.connect(self._mssql_connection_string(), timeout=10)
                c.close()
                self._backend = 'mssql'
                print('✅ [DB] SQL Server connected.')
                return self._backend
            except Exception as e:
                print(f'⚠️  [DB] SQL Server failed ({e}). Falling back to SQLite.')
        else:
            print('⚠️  [DB] pyodbc not installed. Using SQLite.')

        self._backend = 'sqlite'
        self._ensure_sqlite_schema()
        print(f'✅ [DB] SQLite → {self.sqlite_path}')
        return self._backend

    # ── Railway MySQL ──────────────────────────────────────────────────────────

    def _mysql_connect(self):
        return pymysql.connect(
            host=MYSQL_HOST,
            port=MYSQL_PORT,
            user=MYSQL_USER,
            password=MYSQL_PASSWORD,
            database=MYSQL_DB,
            charset='utf8mb4',
            cursorclass=pymysql.cursors.DictCursor,
            autocommit=False,
            connect_timeout=30,
            read_timeout=30,
            write_timeout=30,
        )

    def _ensure_mysql_schema(self):
        """Create all tables in Railway MySQL if they don't exist.
        If tables already exist (imported via TablePlus), skip creation safely."""
        conn = self._mysql_connect()
        try:
            with conn.cursor() as cursor:
                # Check if database already has data (imported via TablePlus)
                cursor.execute("SHOW TABLES")
                existing_tables = {row[list(row.keys())[0]] for row in cursor.fetchall()}
                if 'Users' in existing_tables and 'Departments' in existing_tables:
                    # Tables already exist from SQL import - just seed if empty
                    print('[DB] Tables already exist (imported schema). Skipping CREATE TABLE.')
                    conn.close()
                    self._seed_mysql_safe()
                    return
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Departments (
                        DepartmentID   INT PRIMARY KEY,
                        DepartmentName VARCHAR(255) NOT NULL,
                        DepartmentCode VARCHAR(50)  NOT NULL,
                        TotalSemesters INT          NOT NULL DEFAULT 8,
                        IsShared       TINYINT      NOT NULL DEFAULT 0,
                        CreatedAt      DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Users (
                        UserID       INT PRIMARY KEY AUTO_INCREMENT,
                        UserCode     VARCHAR(50)  NOT NULL UNIQUE,
                        FullName     VARCHAR(255) NOT NULL,
                        Email        VARCHAR(255),
                        Phone        VARCHAR(20),
                        PasswordHash VARCHAR(255) NOT NULL,
                        UserType     VARCHAR(20)  NOT NULL,
                        DepartmentID INT,
                        Gender       VARCHAR(10),
                        DateOfBirth  VARCHAR(20),
                        Address      TEXT,
                        FatherName   VARCHAR(255),
                        MotherName   VARCHAR(255),
                        Semester     INT,
                        JoinDate     DATE         DEFAULT (CURRENT_DATE),
                        IsActive     TINYINT      NOT NULL DEFAULT 1,
                        IsFirstLogin TINYINT      NOT NULL DEFAULT 1,
                        CreatedAt    DATETIME     DEFAULT CURRENT_TIMESTAMP,
                        UpdatedAt    DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS ActivityLogs (
                        LogID     INT PRIMARY KEY AUTO_INCREMENT,
                        UserID    INT,
                        Activity  VARCHAR(255) NOT NULL,
                        Details   TEXT,
                        IPAddress VARCHAR(50),
                        CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Teachers (
                        TeacherID    INT PRIMARY KEY,
                        FullName     VARCHAR(255) NOT NULL,
                        TeacherCode  VARCHAR(50)  NOT NULL UNIQUE,
                        Email        VARCHAR(255),
                        Phone        VARCHAR(20),
                        DepartmentID INT          NOT NULL,
                        Designation  VARCHAR(100) NOT NULL DEFAULT 'Assistant Professor',
                        JoiningDate  DATE,
                        IsActive     TINYINT      NOT NULL DEFAULT 1,
                        CreatedAt    DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Subjects (
                        SubjectID    INT PRIMARY KEY,
                        SubjectName  VARCHAR(255) NOT NULL,
                        SubjectCode  VARCHAR(50)  NOT NULL UNIQUE,
                        Credits      INT          NOT NULL DEFAULT 4,
                        IsLab        TINYINT      NOT NULL DEFAULT 0,
                        DepartmentID INT          NOT NULL,
                        Semester     INT          NOT NULL,
                        CreatedAt    DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Students (
                        StudentID       INT PRIMARY KEY AUTO_INCREMENT,
                        FullName        VARCHAR(255) NOT NULL,
                        RollNumber      VARCHAR(50)  NOT NULL UNIQUE,
                        Email           VARCHAR(255) NOT NULL UNIQUE,
                        DepartmentID    INT          NOT NULL,
                        CurrentSemester INT          NOT NULL,
                        AcademicYear    INT          NOT NULL DEFAULT 2025,
                        IsActive        TINYINT      NOT NULL DEFAULT 1,
                        CreatedAt       DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Timetable (
                        TimetableID  INT PRIMARY KEY AUTO_INCREMENT,
                        DepartmentID INT          NOT NULL,
                        Semester     INT          NOT NULL,
                        SubjectID    INT          NOT NULL,
                        TeacherID    INT          NOT NULL,
                        DayOfWeek    VARCHAR(20)  NOT NULL,
                        PeriodNumber INT          NOT NULL,
                        StartTime    VARCHAR(10)  NOT NULL,
                        EndTime      VARCHAR(10)  NOT NULL,
                        RoomNumber   VARCHAR(50)  NOT NULL DEFAULT 'TBD',
                        IsLab        TINYINT      NOT NULL DEFAULT 0,
                        AcademicYear INT          NOT NULL DEFAULT 2025,
                        CreatedAt    DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS TeacherSubjects (
                        ID           INT PRIMARY KEY AUTO_INCREMENT,
                        TeacherID    INT NOT NULL,
                        SubjectID    INT NOT NULL,
                        DepartmentID INT NOT NULL,
                        Semester     INT NOT NULL,
                        AcademicYear INT NOT NULL DEFAULT 2025,
                        CreatedAt    DATETIME DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE KEY uq_teacher_subject (TeacherID, SubjectID, AcademicYear)
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS StudentEnrollments (
                        EnrollmentID   INT PRIMARY KEY AUTO_INCREMENT,
                        StudentID      INT     NOT NULL,
                        TimetableID    INT     NOT NULL,
                        EnrollmentDate DATE    NOT NULL,
                        IsActive       TINYINT NOT NULL DEFAULT 1,
                        UNIQUE KEY uq_enrollment (StudentID, TimetableID)
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Attendance (
                        AttendanceID   INT PRIMARY KEY AUTO_INCREMENT,
                        StudentID      INT         NOT NULL,
                        SubjectID      INT         NOT NULL,
                        TimetableID    INT,
                        QRCodeID       INT,
                        AttendanceDate DATE        NOT NULL,
                        Status         VARCHAR(20) NOT NULL,
                        MarkedBy       VARCHAR(20) DEFAULT 'QR',
                        MarkedAt       DATETIME    DEFAULT CURRENT_TIMESTAMP,
                        CreatedAt      DATETIME    DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS QRCodes (
                        QRCodeID    INT PRIMARY KEY AUTO_INCREMENT,
                        SubjectID   INT         NOT NULL,
                        TimetableID INT,
                        TeacherID   INT,
                        QRToken     VARCHAR(255) NOT NULL UNIQUE,
                        ExpiresAt   DATETIME    NOT NULL,
                        IsActive    TINYINT     NOT NULL DEFAULT 1,
                        CreatedAt   DATETIME    DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Exams (
                        ExamID       INT PRIMARY KEY AUTO_INCREMENT,
                        SubjectID    INT         NOT NULL,
                        TeacherID    INT         NOT NULL,
                        ExamType     VARCHAR(20) NOT NULL DEFAULT 'CA1',
                        ExamName     VARCHAR(255) NOT NULL,
                        ExamDate     DATE        NOT NULL,
                        StartTime    VARCHAR(10),
                        EndTime      VARCHAR(10),
                        TotalMarks   INT         NOT NULL DEFAULT 100,
                        Duration     INT         NOT NULL DEFAULT 60,
                        Instructions TEXT,
                        IsActive     TINYINT     NOT NULL DEFAULT 1,
                        CreatedAt    DATETIME    DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS ExamQuestions (
                        QuestionID    INT PRIMARY KEY AUTO_INCREMENT,
                        ExamID        INT         NOT NULL,
                        QuestionText  TEXT        NOT NULL,
                        QuestionType  VARCHAR(20) NOT NULL DEFAULT 'MCQ',
                        OptionA       TEXT,
                        OptionB       TEXT,
                        OptionC       TEXT,
                        OptionD       TEXT,
                        CorrectAnswer VARCHAR(10),
                        Marks         INT         NOT NULL DEFAULT 1,
                        QuestionOrder INT         DEFAULT 1,
                        CreatedAt     DATETIME    DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS ExamSubmissions (
                        SubmissionID  INT PRIMARY KEY AUTO_INCREMENT,
                        ExamID        INT     NOT NULL,
                        StudentID     INT     NOT NULL,
                        IsSubmitted   TINYINT NOT NULL DEFAULT 0,
                        SubmittedAt   DATETIME,
                        MarksObtained FLOAT,
                        CreatedAt     DATETIME DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE KEY uq_submission (ExamID, StudentID)
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS ExamAnswers (
                        AnswerID      INT PRIMARY KEY AUTO_INCREMENT,
                        SubmissionID  INT   NOT NULL,
                        QuestionID    INT   NOT NULL,
                        StudentAnswer TEXT,
                        IsCorrect     TINYINT DEFAULT 0,
                        MarksAwarded  FLOAT   DEFAULT 0,
                        CreatedAt     DATETIME DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Marks (
                        MarkID       INT PRIMARY KEY AUTO_INCREMENT,
                        StudentID    INT         NOT NULL,
                        SubjectID    INT         NOT NULL,
                        AcademicYear VARCHAR(20) NOT NULL DEFAULT '2024-25',
                        CA1          FLOAT,
                        CA2          FLOAT,
                        CA3          FLOAT,
                        CA4          FLOAT,
                        CA5          FLOAT,
                        Midterm      FLOAT,
                        Endterm      FLOAT,
                        UpdatedAt    DATETIME DEFAULT CURRENT_TIMESTAMP,
                        UNIQUE KEY uq_marks (StudentID, SubjectID, AcademicYear)
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS StudyMaterials (
                        MaterialID  INT PRIMARY KEY AUTO_INCREMENT,
                        TeacherID   INT          NOT NULL,
                        SubjectID   INT          NOT NULL,
                        Title       VARCHAR(255) NOT NULL,
                        Description TEXT,
                        FilePath    VARCHAR(500),
                        FileType    VARCHAR(20)  DEFAULT 'pdf',
                        FileSize    INT          DEFAULT 0,
                        IsPublished TINYINT      NOT NULL DEFAULT 1,
                        UploadedAt  DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS OnlineClasses (
                        OnlineClassID INT PRIMARY KEY AUTO_INCREMENT,
                        TeacherID     INT          NOT NULL,
                        SubjectID     INT          NOT NULL,
                        Title         VARCHAR(255) NOT NULL,
                        Topic         VARCHAR(255),
                        Description   TEXT,
                        MeetingLink   VARCHAR(500),
                        ScheduledDate DATE         NOT NULL,
                        StartTime     VARCHAR(10),
                        EndTime       VARCHAR(10),
                        IsActive      TINYINT      NOT NULL DEFAULT 1,
                        CreatedAt     DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS Notifications (
                        NotificationID INT PRIMARY KEY AUTO_INCREMENT,
                        StudentID      INT,
                        UserID         INT,
                        Title          VARCHAR(255) NOT NULL,
                        Message        TEXT         NOT NULL,
                        Type           VARCHAR(50)  NOT NULL DEFAULT 'General',
                        IsRead         TINYINT      NOT NULL DEFAULT 0,
                        CreatedAt      DATETIME     DEFAULT CURRENT_TIMESTAMP
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS FeeStructure (
                        FeeID          INT PRIMARY KEY AUTO_INCREMENT,
                        DepartmentID   INT         NOT NULL,
                        Semester       INT         NOT NULL,
                        AcademicYear   VARCHAR(20) NOT NULL DEFAULT '2024-25',
                        TuitionFee     FLOAT       DEFAULT 0,
                        ExamFee        FLOAT       DEFAULT 0,
                        LabFee         FLOAT       DEFAULT 0,
                        LibraryFee     FLOAT       DEFAULT 0,
                        DevelopmentFee FLOAT       DEFAULT 0,
                        OtherCharges   FLOAT       DEFAULT 0,
                        TotalFee       FLOAT       DEFAULT 0,
                        UNIQUE KEY uq_fee (DepartmentID, Semester, AcademicYear)
                    )
                """)
                cursor.execute("""
                    CREATE TABLE IF NOT EXISTS FeePayments (
                        PaymentID       INT PRIMARY KEY AUTO_INCREMENT,
                        StudentID       INT         NOT NULL,
                        AmountPaid      FLOAT       NOT NULL,
                        PaymentDate     DATE        NOT NULL,
                        PaymentMode     VARCHAR(50) DEFAULT 'Online',
                        TransactionID   VARCHAR(100),
                        ReferenceNumber VARCHAR(100),
                        Status          VARCHAR(20) DEFAULT 'Paid',
                        CreatedAt       DATETIME    DEFAULT CURRENT_TIMESTAMP
                    )
                """)
            conn.commit()
            print('✅ [DB] MySQL schema ready.')
            self._seed_mysql(conn)
        finally:
            conn.close()

    def _seed_mysql_safe(self):
        """Safe seed for pre-imported schema - only inserts if tables are truly empty.
        Uses column names matching the imported SQL schema (no TotalSemesters/IsShared)."""
        try:
            conn = self._mysql_connect()
            with conn.cursor() as cursor:
                # Only seed Departments if completely empty
                cursor.execute('SELECT COUNT(*) as cnt FROM Departments')
                if cursor.fetchone()['cnt'] == 0:
                    cursor.executemany(
                        'INSERT IGNORE INTO Departments (DepartmentID, DepartmentName, DepartmentCode) VALUES (%s,%s,%s)',
                        [
                            (1, 'Computer Science & Engineering', 'CSE'),
                            (2, 'Electronics & Communication Engineering', 'ECE'),
                            (3, 'Electrical & Electronics Engineering', 'EEE'),
                            (4, 'Mechanical Engineering', 'MECH'),
                            (5, 'Civil Engineering', 'CIVIL'),
                        ]
                    )
                    conn.commit()
                    print('✅ [DB] MySQL Departments seeded.')

                # Only seed Users if completely empty
                cursor.execute('SELECT COUNT(*) as cnt FROM Users')
                if cursor.fetchone()['cnt'] == 0:
                    import hashlib
                    def dob_hash(dob): return hashlib.sha256(dob.encode()).hexdigest()
                    cursor.executemany(
                        'INSERT IGNORE INTO Users (UserType, UserCode, FullName, Email, Phone, PasswordHash, DepartmentID, DateOfBirth, Gender, IsActive, IsFirstLogin) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,1,1)',
                        [
                            ('Admin',   'ADMIN001', 'System Administrator',  'admin@university.edu',        '9000000001', dob_hash('15-05-1980'), 1, '1980-05-15', 'Male'),
                            ('Teacher', 'TID001',   'Dr. Rajesh Kumar',       'rajesh.kumar@university.edu', '9876543211', dob_hash('12-03-1975'), 1, '1975-03-12', 'Male'),
                        ]
                    )
                    conn.commit()
                    print('✅ [DB] MySQL minimal Users seeded.')
            conn.close()
        except Exception as e:
            print(f'[DB] _seed_mysql_safe warning: {e}')

    def _seed_mysql(self, conn):
        """Seed essential data into MySQL if tables are empty."""
        with conn.cursor() as cursor:
            cursor.execute('SELECT COUNT(*) as cnt FROM Departments')
            if cursor.fetchone()['cnt'] == 0:
                cursor.executemany(
                    'INSERT IGNORE INTO Departments (DepartmentID, DepartmentName, DepartmentCode, TotalSemesters, IsShared) VALUES (%s,%s,%s,%s,%s)',
                    [
                        (0, 'Common / Shared Subjects',               'COMMON', 8, 1),
                        (1, 'Computer Science & Engineering',          'CSE',   8, 0),
                        (2, 'Electronics & Communication Engineering', 'ECE',   8, 0),
                        (3, 'Electrical & Electronics Engineering',    'EEE',   8, 0),
                        (4, 'Mechanical Engineering',                  'MECH',  8, 0),
                        (5, 'Civil Engineering',                       'CIVIL', 8, 0),
                    ]
                )
                conn.commit()
                print('✅ [DB] MySQL Departments seeded.')

            cursor.execute('SELECT COUNT(*) as cnt FROM Users')
            if cursor.fetchone()['cnt'] == 0:
                cursor.executemany(
                    'INSERT IGNORE INTO Users (UserCode, FullName, Email, Phone, PasswordHash, UserType, DepartmentID, DateOfBirth, Gender, IsActive, IsFirstLogin) VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,1,1)',
                    [
                        ('ADMIN001', 'System Administrator', 'admin@university.edu', '9000000001', _hash('15-05-1980'), 'Admin', 1, '1980-05-15', 'Male'),
                        ('TID001', 'Dr. Rajesh Kumar',  'rajesh.kumar@university.edu',  '9876543201', _hash('12-03-1975'), 'Teacher', 1, '1975-03-12', 'Male'),
                        ('TID002', 'Dr. Priya Sharma',  'priya.sharma@university.edu',  '9876543202', _hash('25-07-1978'), 'Teacher', 1, '1978-07-25', 'Female'),
                        ('TID003', 'Dr. Amit Patel',    'amit.patel@university.edu',    '9876543203', _hash('08-11-1980'), 'Teacher', 1, '1980-11-08', 'Male'),
                        ('TID004', 'Dr. Sneha Reddy',   'sneha.reddy@university.edu',   '9876543204', _hash('19-04-1976'), 'Teacher', 1, '1976-04-19', 'Female'),
                        ('TID005', 'Dr. Vikram Singh',  'vikram.singh@university.edu',  '9876543205', _hash('30-09-1979'), 'Teacher', 1, '1979-09-30', 'Male'),
                        ('TID006', 'Dr. Anjali Gupta',  'anjali.gupta@university.edu',  '9876543206', _hash('14-01-1982'), 'Teacher', 1, '1982-01-14', 'Female'),
                        ('TID007', 'Dr. Rahul Verma',   'rahul.verma@university.edu',   '9876543207', _hash('22-06-1977'), 'Teacher', 1, '1977-06-22', 'Male'),
                        ('TID008', 'Dr. Kavita Nair',   'kavita.nair@university.edu',   '9876543208', _hash('05-12-1981'), 'Teacher', 1, '1981-12-05', 'Female'),
                    ]
                )
                conn.commit()
                print('✅ [DB] MySQL Users seeded (Admin + 8 Teachers). First login pw = DOB as DD-MM-YYYY')

    def _execute_query_mysql(self, query: str, params, fetch_one: bool):
        conn = None
        try:
            conn = self._mysql_connect()
            query = _to_mysql_sql(query)
            with conn.cursor() as cursor:
                cursor.execute(query, params if params is not None else ())
                if fetch_one:
                    row = cursor.fetchone()
                    return {k: _serialize_db_value(v) for k, v in row.items()} if row else None
                rows = cursor.fetchall()
                return [{k: _serialize_db_value(v) for k, v in r.items()} for r in rows]
        except Exception as e:
            print(f'❌ [MySQL query] {e}\n   SQL: {query[:120]}')
            raise Exception(f'Database query failed: {e}') from e
        finally:
            if conn: conn.close()

    def _execute_non_query_mysql(self, query: str, params) -> int:
        conn = None
        try:
            conn = self._mysql_connect()
            query = _to_mysql_sql(query)
            with conn.cursor() as cursor:
                cursor.execute(query, params if params is not None else ())
                conn.commit()
                return cursor.rowcount
        except Exception as e:
            if conn: conn.rollback()
            print(f'❌ [MySQL non-query] {e}\n   SQL: {query[:120]}')
            raise Exception(f'Database operation failed: {e}') from e
        finally:
            if conn: conn.close()

    # ── SQL Server ─────────────────────────────────────────────────────────────

    def _mssql_connection_string(self) -> str:
        server = self.server.replace('\\\\', '\\')
        if self.username and self.password:
            return (f'DRIVER={self.driver};SERVER={server};DATABASE={self.database};'
                    f'UID={self.username};PWD={self.password};TrustServerCertificate=yes;')
        return (f'DRIVER={self.driver};SERVER={server};DATABASE={self.database};'
                f'Trusted_Connection=yes;TrustServerCertificate=yes;')

    def _mssql_connect(self):
        try:
            return pyodbc.connect(self._mssql_connection_string(), timeout=15)
        except Exception as e:
            print(f'❌ [DB] SQL Server connect failed: {e}')
            raise

    # ── SQLite ─────────────────────────────────────────────────────────────────

    def _sqlite_connect(self) -> sqlite3.Connection:
        conn = sqlite3.connect(self.sqlite_path)
        conn.row_factory = sqlite3.Row
        conn.execute('PRAGMA foreign_keys = ON')
        conn.execute('PRAGMA journal_mode = WAL')
        return conn

    def _sqlite_has_column(self, conn: sqlite3.Connection, table: str, column: str) -> bool:
        try:
            rows = conn.execute(f'PRAGMA table_info({table})').fetchall()
            return any(r[1] == column for r in rows)
        except Exception:
            return False

    def _sqlite_add_column_if_missing(self, conn: sqlite3.Connection, table: str, col_def: str) -> bool:
        col_name = col_def.split()[0]
        if self._sqlite_has_column(conn, table, col_name):
            return False
        conn.execute(f'ALTER TABLE {table} ADD COLUMN {col_def}')
        return True

    def _migrate_sqlite_schema(self, conn: sqlite3.Connection):
        self._sqlite_add_column_if_missing(conn, 'Departments', 'TotalSemesters INTEGER DEFAULT 8')
        self._sqlite_add_column_if_missing(conn, 'Departments', 'IsShared INTEGER DEFAULT 0')
        self._sqlite_add_column_if_missing(conn, 'Subjects', 'IsLab INTEGER DEFAULT 0')
        self._sqlite_add_column_if_missing(conn, 'Teachers', "Designation TEXT DEFAULT 'Assistant Professor'")
        self._sqlite_add_column_if_missing(conn, 'Teachers', 'JoiningDate TEXT')

        if self._sqlite_add_column_if_missing(conn, 'Timetable', 'DepartmentID INTEGER'):
            if self._sqlite_has_column(conn, 'Timetable', 'ClassID'):
                conn.execute('UPDATE Timetable SET DepartmentID = ClassID WHERE DepartmentID IS NULL')
        if self._sqlite_add_column_if_missing(conn, 'Timetable', "RoomNumber TEXT DEFAULT 'TBD'"):
            if self._sqlite_has_column(conn, 'Timetable', 'Room'):
                conn.execute("UPDATE Timetable SET RoomNumber = COALESCE(Room, 'TBD') WHERE RoomNumber IS NULL OR RoomNumber = ''")
        if self._sqlite_add_column_if_missing(conn, 'Timetable', 'Semester INTEGER'):
            conn.execute('UPDATE Timetable SET Semester = (SELECT s.Semester FROM Subjects s WHERE s.SubjectID = Timetable.SubjectID) WHERE Semester IS NULL')
            conn.execute('UPDATE Timetable SET Semester = 1 WHERE Semester IS NULL')
        if self._sqlite_add_column_if_missing(conn, 'Timetable', 'PeriodNumber INTEGER DEFAULT 1'):
            conn.execute('UPDATE Timetable SET PeriodNumber = 1 WHERE PeriodNumber IS NULL')
        if self._sqlite_add_column_if_missing(conn, 'Timetable', 'IsLab INTEGER DEFAULT 0'):
            conn.execute('UPDATE Timetable SET IsLab = 0 WHERE IsLab IS NULL')

        if self._sqlite_add_column_if_missing(conn, 'TeacherSubjects', 'DepartmentID INTEGER'):
            if self._sqlite_has_column(conn, 'TeacherSubjects', 'ClassID'):
                conn.execute('UPDATE TeacherSubjects SET DepartmentID = ClassID WHERE DepartmentID IS NULL')
        if self._sqlite_add_column_if_missing(conn, 'TeacherSubjects', 'Semester INTEGER'):
            conn.execute('UPDATE TeacherSubjects SET Semester = (SELECT s.Semester FROM Subjects s WHERE s.SubjectID = TeacherSubjects.SubjectID) WHERE Semester IS NULL')
            conn.execute('UPDATE TeacherSubjects SET Semester = 1 WHERE Semester IS NULL')

        if self._sqlite_add_column_if_missing(conn, 'StudentEnrollments', 'TimetableID INTEGER'):
            if self._sqlite_has_column(conn, 'StudentEnrollments', 'ClassID') and \
               self._sqlite_has_column(conn, 'StudentEnrollments', 'SubjectID'):
                conn.execute(
                    'UPDATE StudentEnrollments SET TimetableID = (SELECT t.TimetableID FROM Timetable t WHERE t.SubjectID = StudentEnrollments.SubjectID AND t.DepartmentID = StudentEnrollments.ClassID LIMIT 1) WHERE TimetableID IS NULL'
                )
        self._sqlite_add_column_if_missing(conn, 'StudentEnrollments', "EnrollmentDate TEXT DEFAULT (date('now'))")
        self._sqlite_add_column_if_missing(conn, 'StudentEnrollments', 'IsActive INTEGER DEFAULT 1')

    def _ensure_sqlite_schema(self):
        stmts = [
            """CREATE TABLE IF NOT EXISTS Departments (
                DepartmentID   INTEGER PRIMARY KEY,
                DepartmentName TEXT    NOT NULL UNIQUE,
                DepartmentCode TEXT    NOT NULL UNIQUE,
                TotalSemesters INTEGER NOT NULL DEFAULT 8,
                IsShared       INTEGER NOT NULL DEFAULT 0,
                CreatedAt      TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS Subjects (
                SubjectID    INTEGER PRIMARY KEY,
                SubjectName  TEXT    NOT NULL,
                SubjectCode  TEXT    NOT NULL UNIQUE,
                Credits      INTEGER NOT NULL DEFAULT 4,
                IsLab        INTEGER NOT NULL DEFAULT 0,
                DepartmentID INTEGER NOT NULL REFERENCES Departments(DepartmentID),
                Semester     INTEGER NOT NULL CHECK (Semester BETWEEN 1 AND 8),
                CreatedAt    TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS Teachers (
                TeacherID    INTEGER PRIMARY KEY,
                FullName     TEXT    NOT NULL,
                TeacherCode  TEXT    NOT NULL UNIQUE,
                Email        TEXT    UNIQUE,
                Phone        TEXT,
                DepartmentID INTEGER NOT NULL REFERENCES Departments(DepartmentID),
                Designation  TEXT    NOT NULL DEFAULT 'Assistant Professor',
                JoiningDate  TEXT,
                IsActive     INTEGER NOT NULL DEFAULT 1,
                CreatedAt    TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS TeacherSubjects (
                ID           INTEGER PRIMARY KEY AUTOINCREMENT,
                TeacherID    INTEGER NOT NULL REFERENCES Teachers(TeacherID),
                SubjectID    INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                DepartmentID INTEGER NOT NULL REFERENCES Departments(DepartmentID),
                Semester     INTEGER NOT NULL,
                AcademicYear INTEGER NOT NULL DEFAULT 2025,
                CreatedAt    TEXT    DEFAULT (datetime('now')),
                UNIQUE (TeacherID, SubjectID, AcademicYear)
            )""",
            """CREATE TABLE IF NOT EXISTS Students (
                StudentID       INTEGER PRIMARY KEY AUTOINCREMENT,
                FullName        TEXT    NOT NULL,
                RollNumber      TEXT    NOT NULL UNIQUE,
                Email           TEXT    NOT NULL UNIQUE,
                DepartmentID    INTEGER NOT NULL REFERENCES Departments(DepartmentID),
                CurrentSemester INTEGER NOT NULL CHECK (CurrentSemester BETWEEN 1 AND 8),
                AcademicYear    INTEGER NOT NULL DEFAULT 2025,
                IsActive        INTEGER NOT NULL DEFAULT 1,
                CreatedAt       TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS Timetable (
                TimetableID  INTEGER PRIMARY KEY AUTOINCREMENT,
                DepartmentID INTEGER NOT NULL REFERENCES Departments(DepartmentID),
                Semester     INTEGER NOT NULL CHECK (Semester BETWEEN 1 AND 8),
                SubjectID    INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                TeacherID    INTEGER NOT NULL REFERENCES Teachers(TeacherID),
                DayOfWeek    TEXT    NOT NULL,
                PeriodNumber INTEGER NOT NULL CHECK (PeriodNumber BETWEEN 1 AND 7),
                StartTime    TEXT    NOT NULL,
                EndTime      TEXT    NOT NULL,
                RoomNumber   TEXT    NOT NULL DEFAULT 'TBD',
                IsLab        INTEGER NOT NULL DEFAULT 0,
                AcademicYear INTEGER NOT NULL DEFAULT 2025,
                CreatedAt    TEXT    DEFAULT (datetime('now')),
                UNIQUE (DepartmentID, Semester, DayOfWeek, PeriodNumber, AcademicYear),
                UNIQUE (TeacherID, DayOfWeek, PeriodNumber, AcademicYear)
            )""",
            """CREATE TABLE IF NOT EXISTS StudentEnrollments (
                EnrollmentID   INTEGER PRIMARY KEY AUTOINCREMENT,
                StudentID      INTEGER NOT NULL REFERENCES Students(StudentID),
                TimetableID    INTEGER NOT NULL REFERENCES Timetable(TimetableID),
                EnrollmentDate TEXT    NOT NULL DEFAULT (date('now')),
                IsActive       INTEGER NOT NULL DEFAULT 1,
                UNIQUE (StudentID, TimetableID)
            )""",
            """CREATE TABLE IF NOT EXISTS Users (
                UserID       INTEGER PRIMARY KEY AUTOINCREMENT,
                UserCode     TEXT    NOT NULL UNIQUE,
                FullName     TEXT    NOT NULL,
                Email        TEXT    UNIQUE,
                Phone        TEXT,
                PasswordHash TEXT    NOT NULL,
                UserType     TEXT    NOT NULL CHECK (UserType IN ('Admin','Teacher','Student')),
                DepartmentID INTEGER REFERENCES Departments(DepartmentID),
                Gender       TEXT,
                DateOfBirth  TEXT,
                Address      TEXT,
                FatherName   TEXT,
                MotherName   TEXT,
                Semester     INTEGER,
                JoinDate     TEXT    DEFAULT (date('now')),
                IsActive     INTEGER NOT NULL DEFAULT 1,
                IsFirstLogin INTEGER NOT NULL DEFAULT 1,
                CreatedAt    TEXT    DEFAULT (datetime('now')),
                UpdatedAt    TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS ActivityLogs (
                LogID       INTEGER PRIMARY KEY AUTOINCREMENT,
                UserID      INTEGER REFERENCES Users(UserID),
                Activity    TEXT    NOT NULL,
                Details     TEXT,
                IPAddress   TEXT,
                CreatedAt   TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS Attendance (
                AttendanceID   INTEGER PRIMARY KEY AUTOINCREMENT,
                StudentID      INTEGER NOT NULL REFERENCES Students(StudentID),
                SubjectID      INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                TimetableID    INTEGER REFERENCES Timetable(TimetableID),
                QRCodeID       INTEGER,
                AttendanceDate TEXT    NOT NULL,
                Status         TEXT    NOT NULL CHECK (Status IN ('Present','Absent','Late')),
                MarkedBy       TEXT    DEFAULT 'QR',
                MarkedAt       TEXT    DEFAULT (datetime('now')),
                CreatedAt      TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS QRCodes (
                QRCodeID   INTEGER PRIMARY KEY AUTOINCREMENT,
                SubjectID  INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                TimetableID INTEGER REFERENCES Timetable(TimetableID),
                TeacherID  INTEGER REFERENCES Teachers(TeacherID),
                QRToken    TEXT    NOT NULL UNIQUE,
                ExpiresAt  TEXT    NOT NULL,
                IsActive   INTEGER NOT NULL DEFAULT 1,
                CreatedAt  TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS Exams (
                ExamID       INTEGER PRIMARY KEY AUTOINCREMENT,
                SubjectID    INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                TeacherID    INTEGER NOT NULL REFERENCES Teachers(TeacherID),
                ExamType     TEXT    NOT NULL DEFAULT 'CA1',
                ExamName     TEXT    NOT NULL,
                ExamDate     TEXT    NOT NULL,
                StartTime    TEXT,
                EndTime      TEXT,
                TotalMarks   INTEGER NOT NULL DEFAULT 100,
                Duration     INTEGER NOT NULL DEFAULT 60,
                Instructions TEXT,
                IsActive     INTEGER NOT NULL DEFAULT 1,
                CreatedAt    TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS ExamQuestions (
                QuestionID    INTEGER PRIMARY KEY AUTOINCREMENT,
                ExamID        INTEGER NOT NULL REFERENCES Exams(ExamID),
                QuestionText  TEXT    NOT NULL,
                QuestionType  TEXT    NOT NULL DEFAULT 'MCQ',
                OptionA       TEXT, OptionB TEXT, OptionC TEXT, OptionD TEXT,
                CorrectAnswer TEXT,
                Marks         INTEGER NOT NULL DEFAULT 1,
                QuestionOrder INTEGER DEFAULT 1,
                CreatedAt     TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS ExamSubmissions (
                SubmissionID  INTEGER PRIMARY KEY AUTOINCREMENT,
                ExamID        INTEGER NOT NULL REFERENCES Exams(ExamID),
                StudentID     INTEGER NOT NULL REFERENCES Students(StudentID),
                IsSubmitted   INTEGER NOT NULL DEFAULT 0,
                SubmittedAt   TEXT,
                MarksObtained REAL,
                CreatedAt     TEXT    DEFAULT (datetime('now')),
                UNIQUE (ExamID, StudentID)
            )""",
            """CREATE TABLE IF NOT EXISTS ExamAnswers (
                AnswerID      INTEGER PRIMARY KEY AUTOINCREMENT,
                SubmissionID  INTEGER NOT NULL REFERENCES ExamSubmissions(SubmissionID),
                QuestionID    INTEGER NOT NULL REFERENCES ExamQuestions(QuestionID),
                StudentAnswer TEXT,
                IsCorrect     INTEGER DEFAULT 0,
                MarksAwarded  REAL    DEFAULT 0,
                CreatedAt     TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS Marks (
                MarkID       INTEGER PRIMARY KEY AUTOINCREMENT,
                StudentID    INTEGER NOT NULL REFERENCES Students(StudentID),
                SubjectID    INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                AcademicYear TEXT    NOT NULL DEFAULT '2024-25',
                CA1 REAL, CA2 REAL, CA3 REAL, CA4 REAL, CA5 REAL,
                Midterm REAL, Endterm REAL,
                UpdatedAt    TEXT    DEFAULT (datetime('now')),
                UNIQUE (StudentID, SubjectID, AcademicYear)
            )""",
            """CREATE TABLE IF NOT EXISTS StudyMaterials (
                MaterialID  INTEGER PRIMARY KEY AUTOINCREMENT,
                TeacherID   INTEGER NOT NULL,
                SubjectID   INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                Title       TEXT    NOT NULL,
                Description TEXT,
                FilePath    TEXT,
                FileType    TEXT    DEFAULT 'pdf',
                FileSize    INTEGER DEFAULT 0,
                IsPublished INTEGER NOT NULL DEFAULT 1,
                UploadedAt  TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS OnlineClasses (
                OnlineClassID INTEGER PRIMARY KEY AUTOINCREMENT,
                TeacherID     INTEGER NOT NULL,
                SubjectID     INTEGER NOT NULL REFERENCES Subjects(SubjectID),
                Title         TEXT    NOT NULL,
                Topic         TEXT, Description TEXT, MeetingLink TEXT,
                ScheduledDate TEXT    NOT NULL,
                StartTime     TEXT, EndTime TEXT,
                IsActive      INTEGER NOT NULL DEFAULT 1,
                CreatedAt     TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS Notifications (
                NotificationID INTEGER PRIMARY KEY AUTOINCREMENT,
                StudentID      INTEGER,
                UserID         INTEGER,
                Title          TEXT    NOT NULL,
                Message        TEXT    NOT NULL,
                Type           TEXT    NOT NULL DEFAULT 'General',
                IsRead         INTEGER NOT NULL DEFAULT 0,
                CreatedAt      TEXT    DEFAULT (datetime('now'))
            )""",
            """CREATE TABLE IF NOT EXISTS FeeStructure (
                FeeID        INTEGER PRIMARY KEY AUTOINCREMENT,
                DepartmentID INTEGER NOT NULL REFERENCES Departments(DepartmentID),
                Semester     INTEGER NOT NULL,
                AcademicYear TEXT    NOT NULL DEFAULT '2024-25',
                TuitionFee REAL DEFAULT 0, ExamFee REAL DEFAULT 0,
                LabFee REAL DEFAULT 0, LibraryFee REAL DEFAULT 0,
                DevelopmentFee REAL DEFAULT 0, OtherCharges REAL DEFAULT 0,
                TotalFee REAL DEFAULT 0,
                UNIQUE (DepartmentID, Semester, AcademicYear)
            )""",
            """CREATE TABLE IF NOT EXISTS FeePayments (
                PaymentID       INTEGER PRIMARY KEY AUTOINCREMENT,
                StudentID       INTEGER NOT NULL REFERENCES Students(StudentID),
                AmountPaid      REAL    NOT NULL,
                PaymentDate     TEXT    NOT NULL DEFAULT (date('now')),
                PaymentMode     TEXT    DEFAULT 'Online',
                TransactionID   TEXT, ReferenceNumber TEXT,
                Status          TEXT    DEFAULT 'Paid',
                CreatedAt       TEXT    DEFAULT (datetime('now'))
            )""",
        ]

        conn = self._sqlite_connect()
        try:
            for stmt in stmts:
                try:
                    conn.execute(stmt)
                except Exception as e:
                    print(f'⚠️  [DB] Schema statement skipped: {e}')
            conn.commit()
            self._migrate_sqlite_schema(conn)
            conn.commit()

            dept_before = conn.execute('SELECT COUNT(*) FROM Departments').fetchone()[0]
            conn.executemany(
                'INSERT OR IGNORE INTO Departments (DepartmentID, DepartmentName, DepartmentCode, TotalSemesters, IsShared) VALUES (?,?,?,?,?)',
                [
                    (0, 'Common / Shared Subjects',               'COMMON', 8, 1),
                    (1, 'Computer Science & Engineering',          'CSE',   8, 0),
                    (2, 'Electronics & Communication Engineering', 'ECE',   8, 0),
                    (3, 'Electrical & Electronics Engineering',    'EEE',   8, 0),
                    (4, 'Mechanical Engineering',                  'MECH',  8, 0),
                    (5, 'Civil Engineering',                       'CIVIL', 8, 0),
                ],
            )
            conn.commit()
            dept_after = conn.execute('SELECT COUNT(*) FROM Departments').fetchone()[0]
            if dept_after > dept_before:
                print(f'✅ [DB] Departments ensured (+{dept_after - dept_before}).')

            if conn.execute('SELECT COUNT(*) FROM Subjects').fetchone()[0] == 0:
                conn.executemany(
                    'INSERT OR IGNORE INTO Subjects (SubjectID, SubjectName, SubjectCode, Credits, IsLab, DepartmentID, Semester) VALUES (?,?,?,?,?,?,?)',
                    [
                        (170, 'Professional Communication', 'EN101',   3, 0, 0, 1),
                        (171, 'Engineering Mathematics-I',  'MA101',   4, 0, 0, 1),
                        (190, 'Engineering Physics',        'PH101',   4, 0, 0, 1),
                        (191, 'Physics Lab',                'PH101L',  2, 1, 0, 1),
                        (1,   'Programming in C',           'CSE101',  4, 0, 1, 1),
                        (101, 'Chemistry Lab',              'CH101L',  2, 1, 1, 1),
                        (102, 'C Programming Lab',          'CSE101L', 2, 1, 1, 1),
                        (2,   'Data Structures',            'CSE102',  4, 0, 1, 3),
                        (3,   'Database Management Systems','CSE103',  4, 0, 1, 3),
                        (103, 'Data Structures Lab',        'CSE102L', 2, 1, 1, 3),
                        (104, 'DBMS Lab',                   'CSE103L', 2, 1, 1, 3),
                        (4,   'Operating Systems',          'CSE104',  4, 0, 1, 5),
                        (5,   'Computer Networks',          'CSE105',  4, 0, 1, 5),
                        (6,   'Software Engineering',       'CSE106',  4, 0, 1, 5),
                        (106, 'OS Lab',                     'CSE104L', 2, 1, 1, 5),
                        (7,   'Machine Learning',           'CSE107',  4, 0, 1, 7),
                        (8,   'Big Data Analytics',         'CSE404',  4, 0, 1, 7),
                        (109, 'AI Lab',                     'CSE402L', 2, 1, 1, 7),
                    ],
                )
                conn.commit()

            if conn.execute('SELECT COUNT(*) FROM Teachers').fetchone()[0] == 0:
                conn.executemany(
                    'INSERT OR IGNORE INTO Teachers (TeacherID, FullName, TeacherCode, Email, Phone, DepartmentID, Designation, JoiningDate) VALUES (?,?,?,?,?,?,?,?)',
                    [
                        (1, 'Dr. Rajesh Kumar',  'TID001', 'rajesh.kumar@university.edu',  '9876543201', 1, 'Professor',           '2010-07-01'),
                        (2, 'Dr. Priya Sharma',  'TID002', 'priya.sharma@university.edu',  '9876543202', 1, 'Associate Professor', '2012-07-01'),
                        (3, 'Dr. Amit Patel',    'TID003', 'amit.patel@university.edu',    '9876543203', 1, 'Professor',           '2008-07-01'),
                        (4, 'Dr. Sneha Reddy',   'TID004', 'sneha.reddy@university.edu',   '9876543204', 1, 'Assistant Professor', '2015-07-01'),
                        (5, 'Dr. Vikram Singh',  'TID005', 'vikram.singh@university.edu',  '9876543205', 1, 'Associate Professor', '2013-07-01'),
                        (6, 'Dr. Anjali Gupta',  'TID006', 'anjali.gupta@university.edu',  '9876543206', 1, 'Assistant Professor', '2016-07-01'),
                        (7, 'Dr. Rahul Verma',   'TID007', 'rahul.verma@university.edu',   '9876543207', 1, 'Assistant Professor', '2017-07-01'),
                        (8, 'Dr. Kavita Nair',   'TID008', 'kavita.nair@university.edu',   '9876543208', 1, 'Associate Professor', '2014-07-01'),
                    ],
                )
                conn.commit()

            if conn.execute('SELECT COUNT(*) FROM Timetable').fetchone()[0] == 0:
                conn.executemany(
                    'INSERT OR IGNORE INTO Timetable (DepartmentID, Semester, SubjectID, TeacherID, DayOfWeek, PeriodNumber, StartTime, EndTime, RoomNumber, IsLab, AcademicYear) VALUES (?,?,?,?,?,?,?,?,?,?,?)',
                    [
                        (1, 1, 191, 8, 'Monday',    2, '10:00', '10:50', 'CSE-1-LAB2', 1, 2025),
                        (1, 1,   1, 1, 'Wednesday', 2, '10:00', '10:50', 'CSE-1-R202', 0, 2025),
                        (1, 1, 171, 2, 'Thursday',  4, '12:00', '12:50', 'CSE-1-R204', 0, 2025),
                        (1, 1, 190, 3, 'Thursday',  7, '15:40', '16:30', 'CSE-1-R207', 0, 2025),
                        (1, 1, 170, 5, 'Friday',    3, '11:00', '11:50', 'CSE-1-R203', 0, 2025),
                        (1, 1, 102, 6, 'Friday',    6, '14:40', '15:30', 'CSE-1-LAB6', 1, 2025),
                        (1, 3, 103, 6, 'Monday',    4, '12:00', '12:50', 'CSE-3-LAB4', 1, 2025),
                        (1, 3, 171, 5, 'Tuesday',   4, '12:00', '12:50', 'CSE-3-R304', 0, 2025),
                        (1, 3, 104, 8, 'Tuesday',   6, '14:40', '15:30', 'CSE-3-LAB6', 1, 2025),
                        (1, 3,   2, 2, 'Wednesday', 6, '14:40', '15:30', 'CSE-3-R306', 0, 2025),
                        (1, 3,   3, 3, 'Thursday',  3, '11:00', '11:50', 'CSE-3-R303', 0, 2025),
                    ],
                )
                conn.commit()

            if conn.execute('SELECT COUNT(*) FROM TeacherSubjects').fetchone()[0] == 0:
                conn.execute("INSERT OR IGNORE INTO TeacherSubjects (TeacherID, SubjectID, DepartmentID, Semester, AcademicYear) SELECT DISTINCT TeacherID, SubjectID, DepartmentID, Semester, AcademicYear FROM Timetable")
                conn.commit()

            if conn.execute('SELECT COUNT(*) FROM Users').fetchone()[0] == 0:
                conn.executemany(
                    'INSERT OR IGNORE INTO Users (UserCode, FullName, Email, Phone, PasswordHash, UserType, DepartmentID, DateOfBirth, Gender, IsActive, IsFirstLogin) VALUES (?,?,?,?,?,?,?,?,?,1,1)',
                    [
                        ('ADMIN001', 'System Administrator', 'admin@university.edu', '9000000001', _hash('15-05-1980'), 'Admin', 1, '1980-05-15', 'Male'),
                        ('TID001', 'Dr. Rajesh Kumar',  'rajesh.kumar@university.edu',  '9876543201', _hash('12-03-1975'), 'Teacher', 1, '1975-03-12', 'Male'),
                        ('TID002', 'Dr. Priya Sharma',  'priya.sharma@university.edu',  '9876543202', _hash('25-07-1978'), 'Teacher', 1, '1978-07-25', 'Female'),
                        ('TID003', 'Dr. Amit Patel',    'amit.patel@university.edu',    '9876543203', _hash('08-11-1980'), 'Teacher', 1, '1980-11-08', 'Male'),
                        ('TID004', 'Dr. Sneha Reddy',   'sneha.reddy@university.edu',   '9876543204', _hash('19-04-1976'), 'Teacher', 1, '1976-04-19', 'Female'),
                        ('TID005', 'Dr. Vikram Singh',  'vikram.singh@university.edu',  '9876543205', _hash('30-09-1979'), 'Teacher', 1, '1979-09-30', 'Male'),
                        ('TID006', 'Dr. Anjali Gupta',  'anjali.gupta@university.edu',  '9876543206', _hash('14-01-1982'), 'Teacher', 1, '1982-01-14', 'Female'),
                        ('TID007', 'Dr. Rahul Verma',   'rahul.verma@university.edu',   '9876543207', _hash('22-06-1977'), 'Teacher', 1, '1977-06-22', 'Male'),
                        ('TID008', 'Dr. Kavita Nair',   'kavita.nair@university.edu',   '9876543208', _hash('05-12-1981'), 'Teacher', 1, '1981-12-05', 'Female'),
                    ],
                )
                conn.commit()

            if conn.execute('SELECT COUNT(*) FROM Students').fetchone()[0] == 0:
                conn.executemany(
                    'INSERT OR IGNORE INTO Students (FullName, RollNumber, Email, DepartmentID, CurrentSemester, AcademicYear) VALUES (?,?,?,?,?,?)',
                    [
                        ('Aarav Sharma',    'D1S1N01', 'aarav.sharma@student.edu',    1, 1, 2025),
                        ('Priya Patel',     'D1S1N02', 'priya.patel@student.edu',     1, 1, 2025),
                        ('Rohit Verma',     'D1S1N03', 'rohit.verma@student.edu',     1, 1, 2025),
                        ('Sneha Gupta',     'D1S1N04', 'sneha.gupta@student.edu',     1, 1, 2025),
                        ('Karan Singh',     'D1S1N05', 'karan.singh@student.edu',     1, 1, 2025),
                        ('Ananya Reddy',    'D1S3N01', 'ananya.reddy@student.edu',    1, 3, 2025),
                        ('Vikash Kumar',    'D1S3N02', 'vikash.kumar@student.edu',    1, 3, 2025),
                        ('Divya Nair',      'D1S3N03', 'divya.nair@student.edu',      1, 3, 2025),
                        ('Akash Mehta',     'D1S3N04', 'akash.mehta@student.edu',     1, 3, 2025),
                        ('Pooja Iyer',      'D1S3N05', 'pooja.iyer@student.edu',      1, 3, 2025),
                    ],
                )
                conn.commit()

            if conn.execute('SELECT COUNT(*) FROM StudentEnrollments').fetchone()[0] == 0:
                conn.execute("INSERT OR IGNORE INTO StudentEnrollments (StudentID, TimetableID, EnrollmentDate) SELECT s.StudentID, t.TimetableID, date('now') FROM Students s JOIN Timetable t ON t.DepartmentID = s.DepartmentID AND t.Semester = s.CurrentSemester AND t.AcademicYear = s.AcademicYear")
                conn.commit()

            if conn.execute('SELECT COUNT(*) FROM FeeStructure').fetchone()[0] == 0:
                for dept in range(1, 6):
                    for sem in [1, 3, 5, 7]:
                        conn.execute('INSERT OR IGNORE INTO FeeStructure (DepartmentID, Semester, AcademicYear, TuitionFee, ExamFee, LabFee, LibraryFee, DevelopmentFee, OtherCharges, TotalFee) VALUES (?,?,?,?,?,?,?,?,?,?)', (dept, sem, '2024-25', 45000, 3000, 5000, 1500, 2500, 1000, 58000))
                conn.commit()

        finally:
            conn.close()

    # ── Public API ─────────────────────────────────────────────────────────────

    def execute_query(self, query: str, params: Optional[Tuple] = None,
                      fetch_one: bool = False) -> Optional[Any]:
        backend = self._detect_backend()
        if backend == 'mysql':
            return self._execute_query_mysql(query, params, fetch_one)
        if backend == 'mssql':
            return self._execute_query_mssql(query, params, fetch_one)
        return self._execute_query_sqlite(query, params, fetch_one)

    def execute_non_query(self, query: str, params: Optional[Tuple] = None) -> int:
        backend = self._detect_backend()
        if backend == 'mysql':
            return self._execute_non_query_mysql(query, params)
        if backend == 'mssql':
            return self._execute_non_query_mssql(query, params)
        return self._execute_non_query_sqlite(query, params)

    def execute_scalar(self, query: str, params: Optional[Tuple] = None) -> Any:
        result = self.execute_query(query, params, fetch_one=True)
        if result is None:
            return None
        if isinstance(result, dict):
            return next(iter(result.values()), None)
        return result

    # ── MSSQL internals ────────────────────────────────────────────────────────

    def _execute_query_mssql(self, query: str, params, fetch_one: bool):
        conn = cursor = None
        try:
            conn   = self._mssql_connect()
            cursor = conn.cursor()
            query  = _to_mssql_sql(query).replace('%s', '?')
            cursor.execute(query, params if params is not None else ())
            cols = [c[0] for c in cursor.description] if cursor.description else []
            if fetch_one:
                row = cursor.fetchone()
                if not row:
                    return None
                return {k: _serialize_db_value(v) for k, v in zip(cols, row)}
            return [{k: _serialize_db_value(v) for k, v in zip(cols, r)}
                    for r in cursor.fetchall()]
        except Exception as e:
            print(f'❌ [MSSQL query] {e}\n   SQL: {query[:120]}')
            raise Exception(f'Database query failed: {e}') from e
        finally:
            if cursor: cursor.close()
            if conn:   conn.close()

    def _execute_non_query_mssql(self, query: str, params) -> int:
        conn = cursor = None
        try:
            conn   = self._mssql_connect()
            cursor = conn.cursor()
            query  = _to_mssql_sql(query).replace('%s', '?')
            cursor.execute(query, params if params is not None else ())
            conn.commit()
            return cursor.rowcount
        except Exception as e:
            if conn: conn.rollback()
            print(f'❌ [MSSQL non-query] {e}\n   SQL: {query[:120]}')
            raise Exception(f'Database operation failed: {e}') from e
        finally:
            if cursor: cursor.close()
            if conn:   conn.close()

    # ── SQLite internals ───────────────────────────────────────────────────────

    def _execute_query_sqlite(self, query: str, params, fetch_one: bool):
        conn = None
        try:
            conn = self._sqlite_connect()
            cur  = conn.execute(_to_sqlite_sql(query), params if params is not None else ())
            if fetch_one:
                row = cur.fetchone()
                return dict(row) if row else None
            return [dict(r) for r in cur.fetchall()]
        except Exception as e:
            print(f'❌ [SQLite query] {e}\n   SQL: {query[:120]}')
            raise Exception(f'Database query failed: {e}') from e
        finally:
            if conn: conn.close()

    def _execute_non_query_sqlite(self, query: str, params) -> int:
        conn = None
        try:
            conn = self._sqlite_connect()
            cur  = conn.execute(_to_sqlite_sql(query), params if params is not None else ())
            conn.commit()
            return cur.rowcount
        except Exception as e:
            if conn: conn.rollback()
            print(f'❌ [SQLite non-query] {e}\n   SQL: {query[:120]}')
            raise Exception(f'Database operation failed: {e}') from e
        finally:
            if conn: conn.close()

    # ── Compatibility / diagnostics ────────────────────────────────────────────

    def connect(self):
        backend = self._detect_backend()
        if backend == 'mysql':  return self._mysql_connect()
        if backend == 'mssql':  return self._mssql_connect()
        return self._sqlite_connect()

    def close(self):
        pass

    def test_connection(self) -> bool:
        try:
            self.execute_query('SELECT 1 AS test', fetch_one=True)
            print(f'✅ DB connection OK (backend={self._backend})')
            return True
        except Exception as e:
            print(f'❌ DB connection failed: {e}')
            return False

    def get_table_list(self) -> List[str]:
        backend = self._detect_backend()
        if backend == 'mysql':
            q, k = "SHOW TABLES", None
        elif backend == 'mssql':
            q, k = ("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE' ORDER BY TABLE_NAME"), 'TABLE_NAME'
        else:
            q, k = ("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"), 'name'
        try:
            rows = self.execute_query(q)
            if backend == 'mysql':
                return [list(r.values())[0] for r in rows] if rows else []
            return [r[k] for r in rows] if rows else []
        except Exception:
            return []

    def get_table_row_count(self, table_name: str) -> int:
        try:
            return self.execute_scalar(f'SELECT COUNT(*) FROM {table_name}') or 0
        except Exception:
            return 0


# ── Global singleton ───────────────────────────────────────────────────────────
db = Database()


# ── Standalone diagnostic ──────────────────────────────────────────────────────
def test_database_setup() -> bool:
    print('=' * 60)
    print('🔧 University ERP — Database Connection Test')
    print('=' * 60)
    print(f'\nBackend : {db._detect_backend()}')
    if db._backend == 'mssql':
        print(f'Server  : {db.server}')
        print(f'Database: {db.database}')
    elif db._backend == 'mysql':
        print(f'MySQL   : {MYSQL_HOST}:{MYSQL_PORT}/{MYSQL_DB}')

    if not db.test_connection():
        print('\n❌ Cannot proceed.')
        return False

    tables = db.get_table_list()
    print(f'\n✅ {len(tables)} table(s):')
    for t in tables:
        print(f'   {t}: {db.get_table_row_count(t)} rows')

    required = ['Departments', 'Subjects', 'Teachers', 'Timetable',
                'TeacherSubjects', 'Students', 'StudentEnrollments', 'Users']
    missing = [t for t in required if t not in tables]
    if missing:
        print(f'\n⚠️  Missing: {", ".join(missing)}')
        return False

    print('\n✅ All required tables present.')
    print('=' * 60)
    return True


if __name__ == '__main__':
    print('\n' + '🎓 University ERP — Database Test'.center(60))
    ok = test_database_setup()
    if ok:
        print('\n✅ Database ready. Run: python app.py')
    print()