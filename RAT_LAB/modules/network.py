# network.py — Network discovery and information gathering
#
# Interfaces, active connections, WiFi passwords, ARP table,
# port scanning, network shares. Uses subprocess for command-based
# gathering and socket/concurrent.futures for scanning.

import os
import re
import socket
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed


# ── Well-known port names ──────────────────────────────────────
_PORT_NAMES = {
    21: "ftp", 22: "ssh", 23: "telnet", 25: "smtp", 53: "dns",
    80: "http", 110: "pop3", 135: "msrpc", 139: "netbios", 143: "imap",
    443: "https", 445: "smb", 993: "imaps", 995: "pop3s",
    1433: "mssql", 1521: "oracle", 3306: "mysql", 3389: "rdp",
    5432: "postgres", 5900: "vnc", 5985: "winrm", 6379: "redis",
    8080: "http-alt", 8443: "https-alt", 8888: "http-alt2",
    27017: "mongodb",
}

_DEFAULT_PORTS = [
    21, 22, 23, 25, 53, 80, 110, 135, 139, 143, 443, 445,
    993, 995, 1433, 1521, 3306, 3389, 5432, 5900, 5985,
    6379, 8080, 8443, 8888, 27017,
]


# ═══════════════════════════════════════════════════════════════
# Network Interfaces
# ═══════════════════════════════════════════════════════════════

def get_interfaces() -> list:
    """Get all network interfaces with IP, subnet, gateway.

    Parses 'ipconfig /all' output for adapter details.

    Returns:
        List of dicts with adapter info.
    """
    try:
        result = subprocess.run(
            ["ipconfig", "/all"],
            capture_output=True, text=True, timeout=15,
        )
        adapters = []
        current = None

        for line in result.stdout.splitlines():
            # New adapter section
            if line and not line.startswith(" ") and ":" in line:
                if current:
                    adapters.append(current)
                current = {"name": line.strip().rstrip(":"), "details": {}}
                continue

            if current and ":" in line:
                parts = line.split(":", 1)
                key = parts[0].strip().strip(".")
                val = parts[1].strip()
                if key:
                    current["details"][key] = val

        if current:
            adapters.append(current)

        # Extract key fields
        clean = []
        for a in adapters:
            d = a.get("details", {})
            entry = {
                "name": a["name"],
                "description": d.get("Description", ""),
                "mac": d.get("Physical Address", ""),
                "dhcp": d.get("DHCP Enabled", ""),
            }
            # Find IPv4
            for k, v in d.items():
                if "IPv4" in k:
                    entry["ipv4"] = v.split("(")[0].strip()
                elif "Subnet Mask" in k:
                    entry["subnet"] = v
                elif "Default Gateway" in k and v:
                    entry["gateway"] = v
                elif "DNS Servers" in k:
                    entry["dns"] = v
            if entry.get("ipv4") or entry.get("mac"):
                clean.append(entry)

        return clean

    except Exception as e:
        return [{"error": str(e)}]


# ═══════════════════════════════════════════════════════════════
# Active Connections
# ═══════════════════════════════════════════════════════════════

def get_connections() -> list:
    """Get active TCP/UDP connections via netstat.

    Returns:
        List of dicts with protocol, local_addr, remote_addr, state, pid.
    """
    try:
        result = subprocess.run(
            ["netstat", "-ano"],
            capture_output=True, text=True, timeout=15,
        )
        connections = []
        for line in result.stdout.splitlines():
            line = line.strip()
            if not line or line.startswith("Active") or line.startswith("Proto"):
                continue
            parts = line.split()
            if len(parts) >= 4:
                entry = {
                    "protocol": parts[0],
                    "local_addr": parts[1],
                    "remote_addr": parts[2] if len(parts) > 2 else "",
                }
                if parts[0].upper() == "TCP" and len(parts) >= 5:
                    entry["state"] = parts[3]
                    entry["pid"] = int(parts[4]) if parts[4].isdigit() else 0
                elif parts[0].upper() == "UDP" and len(parts) >= 4:
                    entry["state"] = "LISTENING"
                    entry["pid"] = int(parts[3]) if parts[3].isdigit() else 0
                else:
                    entry["state"] = parts[3] if len(parts) > 3 else ""
                    entry["pid"] = int(parts[-1]) if parts[-1].isdigit() else 0
                connections.append(entry)

        return connections

    except Exception as e:
        return [{"error": str(e)}]


# ═══════════════════════════════════════════════════════════════
# WiFi Passwords
# ═══════════════════════════════════════════════════════════════

