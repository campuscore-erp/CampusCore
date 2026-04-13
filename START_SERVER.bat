@echo off
echo.
echo  ====================================================
echo   CampusCore University ERP - Starting Server
echo  ====================================================
echo.

REM Change to root directory
cd /d "%~dp0root"

REM Check Python is installed
python --version >nul 2>&1
if %errorlevel% neq 0 (
    echo  ERROR: Python is not installed or not in PATH.
    echo  Please install Python 3.10 or newer from https://python.org
    pause
    exit /b 1
)

REM Install/upgrade pip first
echo  Upgrading pip...
python -m pip install --upgrade pip setuptools wheel --quiet

REM FIX: Install dlib-bin (pre-built wheel) before requirements.txt
REM      so face_recognition can find dlib immediately.
echo  Installing dlib-bin (pre-built, no compiler needed)...
pip install dlib-bin --quiet

echo  Installing face_recognition...
pip install face_recognition --quiet

echo  Installing remaining dependencies...
pip install -r requirements.txt --quiet

echo.
echo  Starting Flask server on http://127.0.0.1:5000
echo  Open your browser to: http://127.0.0.1:5000/auth.html
echo  Press Ctrl+C to stop the server.
echo.

python app.py
pause
