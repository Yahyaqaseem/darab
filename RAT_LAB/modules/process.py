# process.py — Process enumeration and termination
# Uses CreateToolhelp32Snapshot for reliable native process listing

import ctypes
import ctypes.wintypes

TH32CS_SNAPPROCESS = 0x00000002
PROCESS_TERMINATE = 0x0001
INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value

kernel32 = ctypes.windll.kernel32


class PROCESSENTRY32(ctypes.Structure):
    """Toolhelp32 process entry structure."""
    _fields_ = [
        ("dwSize", ctypes.wintypes.DWORD),
        ("cntUsage", ctypes.wintypes.DWORD),
        ("th32ProcessID", ctypes.wintypes.DWORD),
        ("th32DefaultHeapID", ctypes.POINTER(ctypes.c_ulong)),
        ("th32ModuleID", ctypes.wintypes.DWORD),
        ("cntThreads", ctypes.wintypes.DWORD),
        ("th32ParentProcessID", ctypes.wintypes.DWORD),
        ("pcPriClassBase", ctypes.c_long),
        ("dwFlags", ctypes.wintypes.DWORD),
        ("szExeFile", ctypes.c_char * 260),
    ]


def list_processes() -> list:
    """Enumerate all running processes via CreateToolhelp32Snapshot.

    Returns:
        List of dicts with pid, name, ppid, and thread count.
    """
    procs = []
    snap = kernel32.CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0)
    if snap == INVALID_HANDLE_VALUE:
        return [{"error": "CreateToolhelp32Snapshot failed"}]

    entry = PROCESSENTRY32()
    entry.dwSize = ctypes.sizeof(PROCESSENTRY32)

    if kernel32.Process32First(snap, ctypes.byref(entry)):
        while True:
            procs.append({
                "pid": entry.th32ProcessID,
                "name": entry.szExeFile.decode("utf-8", errors="replace"),
                "ppid": entry.th32ParentProcessID,
                "threads": entry.cntThreads,
            })
            if not kernel32.Process32Next(snap, ctypes.byref(entry)):
                break

    kernel32.CloseHandle(snap)
    return procs


def kill_process(pid: int) -> dict:
    """Terminate a process by PID using TerminateProcess.

    Args:
        pid: Process ID to terminate.

    Returns:
        Dict with status and result message.
    """
    if pid <= 0:
        return {"status": "error", "message": f"Invalid PID: {pid}"}

    handle = kernel32.OpenProcess(PROCESS_TERMINATE, False, pid)
    if not handle:
        error_code = ctypes.GetLastError()
        return {
            "status": "error",
            "pid": pid,
            "message": f"OpenProcess failed (error {error_code}) — access denied or process not found",
        }

    success = kernel32.TerminateProcess(handle, 0)
    kernel32.CloseHandle(handle)

    if success:
        return {"status": "ok", "pid": pid, "action": "terminated"}
    return {"status": "error", "pid": pid, "message": "TerminateProcess failed"}