def get_wifi_passwords() -> dict:
    """Extract saved WiFi profile names and passwords.

    Uses 'netsh wlan show profiles' and 'netsh wlan show profile key=clear'.

    Returns:
        Dict with list of WiFi profiles and their passwords.
    """
    try:
        # Get profile list
        result = subprocess.run(
            ["netsh", "wlan", "show", "profiles"],
            capture_output=True, text=True, timeout=15,
        )

        profiles = []
        for line in result.stdout.splitlines():
            if "All User Profile" in line or "Current User Profile" in line:
                # Extract profile name after the colon
                match = re.search(r":\s*(.+)", line)
                if match:
                    profiles.append(match.group(1).strip())

        # Get password for each profile
        wifi_list = []
        for profile in profiles:
            try:
                detail = subprocess.run(
                    ["netsh", "wlan", "show", "profile",
                     f"name={profile}", "key=clear"],
                    capture_output=True, text=True, timeout=10,
                )
                password = ""
                auth = ""
                for detail_line in detail.stdout.splitlines():
                    if "Key Content" in detail_line:
                        match = re.search(r":\s*(.+)", detail_line)
                        if match:
                            password = match.group(1).strip()
                    elif "Authentication" in detail_line:
                        match = re.search(r":\s*(.+)", detail_line)
                        if match:
                            auth = match.group(1).strip()

                wifi_list.append({
                    "name": profile,
                    "auth": auth,
                    "password": password,
                })
            except Exception:
                wifi_list.append({"name": profile, "auth": "?", "password": ""})

        return {"status": "ok", "profiles": wifi_list, "count": len(wifi_list)}

    except Exception as e:
        return {"status": "error", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# ARP Table
# ═══════════════════════════════════════════════════════════════

def arp_scan(subnet: str = None) -> list:
    """Get ARP table (nearby devices on the network).

    Parses 'arp -a' output for IP-to-MAC mappings.

    Args:
        subnet: Unused (ARP table is passive, not active scanning).
                Kept for API compatibility.

    Returns:
        List of dicts with ip, mac, and type.
    """
    try:
        result = subprocess.run(
            ["arp", "-a"],
            capture_output=True, text=True, timeout=15,
        )
        entries = []
        for line in result.stdout.splitlines():
            # Match lines like: 192.168.1.1    00-aa-bb-cc-dd-ee     dynamic
            match = re.match(
                r"\s*([\d.]+)\s+([\da-fA-F-]+)\s+(\w+)",
                line,
            )
            if match:
                ip_addr = match.group(1)
                mac = match.group(2).replace("-", ":")
                entry_type = match.group(3).lower()
                if ip_addr != "255.255.255.255":
                    entries.append({
                        "ip": ip_addr,
                        "mac": mac,
                        "type": entry_type,
                    })

        return entries

    except Exception as e:
        return [{"error": str(e)}]


# ═══════════════════════════════════════════════════════════════
# Port Scanner
# ═══════════════════════════════════════════════════════════════

def port_scan(target: str, ports: list = None, timeout: float = 0.5,
              max_workers: int = 50) -> list:
    """Basic TCP connect scan using threading.

    Args:
        target: IP address or hostname to scan.
        ports: List of port numbers (default: common ports).
        timeout: Connection timeout per port in seconds.
        max_workers: Thread pool size for parallel scanning.

    Returns:
        List of dicts with port, status, and service name.
    """
    if ports is None:
        ports = _DEFAULT_PORTS

    results = []

    def _check_port(port: int) -> dict:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(timeout)
            result_code = sock.connect_ex((target, port))
            sock.close()
            status = "open" if result_code == 0 else "closed"
        except Exception:
            status = "error"
        return {
            "port": port,
            "status": status,
            "service": _PORT_NAMES.get(port, "unknown"),
        }

    with ThreadPoolExecutor(max_workers=max_workers) as executor:
        futures = {executor.submit(_check_port, p): p for p in ports}
        for future in as_completed(futures):
            results.append(future.result())

    # Sort by port number and filter to open only
    results.sort(key=lambda x: x["port"])
    return results


# ═══════════════════════════════════════════════════════════════
# Network Shares
# ═══════════════════════════════════════════════════════════════

def get_shares() -> list:
    """List local network shares via 'net share'.

    Returns:
        List of dicts with share name, path, and remark.
    """
    try:
        result = subprocess.run(
            ["net", "share"],
            capture_output=True, text=True, timeout=15,
        )
        shares = []
        lines = result.stdout.splitlines()
        # Skip header lines (first 4 typically)
        data_started = False
        for line in lines:
            if "---" in line:
                data_started = True
                continue
            if not data_started or not line.strip():
                continue
            if line.startswith("The command completed"):
                break
            parts = line.split()
            if len(parts) >= 2:
                shares.append({
                    "name": parts[0],
                    "path": parts[1] if len(parts) > 1 else "",
                    "remark": " ".join(parts[2:]) if len(parts) > 2 else "",
                })

        return shares

    except Exception as e:
        return [{"error": str(e)}]


# ═══════════════════════════════════════════════════════════════
# Combined Discovery
# ═══════════════════════════════════════════════════════════════

def discover_all() -> dict:
    """Run all network discovery functions.

    Returns:
        Dict with combined results from all discovery methods.
    """
    return {
        "status": "ok",
        "interfaces": get_interfaces(),
        "connections": get_connections(),
        "wifi": get_wifi_passwords(),
        "arp_table": arp_scan(),
        "shares": get_shares(),
    }
