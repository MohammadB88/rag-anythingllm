#!/bin/bash


# When there is no resource to monitor the user workload,
# run this command to tell the monitoring operator to deploy the stack to monitor the user workload.
oc -n openshift-monitoring create configmap cluster-monitoring-config \
  --from-literal=config.yaml='enableUserWorkload: true'

# watch user workload monitoring to be deployed
oc get pods -n openshift-user-workload-monitoring -w

echo "Now you can deploy a servicemonitor to allow monitoring operator to gather logs and metrices from a user namespace."
