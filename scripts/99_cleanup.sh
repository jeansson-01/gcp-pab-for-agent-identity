#!/usr/bin/env bash
# ==============================================================================
# Script 99: Cleanup All Demo Resources
# Safely tears down policy bindings, PAB policy, projects, and the folder.
# ==============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00_config.env"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

if [ -f "${SCRIPT_DIR}/.demo_state.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/.demo_state.env"
fi

print_header "Step 99: Cleaning Up All PAB Demo Resources"

read -p "Are you sure you want to delete projects ${PROJECT_1_ID} and ${PROJECT_2_ID}? (y/N): " -r CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Cleanup cancelled."
  exit 0
fi

# 1. Delete Policy Binding
print_step "Deleting PAB Policy Binding (${PAB_BINDING_ID})..."
gcloud iam policy-bindings delete "${PAB_BINDING_ID}" --project="${PROJECT_1_ID}" --location="global" --quiet 2>/dev/null || true
print_success "Policy binding removed."

# 2. Delete PAB Policy
print_step "Deleting Organization PAB Policy (${PAB_POLICY_ID})..."
gcloud iam principal-access-boundary-policies delete "${PAB_POLICY_ID}" --organization="${ORG_ID}" --location="global" --quiet 2>/dev/null || true
print_success "PAB Policy removed."

# 3. Delete Project 1
print_step "Deleting Project 1 (${PROJECT_1_ID})..."
gcloud projects delete "${PROJECT_1_ID}" --quiet 2>/dev/null || true
print_success "Project 1 deleted."

# 4. Delete Project 2
print_step "Deleting Project 2 (${PROJECT_2_ID})..."
gcloud projects delete "${PROJECT_2_ID}" --quiet 2>/dev/null || true
print_success "Project 2 deleted."

# 5. Delete Folder (Optional)
if [ -n "$FOLDER_ID" ]; then
  print_step "Deleting Folder 'my-awesome-PAB-demo' (${FOLDER_ID})..."
  # Allow time for projects to clear out
  sleep 5
  gcloud resource-manager folders delete "${FOLDER_ID}" --quiet 2>/dev/null || print_warning "Folder could not be immediately deleted (projects may take a few minutes to fully purge in GCP)."
fi

# Remove local state file
rm -f "${SCRIPT_DIR}/.demo_state.env"
print_success "Local state file cleaned up."

print_header "Cleanup Finished! All demo resources have been purged."
