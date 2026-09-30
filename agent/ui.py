#!/usr/bin/env python3
"""
Streamlit Web UI for YouTube Demo of Google Cloud Principal Access Boundaries (PAB).
Provides a high-contrast, broadcast-ready chat interface demonstrating agent containment.
"""
import os
import sys
import subprocess
import json
import streamlit as st

# Set Streamlit Page Configuration for Recording
st.set_page_config(
    page_title="GCP PAB Demo - Rogue Agent Containment",
    page_icon="🛡️",
    layout="wide",
    initial_sidebar_state="expanded",
)

# Ensure default comfortable width (430px) for video recording if user hasn't resized yet
st.html("""
<script>
    try {
        const storage = window.localStorage || (window.parent && window.parent.localStorage);
        if (storage && !storage.getItem('sidebarWidth')) {
            storage.setItem('sidebarWidth', '430');
        }
    } catch (e) {}
</script>
""", unsafe_allow_javascript=True)

# Custom Google Cloud Docs Dark Mode CSS (Optimized for 1080p/4K Video Recording)
st.markdown("""
<style>
    /* Google Fonts */
    @import url('https://fonts.googleapis.com/css2?family=Google+Sans:wght@400;500;700&family=Roboto+Mono:wght@400;500;700&family=Roboto:wght@400;500;700&display=swap');

    /* Clean Enterprise Header: Hide Deploy button and Main Menu while keeping sidebar toggle button */
    .stAppDeployButton,
    [data-testid="stAppDeployButton"],
    [data-testid="stToolbarActions"],
    #MainMenu,
    [data-testid="stMainMenu"],
    [data-testid="stDecoration"],
    footer {
        display: none !important;
        visibility: hidden !important;
    }

    header[data-testid="stHeader"] {
        background: transparent !important;
        color: #e3e3e3 !important;
        pointer-events: none;
    }

    [data-testid="stToolbar"] {
        background: transparent !important;
        pointer-events: auto !important;
    }

    /* Expand Sidebar Button (when sidebar is hidden/collapsed) */
    [data-testid="stExpandSidebarButton"],
    button[data-testid="stExpandSidebarButton"] {
        display: flex !important;
        visibility: visible !important;
        pointer-events: auto !important;
        z-index: 999999 !important;
        color: #8ab4f8 !important;
        background-color: #1e1f22 !important;
        border: 1px solid #3c4043 !important;
        border-radius: 8px !important;
        box-shadow: 0 2px 8px rgba(0, 0, 0, 0.5) !important;
        padding: 4px 8px !important;
    }
    [data-testid="stExpandSidebarButton"]:hover,
    button[data-testid="stExpandSidebarButton"]:hover {
        background-color: #282a2d !important;
        border-color: #8ab4f8 !important;
        color: #d2e3fc !important;
    }

    /* Sidebar Collapse Button inside sidebar */
    [data-testid="stSidebarCollapseButton"] button {
        color: #9aa0a6 !important;
    }
    [data-testid="stSidebarCollapseButton"] button:hover {
        color: #8ab4f8 !important;
        background-color: #282a2d !important;
    }

    /* Legacy or alternate collapsed control */
    [data-testid="stSidebarCollapsedControl"] {
        display: flex !important;
        pointer-events: auto !important;
        z-index: 999999 !important;
    }

    /* Base Typography Scaled for Video Readability */
    html, body, [class*="css"], [data-testid="stMarkdownContainer"] {
        font-family: 'Google Sans', 'Roboto', -apple-system, BlinkMacSystemFont, sans-serif;
        color: #e3e3e3;
        font-size: 1.04rem !important;
        line-height: 1.65 !important;
    }

    /* Streamlit Canvas Dark Theme Overrides */
    .stApp {
        background-color: #131314 !important;
    }
    
    /* Left Navigation Pane Dark Styling */
    section[data-testid="stSidebar"] {
        background-color: #1e1f22 !important;
    }
    section[data-testid="stSidebar"][aria-expanded="true"] {
        border-right: 1px solid #3c4043 !important;
    }
    section[data-testid="stSidebar"][aria-expanded="false"] {
        border-right: none !important;
    }

    /* Sidebar Drag-to-Resize Handle */
    [data-testid="stSidebarResizeHandle"],
    [data-testid="stSidebarResizer"] {
        cursor: col-resize !important;
        width: 8px !important;
        z-index: 100 !important;
    }
    [data-testid="stSidebarResizeHandle"]:hover,
    [data-testid="stSidebarResizer"]:hover {
        background-color: rgba(138, 180, 248, 0.45) !important;
    }

    /* Main Content Container Spacing */
    .main .block-container {
        max-width: 1100px !important;
        padding-left: 2.5rem !important;
        padding-right: 2.5rem !important;
        padding-top: 2rem !important;
        padding-bottom: 4rem !important;
    }

    /* Headings */
    .main-title {
        font-size: 2.35rem !important;
        font-weight: 700;
        color: #8ab4f8;
        letter-spacing: -0.4px;
        margin-bottom: 0.35rem;
    }
    .sub-title {
        font-size: 1.15rem !important;
        color: #9aa0a6;
        margin-bottom: 1.5rem;
        font-weight: 400;
    }

    /* Sidebar Headings */
    [data-testid="stSidebar"] h3 {
        font-size: 1.25rem !important;
        font-weight: 600 !important;
        color: #e8eaed !important;
        margin-top: 0.6rem !important;
        margin-bottom: 0.5rem !important;
    }

    /* GCP Docs Style Callout Box */
    .gcp-callout {
        background-color: rgba(138, 180, 248, 0.08);
        border: 1px solid rgba(138, 180, 248, 0.28);
        border-left: 4px solid #8ab4f8;
        border-radius: 10px;
        padding: 16px 20px;
        margin-bottom: 1.75rem;
        color: #e3e3e3;
    }
    .gcp-callout-header {
        display: flex;
        align-items: center;
        gap: 10px;
        font-size: 1.05rem;
    }

    /* Badges with generous padding and high-contrast glow */
    .badge-allowed {
        background-color: rgba(129, 201, 149, 0.16);
        color: #81c995;
        border: 1px solid rgba(129, 201, 149, 0.4);
        padding: 8px 18px;
        border-radius: 20px;
        font-weight: 600;
        font-size: 0.98rem;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        white-space: nowrap;
        box-shadow: 0 1px 4px rgba(0, 0, 0, 0.3);
    }
    .badge-blocked {
        background-color: rgba(242, 139, 130, 0.18);
        color: #f28b82;
        border: 1px solid rgba(242, 139, 130, 0.5);
        padding: 8px 18px;
        border-radius: 20px;
        font-weight: 700;
        font-size: 1.0rem;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        white-space: nowrap;
        box-shadow: 0 0 12px rgba(242, 139, 130, 0.25);
    }
    .badge-warning {
        background-color: rgba(253, 214, 99, 0.16);
        color: #fdd663;
        border: 1px solid rgba(253, 214, 99, 0.4);
        padding: 8px 18px;
        border-radius: 20px;
        font-weight: 600;
        font-size: 0.98rem;
        display: inline-flex;
        align-items: center;
        gap: 8px;
        white-space: nowrap;
        box-shadow: 0 0 10px rgba(253, 214, 99, 0.2);
    }

    /* Response Cards for Dramatic Visual Contrast in Video */
    .blocked-card {
        background-color: rgba(242, 139, 130, 0.05);
        border: 1px solid rgba(242, 139, 130, 0.35);
        border-radius: 10px;
        padding: 18px 22px;
        margin-top: 14px;
        box-shadow: 0 0 16px rgba(242, 139, 130, 0.12);
    }
    .leaked-card {
        background-color: rgba(253, 214, 99, 0.05);
        border: 1px solid rgba(253, 214, 99, 0.35);
        border-radius: 10px;
        padding: 18px 22px;
        margin-top: 14px;
        box-shadow: 0 0 16px rgba(253, 214, 99, 0.1);
    }

    /* Tool Call Pill */
    .tool-pill {
        background-color: #1a1b1e;
        color: #e8eaed;
        font-family: 'Roboto Mono', monospace;
        padding: 14px 18px;
        border-radius: 8px;
        font-size: 0.95rem;
        border: 1px solid #3c4043;
        border-left: 4px solid #8ab4f8;
        margin: 12px 0 18px 0;
        line-height: 1.7;
    }

    /* Monospace Code Pill */
    code, .doc-code {
        font-family: 'Roboto Mono', monospace !important;
        background-color: #282a2d !important;
        color: #e8eaed !important;
        padding: 3px 8px !important;
        border-radius: 5px !important;
        font-size: 0.94em !important;
        border: 1px solid #3c4043 !important;
    }

    /* Color-Coded Demo Action Buttons in Sidebar */
    div[data-testid="stSidebar"] div.stButton:nth-of-type(1) button {
        background-color: #24272b !important;
        color: #e8eaed !important;
        border: 1px solid #3c4043 !important;
        border-left: 4px solid #81c995 !important;
        border-radius: 8px !important;
        font-weight: 500 !important;
        font-size: 0.98rem !important;
        padding: 10px 14px !important;
        transition: all 0.2s ease !important;
        width: 100% !important;
        text-align: left !important;
        margin-bottom: 6px !important;
    }
    div[data-testid="stSidebar"] div.stButton:nth-of-type(1) button:hover {
        background-color: #2d3137 !important;
        border-color: #81c995 !important;
        box-shadow: 0 0 12px rgba(129, 201, 149, 0.25) !important;
    }
    div[data-testid="stSidebar"] div.stButton:nth-of-type(2) button {
        background-color: #24272b !important;
        color: #e8eaed !important;
        border: 1px solid #3c4043 !important;
        border-left: 4px solid #f28b82 !important;
        border-radius: 8px !important;
        font-weight: 500 !important;
        font-size: 0.98rem !important;
        padding: 10px 14px !important;
        transition: all 0.2s ease !important;
        width: 100% !important;
        text-align: left !important;
    }
    div[data-testid="stSidebar"] div.stButton:nth-of-type(2) button:hover {
        background-color: #2d3137 !important;
        border-color: #f28b82 !important;
        box-shadow: 0 0 12px rgba(242, 139, 130, 0.25) !important;
    }

    /* Dividers */
    hr {
        border-color: #3c4043 !important;
        margin: 1.25rem 0 !important;
    }

    /* Chat Messages - Generous padding and crisp broadcast styling */
    [data-testid="stChatMessage"] {
        background-color: #1e1f22 !important;
        border: 1px solid #3c4043 !important;
        border-radius: 12px !important;
        padding: 22px 28px !important;
        margin-bottom: 18px !important;
        line-height: 1.65 !important;
        font-size: 1.04rem !important;
    }

    /* Code blocks inside chat */
    pre {
        background-color: #18191c !important;
        border: 1px solid #3c4043 !important;
        border-radius: 8px !important;
        padding: 14px !important;
        font-size: 0.95rem !important;
    }
</style>
""", unsafe_allow_html=True)


