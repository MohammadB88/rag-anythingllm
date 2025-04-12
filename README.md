# rag-anythingllm

This repository contains the manifests and resources required to deploy a Generative AI (GenAI) GUI with a Retrieval-Augmented Generation (RAG) architecture. The project is designed to simplify the deployment of a scalable and efficient GenAI solution.

Some of the files and instructions are borrowed from these sources:

- [Milvus on OpenShift](https://github.com/rh-aiservices-bu/llm-on-openshift/tree/main/vector-databases/milvus)
- [AnythingLLM on OpenShift](https://github.com/rh-aiservices-bu/llm-on-openshift/blob/main/llm-clients/anythingllm/Readme.md)
- [Ollama and Open WebUI](https://gautam75.medium.com/deploy-ollama-and-open-webui-on-openshift-c88610d3b5c7)

## Project Structure

The repository is organized as follows:

- **`gui_anythingllm/`**: Contains Kubernetes manifests for deploying the GenAI GUI

- **`milvus/`**: Contains resources for deploying Milvus, a vector database used for efficient similarity search and retrieval

- **`model_ollama/`**: Contains manifests for deploying the Ollama model service


## Prerequisites

Before deploying the solution, ensure you have the following:

- A Kubernetes cluster (e.g., OpenShift, Minikube, or any managed Kubernetes service).
  - <span style="color:orange;"> **Notice**: At the moment, the deployment works only on an OpenShift cluster!
- `kubectl` or `oc` CLI tools installed and configured.
- Sufficient storage and compute resources for the deployment.
- Access to the required container images for the GUI, Milvus, and Ollama model.

## Deployment Instructions

1. **Deploy Milvus**:

    - We will install Milvus based on the insttuction from this link [Milvus on OpenShift](https://github.com/rh-aiservices-bu/llm-on-openshift/tree/main/vector-databases/milvus). Accordingly, I have generated the manifest for a standalone deployment.
   - Navigate to the `milvus/` directory.
   - On the cluster, create a namespace called "**milvus**"
   - Since we are deploying a standalone instance, we use this command to create the manifest with release name of "**vectordb**":
     ```sh
     helm template -f openshift-values.yaml vectordb -n milvus --set cluster.enabled=false --set etcd.replicaCount=1 --set minio.mode=standalone --set pulsar.enabled=false milvus/milvus > milvus_manifest_standalone.yaml
     ```
   - SecurityContext in deployment **vectordb-minio** and three statefulsets **vectordb-etcd**, **vectordb-pulsarv3-zookeeper**, **vectordb-pulsarv3-bookie**, should be adjusted to openshift requirements:
     ```sh
        yq '(select(.kind == "StatefulSet" and .metadata.name == "vectordb-etcd") | .spec.template.spec.securityContext) = {}' -i milvus_manifest_standalone.yaml
        yq '(select(.kind == "StatefulSet" and .metadata.name == "vectordb-etcd") | .spec.template.spec.containers[0].securityContext) = {"capabilities": {"drop": ["ALL"]}, "runAsNonRoot": true, "allowPrivilegeEscalation": false}' -i milvus_manifest_standalone.yaml
        yq '(select(.kind == "Deployment" and .metadata.name == "vectordb-minio") | .spec.template.spec.containers[0].securityContext) = {"capabilities": {"drop": ["ALL"]}, "runAsNonRoot": true, "allowPrivilegeEscalation": false, "seccompProfile": {"type": "RuntimeDefault"} }' -i milvus_manifest_standalone.yaml
        yq '(select(.kind == "Deployment" and .metadata.name == "vectordb-minio") | .spec.template.spec.securityContext) = {}' -i milvus_manifest_standalone.yaml
        yq '(select(.kind == "StatefulSet" and .metadata.name == "vectordb-pulsarv3-zookeeper") | .spec.template.spec.securityContext) = {}' -i milvus_manifest_standalone.yaml
        yq '(select(.kind == "StatefulSet" and .metadata.name == "vectordb-pulsarv3-zookeeper") | .spec.template.spec.containers[0].securityContext) = {"capabilities": {"drop": ["ALL"]}, "runAsNonRoot": true, "allowPrivilegeEscalation": false}' -i milvus_manifest_standalone.yaml
        yq '(select(.kind == "StatefulSet" and .metadata.name == "vectordb-pulsarv3-bookie") | .spec.template.spec.securityContext) = {}' -i milvus_manifest_standalone.yaml
        yq '(select(.kind == "StatefulSet" and .metadata.name == "vectordb-pulsarv3-bookie") | .spec.template.spec.containers[0].securityContext) = {"capabilities": {"drop": ["ALL"]}, "runAsNonRoot": true, "allowPrivilegeEscalation": false}' -i milvus_manifest_standalone.yaml
     ```
   - Apply the standalone manifest:
     ```sh
     kubectl apply -f milvus_manifest_standalone.yaml
     ```
   - To deploy the management UI for Milvus, called Attu, apply the file attu-deployment.yaml 

2. **Deploy the GenAI GUI**:
   - Navigate to the `gui_anythingllm/` directory.
   - Apply the manifests in the following order:
     ```sh
     kubectl apply -f all_resources.yaml
     ```

3. **Deploy the Ollama Model Service**:
   - Navigate to the `model_ollama/` directory.
   - Apply the manifests in the following order:
     ```sh
     kubectl apply -f all_resources.yaml
     ```

4. **Verify the Deployment**:
   - Check the status of the pods:
     ```sh
     kubectl get pods
     ```
   - Ensure all pods are running without errors.

5. **Access the GUI**:
   - Use the route URL generated by openshift to access the GenAI GUI.

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the terms of the [LICENSE](http://_vscodecontentref_/1) file.

## Acknowledgments

- [Milvus](https://milvus.io/) for vector database capabilities.
- [Ollama](https://ollama.ai/) for model services.
- Kubernetes and OpenShift for orchestration and deployment.