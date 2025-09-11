import os
import json
from datetime import datetime

import pandas as pd
import streamlit as st

import gspread
from google.oauth2.service_account import Credentials

# ---------- Page config ----------
st.set_page_config(page_title="Coin Path", page_icon="💰", layout="centered")

# ---------- Constants ----------
SHEET_NAME = "Coin Path"          # Spreadsheet name
WORKSHEET_NAME = "Transactions"   # Tab name inside the spreadsheet
CSV_FALLBACK = "transactions.csv"  # Local fallback

INCOME_CATEGORIES = ["Salary", "Freelance", "Investment", "Business", "Other Income"]
EXPENSE_CATEGORIES = [
    "Food", "Rent", "Utilities", "Transportation", "Entertainment",
    "Healthcare", "Shopping", "Savings", "Education", "Other Expense",
]
MODES = ["Cash", "Card", "UPI", "Bank Transfer", "Cheque"]

# ---------- Helpers ----------
@st.cache_data(show_spinner=False)
def _parse_google_secrets(raw):
    """Accept dict or TOML triple-quoted JSON string and return dict or raise."""
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        return json.loads(raw)
    raise ValueError("google_credentials must be dict or JSON string")

@st.cache_resource(show_spinner=False)
def get_sheets_client():
    """Return an authorized gspread client or None if not configured."""
    try:
        creds_raw = st.secrets.get("google_credentials")
        if not creds_raw:
            return None
        creds_info = _parse_google_secrets(creds_raw)
        creds = Credentials.from_service_account_info(
            creds_info,
            scopes=[
                "https://www.googleapis.com/auth/spreadsheets",
                "https://www.googleapis.com/auth/drive",
            ],
        )
        return gspread.authorize(creds)
    except Exception as e:
        st.session_state.setdefault("_conn_error", str(e))
        return None

def get_worksheet(client: gspread.Client):
    """Open spreadsheet and return a worksheet handle; create if missing."""
    # Allow opening by explicit sheet ID to avoid Drive listing scope issues
    sheet_id = st.secrets.get("sheet_id") or os.environ.get("SHEET_ID")
    try:
        if sheet_id:
            sh = client.open_by_key(sheet_id)
        else:
            sh = client.open(SHEET_NAME)
    except gspread.SpreadsheetNotFound:
        # If the spreadsheet itself doesn't exist, raise a helpful error
        raise RuntimeError(
            f"Spreadsheet '{SHEET_NAME}' not found. Create it (or set secret 'sheet_id' with the Sheet ID) and share with the service account."
        )

    try:
        ws = sh.worksheet(WORKSHEET_NAME)
    except gspread.WorksheetNotFound:
        ws = sh.add_worksheet(title=WORKSHEET_NAME, rows=1000, cols=6)
        ws.append_row(["Date", "Type", "Mode", "Category", "Amount", "Notes"])  # headers
    return ws

def ensure_datetime(df: pd.DataFrame) -> pd.DataFrame:
    if "Date" in df.columns:
        df["Date"] = pd.to_datetime(df["Date"], errors="coerce")
    return df

def load_df() -> pd.DataFrame:
    client = get_sheets_client()
    if client is None:
        # fallback to CSV
        if os.path.exists(CSV_FALLBACK):
            return ensure_datetime(pd.read_csv(CSV_FALLBACK))
        return pd.DataFrame(columns=["Date", "Type", "Mode", "Category", "Amount", "Notes"])

    try:
        ws = get_worksheet(client)
        records = ws.get_all_records()
        if not records:
            return pd.DataFrame(columns=["Date", "Type", "Mode", "Category", "Amount", "Notes"])
        return ensure_datetime(pd.DataFrame(records))
    except Exception as e:
        st.session_state.setdefault("_load_error", str(e))
        if os.path.exists(CSV_FALLBACK):
            return ensure_datetime(pd.read_csv(CSV_FALLBACK))
        return pd.DataFrame(columns=["Date", "Type", "Mode", "Category", "Amount", "Notes"])

def append_row(date_value, row_type, mode, category, amount, notes) -> bool:
    """Append one transaction to Sheets or CSV fallback. Returns True on success."""
    client = get_sheets_client()
    if client is None:
        # CSV fallback
        df = load_df()
        new_row = pd.DataFrame({
            "Date": [date_value],
            "Type": [row_type],
            "Mode": [mode],
            "Category": [category],
            "Amount": [amount],
            "Notes": [notes],
        })
        df = pd.concat([df, new_row], ignore_index=True)
        ensure_datetime(df).to_csv(CSV_FALLBACK, index=False)
        return True

    try:
        ws = get_worksheet(client)
        # Ensure headers exist (row 1)
        values = [
            date_value.strftime("%Y-%m-%d") if hasattr(date_value, "strftime") else str(date_value),
            row_type,
            mode,
            category,
            float(amount),
            notes or "",
        ]
        ws.append_row(values)
        return True
    except Exception as e:
        st.session_state.setdefault("_append_error", str(e))
        return False

