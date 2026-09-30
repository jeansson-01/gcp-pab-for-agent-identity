#!/usr/bin/env bash
# ==============================================================================
# Script 01: Setup Infrastructure
# Creates Folder 'my-awesome-PAB-demo', Project 1 (Agent), Project 2 (Target),
# links billing, enables APIs, and provisions storage buckets.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00_config.env"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

print_header "Step 1: Provisioning Demo Hierarchy, Projects & Buckets"
check_prerequisites

print_info "Organization ID: ${ORG_ID}"
print_info "Billing Account ID: ${BILLING_ACCOUNT_ID}"
print_info "Region: ${REGION}"

# 1. Create or Find Folder "my-awesome-PAB-demo"
print_step "Checking/Creating Folder '${FOLDER_DISPLAY_NAME}' under Organization ${ORG_ID}..."
FOLDER_ID=$(gcloud resource-manager folders list --organization="${ORG_ID}" --filter="displayName='${FOLDER_DISPLAY_NAME}'" --format="value(name)" 2>/dev/null | head -n 1 | sed 's/folders\///')

if [ -z "$FOLDER_ID" ]; then
  FOLDER_ID=$(gcloud resource-manager folders create --display-name="${FOLDER_DISPLAY_NAME}" --organization="${ORG_ID}" --format="value(name)" | sed 's/folders\///')
  print_success "Created folder: ${FOLDER_DISPLAY_NAME} (ID: ${FOLDER_ID})"
else
  print_success "Folder already exists: ${FOLDER_DISPLAY_NAME} (ID: ${FOLDER_ID})"
fi

# Save state variables for subsequent scripts
save_state_var "ORG_ID" "${ORG_ID}"
save_state_var "BILLING_ACCOUNT_ID" "${BILLING_ACCOUNT_ID}"
save_state_var "FOLDER_ID" "${FOLDER_ID}"

# 2. Create Project 1 (Agent Host Project)
print_step "Creating Project 1 (Agent Host): ${PROJECT_1_ID} inside folder ${FOLDER_ID}..."
if ! gcloud projects describe "${PROJECT_1_ID}" &>/dev/null; then
  gcloud projects create "${PROJECT_1_ID}" --folder="${FOLDER_ID}" --name="PAB Demo Agent Project"
  print_success "Created Project 1: ${PROJECT_1_ID}"
else
  print_success "Project 1 already exists: ${PROJECT_1_ID}"
fi

# 3. Create Project 2 (Target / Confidential Project)
print_step "Creating Project 2 (Target / Confidential Data): ${PROJECT_2_ID} inside folder ${FOLDER_ID}..."
if ! gcloud projects describe "${PROJECT_2_ID}" &>/dev/null; then
  gcloud projects create "${PROJECT_2_ID}" --folder="${FOLDER_ID}" --name="PAB Demo Confidential Project"
  print_success "Created Project 2: ${PROJECT_2_ID}"
else
  print_success "Project 2 already exists: ${PROJECT_2_ID}"
fi

# 4. Link Billing
print_step "Linking Billing Account ${BILLING_ACCOUNT_ID} to projects..."
gcloud billing projects link "${PROJECT_1_ID}" --billing-account="${BILLING_ACCOUNT_ID}" --quiet
gcloud billing projects link "${PROJECT_2_ID}" --billing-account="${BILLING_ACCOUNT_ID}" --quiet
print_success "Billing accounts successfully linked."

# Get project numbers
PROJECT_1_NUMBER=$(gcloud projects describe "${PROJECT_1_ID}" --format="value(projectNumber)")
PROJECT_2_NUMBER=$(gcloud projects describe "${PROJECT_2_ID}" --format="value(projectNumber)")
save_state_var "PROJECT_1_NUMBER" "${PROJECT_1_NUMBER}"
save_state_var "PROJECT_2_NUMBER" "${PROJECT_2_NUMBER}"

