#!/bin/bash

set -euo pipefail

NAMESPACE="openshift-user-workload-monitoring"

# Ensure user workload monitoring is enabled
echo "Ensuring user workload monitoring is enabled..."

if oc -n openshift-monitoring get configmap cluster-monitoring-config >/dev/null 2>&1; then
  echo "ConfigMap 'cluster-monitoring-config' already exists. Patching it..."
  oc -n openshift-monitoring patch configmap cluster-monitoring-config \
    --type=merge \
    -p='{"data":{"config.yaml":"enableUserWorkload: true\n"}}'
else
  echo "Creating configmap 'cluster-monitoring-config'..."
  oc -n openshift-monitoring create configmap cluster-monitoring-config \
    --from-literal=config.yaml='enableUserWorkload: true'
fi

# Wait for at least one pod in openshift-user-workload-monitoring to be Ready
echo "Waiting for user workload monitoring pods to be ready (namespace: $NAMESPACE)..."

while true; do
  ready_count=$(oc get pods -n "$NAMESPACE" \
    -o jsonpath='{range .items[*]}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}' \
    | grep -c "True" || 0)

  if [ "$ready_count" -gt 0 ]; then
    echo "Found $ready_count Ready pod(s) in namespace $NAMESPACE."
    break
  fi

  echo "No Ready pods in $NAMESPACE yet; waiting 5s..."
  sleep 5
done

echo "Now you can deploy a ServiceMonitor to allow the monitoring operator to gather metrics from a user namespace."