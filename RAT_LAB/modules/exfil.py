# exfil.py — Data exfiltration with compression and chunking
# Prepares files for transport: read → compress (zlib) → base64 → chunk
# Server side: reassemble chunks → decode → decompress → save

import zlib
import base64
import os
CHUNK_SIZE = 1024*1024  # 1MB chunks


def prepare_exfil(filepath: str) -> dict:
    """Prepare a file for exfiltration: compress, encode, and chunk.

    Args:
        filepath: Path to the file to exfiltrate.

    Returns:
        Dict with status, metadata, and list of base64 chunks.
    """
    try:
        filepath = os.path.abspath(filepath)
        if not os.path.exists(filepath):
            return {"status": "error", "message": f"File not found: {filepath}"}

        with open(filepath, "rb") as f:
            raw = f.read()

        # Compress with max effort
        compressed = zlib.compress(raw, 9)
        encoded = base64.b64encode(compressed).decode("ascii")

        # Split into transport-friendly chunks
        chunks = []
        for i in range(0, len(encoded), CHUNK_SIZE):
            chunks.append(encoded[i : i + CHUNK_SIZE])

        return {
            "status": "ok",
            "filename": os.path.basename(filepath),
            "original_size": len(raw),
            "compressed_size": len(compressed),
            "total_chunks": len(chunks),
            "chunks": chunks,
        }
    except Exception as e:
        return {"status": "error", "message": str(e)}


def reassemble(chunks: list) -> bytes:
    """Reassemble exfiltrated chunks back into original file data.

    Args:
        chunks: List of base64-encoded chunk strings.

    Returns:
        Original file bytes (decompressed).
    """
    encoded = "".join(chunks)
    compressed = base64.b64decode(encoded)
    return zlib.decompress(compressed)


def save_exfil(data: bytes, filepath: str) -> dict:
    """Save reassembled exfiltrated data to disk.

    Args:
        data: Decompressed original file bytes.
        filepath: Destination path.

    Returns:
        Dict with status, path, and file size.
    """
    try:
        parent = os.path.dirname(filepath)
        if parent:
            os.makedirs(parent, exist_ok=True)
        with open(filepath, "wb") as f:
            f.write(data)
        return {"status": "ok", "path": filepath, "size": len(data)}
    except Exception as e:
        return {"status": "error", "message": str(e)}
