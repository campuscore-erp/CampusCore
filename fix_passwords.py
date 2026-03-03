"""
fix_passwords.py  —  CampusCore University ERP
================================================
Resets ALL user passwords to their Date of Birth in DD-MM-YYYY format,
and sets IsFirstLogin = 1 so every user must change their password on
first login.

HASHING: Pure sha256 only — NO bcrypt. This is critical: both this
script and auth_routes_merged.py change_password() must use the exact
same hash method so verify_password() always finds a match.

FIRST-LOGIN FLOW
────────────────
  1. Admin runs:  python fix_passwords.py
  2. User opens auth.html → enters UserCode + DOB (e.g. 15-06-1975)
  3. Backend returns isFirstLogin: true → auth.html redirects to change_password.html
  4. change_password.html auto-fills DOB as "Current Password" with a hint
  5. User enters DOB, then chooses a new personal password → saved as sha256
  6. IsFirstLogin set to 0 → user goes to their dashboard
  7. All future logins use the new personal password

USAGE
─────
  python fix_passwords.py            ← reset ALL users
  python fix_passwords.py --show     ← preview only, no DB changes
  python fix_passwords.py TID001     ← reset one specific user by UserCode

PROJECT STRUCTURE
─────────────────
  CampusCore/                    ← project root (this file is here)
  CampusCore/fix_passwords.py    ← this script
  CampusCore/root/               ← Flask backend lives here
  CampusCore/root/app.py
  CampusCore/root/database.py
  CampusCore/root/.env
  CampusCore/root/*.html
"""

import sys, os, hashlib

# ── Path fix ──────────────────────────────────────────────────────────────────
_THIS_FILE  = os.path.realpath(os.path.abspath(__file__))
_SCRIPT_DIR = os.path.dirname(_THIS_FILE)           # CampusCore/
_ROOT_DIR   = os.path.join(_SCRIPT_DIR, 'root')     # CampusCore/root/

for _p in [_ROOT_DIR, _SCRIPT_DIR]:
    if _p not in sys.path:
        sys.path.insert(0, _p)

os.chdir(_ROOT_DIR)

try:
    from database import db
except ModuleNotFoundError:
    print(f"\n❌  Cannot import 'database'.")
    print(f"    Searched: {_ROOT_DIR}")
    print(f"    Files in root/: {os.listdir(_ROOT_DIR) if os.path.isdir(_ROOT_DIR) else '(folder not found)'}\n")
    sys.exit(1)


# ══════════════════════════════════════════════════════════════════════════════
# HASHING  —  pure sha256, no bcrypt
# ══════════════════════════════════════════════════════════════════════════════

def sha256_hash(plain: str) -> str:
    return hashlib.sha256(plain.encode('utf-8')).hexdigest()


# ══════════════════════════════════════════════════════════════════════════════
# DATE FORMATTER
# ══════════════════════════════════════════════════════════════════════════════

def to_ddmmyyyy(dob_val) -> str:
    if not dob_val:
        return ''
    s = str(dob_val).strip()[:10]
    parts = s.split('-')
    if len(parts) == 3:
        if len(parts[0]) == 4:
            return f'{parts[2].zfill(2)}-{parts[1].zfill(2)}-{parts[0]}'
        if len(parts[2]) == 4:
            return s
    return ''


# ══════════════════════════════════════════════════════════════════════════════
# FALLBACK DOBs  (DD-MM-YYYY format)
# ══════════════════════════════════════════════════════════════════════════════

