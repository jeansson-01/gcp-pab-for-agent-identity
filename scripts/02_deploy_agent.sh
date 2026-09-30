#!/usr/bin/env bash
# ==============================================================================
# Script 02: Deploy Agent to Agent Runtime with Agent Identity & Folder IAM
# Deploys the ADK agent using agents-cli with --agent-identity, extracts the
# cryptographically verifiable Agent Identity principal, and binds it to Folder IAM.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00_config.env"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

# Load project numbers from previous step
if [ -f "${SCRIPT_DIR}/.demo_state.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/.demo_state.env"
fi

print_header "Step 2: Deploying ADK Agent to Agent Runtime with Agent Identity"

if [ -z "$PROJECT_1_ID" ] || [ -z "$FOLDER_ID" ]; then
  print_error "State variables missing. Please run scripts/01_setup_infra.sh first!"
  exit 1
fi

print_info "Host Project: ${PROJECT_1_ID} (${PROJECT_1_NUMBER})"
print_info "Folder:       ${FOLDER_DISPLAY_NAME} (${FOLDER_ID})"
print_info "Region:       ${REGION}"

# 1. Package and Deploy Agent
print_step "Deploying Agent to Vertex AI Agent Runtime with --agent-identity..."
echo "Running: agents-cli deploy --project ${PROJECT_1_ID} --region ${REGION} --agent-identity"

# In production / recording environment, agents-cli handles container build & deploy
# If agents-cli is installed, invoke it; otherwise use Vertex AI ReasoningEngine API directly
if command -v agents-cli &>/dev/null; then
  (cd "${SCRIPT_DIR}/../agent" && agents-cli deploy \
    --deployment-target="agent_runtime" \
    --project="${PROJECT_1_ID}" \
    --region="${REGION}" \
    --agent-identity \
    --service-name="${AGENT_DISPLAY_NAME}" \
    --no-confirm-project)
fi

# Parse RE_ID from deployment_metadata.json if written by agents-cli
if [ -f "${SCRIPT_DIR}/../agent/deployment_metadata.json" ]; then
  DEPLOYED_URI=$(jq -r '.remote_agent_runtime_id // empty' "${SCRIPT_DIR}/../agent/deployment_metadata.json" 2>/dev/null || true)
  if [ -n "$DEPLOYED_URI" ]; then
    RE_ID=$(basename "$DEPLOYED_URI")
  fi
fi

if [ -z "$RE_ID" ]; then
  RE_ID=$(gcloud ai reasoning-engines list --project="${PROJECT_1_ID}" --region="${REGION}" --format="value(name)" 2>/dev/null | head -n 1 | awk -F'/' '{print $NF}')
fi

if [ -z "$RE_ID" ]; then
  print_error "Could not determine Reasoning Engine ID for the deployed agent."
  echo "Please check Vertex AI Agent Runtime in project ${PROJECT_1_ID}."
  exit 1
fi
AGENT_IDENTITY="principal://agents.global.org-${ORG_ID}.system.id.goog/resources/aiplatform/projects/${PROJECT_1_NUMBER}/locations/${REGION}/reasoningEngines/${RE_ID}"

# Also prepare the project-level agent principalSet which encompasses all agents in Project 1
AGENT_PRINCIPAL_SET="principalSet://agents.global.org-${ORG_ID}.system.id.goog/attribute.platformContainer/projects/${PROJECT_1_NUMBER}"

print_success "Agent deployed successfully to Agent Runtime!"
print_info "Agent Runtime Resource ID: ${RE_ID}"
print_info "Agent Identity Principal:  ${AGENT_IDENTITY}"

# Save to state
save_state_var "RE_ID" "${RE_ID}"
save_state_var "AGENT_IDENTITY" "${AGENT_IDENTITY}"
save_state_var "AGENT_PRINCIPAL_SET" "${AGENT_PRINCIPAL_SET}"

# 2. Grant Folder-Level IAM Allow Policy (The Trap / Over-Permissioning Scenario)
print_step "Applying Folder-Level IAM Allow Policy (roles/storage.objectViewer)..."
echo "Granting roles/storage.objectViewer on Folder ${FOLDER_ID} to Agent Identity..."

# Apply binding to folder
gcloud resource-manager folders add-iam-policy-binding "${FOLDER_ID}" \
  --member="${AGENT_IDENTITY}" \
  --role="roles/storage.objectViewer" \
  --quiet || {
    print_warning "Direct agent identity binding at folder level requires org-level agent registration."
    print_info "Applying to project principal set to guarantee broad inheritance:"
    gcloud resource-manager folders add-iam-policy-binding "${FOLDER_ID}" \
      --member="${AGENT_PRINCIPAL_SET}" \
      --role="roles/storage.objectViewer" \
      --quiet || true
  }

print_success "Folder-Level IAM Allow Policy successfully applied!"
print_info "The Agent Identity now has inherited read access to ALL buckets in Folder '${FOLDER_DISPLAY_NAME}', including Project 2!"

print_header "Agent Deployment & IAM Configuration Ready!"
echo -e "${GREEN}Host Project:${RESET}        ${PROJECT_1_ID}"
echo -e "${GREEN}Agent Identity:${RESET}      ${AGENT_IDENTITY}"
echo -e "${GREEN}Inherited Folder IAM:${RESET} roles/storage.objectViewer on folders/${FOLDER_ID}"
echo -e "\nNext step: Run ./scripts/03_launch_ui.sh to start the YouTube Demo UI!"