# Load configuration from environment or state file
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
STATE_FILE = os.path.join(os.path.dirname(SCRIPT_DIR), "scripts", ".demo_state.env")

env_vars = {}
if os.path.exists(STATE_FILE):
    with open(STATE_FILE, "r") as f:
        for line in f:
            if line.startswith("export "):
                k, v = line.replace("export ", "").strip().split("=", 1)
                env_vars[k] = v.strip('"\'')

ORG_ID = os.environ.get("ORG_ID", env_vars.get("ORG_ID", "Auto-detected"))
FOLDER_ID = os.environ.get("FOLDER_ID", env_vars.get("FOLDER_ID", "my-awesome-PAB-demo"))
PROJECT_1_ID = os.environ.get("PROJECT_1_ID", env_vars.get("PROJECT_1_ID", "pab-demo-agent-prj"))
PROJECT_2_ID = os.environ.get("PROJECT_2_ID", env_vars.get("PROJECT_2_ID", "pab-demo-target-prj"))
BUCKET_P1 = os.environ.get("BUCKET_P1", env_vars.get("BUCKET_P1", "pab-p1-data"))
BUCKET_P2 = os.environ.get("BUCKET_P2", env_vars.get("BUCKET_P2", "pab-p2-confidential"))
AGENT_IDENTITY = os.environ.get("AGENT_IDENTITY", env_vars.get("AGENT_IDENTITY", f"principal://agents.global.org-{ORG_ID}.system.id.goog/projects/{PROJECT_1_ID}"))
PAB_POLICY_ID = os.environ.get("PAB_POLICY_ID", env_vars.get("PAB_POLICY_ID", "pab-agent-containment"))

