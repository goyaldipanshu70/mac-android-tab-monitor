#!/usr/bin/env python3
"""
TabMonitor Test Client - Python Version
A simple GUI client to test the TabMonitor server
"""

import tkinter as tk
from tkinter import ttk, messagebox
import socket
import threading
import struct
from PIL import Image, ImageTk
import io
import time

class TabMonitorClient:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("TabMonitor Test Client")
        self.root.geometry("900x700")
        
        self.socket = None
        self.connected = False
        self.running = False
        
        self.setup_ui()
        
    def setup_ui(self):
        # Connection frame
        conn_frame = ttk.Frame(self.root, padding="10")
        conn_frame.pack(fill=tk.X)
        
        ttk.Label(conn_frame, text="Server IP:").pack(side=tk.LEFT)
        self.ip_var = tk.StringVar(value="192.168.1.70")
        self.ip_entry = ttk.Entry(conn_frame, textvariable=self.ip_var, width=15)
        self.ip_entry.pack(side=tk.LEFT, padx=(5, 10))
        
        ttk.Label(conn_frame, text="Port:").pack(side=tk.LEFT)
        self.port_var = tk.StringVar(value="8080")
        self.port_entry = ttk.Entry(conn_frame, textvariable=self.port_var, width=8)
        self.port_entry.pack(side=tk.LEFT, padx=(5, 10))
        
        self.connect_btn = ttk.Button(conn_frame, text="Connect", command=self.toggle_connection)
        self.connect_btn.pack(side=tk.LEFT, padx=(10, 0))
        
        # Status label
        self.status_var = tk.StringVar(value="Disconnected")
        self.status_label = ttk.Label(self.root, textvariable=self.status_var, font=("Arial", 12, "bold"))
        self.status_label.pack(pady=(5, 10))
        
        # Screen display frame
        screen_frame = ttk.Frame(self.root, padding="10")
        screen_frame.pack(fill=tk.BOTH, expand=True)
        
        # Canvas for screen display
        self.canvas = tk.Canvas(screen_frame, bg="lightgray", width=800, height=500)
        self.canvas.pack(fill=tk.BOTH, expand=True)
        self.canvas.bind("<Button-1>", self.on_canvas_click)
        
        # Instructions
        instructions = """
Instructions:
1. Start the TabMonitor server on your MacBook
2. Enter the server IP address (shown in server terminal)
3. Click Connect to start mirroring
4. Click on the screen image to send mouse clicks to your MacBook
        """
        
        inst_label = ttk.Label(self.root, text=instructions, justify=tk.LEFT, 
                              font=("Arial", 10), foreground="gray")
        inst_label.pack(pady=10)
        
    def toggle_connection(self):
        if self.connected:
            self.disconnect()
        else:
            self.connect()
            
    def connect(self):
        ip = self.ip_var.get().strip()
        port = self.port_var.get().strip()
        
        if not ip or not port:
            messagebox.showerror("Error", "Please enter IP and port")
            return
            
        try:
            port = int(port)
            self.socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.socket.settimeout(5)
            self.socket.connect((ip, port))
            
            self.connected = True
            self.running = True
            self.status_var.set("Connected")
            self.connect_btn.config(text="Disconnect")
            
            # Start receiving frames
            self.receive_thread = threading.Thread(target=self.receive_frames, daemon=True)
            self.receive_thread.start()
            
            print(f"✅ Connected to {ip}:{port}")
            
        except Exception as e:
            messagebox.showerror("Connection Error", f"Failed to connect: {e}")
            if self.socket:
                self.socket.close()
                
    def disconnect(self):
        self.running = False
        self.connected = False
        
        if self.socket:
            self.socket.close()
            self.socket = None
            
        self.status_var.set("Disconnected")
        self.connect_btn.config(text="Connect")
        self.canvas.delete("all")
        
        print("❌ Disconnected")
        
    def receive_frames(self):
        try:
            while self.running and self.socket:
                # Read frame length (4 bytes)
                length_data = self.recv_exact(4)
                if not length_data:
                    break
                    
                frame_length = struct.unpack('>I', length_data)[0]
                
                if frame_length <= 0 or frame_length > 10 * 1024 * 1024:  # Max 10MB
                    continue
                    
                # Read frame data
                frame_data = self.recv_exact(frame_length)
                if not frame_data:
                    break
                    
                # Display frame
                self.display_frame(frame_data)
                
        except Exception as e:
            if self.running:
                print(f"❌ Receive error: {e}")
                self.root.after(0, self.disconnect)
                
    def recv_exact(self, length):
        """Receive exactly 'length' bytes"""
        data = b''
        while len(data) < length and self.running:
            chunk = self.socket.recv(length - len(data))
            if not chunk:
                return None
            data += chunk
        return data
        
    def display_frame(self, frame_data):
        try:
            # Convert bytes to PIL Image
            image = Image.open(io.BytesIO(frame_data))
            
            # Resize to fit canvas
            canvas_width = self.canvas.winfo_width()
            canvas_height = self.canvas.winfo_height()
            
            if canvas_width > 1 and canvas_height > 1:  # Canvas is ready
                image.thumbnail((canvas_width, canvas_height), Image.Resampling.LANCZOS)
                
                # Convert to PhotoImage
                self.photo = ImageTk.PhotoImage(image)
                
                # Update canvas on main thread
                self.root.after(0, self.update_canvas)
                
        except Exception as e:
            print(f"❌ Display error: {e}")
            
    def update_canvas(self):
        if hasattr(self, 'photo'):
            self.canvas.delete("all")
            x = self.canvas.winfo_width() // 2
            y = self.canvas.winfo_height() // 2
            self.canvas.create_image(x, y, anchor=tk.CENTER, image=self.photo)
            
    def on_canvas_click(self, event):
        if not self.connected:
            return
            
        # Calculate relative coordinates
        canvas_width = self.canvas.winfo_width()
        canvas_height = self.canvas.winfo_height()
        
        rel_x = event.x / canvas_width
        rel_y = event.y / canvas_height
        
        # Send click event
        self.send_click(rel_x, rel_y)
        
    def send_click(self, x, y):
        try:
            message = f"CLICK:{x},{y}\n"
            self.socket.send(message.encode('utf-8'))
            print(f"🖱️ Sent click: ({x:.3f}, {y:.3f})")
        except Exception as e:
            print(f"❌ Click send error: {e}")
            
    def run(self):
        try:
            self.root.mainloop()
        finally:
            self.disconnect()

def main():
    print("🖥️ TabMonitor Test Client")
    print("=" * 30)
    
    client = TabMonitorClient()
    client.run()

if __name__ == "__main__":
    main()
