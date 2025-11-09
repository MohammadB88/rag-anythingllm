#!/bin/bash

oc new-project grafana

# Deployment of the grafana 
# Add grafana helm repo and update the artifacts 
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

# Install the grafana using this helm charts, but disabling runAsUser and fsGroup.
helm install grafana grafana/grafana --set securityContext.runAsUser=Null,securityContext.fsGroup=Null -n grafana


# Configure the grafana deployment
# granting a cluster to a service account named "grafana"
oc adm policy add-cluster-role-to-user cluster-monitoring-view -z grafana

# create a token for a service account which is valid for 200 hours (more than a week)
oc create token grafana --duration=200h -n grafana

