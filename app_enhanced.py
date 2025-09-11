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
ACCENT = "#0A84FF"  # iOS light blue

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

# ---------- UI: iOS-like styling (light blue accent, soft dark) ----------
st.markdown(
    f"""
    <style>
      :root {{ --bg:#0b0b0d; --card:#111216; --muted:#9aa0a6; --border:#1f2126; --accent:{ACCENT}; }}
      .stApp {{ background: var(--bg); color: #fff; font-family: -apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Inter,Helvetica,Arial,'Noto Sans',sans-serif; }}
      #MainMenu, footer, header {{visibility: hidden;}}
      .pill {{display:inline-flex; align-items:center; gap:.5rem; padding:.35rem .6rem; border:1px solid var(--border); border-radius:999px; background:#0f1014; color:#eaeaea; font-size:.85rem;}}
      .metric-card {{background: var(--card); border:1px solid var(--border); border-radius:16px; padding:14px 16px;}}
      .metric-val {{font-weight:700; font-size:1.25rem}}
      .metric-label {{color:var(--muted); font-size:.8rem}}
      .section {{background: var(--card); border:1px solid var(--border); border-radius:16px; padding:16px;}}
      .title {{font-weight:700; font-size:1.05rem; margin-bottom:6px}}
      .amount-display {{ font-variant-numeric: tabular-nums; font-weight: 800; font-size: 3rem; letter-spacing: .5px; text-align:center; margin: 6px 0 2px 0; }}
      .subnote {{ color: var(--muted); font-size: .85rem; text-align:center; }}
      .keypad {{ display:grid; grid-template-columns: repeat(3,1fr); gap:10px; margin-top: 12px; }}
      .key {{ background:#14161b; border:1px solid var(--border); color:#eaeaea; border-radius:14px; padding:16px; font-size:1.25rem; text-align:center; cursor:pointer; }}
      .key.primary {{ background: var(--accent); color:#001328; border:none; font-weight:800; }}
      .seg {{display:flex; gap:6px; background:#0f1014; border:1px solid var(--border); padding:6px; border-radius:12px; width:100%;}}
      .seg-btn {{flex:1; text-align:center; padding:10px 12px; border-radius:10px; color:#cbd1d8; cursor:pointer;}}
      .seg-btn.active {{ background: #172238; color:#e8f1ff; border:1px solid #233251; }}
      .chips {{display:flex; flex-wrap:wrap; gap:8px;}}
      .chip {{ padding:8px 12px; border:1px solid var(--border); border-radius:999px; background:#14161b; color:#eaeaea; cursor:pointer;}}
      .chip.active {{ background: var(--accent); color:#001328; border-color: var(--accent) }}
    </style>
    """,
    unsafe_allow_html=True,
)

# Connection status
client_ok = get_sheets_client() is not None
st.markdown(
    f"<span class='pill'>{'🟢' if client_ok else '🔴'} {'Google Sheets' if client_ok else 'Local CSV'}</span>",
    unsafe_allow_html=True,
)

st.title("Coin Path")
st.caption("Fast, simple finance tracker")

# ---------- Keypad-first entry ----------
if "_amount" not in st.session_state:
    st.session_state._amount = "0"
if "_type" not in st.session_state:
    st.session_state._type = "Expense"
if "_mode" not in st.session_state:
    st.session_state._mode = "Card"
if "_cat" not in st.session_state:
    st.session_state._cat = EXPENSE_CATEGORIES[0]

with st.container():
    st.markdown("<div class='section'>", unsafe_allow_html=True)

    # Type segmented control
    col_t1, col_t2 = st.columns(2)
    with col_t1:
        exp_active = "active" if st.session_state._type == "Expense" else ""
        if st.button("Expense", key="seg_exp", use_container_width=True):
            st.session_state._type = "Expense"; st.session_state._cat = EXPENSE_CATEGORIES[0]
        st.markdown(f"<div class='seg'><div class='seg-btn {exp_active}'></div></div>", unsafe_allow_html=True)
    with col_t2:
        inc_active = "active" if st.session_state._type == "Income" else ""
        if st.button("Income", key="seg_inc", use_container_width=True):
            st.session_state._type = "Income"; st.session_state._cat = INCOME_CATEGORIES[0]
        st.markdown(f"<div class='seg'><div class='seg-btn {inc_active}'></div></div>", unsafe_allow_html=True)

    # Amount display
    st.markdown(f"<div class='amount-display'>$ {float(st.session_state._amount):,.2f}</div>", unsafe_allow_html=True)
    st.markdown("<div class='subnote'>Tap to enter amount</div>", unsafe_allow_html=True)

    # Keypad
    def press_key(val: str):
        amt = st.session_state._amount
        if val == 'C':
            st.session_state._amount = '0'
        elif val == '⌫':
            st.session_state._amount = amt[:-1] if len(amt) > 1 else '0'
        elif val == '.':
            if '.' not in amt:
                st.session_state._amount = amt + '.'
        else:
            st.session_state._amount = (amt if amt != '0' else '') + val

    kcols = st.columns(3)
    keys = [['1','2','3'],['4','5','6'],['7','8','9'],['C','0','⌫']]
    for row in keys:
        c1, c2, c3 = st.columns(3)
        for i, k in enumerate(row):
            with (c1 if i==0 else c2 if i==1 else c3):
                if st.button(k, key=f"k_{k}", use_container_width=True):
                    press_key(k)

    # Category chips
    st.markdown("<div class='title'>Category</div>", unsafe_allow_html=True)
    cats = INCOME_CATEGORIES if st.session_state._type == "Income" else EXPENSE_CATEGORIES
    chip_cols = st.columns(3)
    for i, c in enumerate(cats):
        with chip_cols[i % 3]:
            active = "active" if st.session_state._cat == c else ""
            if st.button(c, key=f"chip_{c}", use_container_width=True):
                st.session_state._cat = c
            st.markdown(f"<div class='chip {active}'></div>", unsafe_allow_html=True)

    # Save row
    c_left, c_right = st.columns([2,1])
    with c_left:
        notes = st.text_input("Add note (optional)")
    with c_right:
        st.session_state._mode = st.selectbox("Mode", MODES, index=MODES.index(st.session_state._mode))

    save_clicked = st.button("Save", type="primary", use_container_width=True)
    st.markdown("</div>", unsafe_allow_html=True)

