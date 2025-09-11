#!/bin/bash

echo "🚀 Personal Finance Tracker PWA"
echo "================================"
echo ""
echo "📱 Choose how to run your app:"
echo ""
echo "1. 📱 Mobile Access (Access from phone)"
echo "2. 💻 Desktop Only"
echo "3. ☁️  Deploy to Cloud"
echo "4. 📋 View Deployment Guide"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo ""
        echo "📱 Starting mobile-optimized version..."
        echo "Your phone can access this app on the same WiFi network!"
        echo ""
        source venv/bin/activate
        python run_mobile.py
        ;;
    2)
        echo ""
        echo "💻 Starting desktop version..."
        echo ""
        source venv/bin/activate
        streamlit run app_enhanced.py
        ;;
    3)
        echo ""
        echo "☁️  Deployment options:"
        echo "1. Streamlit Cloud (easiest)"
        echo "2. Railway"
        echo "3. Docker"
        echo "4. Heroku"
        echo ""
        echo "📖 See DEPLOYMENT.md for detailed instructions"
        echo "🚀 Run 'python deploy.py' to set up deployment files"
        ;;
    4)
        echo ""
        echo "📋 Opening deployment guide..."
        if command -v open &> /dev/null; then
            open DEPLOYMENT.md
        elif command -v xdg-open &> /dev/null; then
            xdg-open DEPLOYMENT.md
        else
            echo "Please open DEPLOYMENT.md to view the guide"
        fi
        ;;
    *)
        echo "Invalid choice. Please run the script again."
        ;;
esac
