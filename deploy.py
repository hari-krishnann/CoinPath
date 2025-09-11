"""
Deployment script for Personal Finance Tracker PWA
Supports multiple deployment options
"""

import os
import subprocess
import sys

def create_requirements():
    """Create requirements.txt for deployment"""
    requirements = """streamlit>=1.28.0
pandas>=2.0.0
plotly>=5.15.0
"""
    
    with open('requirements.txt', 'w') as f:
        f.write(requirements)
    
    print("✅ Created requirements.txt")

def create_streamlit_config():
    """Create Streamlit config for deployment"""
    config_dir = '.streamlit'
    os.makedirs(config_dir, exist_ok=True)
    
    config = """[server]
headless = true
port = 8501
enableCORS = false
enableXsrfProtection = false

[browser]
gatherUsageStats = false
"""
    
    with open(f'{config_dir}/config.toml', 'w') as f:
        f.write(config)
    
    print("✅ Created Streamlit config")

def create_heroku_files():
    """Create files for Heroku deployment"""
    # Procfile
    with open('Procfile', 'w') as f:
        f.write('web: streamlit run app_enhanced.py --server.port=$PORT --server.address=0.0.0.0')
    
    # runtime.txt
    with open('runtime.txt', 'w') as f:
        f.write('python-3.11.0')
    
    print("✅ Created Heroku deployment files")

def create_railway_files():
    """Create files for Railway deployment"""
    with open('railway.json', 'w') as f:
        f.write('''{
  "build": {
    "builder": "NIXPACKS"
  },
  "deploy": {
    "startCommand": "streamlit run app_enhanced.py --server.port=$PORT --server.address=0.0.0.0",
    "healthcheckPath": "/",
    "healthcheckTimeout": 100
  }
}''')
    
    print("✅ Created Railway deployment files")

def create_dockerfile():
    """Create Dockerfile for containerized deployment"""
    dockerfile = """FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8501

HEALTHCHECK CMD curl --fail http://localhost:8501/_stcore/health

ENTRYPOINT ["streamlit", "run", "app_enhanced.py", "--server.port=8501", "--server.address=0.0.0.0"]
"""
    
    with open('Dockerfile', 'w') as f:
        f.write(dockerfile)
    
    print("✅ Created Dockerfile")

def main():
    print("🚀 Setting up Personal Finance Tracker for deployment...")
    
    # Create all necessary files
    create_requirements()
    create_streamlit_config()
    create_heroku_files()
    create_railway_files()
    create_dockerfile()
    
    print("\n�� Deployment Options:")
    print("\n1. 🌐 Streamlit Cloud (Recommended for beginners):")
    print("   - Go to https://share.streamlit.io")
    print("   - Connect your GitHub repository")
    print("   - Deploy automatically")
    
    print("\n2. 🚂 Railway:")
    print("   - Go to https://railway.app")
    print("   - Connect your GitHub repository")
    print("   - Deploy with railway.json")
    
    print("\n3. 🐳 Docker:")
    print("   - Build: docker build -t finance-tracker .")
    print("   - Run: docker run -p 8501:8501 finance-tracker")
    
    print("\n4. ☁️ Heroku:")
    print("   - Install Heroku CLI")
    print("   - Run: heroku create your-app-name")
    print("   - Run: git push heroku main")
    
    print("\n5. 📱 Local Network (for phone access):")
    print("   - Run: streamlit run app_enhanced.py --server.address=0.0.0.0")
    print("   - Access from phone using your computer's IP address")
    
    print("\n✅ All deployment files created!")
    print("📱 The app is now PWA-ready with mobile optimization!")

if __name__ == "__main__":
    main()
