#!/usr/bin/env bash

set -euo pipefail

NAMESPACE="${1:-openshift-gitops}"

echo "##############################################################"
echo "remove applications from ${NAMESPACE}"
echo "##############################################################"


echo "=== Listing AppProjects in namespace ${NAMESPACE} ==="
kubectl get appprojects.argoproj.io -n "${NAMESPACE}" -o name

echo -e "\n=== Deleting AppProjects in namespace ${NAMESPACE} ==="

# Remove finalizers if they exist (to avoid hanging deletion)
kubectl get appprojects.argoproj.io -n "${NAMESPACE}" -o name | while read appproj; do
  echo "Removing finalizers from ${appproj} ..."
  kubectl patch "${appproj}" -n "${NAMESPACE}" --type=json \
    -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
done

# Delete all AppProjects
kubectl delete appprojects.argoproj.io --all -n "${NAMESPACE}"

echo -e "\n=== Done. AppProjects deleted in namespace ${NAMESPACE}."


echo "##############################################################"
echo "remove applications from ${NAMESPACE}"
echo "##############################################################"

echo "=== Listing Argo CD Applications in namespace ${NAMESPACE} ==="
kubectl get applications.argoproj.io -n "${NAMESPACE}" -o name

echo -e "\n=== Deleting ALL Applications in namespace ${NAMESPACE} ==="

kubectl get applications.argoproj.io -n "${NAMESPACE}" -o name | while read app; do
  echo "Removing finalizer from ${app} ..."
  kubectl patch "${app}" -n "${NAMESPACE}" --type=json \
    -p='[{"op": "remove", "path": "/metadata/finalizers"}]' 2>/dev/null || true
done

kubectl delete applications.argoproj.io --all -n "${NAMESPACE}"

echo -e "\n=== Done. Applications deleted in namespace ${NAMESPACE}."
