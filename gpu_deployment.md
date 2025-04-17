## Deployment Instructions - GPU

1. **Deploy the Minio Instance**:
   - We create a namesapce called **minio** on the cluster.
   - Navigate to the `minio_on_openshift/` directory.
   - In the manifests called "**all_resources.yaml**", there is a **PVC**, a **Deployment**, a **Service** and two **routes** to deploy:
     ```sh
     kubectl apply -f all_resources.yaml
     ``` 
   - Make sure all the resources are successfully created and that the pod is running without errors.
   - Default credentials to access Milvus are:
       -  **user** = **'minio'**
       -  **password** = **'minio123'**

2. **Deploy models using vLLM**:
   - I have provided a complete instruction in [model_vllm](./model_vllm/README.md) on how to use vLLM serving runtime in OpenShift AI to deploy models.