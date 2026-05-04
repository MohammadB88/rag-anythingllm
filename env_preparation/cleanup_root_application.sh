#!/usr/bin/env bash

set -euo pipefail

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
  echo "Error: neither oc nor kubectl is installed or available in PATH."
  exit 1
fi

echo "=== Cleaning up Argo CD root deployment ==="
for manifest in "${APP_MANIFESTS[@]}"; do
  if [[ -f "$manifest" ]]; then
    echo "Deleting application manifest: $manifest"
    $KUBECTL_CMD delete -f "$manifest" --ignore-not-found
  else
    echo "Skipping missing manifest: $manifest"
  fi
done

echo "=== Cleanup complete ==="
