#!/bin/bash

echo "🚀 Starting Personal Finance Tracker..."
echo "📦 Setting up virtual environment..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
source venv/bin/activate

echo "📦 Installing dependencies..."
pip install -r requirements.txt

echo "🌐 Starting Streamlit app..."
echo "📱 The app will open in your default browser"
echo "🔗 If it doesn't open automatically, go to: http://localhost:8501"
echo ""
echo "💡 Tip: Run 'python demo_data.py' first to add sample data for testing"
echo ""

# Start the Streamlit app
streamlit run app.py
