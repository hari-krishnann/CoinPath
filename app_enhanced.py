import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime, date
import os
import base64
import gspread
from google.oauth2.service_account import Credentials
import json

# Page configuration for mobile-first PWA
st.set_page_config(
    page_title="Finance Tracker",
    page_icon="💰",
    layout="wide",
    initial_sidebar_state="collapsed"
)

# Custom CSS for mobile-first dark theme
st.markdown("""
<style>
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    .main > div { padding: 0 !important; max-width: 100% !important; }
    .stApp { background: #0a0a0a !important; color: white !important; font-family: 'Inter', sans-serif !important; }
    #MainMenu {visibility: hidden;} footer {visibility: hidden;} header {visibility: hidden;}
    .custom-header { background: #1a1a1a; padding: 1rem; border-bottom: 1px solid #333; margin-bottom: 1rem; }
    .header-content { display: flex; justify-content: space-between; align-items: center; max-width: 400px; margin: 0 auto; }
    .app-title { font-size: 1.2rem; font-weight: 600; color: white; margin: 0; }
    .balance-display { text-align: center; padding: 1rem; background: #1a1a1a; border-radius: 12px; margin: 1rem auto; max-width: 400px; }
    .balance-amount { font-size: 2.5rem; font-weight: 700; color: #00ff88; margin: 0; }
    .balance-label { font-size: 0.9rem; color: #888; margin: 0; }
    .amount-container { text-align: center; padding: 2rem 1rem; background: #1a1a1a; border-radius: 12px; margin: 1rem auto; max-width: 400px; }
    .amount-display { font-size: 3rem; font-weight: 700; color: white; margin: 0; font-family: 'Inter', monospace; }
    .action-buttons { display: flex; gap: 12px; margin: 2rem auto; max-width: 400px; }
    .btn-primary { flex: 1; padding: 16px; background: #00ff88; color: #000; border: none; border-radius: 12px; font-weight: 600; font-size: 1rem; cursor: pointer; transition: all 0.2s; }
    .btn-primary:hover { background: #00cc6a; }
    .btn-secondary { flex: 1; padding: 16px; background: #333; color: white; border: none; border-radius: 12px; font-weight: 600; font-size: 1rem; cursor: pointer; transition: all 0.2s; }
    .btn-secondary:hover { background: #444; }
    .transaction-item { display: flex; justify-content: space-between; align-items: center; padding: 12px 16px; background: #1a1a1a; border-radius: 8px; margin: 8px auto; max-width: 400px; }
    .transaction-left { display: flex; align-items: center; gap: 12px; }
    .transaction-icon { width: 40px; height: 40px; border-radius: 8px; display: flex; align-items: center; justify-content: center; font-size: 1.2rem; }
    .transaction-details h4 { margin: 0; font-size: 0.9rem; font-weight: 500; }
    .transaction-details p { margin: 0; font-size: 0.8rem; color: #888; }
    .transaction-amount { font-weight: 600; font-size: 1rem; }
    .amount-income { color: #00ff88; } .amount-expense { color: #ff4444; }
    .status-indicator { display: inline-block; width: 8px; height: 8px; border-radius: 50%; margin-right: 8px; }
    .status-online { background: #00ff88; } .status-offline { background: #ff4444; }
</style>
""", unsafe_allow_html=True)

# Google Sheets configuration
SHEET_NAME = "Coin Path"
WORKSHEET_NAME = "Transactions"

# Helpers
def ensure_datetime(df: pd.DataFrame) -> pd.DataFrame:
    if 'Date' in df.columns:
        df['Date'] = pd.to_datetime(df['Date'], errors='coerce')
    return df

def get_google_sheets_client():
    """Get Google Sheets client using Streamlit secrets. Accepts JSON string or dict."""
    try:
        creds_info = st.secrets["google_credentials"]
        if isinstance(creds_info, str):
            creds_info = json.loads(creds_info)
        if not isinstance(creds_info, dict):
            raise ValueError("google_credentials must be JSON or dict")
        creds = Credentials.from_service_account_info(
            creds_info,
            scopes=['https://www.googleapis.com/auth/spreadsheets']
        )
        client = gspread.authorize(creds)
        return client
    except Exception as e:
        st.warning(f"Google Sheets connection failed: {str(e)}")
        return None

