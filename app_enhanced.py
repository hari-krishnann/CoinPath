import os
import json
from datetime import datetime

import pandas as pd
import streamlit as st

import gspread
from google.oauth2.service_account import Credentials
import plotly.express as px
import plotly.graph_objects as go

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
    if isinstance(raw, dict):
        return raw
    if isinstance(raw, str):
        return json.loads(raw)
    raise ValueError("google_credentials must be dict or JSON string")

@st.cache_resource(show_spinner=False)
def get_sheets_client():
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
    # Allow opening by explicit sheet ID to avoid Drive listing scope issues
    sheet_id = st.secrets.get("sheet_id") or os.environ.get("SHEET_ID")
    try:
        if sheet_id:
            sh = client.open_by_key(sheet_id)
        else:
            sh = client.open(SHEET_NAME)
    except gspread.SpreadsheetNotFound:
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
    client = get_sheets_client()
    if client is None:
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

# ---------- UI: Apple-like minimal styling ----------
st.markdown(
    """
    <style>
      :root { --bg:#0a0a0a; --card:#111; --muted:#8a8a8a; --border:#262626; --accent:#00e59b; }
      .stApp { background: var(--bg); color: #fff; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Inter,'Helvetica Neue',Arial,'Noto Sans',sans-serif; }
      #MainMenu, footer, header {visibility: hidden;}
      .pill {display:inline-flex; align-items:center; gap:.5rem; padding:.35rem .6rem; border:1px solid var(--border); border-radius:999px; background:#0f0f0f; color:#eaeaea; font-size:.85rem;}
      .metric-card {background: var(--card); border:1px solid var(--border); border-radius:16px; padding:12px 14px;}
      .metric-val {font-weight:700; font-size:1.2rem}
      .metric-label {color:var(--muted); font-size:.8rem}
      .section {background: var(--card); border:1px solid var(--border); border-radius:16px; padding:16px;}
      .chips {display:flex; flex-wrap:wrap; gap:8px}
      .chip {padding:8px 12px; border:1px solid var(--border); border-radius:999px; background:#131313; color:#eaeaea; cursor:pointer;}
      .chip.active {background: var(--accent); color:#001b10; border-color: var(--accent)}
      .primary {background: var(--accent); color:#001b10; border:none; border-radius:12px; padding:12px 16px; font-weight:700}
      .ghost {background:#161616; color:#eaeaea; border:1px solid var(--border); border-radius:12px; padding:12px 16px; font-weight:600}
      .title {font-weight:700; font-size:1.1rem}
    </style>
    """,
    unsafe_allow_html=True,
)

# Connection status pill
client_ok = get_sheets_client() is not None
status_dot = "🟢" if client_ok else "🔴"
status_text = "Google Sheets" if client_ok else "Local CSV"
st.markdown(f"<span class='pill'>{status_dot} {status_text}</span>", unsafe_allow_html=True)

st.markdown("<div style='height:6px'></div>", unsafe_allow_html=True)

st.title("Coin Path")
st.caption("Delightfully simple personal finance")

# ---------- Add flow (clean & focused) ----------
with st.container():
    st.markdown("<div class='section'>", unsafe_allow_html=True)
    col_a, col_b = st.columns([1,1])
    with col_a:
        trx_type = st.segmented_control("Type", options=["Expense", "Income"], default="Expense") if hasattr(st, 'segmented_control') else st.radio("Type", ["Expense", "Income"], horizontal=True)
        amount = st.number_input("Amount ($)", min_value=0.01, step=1.00, format="%.2f")
    with col_b:
        trx_date = st.date_input("Date", value=datetime.now())
        mode = st.selectbox("Mode", MODES)

    # Category chips
    st.markdown("<div class='title'>Category</div>", unsafe_allow_html=True)
    cats = INCOME_CATEGORIES if trx_type == "Income" else EXPENSE_CATEGORIES
    if "_active_cat" not in st.session_state:
        st.session_state._active_cat = cats[0]
    chips_cols = st.columns(4)
    for i, c in enumerate(cats):
        with chips_cols[i % 4]:
            active = "active" if st.session_state._active_cat == c else ""
            if st.button(c, key=f"chip_{c}"):
                st.session_state._active_cat = c
            st.markdown(f"<div class='chip {active}'></div>", unsafe_allow_html=True)
    notes = st.text_input("Notes (optional)")
    col_btn1, col_btn2 = st.columns([1,1])
    with col_btn1:
        add_clicked = st.button("Add Transaction", use_container_width=True, type="primary")
    with col_btn2:
        st.button("Export CSV", use_container_width=True, on_click=None)
    st.markdown("</div>", unsafe_allow_html=True)

