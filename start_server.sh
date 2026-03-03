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

# Install dependencies
echo " Installing/checking dependencies..."
pip3 install -r requirements.txt --quiet

echo ""
echo " Starting Flask server on http://127.0.0.1:5000"
echo " Open root/auth.html in your browser to access the website."
echo " Press Ctrl+C to stop the server."
echo ""

python3 app.py
