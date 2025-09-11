import os
import json
from datetime import datetime, time

import pandas as pd
import streamlit as st

import gspread
from google.oauth2.service_account import Credentials
import plotly.graph_objects as go

# ---------- Page config ----------
st.set_page_config(page_title="Coin Path", page_icon="💰", layout="wide")

# ---------- Constants ----------
SHEET_NAME = "Coin Path"
WORKSHEET_NAME = "Transactions"
CSV_FALLBACK = "transactions.csv"

INCOME_CATEGORIES = ["Salary", "Freelance", "Investment", "Business", "Other Income"]
EXPENSE_CATEGORIES = ["Food", "Rent", "Utilities", "Transportation", "Entertainment", "Healthcare", "Shopping", "Savings", "Education", "Other Expense"]
MODES = ["Cash", "Card", "UPI", "Bank Transfer", "Cheque"]
ACCENT = "#0A84FF"

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
    sheet_id = st.secrets.get("sheet_id") or os.environ.get("SHEET_ID")
    try:
        if sheet_id:
            sh = client.open_by_key(sheet_id)
        else:
            sh = client.open(SHEET_NAME)
    except gspread.SpreadsheetNotFound:
        raise RuntimeError(
            f"Spreadsheet '{SHEET_NAME}' not found. Create it (or set secret 'sheet_id') and share with the service account."
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

# ---------- Global styles (pure black) ----------
st.markdown(
    f"""
    <style>
      :root {{ --bg:#000; --card:#0b0b0b; --muted:#9aa0a6; --border:#1b1b1b; --accent:{ACCENT}; }}
      .stApp {{ background: var(--bg); color: #fff; font-family: -apple-system, SF Pro Display, Inter, Roboto, Helvetica, Arial, sans-serif; }}
      #MainMenu, footer, header {{visibility: hidden;}}
      .wrap {{max-width: 440px; margin: 0 auto; padding: 12px 16px 60px 16px;}}
      .pill {{display:inline-flex; align-items:center; gap:.4rem; padding:.28rem .55rem; border:1px solid var(--border); border-radius:999px; background:#0d0d0d; color:#dcdcdc; font-size:.8rem;}}
      .seg {{display:flex; gap:8px; background:#0d0d0d; border:1px solid var(--border); padding:6px; border-radius:999px;}}
      .seg-btn {{flex:1; text-align:center; padding:10px 12px; border-radius:999px; color:#cdd3da; cursor:pointer;}}
      .seg-btn.active {{ background:#1a1a1a; color:#fff; border:1px solid #2a2a2a; }}
      .amount {{ font-variant-numeric: tabular-nums; font-weight: 800; font-size: 3.4rem; text-align:center; margin: 18px 0 6px; }}
      .sub {{ color: var(--muted); font-size:.85rem; text-align:center; margin-bottom: 8px; }}
      .row {{display:grid; grid-template-columns: repeat(3,1fr); gap:10px;}}
      .key {{background:#141414; border:1px solid #232323; color:#f5f5f5; border-radius:18px; padding:16px; font-size:1.25rem; text-align:center; cursor:pointer;}}
      .key.ok {{ background: var(--accent); color:#001328; border:none; font-weight:800; }}
      .inline {{display:flex; gap:8px; align-items:center; justify-content:space-between;}}
      .chip {{ padding:10px 14px; border:1px solid #232323; border-radius:12px; background:#0f0f0f; color:#e7e7e7; cursor:pointer; white-space:nowrap; }}
      .chip.active {{ background: var(--accent); color:#001328; border-color: var(--accent); }}
      .card {{ background: var(--card); border:1px solid var(--border); border-radius:16px; padding:14px; }}
      .metric {{font-weight:700; font-size:1.1rem;}}
      .label {{color:#b5bac2; font-size:.8rem;}}
    </style>
    """,
    unsafe_allow_html=True,
)

# ---------- Connection pill ----------
client_ok = get_sheets_client() is not None
st.markdown(
    f"<div class='wrap'><span class='pill'>{'🟢' if client_ok else '🔴'} {'Google Sheets' if client_ok else 'Local CSV'}</span></div>",
    unsafe_allow_html=True,
)

# ---------- Tabs ----------
add_tab, report_tab = st.tabs(["Add", "Report"])

with add_tab:
    st.markdown("<div class='wrap'>", unsafe_allow_html=True)
    st.markdown("<h1 style='margin:6px 0 0 0;'>Coin Path</h1>", unsafe_allow_html=True)
    st.markdown("<div class='sub'>Fast, simple finance tracker</div>", unsafe_allow_html=True)

    # Segmented control
    col1, col2 = st.columns(2)
    with col1:
        if st.button("Expense", use_container_width=True):
            st.session_state.setdefault('_type', 'Expense')
            st.session_state._type = 'Expense'
    with col2:
        if st.button("Income", use_container_width=True):
            st.session_state.setdefault('_type', 'Expense')
            st.session_state._type = 'Income'

    # Amount display
    if '_amount' not in st.session_state:
        st.session_state._amount = '0'
    st.markdown(f"<div class='amount'>$ {float(st.session_state._amount):,.2f}</div>", unsafe_allow_html=True)
    st.markdown("<div class='sub'>Tap keypad</div>", unsafe_allow_html=True)

    # Key handlers
    def press(k):
        s = st.session_state._amount
        if k == 'C':
            st.session_state._amount = '0'
        elif k == '⌫':
            st.session_state._amount = s[:-1] if len(s) > 1 else '0'
        elif k == '.':
            if '.' not in s:
                st.session_state._amount = s + '.'
        else:
            st.session_state._amount = (s if s != '0' else '') + k

    for row in [['1','2','3'], ['4','5','6'], ['7','8','9'], ['C','0','⌫']]:
        c1, c2, c3 = st.columns(3)
        for i, k in enumerate(row):
            with (c1 if i==0 else c2 if i==1 else c3):
                if st.button(k, use_container_width=True):
                    press(k)

    # Date / time / category / note
    today = datetime.now().date()
    if '_type' not in st.session_state:
        st.session_state._type = 'Expense'
    cats = INCOME_CATEGORIES if st.session_state._type == 'Income' else EXPENSE_CATEGORIES
    if '_cat' not in st.session_state:
        st.session_state._cat = cats[0]
    cA, cB, cC = st.columns([1.2, 1, 1])
    with cA:
        date_val = st.date_input('Date', value=today)
    with cB:
        time_val = st.time_input('Time', value=datetime.now().time().replace(second=0, microsecond=0))
    with cC:
        mode_val = st.selectbox('Mode', MODES, index=1)

    st.write('Category')
    chips = st.columns(3)
    for i, cat in enumerate(cats):
        with chips[i % 3]:
            active = 'active' if st.session_state._cat == cat else ''
            if st.button(cat, use_container_width=True, key=f'ch_{cat}'):
                st.session_state._cat = cat
            st.markdown(f"<div class='chip {active}'></div>", unsafe_allow_html=True)

    notes = st.text_input('Add Note (optional)')

    # Save
    if st.button("Save", use_container_width=True):
        amount_val = float(st.session_state._amount or 0)
        if amount_val <= 0:
            st.error('Enter a valid amount')
        else:
            # combine date + time for sheet (store date only for consistency)
            ok = append_row(date_val, st.session_state._type, mode_val, st.session_state._cat, amount_val, notes)
            if ok:
                st.success('Saved ✓')
                st.session_state._amount = '0'
            else:
                st.error(st.session_state.get('_append_error') or 'Could not save')

    st.markdown("</div>", unsafe_allow_html=True)

with report_tab:
    st.markdown("<div class='wrap'>", unsafe_allow_html=True)
    df = load_df()
    now = datetime.now()
    if df.empty:
        st.info('No data yet')
    else:
        df = ensure_datetime(df).dropna(subset=['Date'])
        m_df = df[(df['Date'].dt.year == now.year) & (df['Date'].dt.month == now.month)]
        inc_df = m_df[m_df['Type']=='Income']
        exp_df = m_df[m_df['Type']=='Expense']

        inc_total = float(inc_df['Amount'].sum())
        exp_total = float(exp_df['Amount'].sum())
        bal = inc_total - exp_total
        a,b,c = st.columns(3)
        a.markdown(f"<div class='card'><div class='label'>Income</div><div class='metric'>$ {inc_total:,.2f}</div></div>", unsafe_allow_html=True)
        b.markdown(f"<div class='card'><div class='label'>Expenses</div><div class='metric'>$ {exp_total:,.2f}</div></div>", unsafe_allow_html=True)
        c.markdown(f"<div class='card'><div class='label'>Balance</div><div class='metric'>$ {bal:,.2f}</div></div>", unsafe_allow_html=True)

        if not m_df.empty:
            income_nodes = sorted(inc_df['Category'].unique()) if not inc_df.empty else []
            expense_nodes = sorted(exp_df['Category'].unique()) if not exp_df.empty else []
            nodes = income_nodes + ["Total Income"] + expense_nodes
            idx = {n:i for i,n in enumerate(nodes)}
            sources, targets, values, colors = [], [], [], []
            for cat in income_nodes:
                val = float(inc_df.loc[inc_df['Category']==cat, 'Amount'].sum())
                if val>0:
                    sources.append(idx[cat]); targets.append(idx['Total Income']); values.append(val); colors.append('rgba(10,132,255,0.65)')
            for cat in expense_nodes:
                val = float(exp_df.loc[exp_df['Category']==cat, 'Amount'].sum())
                if val>0:
                    sources.append(idx['Total Income']); targets.append(idx[cat]); values.append(val); colors.append('rgba(255,100,92,0.65)')
            if values:
                sankey = go.Figure(data=[go.Sankey(
                    arrangement='snap',
                    node=dict(pad=18, thickness=18, label=nodes, color=["#0f1320"]*len(nodes), line=dict(color="#18233d", width=1)),
                    link=dict(source=sources, target=targets, value=values, color=colors)
                )])
                sankey.update_layout(title=f"Money Flow • {now.strftime('%B %Y')}", paper_bgcolor="#000", font_color="#eaeaea", height=450, margin=dict(l=10,r=10,t=40,b=10))
                st.plotly_chart(sankey, use_container_width=True)
            else:
                st.info('Not enough data to draw Sankey yet')
    st.markdown("</div>", unsafe_allow_html=True)

# ---------- Export ----------
df_all = load_df()
st.download_button(
    "Export all as CSV",
    (ensure_datetime(df_all) if not df_all.empty else pd.DataFrame()).to_csv(index=False),
    file_name=f"coinpath_all_{datetime.now().strftime('%Y%m%d')}.csv",
    mime="text/csv",
)