if 'last_added' not in st.session_state:
    st.session_state.last_added = None

if add_clicked:
    ok = append_row(trx_date, trx_type, mode, st.session_state._active_cat, amount, notes)
    if ok:
        st.session_state.last_added = {
            "Date": trx_date, "Type": trx_type, "Mode": mode,
            "Category": st.session_state._active_cat, "Amount": amount, "Notes": notes
        }
        st.success("Added ✓")
        st.cache_data.clear()
    else:
        st.error(st.session_state.get("_append_error") or "Could not save. Check sharing & secrets.")

# ---------- Overview & Insights ----------
df = load_df()
now = datetime.now()
if not df.empty:
    df = ensure_datetime(df).dropna(subset=["Date"])  # safety
    m_df = df[(df["Date"].dt.year == now.year) & (df["Date"].dt.month == now.month)]
    income = float(m_df[m_df["Type"] == "Income"]["Amount"].sum())
    expense = float(m_df[m_df["Type"] == "Expense"]["Amount"].sum())
    balance = income - expense

    c1, c2, c3 = st.columns(3)
    with c1:
        st.markdown("<div class='metric-card'><div class='metric-label'>Income</div><div class='metric-val'>$%s</div></div>" % f"{income:,.2f}", unsafe_allow_html=True)
    with c2:
        st.markdown("<div class='metric-card'><div class='metric-label'>Expenses</div><div class='metric-val'>$%s</div></div>" % f"{expense:,.2f}", unsafe_allow_html=True)
    with c3:
        st.markdown("<div class='metric-card'><div class='metric-label'>Balance</div><div class='metric-val'>$%s</div></div>" % f"{balance:,.2f}", unsafe_allow_html=True)

    st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)

    # Charts container
    st.markdown("<div class='section'>", unsafe_allow_html=True)
    col1, col2 = st.columns(2)

    # Donut: expenses by category (or income by category if income view)
    with col1:
        if not m_df.empty:
            exp = m_df[m_df["Type"] == "Expense"].groupby("Category")["Amount"].sum().reset_index()
            if exp.empty:
                st.caption("No expenses yet this month")
            else:
                fig = px.pie(exp, values="Amount", names="Category", hole=0.55, color_discrete_sequence=px.colors.sequential.Teal)
                fig.update_layout(height=360, paper_bgcolor="#111", plot_bgcolor="#111", font_color="#eaeaea", margin=dict(l=10,r=10,t=10,b=10))
                st.plotly_chart(fig, use_container_width=True)

    # Trend: daily net flow
    with col2:
        if not m_df.empty:
            daily = m_df.copy()
            daily.loc[daily["Type"] == "Expense", "AmountSigned"] = -daily.loc[daily["Type"] == "Expense", "Amount"]
            daily.loc[daily["Type"] == "Income", "AmountSigned"] = daily.loc[daily["Type"] == "Income", "Amount"]
            series = daily.groupby(daily["Date"].dt.date)["AmountSigned"].sum().reset_index()
            series["CumBalance"] = series["AmountSigned"].cumsum()
            fig2 = go.Figure()
            fig2.add_trace(go.Scatter(x=series["Date"], y=series["CumBalance"], fill='tozeroy', mode='lines', line=dict(color="#00e59b", width=3)))
            fig2.update_layout(height=360, paper_bgcolor="#111", plot_bgcolor="#111", font_color="#eaeaea", margin=dict(l=10,r=10,t=10,b=10), xaxis=dict(gridcolor="#333"), yaxis=dict(gridcolor="#333"))
            st.plotly_chart(fig2, use_container_width=True)
    st.markdown("</div>", unsafe_allow_html=True)

    st.subheader("Recent Transactions")
    st.dataframe(
        m_df.sort_values("Date", ascending=False).head(20)[["Date", "Type", "Mode", "Category", "Amount", "Notes"]],
        use_container_width=True, hide_index=True,
    )
else:
    st.info("No data yet. Add your first transaction above.")

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
                ws = get_worksheet(client)
                st.success("Opened spreadsheet and worksheet successfully")
                try:
                    _ = ws.row_count
                    st.success("Worksheet is readable")
                except Exception as e:
                    st.error(f"Read test failed: {e}")
            except Exception as e:
                st.error(f"Open spreadsheet failed: {e}")

# ---------- Export ----------
df_all = load_df()
st.download_button(
    "Export all as CSV",
    (ensure_datetime(df_all) if not df_all.empty else pd.DataFrame()).to_csv(index=False),
    file_name=f"coinpath_all_{datetime.now().strftime('%Y%m%d')}.csv",
    mime="text/csv",
)
