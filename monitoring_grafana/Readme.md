# Grafana on OpenShift

I used the instruction in this Link (Adding Grafana Dashboard in the Red Hat OpenShift Cluster)[https://docs.tibco.com/pub/wfce/1.3.0/doc/html/Installation-and-Deployment-Guide/Grafana_using_Prometheus.htm] to deploy Grafana on OpenShift

**NOTE**
IT IS IMPORTANT TO USE https instead of http when setting the thanos-guerier as endpoint to access Prometheus.

https://thanos-querier.openshift-monitoring.svc.cluster.local:9091

Instead of 

http://thanos-querier.openshift-monitoring.svc.cluster.local:9091


# Prometheus on OpenShift (OpenShift Monitoring Context)
In OpenShift, there are typically two Prometheus instances:

- Cluster Monitoring Prometheus – managed by OpenShift for platform metrics (namespace: openshift-monitoring)

- User Workload Prometheus – optional, for user projects (namespace: openshift-user-workload-monitoring)

If you’re using the cluster monitoring stack (openshift-monitoring), **Prometheus won’t scrape custom namespaces unless configured to do so**.

### Enable user workload monitoring (if not already):
When trying this command: 

````
oc get configmap cluster-monitoring-config -n openshift-monitoring -o yaml
````

If there’s no ``cluster-monitoring-config`` ConfigMap in the openshift-monitoring namespace, it means your OpenShift cluster is currently running with the default monitoring configuration, and **user workload monitoring is not enabled yet**.

Therefor:
- The Cluster Monitoring Operator in openshift-monitoring manages metrics for platform components only.

- The User Workload Monitoring stack (which scrapes ServiceMonitors in user namespaces) is disabled until you explicitly turn it on.

- Without it, your ServiceMonitor will never be picked up — it’s being ignored.

### 🧰 How to enable user workload monitoring
You’ll need to create the ``cluster-monitoring-config`` ConfigMap manually in the ``openshift-monitoring`` namespace:
````
oc -n openshift-monitoring create configmap cluster-monitoring-config \
  --from-literal=config.yaml='enableUserWorkload: true'
````

After you create this ConfigMap, OpenShift will automatically deploy a second monitoring stack in the openshift-user-workload-monitoring namespace, including:
- prometheus-operator
- prometheus-user-workload
- thanos-ruler-user-workload
- prometheus-adapter

Once those pods are up:

Prometheus in openshift-user-workload-monitoring will automatically start scraping ``ServiceMonitor`` objects from your application namespaces.

# ServiceMonitor
Prometheus needs this ServiceMonitor to scrape metrices from the specified service.

```
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    app: meta-llama3-1b-instruct
  name: meta-llama3-1b-instruct
  namespace: 1nim-model
spec:
  endpoints:
    - interval: 30s
      path: /v1/metrics
      port: api   # portname or 8000
      scheme: http
      scrapeTimeout: 10s
  namespaceSelector: {}
  selector:
    matchLabels:
      app.kubernetes.io/name: meta-llama3-1b-instruct
```

Once deployed, your ServiceMonitor (in example-namespace) should then appear in:

The Prometheus UI (via oc port-forward svc/prometheus-user-workload 9090)

The OpenShift Console → Observe → Targets


# Sample NIM-Dashboard - NameSpace nim-model
In this directory, there is a file called "nim_dashboard_sample.json" which I configured to capture the metrices from models in namspace "nim-model"

# ????Grafana on OpenShift - Grafana-Operator Community Edition
There is also another documentation, but with Grafana-Operator community edition:
https://docs.nvidia.com/launchpad/infrastructure/tanzu-it/latest/openshift-it-step-05.html
