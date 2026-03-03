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

REM Install dependencies if needed
echo  Installing/checking dependencies...
pip install -r requirements.txt --quiet

echo.
echo  Starting Flask server on http://127.0.0.1:5000
echo  Open root\auth.html in your browser to access the website.
echo  Press Ctrl+C to stop the server.
echo.

python app.py
pause