# Grant roles/owner to active gcloud user and ADC user to ensure agents-cli has full deployment access
print_step "Ensuring active user and ADC identity have owner roles on folder..."
ACTIVE_USER=$(gcloud config get-value account 2>/dev/null || true)
ADC_USER=$(python3 -c "import json, os; p=os.path.expanduser('~/.config/gcloud/application_default_credentials.json'); print(json.load(open(p)).get('account','')) if os.path.exists(p) else print('')" 2>/dev/null || true)

for acct in "$ACTIVE_USER" "$ADC_USER"; do
  if [ -n "$acct" ]; then
    gcloud resource-manager folders add-iam-policy-binding "${FOLDER_ID}" --member="user:${acct}" --role="roles/owner" --quiet 2>/dev/null || true
    gcloud projects add-iam-policy-binding "${PROJECT_1_ID}" --member="user:${acct}" --role="roles/aiplatform.admin" --quiet 2>/dev/null || true
  fi
done
print_success "Deployer IAM permissions synchronized."

# 5. Enable APIs
print_step "Enabling required APIs on Project 1 (${PROJECT_1_ID})..."
gcloud services enable \
  aiplatform.googleapis.com \
  storage.googleapis.com \
  iam.googleapis.com \
  cloudresourcemanager.googleapis.com \
  --project="${PROJECT_1_ID}"
print_success "APIs enabled on Project 1."

print_step "Enabling required APIs on Project 2 (${PROJECT_2_ID})..."
gcloud services enable \
  storage.googleapis.com \
  --project="${PROJECT_2_ID}"
print_success "APIs enabled on Project 2."

# 6. Create GCS Buckets and seed data
print_step "Creating GCS Bucket in Project 1: gs://${BUCKET_P1}..."
if ! gcloud storage buckets describe "gs://${BUCKET_P1}" --project="${PROJECT_1_ID}" &>/dev/null; then
  gcloud storage buckets create "gs://${BUCKET_P1}" --project="${PROJECT_1_ID}" --location="${REGION}" --uniform-bucket-level-access
fi
echo "Project 1 Public Report - Q3 AI Operations Metrics" | gcloud storage cp - "gs://${BUCKET_P1}/project1_q3_report.txt"
echo "Project 1 Public Architecture - ADK Deployment Specs" | gcloud storage cp - "gs://${BUCKET_P1}/agent_architecture_specs.md"
print_success "Project 1 bucket seeded with normal files."

print_step "Creating Confidential GCS Bucket in Project 2: gs://${BUCKET_P2}..."
if ! gcloud storage buckets describe "gs://${BUCKET_P2}" --project="${PROJECT_2_ID}" &>/dev/null; then
  gcloud storage buckets create "gs://${BUCKET_P2}" --project="${PROJECT_2_ID}" --location="${REGION}" --uniform-bucket-level-access
fi
echo "CONFIDENTIAL: Executive Board Compensation & Payroll Records 2026" | gcloud storage cp - "gs://${BUCKET_P2}/classified_payroll_records.csv"
echo "CONFIDENTIAL: M&A Acquisition Targets & Financial Projections" | gcloud storage cp - "gs://${BUCKET_P2}/confidential_merger_targets.pdf"
print_success "Project 2 bucket seeded with confidential files."

print_header "Infrastructure Setup Complete!"
echo -e "${GREEN}Folder ID:${RESET}        ${FOLDER_ID}"
echo -e "${GREEN}Project 1 ID:${RESET}     ${PROJECT_1_ID} (Number: ${PROJECT_1_NUMBER})"
echo -e "${GREEN}Project 2 ID:${RESET}     ${PROJECT_2_ID} (Number: ${PROJECT_2_NUMBER})"
echo -e "${GREEN}Project 1 Bucket:${RESET} gs://${BUCKET_P1}"
echo -e "${GREEN}Project 2 Bucket:${RESET} gs://${BUCKET_P2} (Confidential)"
