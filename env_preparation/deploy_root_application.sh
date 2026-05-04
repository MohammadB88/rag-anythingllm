#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_APP_FILE="$SCRIPT_DIR/../gitops/root-application.yaml"
APP_NAME="genai-root"
APP_NAMESPACE="openshift-gitops"

if [[ ! -f "$ROOT_APP_FILE" ]]; then
  echo "Error: root application manifest not found at $ROOT_APP_FILE"
  exit 1
fi

if command -v oc >/dev/null 2>&1; then
  KUBECTL_CMD="oc"
elif command -v kubectl >/dev/null 2>&1; then
  KUBECTL_CMD="kubectl"
else
  echo "Error: neither oc nor kubectl is installed or available in PATH."
  exit 1
fi

echo "=== Deploying root Argo CD application ==="
$KUBECTL_CMD apply -f "$ROOT_APP_FILE"

echo "=== Waiting for Application resource to appear ==="
for i in {1..30}; do
  if $KUBECTL_CMD get application "$APP_NAME" -n "$APP_NAMESPACE" >/dev/null 2>&1; then
    echo "Application '$APP_NAME' exists in namespace '$APP_NAMESPACE'."
    break
  fi
  sleep 2
  if [[ $i -eq 30 ]]; then
    echo "Warning: Application '$APP_NAME' not found after 60 seconds."
  fi
done

if [[ "$KUBECTL_CMD" == "oc" ]]; then
  echo "=== Listing available OpenShift routes ==="
  oc get route --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOST:.spec.host,TLS:.spec.tls.termination --no-headers | awk '{scheme = ($4 == "" ? "http://" : "https://"); print $1 " " $2 " " scheme $3}'
else
  echo "Note: route listing is only supported with 'oc' in OpenShift environments."
fi

echo "=== Deployment helper finished ==="
