#!/bin/bash

set -euo pipefail

GRAFANA_NAMESPACE="grafana"
GRAFANA_RELEASE="grafana"

echo "Ensuring project '$GRAFANA_NAMESPACE' exists..."

if oc get project "$GRAFANA_NAMESPACE" >/dev/null 2>&1; then
  echo "Project '$GRAFANA_NAMESPACE' already exists, using it."
else
  oc new-project "$GRAFANA_NAMESPACE"
  echo "Project '$GRAFANA_NAMESPACE' created."
fi

echo "Adding Grafana Helm chart repository..."
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Check if Helm release already exists; if yes, skip install
echo "Checking Helm release '$GRAFANA_RELEASE' in namespace '$GRAFANA_NAMESPACE'..."

if helm status "$GRAFANA_RELEASE" -n "$GRAFANA_NAMESPACE" >/dev/null 2>&1; then
  echo "Helm release '$GRAFANA_RELEASE' already exists. Skipping installation."
else
  echo "Installing Helm release '$GRAFANA_RELEASE'..."
  helm install "$GRAFANA_RELEASE" grafana/grafana \
    --set securityContext.runAsUser=null,securityContext.fsGroup=null \
    -n "$GRAFANA_NAMESPACE"
fi

echo "Granting cluster-monitoring-view role to the 'grafana' service account..."
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana -n "$GRAFANA_NAMESPACE"

echo "Creating a long‑lived token for the 'grafana' service account (valid for 200 hours)..."
oc create token grafana --duration=200h -n "$GRAFANA_NAMESPACE"

# Get Grafana admin credentials from the secret created by the chart
echo
echo "✅ Grafana installation (or pre‑existing) complete."

GRAFANA_SECRET_NAME="grafana"
GRAFANA_USER_B64=$(oc get secret "$GRAFANA_SECRET_NAME" -n "$GRAFANA_NAMESPACE" -o jsonpath='{.data.admin-user}')
GRAFANA_PASS_B64=$(oc get secret "$GRAFANA_SECRET_NAME" -n "$GRAFANA_NAMESPACE" -o jsonpath='{.data.admin-password}')

GRAFANA_USER=$(echo "$GRAFANA_USER_B64" | base64 -d)
GRAFANA_PASS=$(echo "$GRAFANA_PASS_B64" | base64 -d)

echo "Grafana admin username: $GRAFANA_USER"
echo "Grafana admin password: $GRAFANA_PASS"

# Print Grafana URL (if Route exists)
if oc get route grafana -n "$GRAFANA_NAMESPACE" >/dev/null 2>&1; then
  GRAFANA_HOST=$(oc get route grafana -n "$GRAFANA_NAMESPACE" -o jsonpath='{.spec.host}')
  echo "Grafana web UI URL: https://${GRAFANA_HOST}"
else
  echo "Grafana Route not found yet. You can expose it with:"
  echo "  oc expose svc/grafana -n $GRAFANA_NAMESPACE"
fi