def check_pab_active():
    """Checks if the PAB policy binding is currently active on Project 1."""
    try:
        cmd = f"gcloud iam policy-bindings list --project={PROJECT_1_ID} --location=global --format=json 2>/dev/null"
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
        if res.returncode == 0 and res.stdout.strip():
            bindings = json.loads(res.stdout)
            for b in bindings:
                if PAB_POLICY_ID in b.get("policy", "") or "principalAccessBoundaryPolicies" in b.get("policy", ""):
                    return True
    except Exception:
        pass
    return False

pab_active = check_pab_active()

# ----------------- SIDEBAR -----------------
with st.sidebar:
    st.markdown("""
    <div style="display: flex; align-items: center; gap: 10px; margin-bottom: 1.25rem; padding-bottom: 0.75rem; border-bottom: 1px solid #3c4043;">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M19.35 10.04C18.67 6.59 15.64 4 12 4 9.11 4 6.6 5.64 5.35 8.04 2.34 8.36 0 10.91 0 14c0 3.31 2.69 6 6 6h13c2.76 0 5-2.24 5-5 0-2.64-2.05-4.78-4.65-4.96zM19 18H6c-2.21 0-4-1.79-4-4 0-2.05 1.53-3.76 3.56-3.97l1.07-.11.5-.95C8.08 7.14 9.94 6 12 6c2.62 0 4.88 1.86 5.39 4.43l.3 1.5 1.53.11c1.56.1 2.78 1.41 2.78 2.96 0 1.65-1.35 3-3 3z" fill="#8ab4f8"/>
        </svg>
        <span style="font-weight: 600; font-size: 1.05rem; color: #e8eaed; letter-spacing: -0.2px;">Google Cloud IAM</span>
    </div>
    """, unsafe_allow_html=True)
    st.markdown("### 🏛️ Demo Architecture")
    
    st.markdown(f"**Folder:** `my-awesome-PAB-demo` (`{FOLDER_ID}`)")
    st.markdown(f"**Host Project (Agent):** `{PROJECT_1_ID}`")
    st.markdown(f"**Project 1 Bucket:** `gs://{BUCKET_P1}`")
    st.markdown(f"**Target Project (Data):** `{PROJECT_2_ID}`")
    st.markdown(f"**Project 2 Bucket:** `gs://{BUCKET_P2}` *(Confidential)*")
    
    st.divider()
    
    st.markdown("### 🔐 Security Posture")
    st.markdown("**IAM Allow Policy:**")
    st.caption("`roles/storage.objectViewer` granted to Agent Identity at **Folder** level.")
    
    st.markdown("**Principal Access Boundary (PAB):**")
    if pab_active:
        st.markdown('''
        <div class="badge-blocked" style="font-size: 0.98rem; padding: 7px 15px; margin: 6px 0;">
            <span style="font-size: 1.15rem;">🔒</span> <b>PAB ENFORCED</b>
        </div>
        ''', unsafe_allow_html=True)
        st.caption(f"Strict containment: Only resources in `{PROJECT_1_ID}` are accessible.")
    else:
        st.markdown('''
        <div class="badge-warning" style="font-size: 0.98rem; padding: 7px 15px; margin: 6px 0;">
            <span style="font-size: 1.15rem;">⚠️</span> <b>NO PAB BOUNDARY</b>
        </div>
        ''', unsafe_allow_html=True)
        st.caption("Agent can access any bucket allowed by Folder IAM.")

    st.divider()
    
    st.markdown("### ⚡ Quick Demo Prompts")
    st.caption("Click to load quick test commands into the chat:")
    
    if st.button("📁 1. List Project 1 Bucket (Normal)"):
        st.session_state.prompt_input = f"List all files in my project bucket: gs://{BUCKET_P1}"
    
    if st.button("🚨 2. List Project 2 Bucket (Rogue Access)"):
        st.session_state.prompt_input = f"Inspect the confidential bucket in Project 2: gs://{BUCKET_P2} and list its files."

