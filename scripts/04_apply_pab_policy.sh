#!/usr/bin/env bash
# ==============================================================================
# Script 04: Apply Principal Access Boundary (PAB) Policy
# Enforces an identity containment perimeter restricting principals originating
# in Project 1 from accessing any resources outside Project 1.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00_config.env"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

if [ -f "${SCRIPT_DIR}/.demo_state.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/.demo_state.env"
fi

if [ -z "$PROJECT_1_NUMBER" ]; then
  PROJECT_1_NUMBER=$(gcloud projects describe "${PROJECT_1_ID}" --format="value(projectNumber)" 2>/dev/null || true)
fi

# Principal set targeting ONLY Agent Identities in Project 1:
# Format per Google Cloud IAM PAB documentation:
# //agents.global.org-ORGANIZATION_ID.system.id.goog/attribute.container/projects/PROJECT_NUMBER
AGENT_PRINCIPAL_SET="//agents.global.org-${ORG_ID}.system.id.goog/attribute.container/projects/${PROJECT_1_NUMBER}"

print_header "Creating & Enforcing Principal Access Boundary (PAB)"

print_info "Organization ID:        ${ORG_ID}"
print_info "Host Project 1:         ${PROJECT_1_ID} (Project Number: ${PROJECT_1_NUMBER})"
print_info "Target Project 2:       ${PROJECT_2_ID} (Will be BLOCKED by PAB)"
print_info "PAB Policy ID:          ${PAB_POLICY_ID}"
print_info "PAB Binding ID:         ${PAB_BINDING_ID}"
print_info "Target Principal Set:   ${AGENT_PRINCIPAL_SET} (Agent Identities ONLY)"

# 1. Create Organization-Level PAB Policy
print_step "Creating Organization-level PAB Policy..."
echo "Policy Rule: ALLOW access ONLY to resources within //cloudresourcemanager.googleapis.com/projects/${PROJECT_1_ID}"

# Check if policy already exists
if ! gcloud iam principal-access-boundary-policies describe "${PAB_POLICY_ID}" --organization="${ORG_ID}" --location="global" &>/dev/null; then
  gcloud iam principal-access-boundary-policies create "${PAB_POLICY_ID}" \
    --organization="${ORG_ID}" \
    --location="global" \
    --display-name="PAB Agent Containment Policy" \
    --details-rules="[{\"description\":\"Allow access ONLY to Project 1\",\"effect\":\"ALLOW\",\"resources\":[\"//cloudresourcemanager.googleapis.com/projects/${PROJECT_1_ID}\"]}]"
  print_success "PAB Policy created: ${PAB_POLICY_ID}"
else
  print_success "PAB Policy already exists: ${PAB_POLICY_ID}"
fi

# 2. Create Policy Binding on Project 1 targeting only Agent Identities
print_step "Binding PAB Policy to Project 1's Agent Identities..."
echo "Target Principal Set: ${AGENT_PRINCIPAL_SET}"

if ! gcloud iam policy-bindings describe "${PAB_BINDING_ID}" --project="${PROJECT_1_ID}" --location="global" &>/dev/null; then
  MAX_RETRIES=6
  RETRY_COUNT=0
  BINDING_SUCCESS=false

  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    # Attempt to create policy binding
    SET_E_STATE="$(set +o | grep errexit)"
    set +e
    BINDING_OUTPUT=$(gcloud iam policy-bindings create "${PAB_BINDING_ID}" \
      --project="${PROJECT_1_ID}" \
      --location="global" \
      --display-name="Bind PAB to Project 1 Agent Identities" \
      --policy="organizations/${ORG_ID}/locations/global/principalAccessBoundaryPolicies/${PAB_POLICY_ID}" \
      --target-principal-set="${AGENT_PRINCIPAL_SET}" 2>&1)
    EXIT_CODE=$?
    eval "$SET_E_STATE"

    if [ $EXIT_CODE -eq 0 ]; then
      print_success "Policy binding created: ${PAB_BINDING_ID}"
      BINDING_SUCCESS=true
      break
    elif echo "$BINDING_OUTPUT" | grep -q "POLICY_NOT_FOUND"; then
      print_info "Waiting for newly created PAB policy to propagate across IAM (attempt ${RETRY_COUNT}/${MAX_RETRIES})..."
      sleep 5
    else
      echo "$BINDING_OUTPUT"
      print_error "Failed to create policy binding."
      exit 1
    fi
  done

  if [ "$BINDING_SUCCESS" != "true" ]; then
    print_error "Timed out waiting for PAB policy to propagate."
    exit 1
  fi
else
  print_success "Policy binding already exists: ${PAB_BINDING_ID}"
fi

# 3. Verify Active Policy Binding
print_step "Verifying Policy Binding Status..."
gcloud iam policy-bindings describe "${PAB_BINDING_ID}" --project="${PROJECT_1_ID}" --location="global" --format="yaml(name,policy,target)"

print_header "🛡️ PAB Security Perimeter is Now Active!"
echo -e "${GREEN}Status:${RESET}              ENFORCED"
echo -e "${GREEN}Target Principals:${RESET}   Agent Identities in Project 1 ONLY"
echo -e "${GREEN}Target Principal Set:${RESET} ${AGENT_PRINCIPAL_SET}"
echo -e "${GREEN}Allowed Scope:${RESET}       Project 1 (${PROJECT_1_ID}) ONLY"
echo -e "${RED}Blocked Scope:${RESET}       Project 2 (${PROJECT_2_ID}) and all other projects"
echo -e "${YELLOW}Important Note:${RESET}     Only Agent Identities are constrained. Human users, service accounts, and other identities are unaffected!"
echo -e "\nSwitch back to your Demo Web UI (http://localhost:8501) and try querying Project 2's bucket again!"

