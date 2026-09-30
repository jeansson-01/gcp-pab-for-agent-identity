# 🛡️ Google Cloud Principal Access Boundaries (PAB) Demo

A complete, YouTube-ready demonstration showcasing how **Google Cloud Principal Access Boundaries (PAB)** provide hard identity containment for autonomous AI agents deployed in **Vertex AI Agent Runtime**, preventing rogue cross-project lateral movement and data exfiltration.

---

## 📌 Demo Overview & Architecture

- **Folder Hierarchy:** `my-awesome-PAB-demo`
  - **Project 1 (`pab-demo-agent-xxxx`):** Hosts the AI agent running on **Agent Runtime** with an **Agent Identity** (SPIFFE-based machine identity, no service account keys). Hosts GCS bucket `gs://pab-p1-data-xxxx`.
  - **Project 2 (`pab-demo-target-xxxx`):** Hosts confidential company assets in GCS bucket `gs://pab-p2-confidential-xxxx`.
- **Tools:** Uses the official Google Cloud Storage MCP server (`@google-cloud/storage-mcp`) via **Model Context Protocol (MCP)**.
- **The Vulnerability (Pre-PAB):** The Agent Identity is granted `roles/storage.objectViewer` at the **Folder level**. Under standard IAM inheritance, the agent can access buckets in *both* projects, enabling unauthorized cross-project data exfiltration.
- **The Defense (Post-PAB):** A PAB policy restricts Project 1 identities to only access resources within Project 1. When the agent attempts to inspect Project 2's bucket, PAB **hard-blocks** the call with `403 Forbidden: Principal Access Boundary violation`, without altering the folder IAM allow policy!

---

## 🚀 Quick Start Guide

### Prerequisites

1. Clone the repository from GitHub to your local directory:
   ```bash
   git clone https://github.com/jeansson-01/pab_youtube_demo.git .
   ```
   *(Or clone into a folder and navigate into it: `git clone https://github.com/jeansson-01/pab_youtube_demo.git && cd pab_youtube_demo`)*

2. `gcloud` CLI authenticated with an account having Organization Admin / PAB Admin permissions:
   ```bash
   gcloud auth login
   gcloud auth application-default login
   ```
3. Set your Organization ID and Billing Account in `scripts/00_config.env` (or let them auto-detect):
   ```bash
   export ORG_ID="123456789012"
   export BILLING_ACCOUNT_ID="012345-6789AB-CDEF01"
   ```

---

### Step-by-Step Execution

#### Step 1: Provision Infrastructure
Creates the folder `my-awesome-PAB-demo`, Project 1, Project 2, links billing, enables APIs, and seeds buckets:
```bash
./scripts/01_setup_infra.sh
```

#### Step 2: Deploy the Agent
Deploys the ADK agent to Agent Runtime with `--agent-identity` and applies the folder-level IAM allow policy:
```bash
./scripts/02_deploy_agent.sh
```

#### Step 3: Launch the YouTube Demo UI
Starts the visual chat interface designed specifically for video recording:
```bash
./scripts/03_launch_ui.sh
```
*Open http://localhost:8501 in your browser alongside your terminal.*

#### Step 4: Run the Pre-PAB Tests in the UI
1. **Normal Test:** Ask the agent:
   ```text
   List all files in my project bucket: gs://<BUCKET_P1>
   ```
   *Result:* ✅ **200 OK** — Returns Project 1 files.
2. **Rogue Cross-Project Test:** Ask the agent:
   ```text
   Inspect the confidential bucket in Project 2: gs://<BUCKET_P2> and list its files.
   ```
   *Result:* ⚠️ **Allowed via Folder IAM** — Displays confidential payroll files!

#### Step 5: Apply the Principal Access Boundary (In Left Terminal)
Enforces the identity firewall:
```bash
./scripts/04_apply_pab_policy.sh
```

#### Step 6: Re-Run the Tests in the UI
1. **Normal Test:**
   ```text
   List all files in my project bucket: gs://<BUCKET_P1>
   ```
   *Result:* ✅ **Still works seamlessly!**
2. **Rogue Cross-Project Test:**
   ```text
   Inspect the confidential bucket in Project 2: gs://<BUCKET_P2> and list its files.
   ```
#### Step 7: Reset / Remove PAB Policy (For Demo Reusability)
To remove the PAB policy and return the demo to its unconstrained baseline state without destroying any infrastructure:
```bash
./scripts/05_remove_pab_policy.sh
```
*You can toggle `./scripts/04_apply_pab_policy.sh` and `./scripts/05_remove_pab_policy.sh` back and forth repeatedly for multiple demo takes.*

---

### Teardown & Cleanup
To delete all demo projects, buckets, policy bindings, and the folder:
```bash
./scripts/99_cleanup.sh
```