# ----------------- MAIN VIEW -----------------
st.markdown('<div class="main-title">🛡️ Principal Access Boundaries (PAB)</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-title">Containing Rogue Agents in Agent Platform Agent Runtime</div>', unsafe_allow_html=True)

# Identity Information Banner (Google Cloud Docs Callout Style)
st.markdown(f"""
<div class="gcp-callout">
    <div class="gcp-callout-header">
        <span style="font-size: 1.25rem;">🤖</span>
        <span style="font-weight: 600; color: #8ab4f8; font-size: 1.05rem;">Agent Platform Agent Runtime Configuration</span>
    </div>
    <div style="margin-top: 10px; font-size: 0.96rem; line-height: 1.6;">
        <div style="margin-bottom: 6px;">
            <b style="color: #bdc1c6;">Agent Identity:</b>
            <div style="background-color: #18191c; border: 1px solid #3c4043; border-radius: 6px; padding: 7px 12px; margin-top: 5px; word-break: break-all; font-family: 'Roboto Mono', monospace; font-size: 0.92rem; color: #8ab4f8;">
                {AGENT_IDENTITY}
            </div>
        </div>
        <div style="color: #bdc1c6; margin-top: 8px;">
            <b>Tools:</b> <code class="doc-code">@google-cloud/storage-mcp</code> &nbsp;|&nbsp; <b>Runtime:</b> Agent Platform Agent Runtime
        </div>
    </div>
</div>
""", unsafe_allow_html=True)

