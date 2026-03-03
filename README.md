# 🎓 CampusCore — University ERP System

A complete role-based University ERP with Admin, Teacher, and Student portals.  
Built with **Flask (Python)** backend + **plain HTML/CSS/JS** frontend.

---

## 📁 Project Structure

```
CampusCore/
│
├── fix_passwords.py          ← Run this to reset all passwords to DOB
│
└── root/                     ← Everything else lives here
    ├── app.py                ← Flask entry point  (run this)
    ├── database.py           ← DB layer (auto SQLite fallback)
    ├── auth_routes_merged.py ← /api/auth/*  login, logout, change-pw
    ├── admin_routes_merged.py    ← /api/admin/*
    ├── student_routes_merged.py  ← /api/student/*
    ├── teacher_routes_merged.py  ← /api/teacher/* + /api/timetable/*
    │
    ├── .env                  ← DB + secret keys config
    ├── requirements.txt      ← Python dependencies
    ├── COMPLETE_DATABASE.sql ← SQL Server schema (optional)
    │
    ├── auth.html             ← Login page (all roles)
    ├── admin.html            ← Admin dashboard
    ├── teacher.html          ← Teacher portal
    ├── student.html          ← Student portal
    ├── change_password.html  ← First-login password setup
    ├── timetable.html        ← Public timetable viewer
    │
    └── uploads/              ← Uploaded study materials go here
```

---

## ⚡ Quick Start

### 1. Install Python dependencies

```bash
cd root
pip install -r requirements.txt
```

> If you're on SQL Server, `pyodbc` requires the **ODBC Driver 17 for SQL Server** to be installed.

---

### 2. Configure your database

**Option A — SQL Server (recommended for production)**

Edit `root/.env`:
```env
DB_SERVER=YOUR_PC_NAME\SQLEXPRESS
DB_NAME=UniversityERP
DB_USER=                    # leave blank for Windows Auth
DB_PASSWORD=                # leave blank for Windows Auth
DB_BACKEND=mssql
```

Then run the SQL script to create the schema:
```
SQL Server Management Studio → Open COMPLETE_DATABASE.sql → Execute
```

**Option B — SQLite (zero-config, works out of the box)**

Edit `root/.env` and comment out DB_BACKEND:
```env
# DB_BACKEND=mssql
```

SQLite auto-creates the database at `root/university_erp.db` with full seed data on first run.

---

### 3. Start the server

```bash
cd root
python app.py
```

You should see:
```
============================================================
  CampusCore University ERP — Startup
============================================================
  Loading blueprints:
  OK auth_routes_merged    -> /api/auth/* + /api/common/*
  OK admin_routes_merged   -> /api/admin/*
  OK student_routes_merged -> /api/student/*
  OK teacher_routes_merged -> /api/teacher/* + /api/timetable/*
============================================================
  Starting on http://127.0.0.1:5000
```

---

### 4. Open the website

Double-click `root/auth.html` in your file explorer  
**OR** open in browser: `file:///path/to/CampusCore/root/auth.html`

The frontend automatically connects to `http://localhost:5000`.

---

### 5. Reset passwords (first time setup)

If passwords aren't working, run from the **CampusCore/** folder:

```bash
# From CampusCore/ (parent folder, NOT root/)
python fix_passwords.py
```

This resets every user's password to their **Date of Birth** in `DD-MM-YYYY` format  
and forces a password-change on first login.

Preview without making changes:
```bash
python fix_passwords.py --show
```

Reset a single user:
```bash
python fix_passwords.py TID001
```

---

## 🔑 Default Login Credentials

> **All users must change their password on first login.**  
> First-login password = Date of Birth as `DD-MM-YYYY`

| Role    | User Code  | First-Login Password | Name                  |
|---------|------------|----------------------|-----------------------|
| Admin   | ADMIN001   | 15-05-1980           | System Administrator  |
| Teacher | TID001     | 12-03-1975           | Dr. Rajesh Kumar      |
| Teacher | TID002     | 25-07-1978           | Dr. Priya Sharma      |
| Teacher | TID003     | 08-11-1980           | Dr. Amit Patel        |
| Teacher | TID004     | 19-04-1976           | Dr. Sneha Reddy       |
| Teacher | TID005     | 30-09-1979           | Dr. Vikram Singh      |
| Teacher | TID006     | 14-01-1982           | Dr. Anjali Gupta      |
| Teacher | TID007     | 22-06-1977           | Dr. Rahul Verma       |
| Teacher | TID008     | 05-12-1981           | Dr. Kavita Nair       |
| Student | D1S1N01    | 15-08-2006           | Aarav Sharma (Sem 1)  |
| Student | D1S1N02    | 22-03-2006           | Priya Patel (Sem 1)   |
| Student | D1S3N01    | 14-01-2005           | Ananya Reddy (Sem 3)  |
| Student | D1S3N02    | 30-07-2004           | Vikash Kumar (Sem 3)  |

