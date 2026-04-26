#!/bin/bash

set -e

# ====== CONFIG ======
NAMESPACE="ollama"
DEPLOYMENT_NAME="ollama"
CONTAINER_NAME="ollama"
SERVICE_NAME="ollama"
MODELS=("llama3.2:3b" "mistral:7b" "all-minilm:33m")

PVC_FILE="pvc.yaml"
DEPLOY_FILE="deployment.yaml"
SVC_FILE="service.yaml"

# ====== STEP 1: CREATE NAMESPACE ======
echo "Creating namespace: $NAMESPACE"
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create namespace $NAMESPACE

# ====== STEP 2: STORAGECLASS CONDITION ======
read -p "Do you want to set a StorageClass? (y/n): " USE_SC

if [[ "$USE_SC" == "y" || "$USE_SC" == "Y" ]]; then
    echo "Applying StorageClass to PVC..."

    TMP_PVC="pvc_tmp.yaml"

    awk '
    /spec:/ && !sc_added {
        print
        print "  storageClassName: ocs-external-storagecluster-ceph-rbd"
        sc_added=1
        next
    }
    {print}
    ' $PVC_FILE > $TMP_PVC

    kubectl apply -n $NAMESPACE -f $TMP_PVC
else
    echo "Deploying PVC without StorageClass..."
    kubectl apply -n $NAMESPACE -f $PVC_FILE
fi

# ====== APPLY DEPLOYMENT & SERVICE ======
echo "Applying Deployment and Service..."
kubectl apply -n $NAMESPACE -f $DEPLOY_FILE
kubectl apply -n $NAMESPACE -f $SVC_FILE

# ====== WAIT FOR DEPLOYMENT ======
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE

# ====== STEP 3: DOWNLOAD MODELS ======
echo "Downloading models inside Ollama pod..."

POD=$(kubectl get pods -n $NAMESPACE -l app=$DEPLOYMENT_NAME -o jsonpath="{.items[0].metadata.name}")

for model in "${MODELS[@]}"; do
    echo "Pulling model: $model"
    kubectl exec -n $NAMESPACE $POD -c $CONTAINER_NAME -- ollama pull $model
done

# ====== STEP 4: TEST API ======
echo "Testing Ollama API..."

kubectl port-forward svc/$SERVICE_NAME -n $NAMESPACE 11434:11434 >/dev/null 2>&1 &
PF_PID=$!

sleep 5

for model in "${MODELS[@]}"; do
    echo "Testing model: $model"

    RESPONSE=$(curl -s http://localhost:11434/api/generate \
        -d "{
            \"model\": \"$model\",
            \"prompt\": \"Hello\",
            \"stream\": false
        }")

    if [[ $RESPONSE == *"response"* ]]; then
        echo "✅ $model is working"
    else
        echo "❌ $model failed"
    fi
done

# Cleanup
kill $PF_PID

echo "All steps completed successfully."
