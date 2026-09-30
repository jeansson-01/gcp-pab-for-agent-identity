#!/usr/bin/env bash
# ==============================================================================
# Script 03: Launch YouTube Demo Web UI & Cloud Console Links
# Starts the Streamlit-based high-contrast visual chat interface and provides
# direct deep links to the Google Cloud Console Reasoning Engine Playground.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/00_config.env"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/common.sh"

if [ -f "${SCRIPT_DIR}/.demo_state.env" ]; then
  # shellcheck disable=SC1090
  source "${SCRIPT_DIR}/.demo_state.env"
fi

print_header "Step 3: Launching Demo UI for Recording"

print_info "Host Project (Agent):      ${PROJECT_1_ID}"
print_info "Target Project (Data):     ${PROJECT_2_ID}"
print_info "Project 1 Bucket:          gs://${BUCKET_P1}"
print_info "Project 2 Bucket:          gs://${BUCKET_P2} (Confidential)"

echo -e "\n${BOLD}${CYAN}🔗 Cloud Console Playground Deep Link (Optional alternative):${RESET}"
echo -e "   https://console.cloud.google.com/vertex-ai/reasoning-engines?project=${PROJECT_1_ID}\n"

# Virtual Environment Configuration
VENV_DIR="${VIRTUAL_ENV:-${PROJECT_ROOT}/.venv}"

print_step "Checking Python virtual environment (${VENV_DIR})..."
if [ ! -d "${VENV_DIR}" ]; then
  print_info "Creating virtual environment at ${VENV_DIR}..."
  if command -v uv &>/dev/null; then
    uv venv "${VENV_DIR}"
  else
    python3 -m venv "${VENV_DIR}"
  fi
fi

VENV_PYTHON="${VENV_DIR}/bin/python"

if ! "${VENV_PYTHON}" -c "import streamlit" &>/dev/null; then
  print_warning "Streamlit is not installed in the virtual environment."
  print_info "Installing streamlit into ${VENV_DIR}..."
  if command -v uv &>/dev/null; then
    uv pip install --python "${VENV_PYTHON}" streamlit
  else
    "${VENV_DIR}/bin/pip" install --quiet streamlit
  fi
fi

print_success "Launching Storage Agent Chat UI on http://localhost:8501..."
echo -e "${YELLOW}Press Ctrl+C to stop the UI when recording is complete.${RESET}\n"

"${VENV_PYTHON}" -m streamlit run "${PROJECT_ROOT}/agent/ui.py" --server.port 8501 --server.headless true --server.runOnSave true

