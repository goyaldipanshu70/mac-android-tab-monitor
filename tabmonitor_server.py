#!/usr/bin/env python3
"""
TabMonitor Server - Python Version
A simplified Python implementation for quick testing
"""

import socket
import threading
import time
import struct
from PIL import ImageGrab
import io
import sys

class TabMonitorServer:
    def __init__(self, port=8080):
        self.port = port
        self.clients = []
        self.running = False
        self.server_socket = None
        
    def get_local_ip(self):
        """Get the local IP address"""
        try:
            # Connect to a remote address to get local IP
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "127.0.0.1"
    
    def start_server(self):
        """Start the TCP server"""
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.server_socket.bind(('0.0.0.0', self.port))
            self.server_socket.listen(5)
            self.running = True
            
            ip = self.get_local_ip()
            print(f"🚀 TabMonitor Server Started!")
            print(f"📱 Connect your Android device to: {ip}:{self.port}")
            print(f"🔄 Waiting for connections...")
            
            # Start screen capture in separate thread
            capture_thread = threading.Thread(target=self.capture_and_broadcast, daemon=True)
            capture_thread.start()
            
            while self.running:
                try:
                    client_socket, addr = self.server_socket.accept()
                    print(f"📱 Client connected from {addr}")
                    self.clients.append(client_socket)
                    
                    # Handle client in separate thread
                    client_thread = threading.Thread(
                        target=self.handle_client, 
                        args=(client_socket,), 
                        daemon=True
                    )
                    client_thread.start()
                    
                except socket.error:
                    break
                    
        except Exception as e:
            print(f"❌ Server error: {e}")
        finally:
            self.stop_server()
    
    def handle_client(self, client_socket):
        """Handle individual client connections"""
        try:
            while self.running:
                data = client_socket.recv(1024)
                if not data:
                    break
                    
                # Handle touch events
                message = data.decode('utf-8').strip()
                if message.startswith("CLICK:"):
                    coords = message.replace("CLICK:", "").split(",")
                    if len(coords) == 2:
                        try:
                            x = float(coords[0])
                            y = float(coords[1])
                            self.simulate_click(x, y)
                            print(f"🖱️  Click at ({x:.2f}, {y:.2f})")
                        except ValueError:
                            pass
                            
        except socket.error:
            pass
        finally:
            if client_socket in self.clients:
                self.clients.remove(client_socket)
            client_socket.close()
            print("📱 Client disconnected")
    
    def simulate_click(self, rel_x, rel_y):
        """Simulate mouse click at relative coordinates"""
        try:
            import pyautogui
            # Get screen size
            screen_width, screen_height = pyautogui.size()
            # Convert relative to absolute coordinates
            abs_x = int(rel_x * screen_width)
            abs_y = int(rel_y * screen_height)
            # Perform click
            pyautogui.click(abs_x, abs_y)
        except ImportError:
            print("⚠️  pyautogui not installed. Touch events disabled.")
            print("💡 Install with: pip install pyautogui")
    
    def capture_and_broadcast(self):
        """Capture screen and broadcast to all clients"""
        print("📸 Starting screen capture...")
        
        while self.running:
            try:
                if not self.clients:
                    time.sleep(0.1)
                    continue
                
                # Capture screen
                screenshot = ImageGrab.grab()
                
                # Resize for better performance (50% of original)
                width, height = screenshot.size
                screenshot = screenshot.resize((width//2, height//2))
                
                # Convert to JPEG
                img_buffer = io.BytesIO()
                screenshot.save(img_buffer, format='JPEG', quality=70)
                frame_data = img_buffer.getvalue()
                
                # Send to all clients
                self.broadcast_frame(frame_data)
                
                # 30 FPS
                time.sleep(1/30)
                
            except Exception as e:
                print(f"❌ Capture error: {e}")
                time.sleep(1)
    
    def broadcast_frame(self, frame_data):
        """Send frame to all connected clients"""
        if not self.clients:
            return
            
        # Prepare frame with length header
        frame_length = len(frame_data)
        header = struct.pack('>I', frame_length)  # Big endian 4-byte integer
        packet = header + frame_data
        
        # Send to all clients
        disconnected_clients = []
        for client in self.clients[:]:  # Copy list to avoid modification during iteration
            try:
                client.send(packet)
            except socket.error:
                disconnected_clients.append(client)
        
        # Remove disconnected clients
        for client in disconnected_clients:
            if client in self.clients:
                self.clients.remove(client)
            client.close()
    
    def stop_server(self):
        """Stop the server"""
        self.running = False
        
        # Close all client connections
        for client in self.clients:
            client.close()
        self.clients.clear()
        
        # Close server socket
        if self.server_socket:
            self.server_socket.close()
        
        print("🛑 Server stopped")

def main():
    print("🖥️  TabMonitor Server (Python Version)")
    print("=" * 40)
    
    # Check dependencies
    try:
        import PIL
        print("✅ PIL/Pillow found")
    except ImportError:
        print("❌ PIL/Pillow not found. Install with: pip install Pillow")
        return
    
    try:
        import pyautogui
        print("✅ pyautogui found (touch events enabled)")
    except ImportError:
        print("⚠️  pyautogui not found (touch events disabled)")
        print("💡 Install with: pip install pyautogui")
    
    print()
    
    server = TabMonitorServer()
    
    try:
        server.start_server()
    except KeyboardInterrupt:
        print("\n🛑 Shutting down server...")
        server.stop_server()

if __name__ == "__main__":
    main()