if save_clicked:
    amount_val = float(st.session_state._amount or 0)
    if amount_val <= 0:
        st.error("Enter a valid amount")
    else:
        ok = append_row(datetime.now().date(), st.session_state._type, st.session_state._mode, st.session_state._cat, amount_val, notes)
        if ok:
            st.success("Saved ✓")
            st.session_state._amount = "0"
        else:
            st.error(st.session_state.get("_append_error") or "Could not save.")

# ---------- Data & Monthly Sankey ----------
df = load_df()
now = datetime.now()
if not df.empty:
    df = ensure_datetime(df).dropna(subset=['Date'])
    m_df = df[(df['Date'].dt.year == now.year) & (df['Date'].dt.month == now.month)]

    inc_total = float(m_df[m_df['Type']=='Income']['Amount'].sum())
    exp_total = float(m_df[m_df['Type']=='Expense']['Amount'].sum())
    bal = inc_total - exp_total

    c1, c2, c3 = st.columns(3)
    c1.markdown(f"<div class='metric-card'><div class='metric-label'>Income</div><div class='metric-val'>$ {inc_total:,.2f}</div></div>", unsafe_allow_html=True)
    c2.markdown(f"<div class='metric-card'><div class='metric-label'>Expenses</div><div class='metric-val'>$ {exp_total:,.2f}</div></div>", unsafe_allow_html=True)
    c3.markdown(f"<div class='metric-card'><div class='metric-label'>Balance</div><div class='metric-val'>$ {bal:,.2f}</div></div>", unsafe_allow_html=True)

    st.markdown("<div style='height:8px'></div>", unsafe_allow_html=True)

    if not m_df.empty:
        inc_df = m_df[m_df['Type']=='Income']
        exp_df = m_df[m_df['Type']=='Expense']
        if not inc_df.empty or not exp_df.empty:
            # Nodes: income categories + Total Income + expense categories
            income_nodes = sorted(inc_df['Category'].unique()) if not inc_df.empty else []
            expense_nodes = sorted(exp_df['Category'].unique()) if not exp_df.empty else []
            nodes = income_nodes + ["Total Income"] + expense_nodes
            idx = {n:i for i,n in enumerate(nodes)}

            sources, targets, values, colors = [], [], [], []
            # income source -> Total Income
            for cat in income_nodes:
                val = float(inc_df.loc[inc_df['Category']==cat, 'Amount'].sum())
                if val>0:
                    sources.append(idx[cat]); targets.append(idx['Total Income']); values.append(val); colors.append('rgba(10,132,255,0.65)')
            # Total Income -> expense categories
            for cat in expense_nodes:
                val = float(exp_df.loc[exp_df['Category']==cat, 'Amount'].sum())
                if val>0:
                    sources.append(idx['Total Income']); targets.append(idx[cat]); values.append(val); colors.append('rgba(255,100,92,0.65)')

            sankey = go.Figure(data=[go.Sankey(
                arrangement='snap',
                node=dict(
                    pad=18, thickness=18,
                    label=nodes, color=["#192132"]*len(nodes),
                    line=dict(color="#22314f", width=1)
                ),
                link=dict(source=sources, target=targets, value=values, color=colors)
            )])
            sankey.update_layout(
                title=f"Money Flow • {now.strftime('%B %Y')}",
                paper_bgcolor="#111216", font_color="#eaeaea", height=420, margin=dict(l=10,r=10,t=40,b=10)
            )
            st.plotly_chart(sankey, use_container_width=True)
else:
    st.info("No data yet. Add your first transaction above.")

# ---------- Export ----------
df_all = load_df()
st.download_button(
    "Export all as CSV",
    (ensure_datetime(df_all) if not df_all.empty else pd.DataFrame()).to_csv(index=False),
    file_name=f"coinpath_all_{datetime.now().strftime('%Y%m%d')}.csv",
    mime="text/csv",
)
