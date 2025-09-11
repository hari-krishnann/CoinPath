import json
import os
from datetime import datetime, date
from typing import Dict, List

import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import streamlit as st

# --------------------- App Config ---------------------
st.set_page_config(page_title="FlowTrack", page_icon="💧", layout="wide")

DATA_FILE = "transactions.csv"
SETTINGS_FILE = "flowtrack_settings.json"
DEFAULT_CURRENCY = "USD"
DEFAULT_CATEGORIES = {
    "Income": ["Salary", "Freelance", "Investments", "Other"],
    "Expense": [
        "Food", "Rent", "Utilities", "Transport", "Entertainment",
        "Healthcare", "Shopping", "Savings", "Education", "Other"
    ],
}

# --------------------- Persistence ---------------------

def load_settings() -> Dict:
    if os.path.exists(SETTINGS_FILE):
        try:
            with open(SETTINGS_FILE, "r") as f:
                return json.load(f)
        except Exception:
            pass
    return {
        "currency": DEFAULT_CURRENCY,
        "budgets": {cat: 0 for cat in DEFAULT_CATEGORIES["Expense"]},
        "recurring": [],  # list of {date(1-28), type, mode, category, amount, notes}
    }

def save_settings(settings: Dict) -> None:
    with open(SETTINGS_FILE, "w") as f:
        json.dump(settings, f, indent=2)


def ensure_df_columns(df: pd.DataFrame) -> pd.DataFrame:
    cols = ["Date", "Type", "Mode", "Category", "Amount", "Notes"]
    for c in cols:
        if c not in df.columns:
            df[c] = None
    df["Date"] = pd.to_datetime(df["Date"], errors="coerce")
    df["Amount"] = pd.to_numeric(df["Amount"], errors="coerce").fillna(0.0)
    return df[cols]


def load_transactions() -> pd.DataFrame:
    if os.path.exists(DATA_FILE):
        df = pd.read_csv(DATA_FILE)
        return ensure_df_columns(df)
    return ensure_df_columns(pd.DataFrame())


def save_transactions(df: pd.DataFrame) -> None:
    ensure_df_columns(df).to_csv(DATA_FILE, index=False)


def add_transaction_row(date_value, ttype, mode, category, amount, notes):
    df = load_transactions()
    new_row = {
        "Date": pd.to_datetime(date_value),
        "Type": ttype,
        "Mode": mode,
        "Category": category,
        "Amount": float(amount),
        "Notes": notes,
    }
    df = pd.concat([df, pd.DataFrame([new_row])], ignore_index=True)
    save_transactions(df)
    return df

# --------------------- Utilities ---------------------

def month_filter(df: pd.DataFrame, year: int, month: int) -> pd.DataFrame:
    if df.empty:
        return df
    df = df.copy()
    df = df.dropna(subset=["Date"])  # safety
    return df[(df["Date"].dt.year == year) & (df["Date"].dt.month == month)]


def format_currency(x: float, currency: str) -> str:
    symbol = "$" if currency == "USD" else ("₹" if currency == "INR" else "$")
    return f"{symbol}{x:,.2f}"

# --------------------- Sidebar ---------------------
settings = load_settings()

st.sidebar.title("FlowTrack")
page = st.sidebar.radio("Navigate", [
    "Dashboard", "Add Transaction", "Reports", "Export Data", "Settings"
])

# Month selection (shared)
now = datetime.now()
sel_year = st.sidebar.selectbox("Year", list(range(now.year - 3, now.year + 2)), index=3)
sel_month = st.sidebar.selectbox("Month", list(range(1, 13)), index=now.month - 1,
                                format_func=lambda m: datetime(2000, m, 1).strftime("%B"))

