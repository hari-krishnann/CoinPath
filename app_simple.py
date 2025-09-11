import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime, date
import os
import base64

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
    /* Import Google Fonts */
    @import url('https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap');
    
    /* Global styles */
    .main > div {
        padding: 0 !important;
        max-width: 100% !important;
    }
    
    .stApp {
        background: #0a0a0a !important;
        color: white !important;
        font-family: 'Inter', sans-serif !important;
    }
    
    /* Hide Streamlit branding */
    #MainMenu {visibility: hidden;}
    footer {visibility: hidden;}
    header {visibility: hidden;}
    
    /* Custom header */
    .custom-header {
        background: #1a1a1a;
        padding: 1rem;
        border-bottom: 1px solid #333;
        margin-bottom: 1rem;
    }
    
    .header-content {
        display: flex;
        justify-content: space-between;
        align-items: center;
        max-width: 400px;
        margin: 0 auto;
    }
    
    .app-title {
        font-size: 1.2rem;
        font-weight: 600;
        color: white;
        margin: 0;
    }
    
    .balance-display {
        text-align: center;
        padding: 1rem;
        background: #1a1a1a;
        border-radius: 12px;
        margin: 1rem auto;
        max-width: 400px;
    }
    
    .balance-amount {
        font-size: 2.5rem;
        font-weight: 700;
        color: #00ff88;
        margin: 0;
    }
    
    .balance-label {
        font-size: 0.9rem;
        color: #888;
        margin: 0;
    }
    
    /* Transaction type selector */
    .transaction-type {
        display: flex;
        background: #1a1a1a;
        border-radius: 12px;
        padding: 4px;
        margin: 1rem auto;
        max-width: 400px;
    }
    
    .type-button {
        flex: 1;
        padding: 12px;
        text-align: center;
        border-radius: 8px;
        font-weight: 500;
        cursor: pointer;
        transition: all 0.2s;
        border: none;
        background: transparent;
        color: #888;
    }
    
    .type-button.active {
        background: #333;
        color: white;
    }
    
    /* Amount input */
    .amount-container {
        text-align: center;
        padding: 2rem 1rem;
        background: #1a1a1a;
        border-radius: 12px;
        margin: 1rem auto;
        max-width: 400px;
    }
    
    .amount-display {
        font-size: 3rem;
        font-weight: 700;
        color: white;
        margin: 0;
        font-family: 'Inter', monospace;
    }
    
    /* Category selector */
    .category-grid {
        display: grid;
        grid-template-columns: repeat(2, 1fr);
        gap: 8px;
        margin: 1rem auto;
        max-width: 400px;
    }
    
    .category-button {
        padding: 16px 12px;
        background: #1a1a1a;
        border: 1px solid #333;
        border-radius: 8px;
        color: white;
        font-size: 0.9rem;
        cursor: pointer;
        transition: all 0.2s;
    }
    
    .category-button:hover {
        background: #333;
    }
    
    .category-button.selected {
        background: #00ff88;
        color: #000;
        border-color: #00ff88;
    }
    
    /* Action buttons */
    .action-buttons {
        display: flex;
        gap: 12px;
        margin: 2rem auto;
        max-width: 400px;
    }
    
    .btn-primary {
        flex: 1;
        padding: 16px;
        background: #00ff88;
        color: #000;
        border: none;
        border-radius: 12px;
        font-weight: 600;
        font-size: 1rem;
        cursor: pointer;
        transition: all 0.2s;
    }
    
    .btn-primary:hover {
        background: #00cc6a;
    }
    
    .btn-secondary {
        flex: 1;
        padding: 16px;
        background: #333;
        color: white;
        border: none;
        border-radius: 12px;
        font-weight: 600;
        font-size: 1rem;
        cursor: pointer;
        transition: all 0.2s;
    }
    
    .btn-secondary:hover {
        background: #444;
    }
    
    /* Recent transactions */
    .transaction-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px 16px;
        background: #1a1a1a;
        border-radius: 8px;
        margin: 8px auto;
        max-width: 400px;
    }
    
    .transaction-left {
        display: flex;
        align-items: center;
        gap: 12px;
    }
    
    .transaction-icon {
        width: 40px;
        height: 40px;
        border-radius: 8px;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.2rem;
    }
    
    .transaction-details h4 {
        margin: 0;
        font-size: 0.9rem;
        font-weight: 500;
    }
    
    .transaction-details p {
        margin: 0;
        font-size: 0.8rem;
        color: #888;
    }
    
    .transaction-amount {
        font-weight: 600;
        font-size: 1rem;
    }
    
    .amount-income {
        color: #00ff88;
    }
    
    .amount-expense {
        color: #ff4444;
    }
    
    /* Mobile optimizations */
    @media (max-width: 768px) {
        .main > div {
            padding: 0 !important;
        }
        
        .amount-display {
            font-size: 2.5rem;
        }
        
        .balance-amount {
            font-size: 2rem;
        }
    }
    
    /* Hide Streamlit elements */
    .stSelectbox > div > div {
        background: #1a1a1a !important;
        border: 1px solid #333 !important;
    }
    
    .stNumberInput > div > div > input {
        background: #1a1a1a !important;
        border: 1px solid #333 !important;
        color: white !important;
    }
    
    .stDateInput > div > div > input {
        background: #1a1a1a !important;
        border: 1px solid #333 !important;
        color: white !important;
    }
