import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime, date
import os
import json
import base64
from io import StringIO

# Page configuration for PWA
st.set_page_config(
    page_title="Personal Finance Tracker",
    page_icon="💰",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Add PWA meta tags
st.markdown("""
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="theme-color" content="#ff6b6b">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="default">
<meta name="apple-mobile-web-app-title" content="Finance Tracker">
<link rel="manifest" href="manifest.json">
""", unsafe_allow_html=True)

# File path for storing transactions
TRANSACTIONS_FILE = "transactions.csv"

def load_transactions():
    """Load transactions from CSV file or session state"""
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

def create_sankey_diagram(df):
    """Create Sankey diagram for money flow visualization"""
    if df.empty:
        return go.Figure()
    
    # Prepare data for Sankey
    income_df = df[df['Type'] == 'Income']
    expense_df = df[df['Type'] == 'Expense']
    
    # Get unique sources and targets
    income_sources = income_df['Category'].unique()
    expense_categories = expense_df['Category'].unique()
    
    # Create node labels
    nodes = list(income_sources) + ['Total Income'] + list(expense_categories)
    node_indices = {node: i for i, node in enumerate(nodes)}
    
    # Create links
    sources = []
    targets = []
    values = []
    colors = []
    
    # Income sources to Total Income
    for source in income_sources:
        amount = income_df[income_df['Category'] == source]['Amount'].sum()
        if amount > 0:
            sources.append(node_indices[source])
            targets.append(node_indices['Total Income'])
            values.append(amount)
            colors.append('rgba(0, 255, 0, 0.6)')  # Green for income
    
    # Total Income to Expense categories
    total_income = income_df['Amount'].sum()
    for target in expense_categories:
        amount = expense_df[expense_df['Category'] == target]['Amount'].sum()
        if amount > 0:
            sources.append(node_indices['Total Income'])
            targets.append(node_indices[target])
            values.append(amount)
            colors.append('rgba(255, 0, 0, 0.6)')  # Red for expenses
    
    # Create Sankey diagram
    fig = go.Figure(data=[go.Sankey(
        node=dict(
            pad=15,
            thickness=20,
            line=dict(color="black", width=0.5),
            label=nodes,
            color="lightblue"
        ),
        link=dict(
            source=sources,
            target=targets,
            value=values,
            color=colors
        )
    )])
    
    fig.update_layout(
        title_text="Money Flow Visualization",
        font_size=12,
        height=600
    )
    
    return fig

def export_data(df):
    """Export data as CSV"""
    csv = df.to_csv(index=False)
    b64 = base64.b64encode(csv.encode()).decode()
    return b64

def main():
    # Custom CSS for mobile optimization
    st.markdown("""
    <style>
    .main > div {
        padding-top: 2rem;
    }
    .stSelectbox > div > div {
        background-color: white;
    }
    .stNumberInput > div > div > input {
        background-color: white;
    }
    .stTextArea > div > div > textarea {
        background-color: white;
    }
    .stDateInput > div > div > input {
        background-color: white;
    }
    @media (max-width: 768px) {
        .main > div {
            padding-left: 1rem;
            padding-right: 1rem;
        }
        .stTabs [data-baseweb="tab-list"] {
            gap: 0.5rem;
        }
        .stTabs [data-baseweb="tab"] {
            height: 2.5rem;
            padding-left: 1rem;
            padding-right: 1rem;
        }
    }
    </style>
    """, unsafe_allow_html=True)
    
    st.title("💰 Personal Finance Tracker")
    st.markdown("*Track your finances anywhere, anytime*")
    
    # Sidebar for month selection
    st.sidebar.header("�� Select Month")
    
    # Get current date for default selection
    current_date = datetime.now()
    selected_year = st.sidebar.selectbox(
        "Year",
        range(2020, current_date.year + 2),
        index=current_date.year - 2020
    )
    selected_month = st.sidebar.selectbox(
        "Month",
        range(1, 13),
        index=current_date.month - 1,
        format_func=lambda x: datetime(2023, x, 1).strftime('%B')
    )
    
    # Load transactions
    df = load_transactions()
    
    # Main content tabs
    tab1, tab2, tab3, tab4 = st.tabs(["📝 Add Transaction", "📊 Dashboard", "📈 Monthly Report", "☁️ Cloud Sync"])
    
    with tab1:
        st.header("Add New Transaction")
        
        with st.form("transaction_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                transaction_date = st.date_input("Date", value=current_date)
                transaction_type = st.selectbox("Type", ["Income", "Expense"])
                mode = st.selectbox("Mode", ["Cash", "Cheque", "Card", "UPI", "Bank Transfer"])
            
            with col2:
                if transaction_type == "Income":
                    category = st.selectbox("Category", ["Salary", "Freelance", "Investment", "Business", "Other Income"])
                else:
                    category = st.selectbox("Category", ["Food", "Rent", "Utilities", "Transportation", "Entertainment", "Healthcare", "Shopping", "Savings", "Education", "Other Expense"])
                
                amount = st.number_input("Amount (₹)", min_value=0.01, step=0.01, format="%.2f")
                notes = st.text_area("Notes (Optional)", placeholder="Add any additional notes...")
            
            submitted = st.form_submit_button("Add Transaction", use_container_width=True)
            
            if submitted:
                if amount > 0:
                    add_transaction(transaction_date, transaction_type, mode, category, amount, notes)
                    st.success("✅ Transaction added successfully!")
                    st.rerun()
                else:
                    st.error("Please enter a valid amount greater than 0.")
    
    with tab2:
        st.header("📊 Monthly Dashboard")
        
        # Filter data for selected month
        monthly_df = get_monthly_data(df, selected_year, selected_month)
        
        if monthly_df.empty:
            st.info(f"No transactions found for {datetime(selected_year, selected_month, 1).strftime('%B %Y')}")
        else:
            # Calculate summary
            income, expenses, balance = calculate_summary(monthly_df)
            
            # Display summary cards
            col1, col2, col3 = st.columns(3)
            
            with col1:
                st.metric(
                    label="💰 Total Income",
                    value=f"₹{income:,.2f}",
                    delta=None
                )
            
            with col2:
                st.metric(
                    label="💸 Total Expenses",
                    value=f"₹{expenses:,.2f}",
                    delta=None
                )
            
            with col3:
                balance_color = "normal" if balance >= 0 else "inverse"
                st.metric(
                    label="⚖️ Balance",
                    value=f"₹{balance:,.2f}",
                    delta=None
                )
            
            # Show recent transactions
            st.subheader("Recent Transactions")
            display_df = monthly_df.sort_values('Date', ascending=False)
            st.dataframe(
                display_df[['Date', 'Type', 'Category', 'Amount', 'Notes']],
                use_container_width=True
            )
    
    with tab3:
        st.header("📈 Monthly Report")
        
        # Filter data for selected month
        monthly_df = get_monthly_data(df, selected_year, selected_month)
        
        if monthly_df.empty:
            st.info(f"No transactions found for {datetime(selected_year, selected_month, 1).strftime('%B %Y')}")
        else:
            # Create and display Sankey diagram
            sankey_fig = create_sankey_diagram(monthly_df)
            st.plotly_chart(sankey_fig, use_container_width=True)
            
            # Export button
            st.subheader("📤 Export Data")
            
            if st.button("Export Monthly Transactions as CSV", use_container_width=True):
                # Prepare data for export
                export_df = monthly_df.copy()
                export_df['Date'] = export_df['Date'].dt.strftime('%Y-%m-%d')
                
                # Create CSV
                csv_data = export_data(export_df)
                
                # Download button
                st.download_button(
                    label="📥 Download CSV",
                    data=base64.b64decode(csv_data).decode(),
                    file_name=f"transactions_{selected_year}_{selected_month:02d}.csv",
                    mime="text/csv",
                    use_container_width=True
                )
            
            # Show detailed breakdown
            st.subheader("📋 Detailed Breakdown")
            
            col1, col2 = st.columns(2)
            
            with col1:
                st.write("**Income by Category**")
                income_breakdown = monthly_df[monthly_df['Type'] == 'Income'].groupby('Category')['Amount'].sum().sort_values(ascending=False)
                if not income_breakdown.empty:
                    st.bar_chart(income_breakdown)
                else:
                    st.info("No income data for this month")
            
            with col2:
                st.write("**Expenses by Category**")
                expense_breakdown = monthly_df[monthly_df['Type'] == 'Expense'].groupby('Category')['Amount'].sum().sort_values(ascending=False)
                if not expense_breakdown.empty:
                    st.bar_chart(expense_breakdown)
                else:
                    st.info("No expense data for this month")
    
    with tab4:
        st.header("☁️ Cloud Sync & Backup")
        
        st.info("💡 **PWA Features:** This app works offline and can be installed on your phone!")
        
        col1, col2 = st.columns(2)
        
        with col1:
            st.subheader("📤 Export All Data")
            if st.button("Export Complete Dataset", use_container_width=True):
                export_df = df.copy()
                export_df['Date'] = export_df['Date'].dt.strftime('%Y-%m-%d')
                csv_data = export_data(export_df)
                
                st.download_button(
                    label="📥 Download All Transactions",
                    data=base64.b64decode(csv_data).decode(),
                    file_name=f"all_transactions_{datetime.now().strftime('%Y%m%d')}.csv",
                    mime="text/csv",
                    use_container_width=True
                )
        
        with col2:
            st.subheader("📥 Import Data")
            uploaded_file = st.file_uploader("Upload CSV file", type=['csv'], help="Upload a previously exported CSV file")
            
            if uploaded_file is not None:
                try:
                    # Read uploaded file
                    uploaded_df = pd.read_csv(uploaded_file)
                    uploaded_df['Date'] = pd.to_datetime(uploaded_df['Date'])
                    
                    # Merge with existing data
                    combined_df = pd.concat([df, uploaded_df], ignore_index=True)
                    combined_df = combined_df.drop_duplicates()
                    
                    if st.button("Import Data", use_container_width=True):
                        save_transactions(combined_df)
                        st.success("✅ Data imported successfully!")
                        st.rerun()
                        
                except Exception as e:
                    st.error(f"Error importing file: {str(e)}")
        
        st.subheader("📱 Mobile Installation")
        st.markdown("""
        **To install this app on your phone:**
        1. Open this app in your mobile browser
        2. Look for "Add to Home Screen" option
        3. Tap "Add" to install the app
        4. The app will work offline and sync when online!
        """)
        
        st.subheader("🔒 Data Privacy")
        st.markdown("""
        - All data is stored locally on your device
        - No data is sent to external servers
        - Export/Import features for backup
        - Works completely offline
        """)

if __name__ == "__main__":
    main()