# --------------------- Dashboard ---------------------
if page == "Dashboard":
    st.header("Dashboard")
    df = load_transactions()
    mdf = month_filter(df, sel_year, sel_month)
    income = float(mdf[mdf["Type"] == "Income"]["Amount"].sum()) if not mdf.empty else 0.0
    expense = float(mdf[mdf["Type"] == "Expense"]["Amount"].sum()) if not mdf.empty else 0.0
    balance = income - expense

    c1, c2, c3 = st.columns(3)
    c1.metric("Total Income", format_currency(income, settings["currency"]))
    c2.metric("Total Expenses", format_currency(expense, settings["currency"]))
    c3.metric("Net Balance", format_currency(balance, settings["currency"]))

    # Budgets progress
    st.subheader("Budgets")
    exp_by_cat = mdf[mdf["Type"] == "Expense"].groupby("Category")["Amount"].sum() if not mdf.empty else pd.Series(dtype=float)
    for cat, limit in settings.get("budgets", {}).items():
        used = float(exp_by_cat.get(cat, 0))
        pct = 0 if limit <= 0 else min(100, int(used / limit * 100))
        color = "#2ecc71" if pct < 70 else ("#f1c40f" if pct < 100 else "#e74c3c")
        st.progress(pct, text=f"{cat}: {format_currency(used, settings['currency'])} / {format_currency(limit, settings['currency'])}")

    # Trend chart
    st.subheader("Income vs Expenses (Daily)")
    if not mdf.empty:
        t = mdf.copy()
        t["DateOnly"] = t["Date"].dt.date
        daily_inc = t[t["Type"] == "Income"].groupby("DateOnly")["Amount"].sum()
        daily_exp = t[t["Type"] == "Expense"].groupby("DateOnly")["Amount"].sum()
        trend = pd.DataFrame({
            "Date": sorted(set(daily_inc.index).union(set(daily_exp.index)))
        })
        trend["Income"] = trend["Date"].map(daily_inc).fillna(0)
        trend["Expense"] = trend["Date"].map(daily_exp).fillna(0)
        fig = px.line(trend, x="Date", y=["Income", "Expense"], markers=True,
                      color_discrete_map={"Income": "#2ecc71", "Expense": "#e74c3c"})
        fig.update_layout(height=360, margin=dict(l=10, r=10, t=10, b=10))
        st.plotly_chart(fig, use_container_width=True)
    else:
        st.info("No data for selected month")

    st.link_button("Quick Add", "#add-transaction", type="primary")

# --------------------- Add Transaction ---------------------
if page == "Add Transaction":
    st.header("Add Transaction")
    df = load_transactions()

    with st.form("add_form", clear_on_submit=True):
        col1, col2, col3 = st.columns(3)
        with col1:
            d = st.date_input("Date", value=date.today())
        with col2:
            ttype = st.radio("Type", ["Income", "Expense"], horizontal=True)
        with col3:
            mode = st.selectbox("Mode", ["Cash", "Cheque", "Card", "Bank Transfer", "UPI"]) 

        cats = DEFAULT_CATEGORIES[ttype]
        category = st.selectbox("Category", cats)
        amount = st.number_input("Amount", min_value=0.01, step=0.01, format="%.2f")
        notes = st.text_area("Notes (optional)")

        submitted = st.form_submit_button("Save", type="primary")

    if submitted:
        add_transaction_row(d, ttype, mode, category, amount, notes)
        st.success("Transaction saved!")