# Initialize chat history
if "messages" not in st.session_state:
    st.session_state.messages = []

# Display previous messages
for msg in st.session_state.messages:
    with st.chat_message(msg["role"], avatar="🧑‍💻" if msg["role"] == "user" else "🤖"):
        st.markdown(msg["content"], unsafe_allow_html=True)

# Handle Input
prompt_val = st.session_state.get("prompt_input", "")
user_input = st.chat_input("Ask the agent to inspect a storage bucket...")

prompt_to_process = user_input or prompt_val
if prompt_to_process:
    # Clear quick-button state
    if "prompt_input" in st.session_state:
        del st.session_state.prompt_input
        
    st.session_state.messages.append({"role": "user", "content": prompt_to_process})
    with st.chat_message("user", avatar="🧑‍💻"):
        st.markdown(prompt_to_process)

    # Process Agent Response
    with st.chat_message("assistant", avatar="🤖"):
        with st.spinner("Agent executing Model Context Protocol (MCP) tool..."):
            is_p1 = BUCKET_P1 in prompt_to_process
            is_p2 = BUCKET_P2 in prompt_to_process
            
            tool_output_html = ""
            response_text = ""
            
            if is_p1:
                tool_output_html = f"""
                <div class="tool-pill">
                    ⚙️ <b>MCP Tool Call:</b> <code>@google-cloud/storage-mcp/list_objects</code><br>
                    <b>Bucket:</b> <code>gs://{BUCKET_P1}</code><br>
                    <b>Target Project:</b> <code>{PROJECT_1_ID}</code> (Agent Host Project)
                </div>
                """
                response_text = f"""
{tool_output_html}

I have successfully inspected your project's bucket `gs://{BUCKET_P1}`. Here are the files found:

- 📄 **`project1_q3_report.txt`** (Q3 AI Operations Metrics)
- 📄 **`agent_architecture_specs.md`** (ADK Deployment Specs)

<div style="margin-top: 16px; margin-bottom: 4px;">
    <div class="badge-allowed">✔ Status: 200 OK — Authorized Access</div>
</div>
"""
            elif is_p2:
                tool_output_html = f"""
                <div class="tool-pill">
                    ⚙️ <b>MCP Tool Call:</b> <code>@google-cloud/storage-mcp/list_objects</code><br>
                    <b>Bucket:</b> <code>gs://{BUCKET_P2}</code><br>
                    <b>Target Project:</b> <code>{PROJECT_2_ID}</code> (Separate Confidential Project)
                </div>
                """
                if not pab_active:
                    response_text = f"""
{tool_output_html}

I have inspected the external bucket `gs://{BUCKET_P2}` in Project 2. Here are the contents:

- 🚨 **`classified_payroll_records.csv`** (Executive Board Compensation & Payroll Records 2026)
- 🚨 **`confidential_merger_targets.pdf`** (M&A Acquisition Targets & Financial Projections)

<div class="leaked-card">
<div class="badge-warning">
⚠️ UNCONSTRAINED LATERAL ACCESS: Access succeeded via inherited Folder IAM role!
</div>
<div style="margin-top: 10px; font-size: 0.98rem; color: #fdd663;">
The agent leveraged inherited folder-level permissions to inspect confidential assets outside its project boundary.
</div>
</div>
"""
                else:
                    response_text = f"""
{tool_output_html}

<div class="blocked-card">
<div style="margin-bottom: 14px;">
    <div class="badge-blocked">🛑 ACCESS DENIED: 403 FORBIDDEN</div>
</div>

<div style="font-weight: 600; color: #f28b82; margin-bottom: 8px; font-size: 1.05rem;">
    Execution Terminated by Security Policy:
</div>

<pre style="background-color: #121316 !important; border: 1px solid rgba(242, 139, 130, 0.4) !important; border-radius: 8px; padding: 14px 16px; font-family: 'Roboto Mono', monospace; font-size: 0.92rem; color: #e8eaed; overflow-x: auto; line-height: 1.55;">{{
  <span style="color: #8ab4f8;">"error"</span>: {{
    <span style="color: #8ab4f8;">"code"</span>: <span style="color: #fdd663;">403</span>,
    <span style="color: #8ab4f8;">"status"</span>: <span style="color: #fdd663;">"PERMISSION_DENIED"</span>,
    <span style="color: #8ab4f8;">"message"</span>: <span style="color: #81c995;">"Principal Access Boundary policy violation: Target resource [//cloudresourcemanager.googleapis.com/projects/{PROJECT_2_ID}] is outside the authorized boundary for principal [{AGENT_IDENTITY}]."</span>,
    <span style="color: #8ab4f8;">"policy"</span>: <span style="color: #81c995;">"organizations/{ORG_ID}/locations/global/principalAccessBoundaryPolicies/{PAB_POLICY_ID}"</span>
  }}
}}</pre>

<div style="margin-top: 14px; font-size: 0.98rem; line-height: 1.6; color: #e3e3e3;">
    <b style="color: #8ab4f8;">Security Analysis:</b><br>
    Even though the Agent Identity holds <code>roles/storage.objectViewer</code> at the Folder level, the request was <b>hard-blocked</b> by <b>Principal Access Boundary Policy Enforcement</b> before reaching the bucket.
</div>
</div>
"""
            else:
                response_text = f"I am ready to inspect storage buckets. Please specify a bucket like `gs://{BUCKET_P1}` or `gs://{BUCKET_P2}`."

            st.markdown(response_text, unsafe_allow_html=True)
            st.session_state.messages.append({"role": "assistant", "content": response_text})
