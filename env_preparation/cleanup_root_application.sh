#!/usr/bin/env bash

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GITOPS_DIR="$SCRIPT_DIR/../gitops"
APP_MANIFESTS=(
  "$GITOPS_DIR/root-application.yaml"
  "$GITOPS_DIR/anythingllm.yaml"
  "$GITOPS_DIR/minio.yaml"
  "$GITOPS_DIR/llm_llama.yaml"
  "$GITOPS_DIR/llm_vllm_granite.yaml"
)

if command -v oc >/dev/null 2>&1; then
  KUBECTL_CMD="oc"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="kubectl"
else
  echo -e "${RED}Error: neither oc nor kubectl is installed or available in PATH.${NC}"
  exit 1
fi

echo -e "${BLUE}=== Cleaning up Argo CD root deployment ===${NC}"
for manifest in "${APP_MANIFESTS[@]}"; do
  if [[ -f "$manifest" ]]; then
    echo -e "${YELLOW}Deleting application manifest: $manifest${NC}"
    $KUBECTL_CMD delete -f "$manifest" --ignore-not-found
  else
    echo -e "${YELLOW}Skipping missing manifest: $manifest${NC}"
  fi
done

echo -e "${GREEN}=== Cleanup complete ===${NC}"