FALLBACK_DOBS = {
    'ADMIN001': '15-05-1980',
    'ADMIN002': '22-09-1985',
    'TID001': '12-03-1975', 'TID002': '25-07-1978', 'TID003': '08-11-1980',
    'TID004': '19-04-1976', 'TID005': '30-09-1979', 'TID006': '14-01-1982',
    'TID007': '22-06-1977', 'TID008': '05-12-1981', 'TID009': '17-08-1974',
    'TID010': '28-02-1983', 'TID011': '10-10-1978', 'TID012': '03-05-1980',
    'TID013': '16-07-1975', 'TID014': '27-03-1982', 'TID015': '09-11-1977',
    'TID016': '21-06-1979', 'TID017': '13-01-1976', 'TID018': '04-09-1984',
    'TID019': '18-04-1978', 'TID020': '29-12-1981', 'TID021': '11-08-1975',
    'TID022': '24-02-1980', 'TID023': '07-06-1977', 'TID024': '19-10-1983',
    'TID025': '31-03-1979', 'TID026': '14-07-1976', 'TID027': '26-11-1981',
    'TID028': '09-05-1978', 'TID029': '20-09-1980', 'TID030': '02-01-1974',
    'TID031': '15-04-1977', 'TID032': '27-08-1982', 'TID033': '10-12-1975',
    'TID034': '22-03-1979', 'TID035': '04-07-1976', 'TID036': '16-11-1983',
    'TID037': '28-02-1978', 'TID038': '10-06-1981', 'TID039': '22-10-1980',
    'TID040': '05-04-1977', 'TID041': '17-08-1975', 'TID042': '29-12-1982',
    'TID043': '11-05-1979', 'TID044': '23-09-1976', 'TID045': '05-01-1980',
    'TID046': '18-04-1983', 'TID047': '30-08-1977', 'TID048': '12-12-1981',
    'TID049': '24-03-1978', 'TID050': '06-07-1975',
    'D1S1N01': '15-08-2006', 'D1S1N02': '22-03-2006', 'D1S1N03': '10-11-2005',
    'D1S1N04': '05-06-2006', 'D1S1N05': '28-09-2005',
    'D1S3N01': '14-01-2005', 'D1S3N02': '30-07-2004', 'D1S3N03': '19-04-2005',
    'D1S3N04': '08-12-2004', 'D1S3N05': '25-02-2005',
}


def resolve_dob(user_code: str, dob_from_db) -> str:
    dob = to_ddmmyyyy(dob_from_db)
    if dob:
        return dob
    return FALLBACK_DOBS.get(user_code)


# ══════════════════════════════════════════════════════════════════════════════
# CORE RESET
# ══════════════════════════════════════════════════════════════════════════════

def reset_passwords(user_code_filter: str = None, dry_run: bool = False) -> list:
    if user_code_filter:
        users = db.execute_query(
            "SELECT UserID, UserCode, UserType, FullName, DateOfBirth "
            "FROM Users WHERE UserCode = ?",
            (user_code_filter,)
        ) or []
    else:
        users = db.execute_query(
            "SELECT UserID, UserCode, UserType, FullName, DateOfBirth "
            "FROM Users ORDER BY UserType, UserCode"
        ) or []

    if not users:
        print("⚠️  No users found. Start the Flask app first to seed the database.")
        return []

    print(f"Found {len(users)} user(s).  Processing…\n")
    results = []

    for u in users:
        code    = u['UserCode']
        dob_raw = u.get('DateOfBirth')
        name    = u['FullName']
        utype   = u['UserType']
        uid     = u['UserID']

        password = resolve_dob(code, dob_raw)

        if not password:
            print(f"  ⚠️  [{utype:<7}] {code:<20} — DOB unknown, SKIPPED")
            results.append({'type': utype, 'code': code, 'name': name,
                            'password': '(SKIPPED — DOB unknown)', 'dob_raw': str(dob_raw), 'ok': False})
            continue

        if not dry_run:
            try:
                pw_hash = sha256_hash(password)
                parts   = password.split('-')
                iso_dob = f'{parts[2]}-{parts[1]}-{parts[0]}' if len(parts) == 3 else None

                if iso_dob:
                    db.execute_non_query(
                        "UPDATE Users SET PasswordHash = ?, IsFirstLogin = 1, "
                        "DateOfBirth = COALESCE(DateOfBirth, ?) WHERE UserID = ?",
                        (pw_hash, iso_dob, uid)
                    )
                else:
                    db.execute_non_query(
                        "UPDATE Users SET PasswordHash = ?, IsFirstLogin = 1 WHERE UserID = ?",
                        (pw_hash, uid)
                    )
                print(f"  ✅ [{utype:<7}] {code:<20} → {password}")
            except Exception as e:
                print(f"  ❌ [{utype:<7}] {code:<20} → FAILED: {e}")
                results.append({'type': utype, 'code': code, 'name': name,
                                'password': f'ERROR: {e}', 'dob_raw': str(dob_raw), 'ok': False})
                continue
        else:
            print(f"  🔍 [{utype:<7}] {code:<20} → {password}  [preview only]")

        results.append({'type': utype, 'code': code, 'name': name,
                        'password': password, 'dob_raw': str(dob_raw), 'ok': True})

    return results