---

## 🏗️ How It Works

```
Browser (HTML files)  ←→  Flask API (port 5000)  ←→  Database (MSSQL or SQLite)
```

1. User opens `auth.html`, selects role tab, enters UserCode + DOB password
2. `POST /api/auth/login` → validates credentials, returns JWT token
3. If `IsFirstLogin=1` → redirect to `change_password.html` → must set new password
4. After login, JWT stored in `localStorage` → used for all subsequent API calls
5. Each portal page checks token on load → redirects to `auth.html` if invalid/expired
6. JWT expires after **24 hours** → user must log in again

---

## 🌐 API Endpoints Summary

### Auth (`/api/auth/`)
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/login` | Login with UserCode + password |
| POST | `/api/auth/logout` | Logout (invalidate token) |
| POST | `/api/auth/change-password` | Change password (first login) |
| GET | `/api/auth/profile` | Get current user profile |

### Admin (`/api/admin/`) — requires Admin JWT
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/admin/dashboard` | Stats overview |
| GET/POST | `/api/admin/students` | List/add students |
| PUT | `/api/admin/students/{id}` | Edit student |
| POST | `/api/admin/students/{id}/toggle-active` | Enable/disable |
| DELETE | `/api/admin/students/{id}` | Delete student |
| GET/POST | `/api/admin/teachers` | List/add teachers |
| POST | `/api/admin/reset-password/{uid}` | Reset any user's password |
| GET/POST | `/api/admin/departments` | Departments CRUD |
| GET/POST | `/api/admin/subjects` | Subjects CRUD |
| GET/POST/DELETE | `/api/admin/timetable` | Timetable CRUD |
| GET/POST | `/api/admin/fee-structure` | Fee structure CRUD |

### Student (`/api/student/`) — requires Student JWT
| Endpoint | Description |
|----------|-------------|
| `/api/student/dashboard` | Dashboard stats |
| `/api/student/timetable` | Weekly timetable |
| `/api/student/attendance` | Attendance records |
| `/api/student/attendance/scan-qr` | Mark attendance via QR |
| `/api/student/exams` | Upcoming exams |
| `/api/student/exams/{id}/submit` | Submit exam answers |
| `/api/student/marks` | Academic results |
| `/api/student/materials` | Study materials |
| `/api/student/fees` | Fee status |
| `/api/student/notifications` | Notifications |

### Teacher (`/api/teacher/`) — requires Teacher JWT
| Endpoint | Description |
|----------|-------------|
| `/api/teacher/dashboard` | Dashboard |
| `/api/teacher/timetable` | Own timetable |
| `/api/teacher/attendance/submit` | Mark student attendance |
| `/api/teacher/attendance/generate-qr` | Generate QR code |
| `/api/teacher/exams` | Create/manage exams |
| `/api/teacher/materials` | Upload study materials |
| `/api/teacher/online-classes` | Schedule online classes |
| `/api/teacher/notifications` | Send notifications |

---

## 🛠️ Troubleshooting

**"Cannot connect to server" on login page**
- Make sure `python app.py` is running in the `root/` folder
- Check Flask started successfully (no import errors)
- Verify port 5000 is not blocked by firewall

**"Invalid credentials" with correct DOB**
- Run `python fix_passwords.py` from the `CampusCore/` folder to reset all passwords
- Make sure DOB format is strictly `DD-MM-YYYY` (e.g. `15-08-2006`)

**SQL Server connection failed**
- Check `DB_SERVER` in `.env` matches your PC name exactly
- Try `YOUR_PC_NAME\SQLEXPRESS` format
- Ensure SQL Server service is running
- Run `COMPLETE_DATABASE.sql` first if database doesn't exist

**SQLite: database not found**
- Make sure you run `python app.py` from inside the `root/` folder
- The `university_erp.db` file is created automatically on first run

**Wrong role error on login**
- Admin accounts can only log in on the Admin tab
- Teacher accounts on the Teacher tab
- Student accounts on the Student tab

---

## 📝 Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | Python 3.10+, Flask 3.x |
| Auth | JWT (flask-jwt-extended) |
| Database | SQL Server 2019 / SQLite 3 |
| Frontend | HTML5, CSS3, Vanilla JS |
| Fonts | Google Fonts — Sora, JetBrains Mono |
| QR Code | jsQR (student), qrcodejs (teacher) |

---

© 2026 CampusCore University ERP