def load_transactions_from_sheets():
    try:
        client = get_google_sheets_client()
        if not client:
            return pd.DataFrame(columns=['Date', 'Type', 'Mode', 'Category', 'Amount', 'Notes'])
        sheet = client.open(SHEET_NAME).worksheet(WORKSHEET_NAME)
        records = sheet.get_all_records()
        if not records:
            return pd.DataFrame(columns=['Date', 'Type', 'Mode', 'Category', 'Amount', 'Notes'])
        df = pd.DataFrame(records)
        df = ensure_datetime(df)
        return df
    except Exception as e:
        st.warning(f"Could not load from Google Sheets: {str(e)}")
        return load_transactions_from_csv()

def save_transactions_to_sheets(df: pd.DataFrame) -> bool:
    try:
        client = get_google_sheets_client()
        if not client:
            return False
        df = ensure_datetime(df).copy()
        sheet = client.open(SHEET_NAME).worksheet(WORKSHEET_NAME)
        sheet.clear()
        headers = ['Date', 'Type', 'Mode', 'Category', 'Amount', 'Notes']
        sheet.append_row(headers)
        for _, row in df.iterrows():
            sheet.append_row([
                row['Date'].strftime('%Y-%m-%d') if pd.notna(row['Date']) else '',
                row.get('Type', ''),
                row.get('Mode', ''),
                row.get('Category', ''),
                float(row.get('Amount', 0)) if pd.notna(row.get('Amount', 0)) else 0,
                row.get('Notes', '')
            ])
        return True
    except Exception as e:
        st.error(f"Could not save to Google Sheets: {str(e)}")
        return False

def load_transactions_from_csv():
    if os.path.exists("transactions.csv"):
        df = pd.read_csv("transactions.csv")
        return ensure_datetime(df)
    else:
        return pd.DataFrame(columns=['Date', 'Type', 'Mode', 'Category', 'Amount', 'Notes'])

def save_transactions_to_csv(df):
    ensure_datetime(df).to_csv("transactions.csv", index=False)

def load_transactions():
    return load_transactions_from_sheets()

def save_transactions(df):
    if not save_transactions_to_sheets(df):
        save_transactions_to_csv(df)
        st.warning("Saved to local file. Google Sheets not available.")

def add_transaction(date, transaction_type, mode, category, amount, notes):
    df = load_transactions()
    new_transaction = pd.DataFrame({
        'Date': [date], 'Type': [transaction_type], 'Mode': [mode],
        'Category': [category], 'Amount': [amount], 'Notes': [notes]
    })
    df = pd.concat([df, new_transaction], ignore_index=True)
    save_transactions(df)
    return df

def get_monthly_data(df, year, month):
    df = ensure_datetime(df).dropna(subset=['Date'])
    return df[(df['Date'].dt.year == year) & (df['Date'].dt.month == month)]

def calculate_summary(df):
    income = df[df['Type'] == 'Income']['Amount'].sum()
    expenses = df[df['Type'] == 'Expense']['Amount'].sum()
    balance = income - expenses
    return income, expenses, balance

def get_category_icon(category):
    icons = {
        'Food': '\U0001F37D\uFE0F', 'Rent': '🏠', 'Utilities': '⚡', 'Transportation': '🚗',
        'Entertainment': '🎬', 'Healthcare': '🏥', 'Shopping': '🛍️', 'Savings': '💰',
        'Education': '📚', 'Other Expense': '📝', 'Salary': '💼', 'Freelance': '💻',
        'Investment': '📈', 'Business': '🏢', 'Other Income': '💵'
    }
    return icons.get(category, '📝')

