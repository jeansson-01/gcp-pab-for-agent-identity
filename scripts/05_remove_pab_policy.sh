#!/usr/bin/env bash
# ==============================================================================
# Script 05: Remove Principal Access Boundary (PAB) Policy
# Deletes the PAB policy binding and organization policy to reset the demo
# environment back to its unconstrained baseline state.
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

print_header "Removing Principal Access Boundary (Resetting Environment)"

print_info "Host Project:   ${PROJECT_1_ID}"
print_info "PAB Binding ID: ${PAB_BINDING_ID}"
print_info "PAB Policy ID:  ${PAB_POLICY_ID}"

# 1. Delete Policy Binding on Project 1
print_step "Removing PAB Policy Binding from Project 1..."
if gcloud iam policy-bindings describe "${PAB_BINDING_ID}" --project="${PROJECT_1_ID}" --location="global" &>/dev/null; then
  gcloud iam policy-bindings delete "${PAB_BINDING_ID}" --project="${PROJECT_1_ID}" --location="global" --quiet
  print_success "Policy binding '${PAB_BINDING_ID}' successfully deleted."
else
  print_info "Policy binding '${PAB_BINDING_ID}' does not exist or was already removed."
fi

# 2. Delete Organization PAB Policy
print_step "Deleting Organization-level PAB Policy..."
if gcloud iam principal-access-boundary-policies describe "${PAB_POLICY_ID}" --organization="${ORG_ID}" --location="global" &>/dev/null; then
  MAX_RETRIES=6
  RETRY_COUNT=0
  DELETE_SUCCESS=false

  while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    
    SET_E_STATE="$(set +o | grep errexit)"
    set +e
    DELETE_OUTPUT=$(gcloud iam principal-access-boundary-policies delete "${PAB_POLICY_ID}" --organization="${ORG_ID}" --location="global" --quiet 2>&1)
    EXIT_CODE=$?
    eval "$SET_E_STATE"

    if [ $EXIT_CODE -eq 0 ]; then
      print_success "PAB Policy '${PAB_POLICY_ID}' successfully deleted."
      DELETE_SUCCESS=true
      break
    elif echo "$DELETE_OUTPUT" | grep -q "POLICY_HAS_BINDINGS"; then
      print_info "Waiting for binding deletion to propagate across IAM (attempt ${RETRY_COUNT}/${MAX_RETRIES})..."
      sleep 5
    else
      echo "$DELETE_OUTPUT"
      print_error "Failed to delete PAB policy."
      exit 1
    fi
  done

  if [ "$DELETE_SUCCESS" != "true" ]; then
    print_error "Timed out waiting to delete PAB policy."
    exit 1
  fi
else
  print_info "PAB Policy '${PAB_POLICY_ID}' does not exist or was already removed."
fi

print_header "🔓 PAB Perimeter Removed — Baseline Environment Restored!"
echo -e "${YELLOW}Status:${RESET}          UNCONSTRAINED"
echo -e "${YELLOW}Access Effect:${RESET}   The Agent can now access Project 2's bucket again via Folder IAM."
echo -e "${CYAN}Next:${RESET}            You can re-run ./scripts/04_apply_pab_policy.sh at any time to re-enable PAB!"
