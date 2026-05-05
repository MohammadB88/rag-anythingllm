#!/usr/bin/env bash

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_APP_FILE="$SCRIPT_DIR/../gitops/root-application.yaml"
APP_NAME="genai-root"
APP_NAMESPACE="openshift-gitops"

if command -v oc >/dev/null 2>&1; then
  KUBECTL_CMD="oc"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="kubectl"
else
  echo -e "${RED}Error: neither oc nor kubectl is installed or available in PATH.${NC}"
  exit 1
fi

echo "**********************"
echo -e "${BLUE}=== Deploying root Argo CD application ===${NC}"
echo "**********************"
$KUBECTL_CMD apply -f "$ROOT_APP_FILE"

echo "**********************"
echo -e "${BLUE}=== Waiting for Application '$APP_NAME' to be ready (up to 2 minutes) ===${NC}"
echo "**********************"


wait_for_app_ready() {
  local max_attempts=60
  local attempt=1
  
  while [[ $attempt -le $max_attempts ]]; do
    # Check if application exists
    if ! $KUBECTL_CMD get application "$APP_NAME" -n "$APP_NAMESPACE" >/dev/null 2>&1; then
      echo -e "${YELLOW}[$attempt/$max_attempts] Waiting for Application '$APP_NAME' resource to appear...${NC}"
      sleep 2
      ((attempt++))
      continue
    fi
    
    # Check if application is synced and healthy
    local sync_status=$($KUBECTL_CMD get application "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.status.operationState.phase}' 2>/dev/null || echo "Unknown")
    local health_status=$($KUBECTL_CMD get application "$APP_NAME" -n "$APP_NAMESPACE" -o jsonpath='{.status.health.status}' 2>/dev/null || echo "Unknown")
    
    if [[ "$sync_status" == "Succeeded" ]] && [[ "$health_status" == "Healthy" ]]; then
      echo -e "${GREEN}✓ Application '$APP_NAME' is READY!${NC}"
      echo -e "${GREEN}  Sync Status: $sync_status${NC}"
      echo -e "${GREEN}  Health Status: $health_status${NC}"
      return 0
    fi
    
    # Still waiting
    printf -v remaining_time '%d seconds remaining\n' $((($max_attempts - $attempt) * 2))
    echo -e "${YELLOW}[$attempt/$max_attempts] Sync: $sync_status | Health: $health_status | $remaining_time${NC}"
    
    sleep 2
    ((attempt++))
  done
  
  # Timeout reached
  echo -e "${RED}✗ Application did not reach ready state within 2 minutes${NC}"
  echo -e "${YELLOW}Current status:${NC}"
  $KUBECTL_CMD describe application "$APP_NAME" -n "$APP_NAMESPACE" || true
  return 1
}

wait_for_app_ready

echo "**********************"
if [[ "$KUBECTL_CMD" == "oc" ]]; then
  echo -e "${BLUE}=== Listing available OpenShift routes ===${NC}"
  echo "**********************"
  oc get route --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOST:.spec.host,TLS:.spec.tls.termination --no-headers | awk '{scheme = ($4 == "" ? "http://" : "https://"); print $1 " " $2 " " scheme $3}'
else
  echo -e "${YELLOW}Note: route listing is only supported with 'oc' in OpenShift environments.${NC}"
fi

echo "**********************"
echo -e "${GREEN}=== Deployment helper finished ===${NC}"
echo "**********************"