def main():
    sheets_connected = bool(get_google_sheets_client())
    status_class = "status-online" if sheets_connected else "status-offline"
    status_text = "Google Sheets" if sheets_connected else "Local Storage"
    st.markdown(f"""
    <div class=\"custom-header\"> <div class=\"header-content\">
    <h1 class=\"app-title\">Finance Tracker</h1>
    <div style=\"color:#888;font-size:0.9rem;\"><span class=\"status-indicator {status_class}\"></span>{status_text}</div>
    </div></div>
    """, unsafe_allow_html=True)

    df = load_transactions()
    current_date = datetime.now()
    monthly_df = get_monthly_data(df, current_date.year, current_date.month)
    income, expenses, balance = calculate_summary(monthly_df)
    st.markdown(f"""
    <div class=\"balance-display\"><p class=\"balance-label\">Balance</p><h1 class=\"balance-amount\">${balance:,.2f}</h1></div>
    """, unsafe_allow_html=True)

    tab1, tab2 = st.tabs(["➕ Add", "📊 History"])
    with tab1:
        col1, col2 = st.columns(2)
        with col1:
            expense_selected = st.button("Expense", key="expense_btn", use_container_width=True)
        with col2:
            income_selected = st.button("Income", key="income_btn", use_container_width=True)
        if income_selected:
            transaction_type = "Income"
            categories = ["Salary", "Freelance", "Investment", "Business", "Other Income"]
        else:
            transaction_type = "Expense"
            categories = ["Food", "Rent", "Utilities", "Transportation", "Entertainment", "Healthcare", "Shopping", "Savings", "Education", "Other Expense"]
        amount = st.number_input("Amount ($)", min_value=0.01, step=0.01, format="%.2f", key="amount_input")
        st.write("**Category**")
        cols = st.columns(2)
        selected_category = st.session_state.get('selected_category')
        for i, category in enumerate(categories):
            with cols[i % 2]:
                if st.button(f"{get_category_icon(category)} {category}", key=f"cat_{category}", use_container_width=True):
                    selected_category = category
                    st.session_state['selected_category'] = category
        col1, col2 = st.columns(2)
        with col1:
            transaction_date = st.date_input("Date", value=current_date, key="date_input")
        with col2:
            mode = st.selectbox("Mode", ["Cash", "Card", "UPI", "Bank Transfer"], key="mode_input")
        notes = st.text_input("Notes (optional)", placeholder="Add a note...", key="notes_input")
        if st.button("Add Transaction", type="primary", use_container_width=True):
            if amount > 0 and selected_category:
                add_transaction(transaction_date, transaction_type, mode, selected_category, amount, notes)
                st.success("✅ Transaction added!")
                st.rerun()
            elif amount <= 0:
                st.error("Please enter a valid amount")
            else:
                st.error("Please select a category")

    with tab2:
        st.write("**Recent Transactions**")
        if monthly_df.empty:
            st.info("No transactions this month")
        else:
            recent_df = monthly_df.sort_values('Date', ascending=False).head(10)
            for _, row in recent_df.iterrows():
                amount_class = "amount-income" if row['Type'] == 'Income' else "amount-expense"
                amount_sign = "+" if row['Type'] == 'Income' else "-"
                st.markdown(f"""
                <div class=\"transaction-item\">
                    <div class=\"transaction-left\">
                        <div class=\"transaction-icon\" style=\"background: {'#00ff88' if row['Type']=='Income' else '#ff4444'};\">{get_category_icon(row['Category'])}</div>
                        <div class=\"transaction-details\"><h4>{row['Category']}</h4><p>{pd.to_datetime(row['Date']).strftime('%b %d') if pd.notna(row['Date']) else ''} • {row.get('Mode','')}</p></div>
                    </div>
                    <div class=\"transaction-amount {amount_class}\">{amount_sign}${row['Amount']:,.2f}</div>
                </div>
                """, unsafe_allow_html=True)
        if not monthly_df.empty:
            st.write("**Monthly Summary**")
            col1, col2, col3 = st.columns(3)
            with col1: st.metric("Income", f"${income:,.0f}")
            with col2: st.metric("Expenses", f"${expenses:,.0f}")
            with col3: st.metric("Balance", f"${balance:,.0f}")

if __name__ == "__main__":
    main()
