#!/usr/bin/env bash

set -euo pipefail

RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
DEFAULT="\e[39m"
RESET="\e[0m"

log()  { echo -e "${DEFAULT}" "$(date +%H:%M:%S)" "${CYAN}" "$*" "${RESET}" >&2; }
warn() { echo -e "${DEFAULT}" "$(date +%H:%M:%S)" "${YELLOW}" "$*" "${RESET}" >&2; }
die()  { echo -e "${DEFAULT}" "$(date +%H:%M:%S)" "${RED}" "$*" "${RESET}" >&2; exit 1; }


# -----------------------------
# Ask for dry-run
# -----------------------------
read -rp "Run in dry-run mode? [y/N]: " DRY_RUN_INPUT

if [[ "${DRY_RUN_INPUT,,}" == "y" || "${DRY_RUN_INPUT,,}" == "yes" ]]; then
  DRY_RUN="--dry-run=client"
  log "Dry-run mode ENABLED"
else
  DRY_RUN=""
  warn "Dry-run mode DISABLED (resources will be deleted)"
fi

# -----------------------------
# Delete GitOps resources
# -----------------------------
delete_resources() {
  local resource="$1"

  log "Deleting ${resource} (all namespaces)..."

  oc get "$resource" --all-namespaces -o name 2>/dev/null \
    | xargs -r oc delete $DRY_RUN
}

delete_resources applications.argoproj.io
delete_resources applicationsets.argoproj.io
delete_resources appprojects.argoproj.io

log "GitOps cleanup completed."