# --------------------- Reports ---------------------
if page == "Reports":
    st.header("Reports")
    df = load_transactions()
    mdf = month_filter(df, sel_year, sel_month)
    if mdf.empty:
        st.info("No data for selected month")
    else:
        # Sankey
        st.subheader("Money Flow (Sankey)")
        inc = mdf[mdf["Type"] == "Income"]
        exp = mdf[mdf["Type"] == "Expense"]
        income_nodes = sorted(inc["Category"].unique()) if not inc.empty else []
        expense_nodes = sorted(exp["Category"].unique()) if not exp.empty else []
        nodes = income_nodes + ["Total Income"] + expense_nodes
        idx = {n: i for i, n in enumerate(nodes)}
        s, t, v, c = [], [], [], []
        for cat in income_nodes:
            val = float(inc.loc[inc["Category"] == cat, "Amount"].sum())
            if val > 0:
                s.append(idx[cat]); t.append(idx["Total Income"]); v.append(val); c.append("rgba(52, 152, 219, 0.7)")
        for cat in expense_nodes:
            val = float(exp.loc[exp["Category"] == cat, "Amount"].sum())
            if val > 0:
                s.append(idx["Total Income"]); t.append(idx[cat]); v.append(val); c.append("rgba(231, 76, 60, 0.7)")
        if v:
            sankey = go.Figure(data=[go.Sankey(
                node=dict(pad=16, thickness=18, label=nodes, color=["#ecf0f1"]*len(nodes), line=dict(color="#bdc3c7", width=1)),
                link=dict(source=s, target=t, value=v, color=c)
            )])
            sankey.update_layout(height=420, margin=dict(l=10, r=10, t=10, b=10))
            st.plotly_chart(sankey, use_container_width=True)
        else:
            st.info("Not enough data to build Sankey")

        colA, colB = st.columns(2)
        with colA:
            st.subheader("Expenses by Category")
            exp_by = exp.groupby("Category")["Amount"].sum().reset_index() if not exp.empty else pd.DataFrame(columns=["Category","Amount"])
            if not exp_by.empty:
                fig_pie = px.pie(exp_by, names="Category", values="Amount", hole=0.5)
                fig_pie.update_layout(height=360, margin=dict(l=10, r=10, t=10, b=10))
                st.plotly_chart(fig_pie, use_container_width=True)
            else:
                st.info("No expenses this month")
        with colB:
            st.subheader("Cumulative Cash Flow")
            t = mdf.copy()
            t["Sign"] = t["Amount"] * t["Type"].map({"Income": 1, "Expense": -1})
            t = t.sort_values("Date")
            t["CumFlow"] = t["Sign"].cumsum()
            fig_line = px.line(t, x="Date", y="CumFlow")
            fig_line.update_layout(height=360, margin=dict(l=10, r=10, t=10, b=10))
            st.plotly_chart(fig_line, use_container_width=True)

        # Insights
        st.subheader("Insights")
        if not exp_by.empty:
            total_exp = exp_by["Amount"].sum()
            top_cat = exp_by.sort_values("Amount", ascending=False).iloc[0]
            pct = (top_cat["Amount"] / total_exp) * 100 if total_exp > 0 else 0
            st.write(f"- {top_cat['Category']} is {pct:.1f}% of your spending this month.")

# --------------------- Export ---------------------
if page == "Export Data":
    st.header("Export Data")
    df = load_transactions()
    mdf = month_filter(df, sel_year, sel_month)
    st.download_button(
        label="Download selected month as CSV",
        data=(mdf.to_csv(index=False) if not mdf.empty else pd.DataFrame().to_csv(index=False)),
        file_name=f"flowtrack_{sel_year}_{sel_month:02d}.csv",
        mime="text/csv",
    )
    st.download_button(
        label="Download all transactions as CSV",
        data=(df.to_csv(index=False) if not df.empty else pd.DataFrame().to_csv(index=False)),
        file_name="flowtrack_all.csv",
        mime="text/csv",
    )

# --------------------- Settings ---------------------
if page == "Settings":
    st.header("Settings")
    with st.form("settings_form"):
        currency = st.selectbox("Default currency", ["USD", "INR", "EUR", "GBP"], index=["USD","INR","EUR","GBP"].index(settings.get("currency","USD")))
        st.subheader("Monthly Budgets")
        budgets = {}
        cols = st.columns(2)
        for i, cat in enumerate(DEFAULT_CATEGORIES["Expense"]):
            with cols[i % 2]:
                budgets[cat] = st.number_input(f"Budget for {cat}", min_value=0.0, step=50.0, value=float(settings.get("budgets", {}).get(cat, 0)))
        st.subheader("Recurring Transactions")
        st.caption("Add fixed entries like rent or salary; day 1–28 of the month")
        rec_day = st.number_input("Day of month", min_value=1, max_value=28, step=1, value=1)
        rec_type = st.radio("Type", ["Income", "Expense"], horizontal=True)
        rec_mode = st.selectbox("Mode", ["Cash", "Cheque", "Card", "Bank Transfer", "UPI"], key="rec_mode")
        rec_cat = st.selectbox("Category", DEFAULT_CATEGORIES[rec_type], key="rec_cat")
        rec_amt = st.number_input("Amount", min_value=0.01, step=0.01, value=1000.0)
        rec_note = st.text_input("Notes")
        add_rec = st.checkbox("Add this recurring item")
        submitted = st.form_submit_button("Save Settings", type="primary")

    if submitted:
        settings["currency"] = currency
        settings["budgets"] = budgets
        if add_rec:
            settings.setdefault("recurring", []).append({
                "day": int(rec_day),
                "type": rec_type,
                "mode": rec_mode,
                "category": rec_cat,
                "amount": float(rec_amt),
                "notes": rec_note,
            })
        save_settings(settings)
        st.success("Settings saved")

# Anchor for quick add
st.markdown("<a id='add-transaction'></a>", unsafe_allow_html=True)
