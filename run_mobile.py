"""
Run the app on local network so you can access it from your phone
"""

import subprocess
import socket
import streamlit as st
import sys
import os

def get_local_ip():
    """Get the local IP address"""
    try:
        # Connect to a remote server to get local IP
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except:
        return "127.0.0.1"

def main():
    print("📱 Starting Personal Finance Tracker for Mobile Access...")
    print("=" * 60)
    
    # Get local IP
    local_ip = get_local_ip()
    port = 8501
    
    print(f"🌐 Your app will be available at:")
    print(f"   http://{local_ip}:{port}")
    print(f"   http://localhost:{port}")
    print()
    print("📱 To access from your phone:")
    print(f"   1. Make sure your phone is on the same WiFi network")
    print(f"   2. Open your phone's browser")
    print(f"   3. Go to: http://{local_ip}:{port}")
    print(f"   4. Add to home screen for PWA experience!")
    print()
    print("🔧 To stop the app, press Ctrl+C")
    print("=" * 60)
    print()
    
    # Start the app
    try:
        subprocess.run([
            sys.executable, "-m", "streamlit", "run", "app_enhanced.py",
            "--server.address", "0.0.0.0",
            "--server.port", str(port),
            "--server.headless", "true"
        ])
    except KeyboardInterrupt:
        print("\n👋 App stopped. Thanks for using Personal Finance Tracker!")

if __name__ == "__main__":
    main()
