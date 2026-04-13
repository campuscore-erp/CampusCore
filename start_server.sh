#!/bin/bash

echo ""
echo " ===================================================="
echo "  CampusCore University ERP - Starting Server"
echo " ===================================================="
echo ""

# Change to root directory
cd "$(dirname "$0")/root"

# Check Python is installed
if ! command -v python3 &> /dev/null; then
    echo " ERROR: python3 is not installed."
    echo " Install with: sudo apt install python3 python3-pip"
    exit 1
fi

# Upgrade pip/build tools
echo " Upgrading pip..."
python3 -m pip install --upgrade pip setuptools wheel --quiet

# FIX: Install dlib-bin (pre-built wheel) BEFORE requirements.txt.
# Without this, "pip install -r requirements.txt" tries to compile dlib
# from C++ source which requires cmake/boost and takes ~5 min (or fails).
echo " Installing dlib-bin (pre-built wheel, no compiler needed)..."
pip3 install dlib-bin --quiet

echo " Installing face_recognition..."
pip3 install face_recognition --quiet

# Install remaining dependencies
echo " Installing remaining dependencies..."
pip3 install -r requirements.txt --quiet

echo ""
echo " Starting Flask server on http://127.0.0.1:5000"
echo " Open your browser to: http://127.0.0.1:5000/auth.html"
echo " Press Ctrl+C to stop the server."
echo ""

python3 app.py
