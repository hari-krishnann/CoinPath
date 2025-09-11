"""
Smart launcher that handles port conflicts and provides multiple options
"""

import subprocess
import socket
import sys
import os
import time

def find_free_port(start_port=8501):
    """Find a free port starting from start_port"""
    port = start_port
    while port < start_port + 100:  # Try up to 100 ports
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.bind(('localhost', port))
                return port
        except OSError:
            port += 1
    return None

def kill_process_on_port(port):
    """Kill any process running on the specified port"""
    try:
        result = subprocess.run(['lsof', '-ti', f':{port}'], 
                              capture_output=True, text=True)
        if result.stdout.strip():
            pid = result.stdout.strip()
            subprocess.run(['kill', pid])
            print(f"🔄 Killed process {pid} on port {port}")
            time.sleep(2)  # Wait for port to be released
            return True
    except:
        pass
    return False

def get_local_ip():
    """Get the local IP address"""
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def run_streamlit(port, address="localhost", mobile=False):
    """Run Streamlit with the specified port and address"""
    cmd = [
        sys.executable, "-m", "streamlit", "run", "app_enhanced.py",
        "--server.port", str(port),
        "--server.address", address,
        "--server.headless", "true"
    ]
    
    if mobile:
        print(f"📱 Mobile Access Mode")
        print(f"🌐 Your app will be available at:")
        print(f"   http://{get_local_ip()}:{port}")
        print(f"   http://localhost:{port}")
        print()
        print("📱 To access from your phone:")
        print(f"   1. Make sure your phone is on the same WiFi network")
        print(f"   2. Open your phone's browser")
        print(f"   3. Go to: http://{get_local_ip()}:{port}")
        print(f"   4. Add to home screen for PWA experience!")
    else:
        print(f"💻 Desktop Mode")
        print(f"🌐 Your app will be available at:")
        print(f"   http://localhost:{port}")
    
    print()
    print("🔧 To stop the app, press Ctrl+C")
    print("=" * 60)
    print()
    
    try:
        subprocess.run(cmd)
    except KeyboardInterrupt:
        print("\n👋 App stopped. Thanks for using Personal Finance Tracker!")

def main():
    print("🚀 Personal Finance Tracker PWA")
    print("================================")
    print()
    print("📱 Choose how to run your app:")
    print()
    print("1. 📱 Mobile Access (Access from phone)")
    print("2. 💻 Desktop Only")
    print("3. 🔧 Force kill port 8501 and restart")
    print("4. 🎯 Use different port")
    print()
    
    choice = input("Enter your choice (1-4): ").strip()
    
    if choice == "1":
        # Mobile access
        port = find_free_port(8501)
        if port is None:
            print("❌ Could not find a free port. Please try option 3 or 4.")
            return
        
        if port != 8501:
            print(f"⚠️  Port 8501 is busy, using port {port} instead")
        
        run_streamlit(port, address="0.0.0.0", mobile=True)
        
    elif choice == "2":
        # Desktop only
        port = find_free_port(8501)
        if port is None:
            print("❌ Could not find a free port. Please try option 3 or 4.")
            return
        
        if port != 8501:
            print(f"⚠️  Port 8501 is busy, using port {port} instead")
        
        run_streamlit(port, address="localhost", mobile=False)
        
    elif choice == "3":
        # Force kill and restart
        print("🔧 Killing process on port 8501...")
        if kill_process_on_port(8501):
            print("✅ Port 8501 is now free!")
        else:
            print("ℹ️  No process found on port 8501")
        
        print("\n📱 Choose mode:")
        print("1. Mobile Access")
        print("2. Desktop Only")
        mode = input("Enter choice (1-2): ").strip()
        
        if mode == "1":
            run_streamlit(8501, address="0.0.0.0", mobile=True)
        else:
            run_streamlit(8501, address="localhost", mobile=False)
            
    elif choice == "4":
        # Use different port
        try:
            port = int(input("Enter port number (e.g., 8502, 8503): "))
        except ValueError:
            print("❌ Invalid port number")
            return
        
        if not (1024 <= port <= 65535):
            print("❌ Port must be between 1024 and 65535")
            return
        
        print("\n📱 Choose mode:")
        print("1. Mobile Access")
        print("2. Desktop Only")
        mode = input("Enter choice (1-2): ").strip()
        
        if mode == "1":
            run_streamlit(port, address="0.0.0.0", mobile=True)
        else:
            run_streamlit(port, address="localhost", mobile=False)
    else:
        print("❌ Invalid choice. Please run the script again.")

if __name__ == "__main__":
    main()
