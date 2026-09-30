#!/usr/bin/env bash
# ==============================================================================
# Script: Backend Smoke Test
# Direct API / CLI test for verifying the before/after behavior from the terminal.
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

print_header "Running Terminal Smoke Test for PAB Demo"

print_step "1. Testing Project 1 Bucket Access (gs://${BUCKET_P1})..."
gcloud storage ls "gs://${BUCKET_P1}" || {
  print_error "Failed to list Project 1 bucket."
}
print_success "Project 1 Bucket listed successfully."

print_step "2. Testing Project 2 Bucket Access (gs://${BUCKET_P2})..."
if gcloud storage ls "gs://${BUCKET_P2}" &>/dev/null; then
  print_warning "Project 2 Bucket was listed (Allowed under current identity/PAB status)."
else
  print_success "Project 2 Bucket access was DENIED (PAB is actively enforcing boundary!)."
fi
