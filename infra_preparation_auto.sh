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


MANIFEST="manifest.yaml"
NAMESPACE="default"

echo "Deploying Kubernetes manifest..."
log kubectl apply -n "$NAMESPACE" -f "$MANIFEST" --dry-run=client

echo "Deployment complete."