# ══════════════════════════════════════════════════════════════════════════════
# DISPLAY
# ══════════════════════════════════════════════════════════════════════════════

def print_summary(results: list):
    if not results:
        return
    W = 78
    print("\n" + "═" * W)
    print("  FIRST-LOGIN CREDENTIALS  (password = Date of Birth)".center(W))
    print("═" * W)
    print(f"     {'TYPE':<9} {'USER CODE':<22} {'FIRST-LOGIN PASSWORD':<20} NAME")
    print(f"     {'─'*9} {'─'*22} {'─'*20} {'─'*20}")
    for r in results:
        icon = '✅' if r['ok'] else '❌'
        print(f"  {icon}  {r['type']:<9} {r['code']:<22} {r['password']:<20} {r['name']}")
    ok  = sum(1 for r in results if r['ok'])
    bad = len(results) - ok
    print("═" * W)
    print(f"  {ok} reset  |  {bad} skipped / failed")
    print("═" * W)
    print()
    print("  HOW TO LOG IN AFTER THIS SCRIPT")
    print("  ─────────────────────────────────────────────────────────────────")
    print("  1.  Open auth.html in your browser")
    print("  2.  Enter your User Code  (e.g. TID001)")
    print("  3.  Enter your Date of Birth as the password")
    print("      Format: DD-MM-YYYY  (e.g. 12-03-1975)")
    print("  4.  You will be redirected to the password-change page")
    print("  5.  Your DOB will be pre-filled as 'Current Password' with a hint")
    print("  6.  Enter and confirm your new personal password (min 6 chars)")
    print("  7.  From now on, use your new password to log in")
    print()
    print("  ⚠️  Format is strictly DD-MM-YYYY  (day-month-year, hyphens)")
    print("═" * W + "\n")


# ══════════════════════════════════════════════════════════════════════════════
# ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════

if __name__ == '__main__':
    args        = sys.argv[1:]
    dry_run     = '--show' in args or '--dry-run' in args
    user_filter = next((a for a in args if not a.startswith('--')), None)

    print()
    print("🔧  PASSWORD RESET UTILITY — CampusCore ERP".center(78))
    print()

    if not db.test_connection():
        print("❌ Cannot connect to database. Check your .env / DB configuration.")
        sys.exit(1)
    print()

    if dry_run:
        print("  Preview mode (--show): no changes will be made to the database.\n")
    if user_filter:
        print(f"  Filtering to single user: {user_filter}\n")

    results = reset_passwords(user_code_filter=user_filter, dry_run=dry_run)

    if results:
        ok  = sum(1 for r in results if r['ok'])
        bad = len(results) - ok
        print(f"\n  Done — {ok} reset, {bad} skipped/failed.")
        print_summary(results)
        if not dry_run:
            print("✅ All passwords reset. Users can now log in with their Date of Birth.\n")
    else:
        print("❌ No results. See errors above.")
        sys.exit(1)
