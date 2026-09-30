#!/usr/bin/env bash
# ==============================================================================
# Helper utilities, ANSI colors, and pre-flight checks for PAB Demo
# ==============================================================================

# ANSI Color Codes
BOLD="\033[1m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
RESET="\033[0m"

print_header() {
  echo -e "\n${BOLD}${CYAN}══════════════════════════════════════════════════════════════════════════${RESET}"
  echo -e "${BOLD}${CYAN}  $1${RESET}"
  echo -e "${BOLD}${CYAN}══════════════════════════════════════════════════════════════════════════${RESET}\n"
}

print_step() {
  echo -e "${BOLD}${BLUE}==>${RESET} ${BOLD}$1${RESET}"
}

print_success() {
  echo -e "   ${GREEN}✔${RESET} $1"
}

print_warning() {
  echo -e "   ${YELLOW}⚠${RESET} $1"
}

print_error() {
  echo -e "   ${RED}✖${RESET} $1"
}

print_info() {
  echo -e "   ${MAGENTA}ℹ${RESET} $1"
}

check_prerequisites() {
  local missing_tools=()
  for cmd in gcloud jq uv; do
    if ! command -v "$cmd" &>/dev/null; then
      missing_tools+=("$cmd")
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_error "Missing required tools: ${missing_tools[*]}"
    echo "Please install them before running this demo."
    exit 1
  fi

  if [ -z "$ORG_ID" ]; then
    print_info "Attempting to auto-detect Organization ID via gcloud..."
    ORG_ID=$(gcloud organizations list --format="value(name)" 2>/dev/null | head -n 1 | sed 's/organizations\///')
    if [ -n "$ORG_ID" ]; then
      print_success "Auto-detected Organization ID: ${ORG_ID}"
    elif [ -t 0 ]; then
      echo -e "\n${BOLD}${YELLOW}Organization ID is required.${RESET}"
      read -r -p "Enter your Google Cloud Organization ID (numerical): " ORG_ID
    fi
  fi

  if [ -z "$ORG_ID" ]; then
    print_error "ORGANIZATION_ID is not set."
    echo "Please set export ORG_ID='<YOUR_NUMERICAL_ORG_ID>' in scripts/00_config.env or in your terminal."
    exit 1
  fi

  if [ -z "$BILLING_ACCOUNT_ID" ]; then
    print_info "Attempting to auto-detect active Billing Account ID via gcloud..."
    BILLING_ACCOUNT_ID=$(gcloud billing accounts list --filter="open=true" --format="value(name)" 2>/dev/null | head -n 1 | sed 's/billingAccounts\///')
    if [ -n "$BILLING_ACCOUNT_ID" ]; then
      print_success "Auto-detected Billing Account ID: ${BILLING_ACCOUNT_ID}"
    elif [ -t 0 ]; then
      echo -e "\n${BOLD}${YELLOW}Billing Account ID is required.${RESET}"
      read -r -p "Enter your Google Cloud Billing Account ID (format: XXXXXX-XXXXXX-XXXXXX): " BILLING_ACCOUNT_ID
    fi
  fi

  if [ -z "$BILLING_ACCOUNT_ID" ]; then
    print_error "BILLING_ACCOUNT_ID is not set."
    echo "Please set export BILLING_ACCOUNT_ID='<YOUR_BILLING_ACCOUNT_ID>' in scripts/00_config.env or in your terminal."
    exit 1
  fi
}

save_state_var() {
  local key="$1"
  local val="$2"
  local state_file="${SCRIPT_DIR}/.demo_state.env"
  touch "$state_file"
  local tmp_file="${state_file}.tmp.$$"
  grep -v "^export ${key}=" "$state_file" > "$tmp_file" 2>/dev/null || true
  echo "export ${key}=${val}" >> "$tmp_file"
  mv "$tmp_file" "$state_file"
}

