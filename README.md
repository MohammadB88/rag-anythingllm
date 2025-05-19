# RAG - AnythingLLM

This repository contains the manifests and resources required to deploy a Generative AI (GenAI) GUI with a Retrieval-Augmented Generation (RAG) architecture. The project is designed to simplify the deployment of a scalable and efficient GenAI solution. Below is an image illustrating the RAG Architecture for better understanding. 

<div align="center">
  <img src="images/rag_architecture.png" alt="RAG - Architecture" width="500">
</div>

Some of the files and instructions are borrowed from these sources:

- [Milvus on OpenShift](https://github.com/rh-aiservices-bu/llm-on-openshift/tree/main/vector-databases/milvus)
- [AnythingLLM on OpenShift](https://github.com/rh-aiservices-bu/llm-on-openshift/blob/main/llm-clients/anythingllm/Readme.md)
- [Ollama and Open WebUI](https://gautam75.medium.com/deploy-ollama-and-open-webui-on-openshift-c88610d3b5c7)
- [Minio on Openshift](https://ai-on-openshift.io/tools-and-applications/minio/minio/#validate)

## Project Structure

The repository is organized as follows:

- **`milvus/`**: Contains resources for deploying Milvus, a vector database used for efficient similarity search and retrieval

- **`minio_on_openshift/`**: Contains manifests for deployeing a minio instance with a persistant volume

- **`model_ollama/`**: Contains manifests for deploying the Ollama model service with a persistant volume

- **`gui_anythingllm/`**: Contains Kubernetes manifests for deploying the GenAI GUI with a persistant volume

- **`images/`**: Contains images used in the documentation, such as screenshots and diagrams.



## Prerequisites

Before deploying the solution, ensure you have the following:

- A Kubernetes cluster (e.g., OpenShift, Minikube, or any managed Kubernetes service).
  - <span style="color:orange;"> **Notice**: At the moment, the deployment works only on an OpenShift cluster!
- `kubectl` or `oc` CLI tools installed and configured.
- Sufficient storage and compute resources for the deployment.
- Access to the required container images for the GUI, Milvus, and Ollama model.

## Deployment Instructions - Model
In case you have a cluster with only CPU resources, follow the instructions in below page to deploy models using Ollama model server:

[Model Deplyoment on CPU](./cpu_deployment.md)

But if you are lucky to have GPU worker nodes in your Cluster, go to this page, which explains using vLLM model server for model deployment:

[Model Deplyoment on GPU](./gpu_deployment.md) **!!! At the moment, it only works on OpenShift AI !!!**


## Deployment Instructions - Vector Database & GUI
Before deploying the vector database and GUI, make sure that your model is running and reachable.

1. **Deploy Milvus**:
   - We will install Milvus based on the insttuction from this link [Milvus on OpenShift](https://github.com/rh-aiservices-bu/llm-on-openshift/tree/main/vector-databases/milvus). Accordingly, I have generated the manifest for a standalone deployment.
   - Navigate to the `milvus/` directory.
   - On the cluster, create a namespace called "**milvus**".
   - We call the release name to be "**vectordb**".
   - This command is used to create the manifest for a standalone deployment:
     ```sh
     helm template -f openshift-values.yaml vectordb -n milvus --set cluster.enabled=false --set etcd.replicaCount=1 --set minio.mode=standalone --set pulsar.enabled=false milvus/milvus > milvus_manifest_standalone.yaml
     ```
   - SecurityContext in deployment **vectordb-minio** and three statefulsets **vectordb-etcd**, **vectordb-pulsarv3-zookeeper**, and **vectordb-pulsarv3-bookie**, should be adjusted to openshift requirements:
     - For **vectordb-etcd**, **vectordb-pulsarv3-zookeeper**, and **vectordb-pulsarv3-bookie**:
         - *.spec.template.spec.securityContext* should be set to empty: **{}**
         - *.spec.template.spec.containers[0].securityContext* should be set to:
        ```sh
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
        ```
    
     - For **vectordb-minio**:
         - *.spec.template.spec.securityContext* should be set to empty: **{}**
         - *.spec.template.spec.containers[0].securityContext* should be set to:
        ```sh
        securityContext:
          runAsNonRoot: true
          allowPrivilegeEscalation: false
          capabilities:
            drop: ["ALL"]
          seccompProfile: 
            type: "RuntimeDefault"
        ```

   - Deploy the standalone instance using the manifest:
     ```sh
     kubectl apply -f milvus_manifest_standalone.yaml
     ```
   - It is possible to deploy an user interface (UI) for the Milvus Vector database. It is called attu and can be deployed using the below [manifest](https://github.com/rh-aiservices-bu/llm-on-openshift/blob/main/vector-databases/milvus/attu-deployment.yaml):
     ```sh
     kubectl apply -f attu-deployment.yaml
     ```
   - Make sure all the resources are successfully created and that the pods are running without errors.
   - Default credentials to access Milvus are:
       -  **user** = **'root'**
       -  **password** = **'Milvus'**

2. **Deploy the GenAI GUI**:
   - GenAI GUI will be deployed in its namesapce, as well. 
   - When creating a route for this microservice, this name will appear in the URL. Therefore, we choose a meaningfull name as "**rag-genai**".
   - Navigate to the `gui_anythingllm/` directory.
   - Apply the manifests **all_resources.yaml** to deploy a **PVC**, a **Deployment**, a **Service**, and the route to access the GUI:
     ```sh
     kubectl apply -f all_resources.yaml
     ```
   - Make sure all the resources are successfully created.
   - AnythingLLM pod listens on port **"8888"**
   - Once the pods are running, the URL can be accessed to begin configuring the interface.
     
     <img src="images/gui_first_page.png" alt="RAG GUI - first page" width="400">

3. **Configure the GenAI GUI**:
   - First, we choose ollama as the model runtime and set the base URL and correct chat model (i.e. *"llama3.2:3b"*). Here, the base URL is built as below (i.e. *"http://ollama.model-ollama.svc.cluster.local:11434"*).:
     ```sh
     BASE_URL = http://OLLAMA_SERVICE:SERVICE_PORT
     ```
     <img src="images/gui_llm_interface.png" alt="RAG GUI - llm interface" width="400">

   - Set up an admin user and its password:
  
     <img src="images/gui_user_setup.png" alt="RAG GUI - user setup" width="400">

   - Set a workspace name:
     
     <img src="images/gui_workspace_name.png" alt="RAG GUI - workspace" width="400">

   - From the bottom-left corner of the landing page, navigate to the settings menu.
   - In the customization tab, we set a new **logo**, a suitable **app name** (i.e. *AI Assistant*), some **customized messages** for the welcome page, **icon and links** to the main website or a github page, an appropriate **tab title** and finally a nice **favicon**:
     
     <img src="images/gui_customization.png" alt="RAG GUI - customization" width="400">

   - Go to the embedding tab and set the URL and model. As an example, if milvus instance is deployed on the same cluster and password is set to default:
      - **URL:** ***"http://ollama.model-ollama.svc.cluster.local:11434"***
      - **Embedding Model:** **"all-minilm:33m"**
      - **Max Embedding Chunk Length:** **"8192"**
  
     
     <img src="images/gui_embedding.png" alt="RAG GUI - embedding" width="400">

   - Go to the vector database tab and set the URL. As an example, if milvus instance is deployed on the same cluster and password is set to default:
      - **URL:** ***"http://vectordb-milvus.milvus.svc.cluster.local:19530"***
      - **USERNAME:** **"root"**
      - **PASSWORD:** **"Milvus"**
  
     <img src="images/gui_vectordb.png" alt="RAG GUI - vector database" width="400">

4. **Chat with your Documents**:
   - Now you can upload documents and add URLs, which will be then embedded in the workspace, as shown in these images:

    <img src="images/gui_upload_doc_url0.png" alt="RAG GUI - vector database" width="100">

    <img src="images/gui_upload_doc_url.png" alt="RAG GUI - vector database" width="400">
   
   - The model uses these embedded information to generate a more accurate response with links to the appropriate sources. 

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

## License

This project is licensed under the terms of the [LICENSE](http://_vscodecontentref_/1) file.

## Acknowledgments

- [Milvus](https://milvus.io/) for vector database capabilities.
- [Ollama](https://ollama.ai/) for model services.
- [AnythingLLM](https://github.com/Mintplex-Labs/anything-llm) for customizable GUI.