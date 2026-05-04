#!/usr/bin/env bash

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_APP_FILE="$SCRIPT_DIR/../gitops/root-application.yaml"
APP_NAME="genai-root"
APP_NAMESPACE="openshift-gitops"

if [[ ! -f "$ROOT_APP_FILE" ]]; then
  echo -e "${RED}Error: root application manifest not found at $ROOT_APP_FILE${NC}"
  exit 1
fi

if command -v oc >/dev/null 2>&1; then
  KUBECTL_CMD="oc"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="kubectl"
else
  echo -e "${RED}Error: neither oc nor kubectl is installed or available in PATH.${NC}"
  exit 1
fi

echo -e "${BLUE}=== Deploying root Argo CD application ===${NC}"
$KUBECTL_CMD apply -f "$ROOT_APP_FILE"

echo -e "${BLUE}=== Waiting for Application resource to appear ===${NC}"
for i in {1..30}; do
  if $KUBECTL_CMD get application "$APP_NAME" -n "$APP_NAMESPACE" >/dev/null 2>&1; then
    echo -e "${GREEN}Application '$APP_NAME' exists in namespace '$APP_NAMESPACE'.${NC}"
    break
  fi
  sleep 2
  if [[ $i -eq 30 ]]; then
    echo -e "${YELLOW}Warning: Application '$APP_NAME' not found after 60 seconds.${NC}"
  fi
done

if [[ "$KUBECTL_CMD" == "oc" ]]; then
  echo -e "${BLUE}=== Listing available OpenShift routes ===${NC}"
  oc get route --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOST:.spec.host,TLS:.spec.tls.termination --no-headers | awk '{scheme = ($4 == "" ? "http://" : "https://"); print $1 " " $2 " " scheme $3}'
else
  echo -e "${YELLOW}Note: route listing is only supported with 'oc' in OpenShift environments.${NC}"
fi

echo -e "${GREEN}=== Deployment helper finished ===${NC}"
