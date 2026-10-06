# screenshot.py — Screen capture via Windows GDI (no PIL dependency)
# Captures primary display, compresses as BMP + zlib, base64 encodes for transport

import ctypes
import ctypes.wintypes
import struct
import base64
import zlib

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32


def capture() -> str:
    """Capture the primary monitor and return zlib-compressed, base64-encoded BMP.

    Uses raw GDI calls — no third-party image libraries required.

    Returns:
        Base64 string of zlib-compressed BMP data.
    """
    width = user32.GetSystemMetrics(0)   # SM_CXSCREEN
    height = user32.GetSystemMetrics(1)  # SM_CYSCREEN

    # Acquire device contexts
    hdc_screen = user32.GetDC(0)
    hdc_mem = gdi32.CreateCompatibleDC(hdc_screen)
    hbmp = gdi32.CreateCompatibleBitmap(hdc_screen, width, height)
    old_bmp = gdi32.SelectObject(hdc_mem, hbmp)

    # BitBlt entire screen into memory DC
    SRCCOPY = 0x00CC0020
    gdi32.BitBlt(hdc_mem, 0, 0, width, height, hdc_screen, 0, 0, SRCCOPY)

    # BITMAPINFOHEADER (40 bytes)
    bmi = struct.pack(
        "<IiiHHIIiiII",
        40,       # biSize
        width,    # biWidth
        -height,  # biHeight (negative = top-down DIB)
        1,        # biPlanes
        24,       # biBitCount (24-bit RGB)
        0,        # biCompression (BI_RGB)
        0,        # biSizeImage (0 for BI_RGB)
        0, 0,     # biXPelsPerMeter, biYPelsPerMeter
        0, 0,     # biClrUsed, biClrImportant
    )

    # Row stride: each scanline padded to 4-byte boundary
    row_size = ((width * 3 + 3) // 4) * 4
    img_size = row_size * height

    # Extract pixel data
    pixel_buf = ctypes.create_string_buffer(img_size)
    gdi32.GetDIBits(hdc_mem, hbmp, 0, height, pixel_buf, bmi, 0)

    # Assemble BMP file in memory
    file_size = 54 + img_size
    bmp_file_header = struct.pack("<2sIHHI", b"BM", file_size, 0, 0, 54)
    bmp_data = bmp_file_header + bmi + pixel_buf.raw

    # Cleanup GDI objects
    gdi32.SelectObject(hdc_mem, old_bmp)
    gdi32.DeleteObject(hbmp)
    gdi32.DeleteDC(hdc_mem)
    user32.ReleaseDC(0, hdc_screen)

    # Compress and encode for transport
    compressed = zlib.compress(bmp_data, 6)
    return base64.b64encode(compressed).decode("ascii")


def save_screenshot(b64_data: str, filepath: str) -> None:
    """Decode and decompress a received screenshot, save to disk.

    Args:
        b64_data: Base64-encoded, zlib-compressed BMP data.
        filepath: Destination file path (.bmp).
    """
    compressed = base64.b64decode(b64_data)
    bmp_data = zlib.decompress(compressed)
    with open(filepath, "wb") as f:
        f.write(bmp_data)
