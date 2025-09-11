"""
Google Sheets Setup Script
Run this once to set up your Google Sheets integration
"""

import gspread
from google.oauth2.service_account import Credentials
import json
import pandas as pd
from datetime import datetime

def setup_google_sheets():
    """Setup Google Sheets for finance tracking"""
    
    print("🔧 Google Sheets Setup for Finance Tracker")
    print("=" * 50)
    print()
    print("�� Follow these steps:")
    print()
    print("1. Go to: https://console.cloud.google.com/")
    print("2. Create a new project (or select existing)")
    print("3. Enable Google Sheets API:")
    print("   - Go to 'APIs & Services' > 'Library'")
    print("   - Search for 'Google Sheets API'")
    print("   - Click 'Enable'")
    print()
    print("4. Create Service Account:")
    print("   - Go to 'APIs & Services' > 'Credentials'")
    print("   - Click 'Create Credentials' > 'Service Account'")
    print("   - Name: 'finance-tracker'")
    print("   - Click 'Create and Continue'")
    print("   - Skip role assignment, click 'Continue'")
    print("   - Click 'Done'")
    print()
    print("5. Create Key:")
    print("   - Click on your service account")
    print("   - Go to 'Keys' tab")
    print("   - Click 'Add Key' > 'Create new key'")
    print("   - Choose 'JSON' format")
    print("   - Download the JSON file")
    print()
    print("6. Create Google Sheet:")
    print("   - Go to: https://sheets.google.com")
    print("   - Create new sheet named 'Finance Tracker'")
    print("   - Share with your service account email")
    print("   - Give 'Editor' permissions")
    print()
    print("7. Add to Streamlit:")
    print("   - Copy the JSON content")
    print("   - Go to your Streamlit app")
    print("   - Add as secret in Streamlit Cloud")
    print()
    print("📝 Your sheet will have these columns:")
    print("   Date, Type, Mode, Category, Amount, Notes")
    print()
    print("✅ Once setup is complete, your data will be saved to Google Sheets!")

if __name__ == "__main__":
    setup_google_sheets()