# ---------- UI ----------
# Connection pill
client_ok = get_sheets_client() is not None
status_dot = "🟢" if client_ok else "🔴"
status_text = "Google Sheets" if client_ok else "Local CSV"
st.markdown(f"**Connection:** {status_dot} {status_text}")
if not client_ok and st.session_state.get("_conn_error"):
    st.caption(f"Note: {st.session_state['_conn_error']}")

# ---------- Diagnostics ----------
with st.expander("🔍 Connection diagnostics", expanded=not client_ok):
    creds_raw = st.secrets.get("google_credentials")
    sa_email = None
    try:
        if isinstance(creds_raw, str):
            sa_email = json.loads(creds_raw).get("client_email")
        elif isinstance(creds_raw, dict):
            sa_email = creds_raw.get("client_email")
    except Exception:
        pass
    st.write("- **Service account email**:", sa_email or "(missing)")
    st.write("- **Spreadsheet**:", SHEET_NAME)
    st.write("- **Worksheet**:", WORKSHEET_NAME)

    if st.button("Run diagnostics"):
        client = get_sheets_client()
        if client is None:
            st.error("No Google Sheets client. Check secrets format and API access.")
        else:
            try:
                sh = client.open(SHEET_NAME)
                st.success("Opened spreadsheet successfully")
                try:
                    ws = sh.worksheet(WORKSHEET_NAME)
                    st.success("Found worksheet successfully")
                except gspread.WorksheetNotFound:
                    ws = sh.add_worksheet(title=WORKSHEET_NAME, rows=1000, cols=6)
                    ws.append_row(["Date", "Type", "Mode", "Category", "Amount", "Notes"])  # headers
                    st.warning("Worksheet was missing; created it and added headers.")
                try:
                    _ = ws.row_count
                    st.success("Worksheet is readable")
                except Exception as e:
                    st.error(f"Read test failed: {e}")
            except Exception as e:
                st.error(f"Open spreadsheet failed: {e}")

st.title("Coin Path")
st.caption("Simple personal finance tracker")

# Entry form (reliable, single-submit)
with st.form("entry_form", clear_on_submit=True):
    col1, col2 = st.columns(2)
    with col1:
        trx_type = st.radio("Type", ["Expense", "Income"], horizontal=True)
        amount = st.number_input("Amount ($)", min_value=0.01, step=0.01, format="%.2f")
        category = st.selectbox(
            "Category",
            INCOME_CATEGORIES if trx_type == "Income" else EXPENSE_CATEGORIES,
        )
    with col2:
        trx_date = st.date_input("Date", value=datetime.now())
        mode = st.selectbox("Mode", MODES)
        notes = st.text_input("Notes (optional)")

    submitted = st.form_submit_button("Add Transaction")

if submitted:
    ok = append_row(trx_date, trx_type, mode, category, amount, notes)
    if ok:
        st.success("Transaction added")
        st.cache_data.clear()  # clear cached secrets parsing
    else:
        st.error(st.session_state.get("_append_error") or "Could not save. Check connection and sharing permissions.")

# Dashboard for current month
df = load_df()
now = datetime.now()
if not df.empty:
    df = ensure_datetime(df).dropna(subset=["Date"])  # safety
    m_df = df[(df["Date"].dt.year == now.year) & (df["Date"].dt.month == now.month)]
    income = float(m_df[m_df["Type"] == "Income"]["Amount"].sum())
    expense = float(m_df[m_df["Type"] == "Expense"]["Amount"].sum())
    balance = income - expense

    c1, c2, c3 = st.columns(3)
    c1.metric("Income", f"${income:,.2f}")
    c2.metric("Expenses", f"${expense:,.2f}")
    c3.metric("Balance", f"${balance:,.2f}")

    st.subheader("Recent Transactions")
    st.dataframe(
        m_df.sort_values("Date", ascending=False).head(20)[
            ["Date", "Type", "Mode", "Category", "Amount", "Notes"]
        ],
        use_container_width=True,
        hide_index=True,
    )
else:
    st.info("No data yet. Add your first transaction above.")

# Export
st.download_button(
    "Export all as CSV",
    (ensure_datetime(df) if not df.empty else pd.DataFrame()).to_csv(index=False),
    file_name=f"coinpath_all_{now.strftime('%Y%m%d')}.csv",
    mime="text/csv",
)
