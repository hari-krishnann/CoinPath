"""
Demo script to add sample transactions for testing the app
Run this script to populate the app with sample data
"""

import pandas as pd
from datetime import datetime, timedelta
import random

def create_demo_data():
    """Create sample transaction data"""
    
    # Sample transactions
    transactions = [
        # Income transactions
        {"Date": "2024-01-01", "Type": "Income", "Mode": "Cheque", "Category": "Salary", "Amount": 50000, "Notes": "Monthly salary"},
        {"Date": "2024-01-15", "Type": "Income", "Mode": "Cash", "Category": "Freelance", "Amount": 5000, "Notes": "Freelance project"},
        {"Date": "2024-01-20", "Type": "Income", "Mode": "Cheque", "Category": "Investment", "Amount": 2000, "Notes": "Dividend income"},
        
        # Expense transactions
        {"Date": "2024-01-02", "Type": "Expense", "Mode": "Cash", "Category": "Rent", "Amount": 15000, "Notes": "Monthly rent"},
        {"Date": "2024-01-03", "Type": "Expense", "Mode": "Cash", "Category": "Food", "Amount": 3000, "Notes": "Groceries"},
        {"Date": "2024-01-05", "Type": "Expense", "Mode": "Cash", "Category": "Transportation", "Amount": 2000, "Notes": "Fuel and transport"},
        {"Date": "2024-01-08", "Type": "Expense", "Mode": "Cheque", "Category": "Utilities", "Amount": 2500, "Notes": "Electricity bill"},
        {"Date": "2024-01-10", "Type": "Expense", "Mode": "Cash", "Category": "Entertainment", "Amount": 1500, "Notes": "Movie tickets"},
        {"Date": "2024-01-12", "Type": "Expense", "Mode": "Cash", "Category": "Healthcare", "Amount": 800, "Notes": "Medicine"},
        {"Date": "2024-01-15", "Type": "Expense", "Mode": "Cheque", "Category": "Shopping", "Amount": 4000, "Notes": "Online shopping"},
        {"Date": "2024-01-18", "Type": "Expense", "Mode": "Cash", "Category": "Food", "Amount": 2000, "Notes": "Restaurant"},
        {"Date": "2024-01-22", "Type": "Expense", "Mode": "Cheque", "Category": "Savings", "Amount": 10000, "Notes": "Monthly savings"},
        {"Date": "2024-01-25", "Type": "Expense", "Mode": "Cash", "Category": "Utilities", "Amount": 1200, "Notes": "Internet bill"},
        {"Date": "2024-01-28", "Type": "Expense", "Mode": "Cash", "Category": "Food", "Amount": 1500, "Notes": "Groceries"},
        {"Date": "2024-01-30", "Type": "Expense", "Mode": "Cash", "Category": "Transportation", "Amount": 800, "Notes": "Taxi fare"},
    ]
    
    # Create DataFrame
    df = pd.DataFrame(transactions)
    df['Date'] = pd.to_datetime(df['Date'])
    
    # Save to CSV
    df.to_csv('transactions.csv', index=False)
    print("Demo data created successfully!")
    print(f"Added {len(transactions)} sample transactions")
    print("\nSample data includes:")
    print("- 3 income transactions (₹57,000 total)")
    print("- 12 expense transactions (₹35,300 total)")
    print("- Net balance: ₹21,700")
    print("\nYou can now run 'streamlit run app.py' to see the app with sample data!")

if __name__ == "__main__":
    create_demo_data()
