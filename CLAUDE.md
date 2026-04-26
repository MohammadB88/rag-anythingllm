# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GenAI Application Platform - A production-ready infrastructure for deploying Generative AI applications on OpenShift, featuring multiple LLM serving runtimes, vector databases, object storage, API gateways, web interfaces, and monitoring.

## Architecture Components

- **Model Serving Runtimes**: Ollama (CPU), vLLM (CPU/GPU), NVIDIA NIM (GPU)
- **Vector Database**: Milvus for embeddings and similarity search
- **Object Storage**: MinIO (S3-compatible)
- **API Gateway**: LiteLLM for unified model API access
- **Web GUIs**: AnythingLLM, OpenWebUI for document management and chat
- **Monitoring**: Grafana dashboards + Prometheus (ServiceMonitor-based metrics)
- **Load Testing**: k6-based test suite (smoke, stress, spike, soak, breakpoint tests)

## Directory Structure

```
genai-application/
├── env_preparation/        # Environment setup/cleanup scripts
├── gitops/                 # ArgoCD AppProject/Application manifests
├── models/                 # LLM deployments
│   ├── ollama/            # CPU-based Ollama runtime
│   ├── vllm/              # vLLM CPU/GPU with OpenShift AI
│   └── nvidia_nim/        # NVIDIA NIM GPU microservices
├── vectordb/milvus/        # Milvus vector DB (Helm values + manifests)
├── s3_storage/minio_on_openshift/  # MinIO object storage
├── web_interfaces/         # GUI deployments (AnythingLLM, OpenWebUI)
├── monitoring_alerting/    # Grafana, Prometheus rules, ServiceMonitors
├── tests/last_und_performance/  # k6 load/performance tests
└── rag_usecase/            # RAG architecture reference implementation
```

## Commands

### Prerequisites
- `oc` or `kubectl` configured for OpenShift 4.x+
- Helm 3.x (for Milvus, k6-operator deployments)

### Environment Setup
```sh
# Remove ArgoCD resources (dry-run first)
./env_preparation/remove_resources_argocd.sh

# Remove namespace resources
./env_preparation/remove_resources_ns.sh

# Enable user workload monitoring (required for ServiceMonitors)
oc -n openshift-monitoring create configmap cluster-monitoring-config \
  --from-literal=config.yaml='enableUserWorkload: true'
```

### Deploy Components

```sh
# MinIO storage
kubectl apply -f s3_storage/minio_on_openshift/all_resources.yaml

# Milvus vector DB (standalone)
helm template -f vectordb/milvus/openshift-values.yaml vectordb -n milvus \
  --set cluster.enabled=false --set etcd.replicaCount=1 \
  --set minio.mode=standalone milvus/milvus > milvus_manifest_standalone.yaml
kubectl apply -f milvus_manifest_standalone.yaml

# Ollama (CPU models)
kubectl apply -f models/ollama/all_resources.yaml
# Then pull models inside pod: ollama pull llama3.2:3b, all-minilm:33m

# vLLM via OpenShift AI UI (models stored in MinIO, served via KServe)

# NVIDIA NIM (GPU)
kubectl apply -f models/nvidia_nim/llama321b/  # Requires NGC API key secret

# AnythingLLM GUI
kubectl apply -f web_interfaces/anythingllm/all_resources.yaml

# k6 Operator for load testing
helm install k6-operator grafana/k6-operator -n k6-operator --create-namespace
```

### Load Testing with k6

```sh
# Deploy test script ConfigMap + TestRun
kubectl apply -f tests/last_und_performance/configmap.yaml
kubectl apply -f tests/last_und_performance/testrun.yaml

# Test types: smoke, average_load, stress, soak, spike, breakpoint
```

## Key Configuration Patterns

### GitOps (ArgoCD)
- AppProject `llms` in `openshift-gitops` namespace
- Deployments target `llms` namespace
- Source repo: GitHub (MohammadB88/rag-anythingllm)

### ServiceMonitor Setup
- Metrics endpoint: `/v1/metrics` (NIM models)
- Requires `enableUserWorkload: true` in cluster-monitoring-config
- ServiceMonitor discovers services with matching labels in user namespaces

### SecurityContext (OpenShift)
- Pods must run as non-root: `runAsNonRoot: true`
- Drop capabilities: `capabilities.drop: ["ALL"]`
- Use `seccompProfile.type: RuntimeDefault` where required

### Default Credentials
- MinIO: user=`minio`, password=`minio123`
- Milvus: user=`root`, password=`Milvus`

## RAG Architecture Flow

1. User uploads documents via AnythingLLM GUI
2. Documents sent to embedding model (Ollama: `all-minilm:33m`)
3. Embeddings stored in Milvus vector DB
4. Chat queries retrieve relevant vectors + send to LLM (Ollama: `llama3.2:3b`)
5. LLM generates response with source citations

## NVIDIA NIM Deployment

Requires NGC API key and GPU nodes:
```sh
# Create image pull secret
oc create secret docker-registry nim-pull-secret \
  --docker-username='$oauthtoken' --docker-server='nvcr.io' \
  --docker-password='nvapi-XXXXX'

# Deploy model (update NGC_API_KEY in deployment manifest)
kubectl apply -f models/nvidia_nim/llama321b/
```

## Grafana Dashboards

- GPU utilization: `grafana_openshift/gpu_dashboard.json` (NVIDIA DCGM Exporter)
- NIM metrics: `grafana_openshift/nim_dashboard_sample.json`
- Prometheus endpoint: `https://thanos-querier.openshift-monitoring.svc.cluster.local:9091`
