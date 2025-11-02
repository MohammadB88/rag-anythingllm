# 🚀 Deploying NVIDIA NIM Models Anywhere

NVIDIA NIM provides prebuilt, optimized microservices for deploying AI models efficiently across diverse environments. Whether you're working on a local workstation, cloud infrastructure, or Kubernetes clusters, NIM ensures streamlined deployment and high-performance inference

## 📦 Prerequisites

- Kubernetes: At this point, OpenShift is preferred!
- NVIDIA GPU: Ensure access to an NVIDIA GPU with appropriate drivers installed.
- NGC API Key: Obtain an API key from the [NVIDIA NGC Catalog](https://ngc.nvidia.com/).
- NVIDIA Developer Program Membership: Join the [NVIDIA Developer Program](https://developer.nvidia.com/) for access to NIM microservices

## ☁️ Deploying on Kubernetes

For scalable deployments, use Kubernetes with the following steps:

### Create the Image Pull Secret:
Create an Image Pull Secret to pull NIM images from *"nvcr.io"* container registery:

```shell
oc create secret docker-registry nim-pull-secret --docker-username='$oauthtoken' --docker-server='nvcr.io' --docker-password='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'
```

### Create the NGC API Key Secret:


### Create a PersistentVolumeClaim (PVC):

### Define the Deployment:

### Deploy all the resources, except *image pull secret*, in one shot!

On openshift create a Namespace called *"model-nividia-nim"* and deploy the resoruces from the file in this directory. 

***Attention:*** Remember to replace the *"API_KEY_GENERATED_FROM_NGC"* with the *"API_KEY"* generated on *"NVIDIA NGC"* website