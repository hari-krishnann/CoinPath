import streamlit as st
import pandas as pd
import plotly.graph_objects as go
from datetime import datetime, date
import os

# Page configuration
st.set_page_config(
    page_title="Personal Finance Tracker",
    page_icon="💰",
    layout="wide"
)

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

def main():
    st.title("💰 Personal Finance Tracker")
    
    # Sidebar for month selection
    st.sidebar.header("📅 Select Month")
    
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
    tab1, tab2, tab3 = st.tabs(["📝 Add Transaction", "📊 Dashboard", "📈 Monthly Report"])
    
    with tab1:
        st.header("Add New Transaction")
        
        with st.form("transaction_form"):
            col1, col2 = st.columns(2)
            
            with col1:
                transaction_date = st.date_input("Date", value=current_date)
                transaction_type = st.selectbox("Type", ["Income", "Expense"])
                mode = st.selectbox("Mode", ["Cash", "Cheque"])
            
            with col2:
                if transaction_type == "Income":
                    category = st.selectbox("Category", ["Salary", "Freelance", "Investment", "Other Income"])
                else:
                    category = st.selectbox("Category", ["Food", "Rent", "Utilities", "Transportation", "Entertainment", "Healthcare", "Shopping", "Savings", "Other Expense"])
                
                amount = st.number_input("Amount", min_value=0.01, step=0.01, format="%.2f")
                notes = st.text_area("Notes (Optional)", placeholder="Add any additional notes...")
            
            submitted = st.form_submit_button("Add Transaction")
            
            if submitted:
                if amount > 0:
                    add_transaction(transaction_date, transaction_type, mode, category, amount, notes)
                    st.success("Transaction added successfully!")
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
                    label="�� Total Income",
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
            
            if st.button("Export Monthly Transactions as CSV"):
                # Prepare data for export
                export_df = monthly_df.copy()
                export_df['Date'] = export_df['Date'].dt.strftime('%Y-%m-%d')
                
                # Create CSV
                csv = export_df.to_csv(index=False)
                
                # Download button
                st.download_button(
                    label="Download CSV",
                    data=csv,
                    file_name=f"transactions_{selected_year}_{selected_month:02d}.csv",
                    mime="text/csv"
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

if __name__ == "__main__":
    main()