</style>
""", unsafe_allow_html=True)

# File path for storing transactions
TRANSACTIONS_FILE = "transactions.csv"

def load_transactions():
    """Load transactions from CSV file"""
    if os.path.exists(TRANSACTIONS_FILE):
        df = pd.read_csv(TRANSACTIONS_FILE)
        df['Date'] = pd.to_datetime(df['Date'])
        return df
    else:
        return pd.DataFrame(columns=['Date', 'Type', 'Mode', 'Category', 'Amount', 'Notes'])

def save_transactions(df):
    """Save transactions to CSV file"""
    df.to_csv(TRANSACTIONS_FILE, index=False)

def add_transaction(date, transaction_type, mode, category, amount, notes):
    """Add a new transaction"""
    df = load_transactions()
    new_transaction = pd.DataFrame({
        'Date': [date],
        'Type': [transaction_type],
        'Mode': [mode],
        'Category': [category],
        'Amount': [amount],
        'Notes': [notes]
    })
    df = pd.concat([df, new_transaction], ignore_index=True)
    save_transactions(df)
    return df

def get_monthly_data(df, year, month):
    """Filter transactions for a specific month"""
    return df[(df['Date'].dt.year == year) & (df['Date'].dt.month == month)]

def calculate_summary(df):
    """Calculate summary statistics"""
    income = df[df['Type'] == 'Income']['Amount'].sum()
    expenses = df[df['Type'] == 'Expense']['Amount'].sum()
    balance = income - expenses
    return income, expenses, balance

def get_category_icon(category):
    """Get emoji icon for category"""
    icons = {
        'Food': '🍽️',
        'Rent': '🏠',
        'Utilities': '⚡',
        'Transportation': '🚗',
        'Entertainment': '🎬',
        'Healthcare': '🏥',
        'Shopping': '🛍️',
        'Savings': '💰',
        'Education': '📚',
        'Other Expense': '📝',
        'Salary': '💼',
        'Freelance': '💻',
        'Investment': '📈',
        'Business': '🏢',
        'Other Income': '💵'
    }
    return icons.get(category, '📝')

def main():
    # Custom header
    st.markdown("""
    <div class="custom-header">
        <div class="header-content">
            <h1 class="app-title">Finance Tracker</h1>
            <div style="color: #888; font-size: 0.9rem;">{}</div>
        </div>
    </div>
    """.format(datetime.now().strftime("%b %d")), unsafe_allow_html=True)
    
    # Load transactions
    df = load_transactions()
    
    # Calculate current month balance
    current_date = datetime.now()
    monthly_df = get_monthly_data(df, current_date.year, current_date.month)
    income, expenses, balance = calculate_summary(monthly_df)
    
    # Balance display
    st.markdown(f"""
    <div class="balance-display">
        <p class="balance-label">Balance</p>
        <h1 class="balance-amount">${balance:,.2f}</h1>
    </div>
    """, unsafe_allow_html=True)
    
    # Main tabs
    tab1, tab2 = st.tabs(["➕ Add", "📊 History"])
    
    with tab1:
        # Transaction type selector
        col1, col2 = st.columns(2)
        with col1:
            expense_selected = st.button("Expense", key="expense_btn", use_container_width=True)
        with col2:
            income_selected = st.button("Income", key="income_btn", use_container_width=True)
        
        # Determine transaction type
        if income_selected:
            transaction_type = "Income"
            categories = ["Salary", "Freelance", "Investment", "Business", "Other Income"]
        else:
            transaction_type = "Expense"
            categories = ["Food", "Rent", "Utilities", "Transportation", "Entertainment", "Healthcare", "Shopping", "Savings", "Education", "Other Expense"]
        
        # Amount input
        amount = st.number_input(
            "Amount ($)",
            min_value=0.01,
            step=0.01,
            format="%.2f",
            key="amount_input",
            help="Enter the transaction amount"
        )
        
        # Category selection
        st.write("**Category**")
        cols = st.columns(2)
        selected_category = None
        
        for i, category in enumerate(categories):
            with cols[i % 2]:
                if st.button(f"{get_category_icon(category)} {category}", key=f"cat_{category}", use_container_width=True):
                    selected_category = category
        
        # Date and notes
        col1, col2 = st.columns(2)
        with col1:
            transaction_date = st.date_input("Date", value=current_date, key="date_input")
        with col2:
            mode = st.selectbox("Mode", ["Cash", "Card", "UPI", "Bank Transfer"], key="mode_input")
        
        notes = st.text_input("Notes (optional)", placeholder="Add a note...", key="notes_input")
        
        # Add transaction button
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
        # Recent transactions
        st.write("**Recent Transactions**")
        
        if monthly_df.empty:
            st.info("No transactions this month")
        else:
            # Show last 10 transactions
            recent_df = monthly_df.sort_values('Date', ascending=False).head(10)
            
            for _, row in recent_df.iterrows():
                amount_class = "amount-income" if row['Type'] == 'Income' else "amount-expense"
                amount_sign = "+" if row['Type'] == 'Income' else "-"
                
                st.markdown(f"""
                <div class="transaction-item">
                    <div class="transaction-left">
                        <div class="transaction-icon" style="background: {'#00ff88' if row['Type'] == 'Income' else '#ff4444'};">
                            {get_category_icon(row['Category'])}
                        </div>
                        <div class="transaction-details">
                            <h4>{row['Category']}</h4>
                            <p>{row['Date'].strftime('%b %d')} • {row['Mode']}</p>
                        </div>
                    </div>
                    <div class="transaction-amount {amount_class}">
                        {amount_sign}${row['Amount']:,.2f}
                    </div>
                </div>
                """, unsafe_allow_html=True)
        
        # Monthly summary
        if not monthly_df.empty:
            st.write("**Monthly Summary**")
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.metric("Income", f"${income:,.0f}")
            with col2:
                st.metric("Expenses", f"${expenses:,.0f}")
            with col3:
                st.metric("Balance", f"${balance:,.0f}")

if __name__ == "__main__":
    main()
