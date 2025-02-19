# OpenShift Update Service

## Install the operator

TBC

## Build and push the graph data image

```bash
podman build -f ./Containerfile -t harbor.spenscot.ddns.net/openshift4/graph-data:latest
podman login harbor.spenscot.ddns.net --tls-verify=false
podman push --tls-verify=false harbor.spenscot.ddns.net/openshift4/graph-data:latest
```

## Create the graph data application

`oc apply -f update-service.yaml`

## Add the registry CA to the cluster

```bash
oc create configmap registry-config --from-file=harbor.spenscot.ddns.net=/home/crscott/Documents/prog/openshift/agent-sno/harbor/ca.crt -n openshift-config
oc patch image.config.openshift.io cluster --type=merge -p '{"spec": {"additionalTrustedCA": {"name": "registry-config"}}}'
```

## Update the CVO

```bash
NAMESPACE=openshift-update-service
NAME=service
POLICY_ENGINE_GRAPH_URI="$(oc -n "${NAMESPACE}" get -o jsonpath='{.status.policyEngineURI}/api/upgrades_info/v1/graph{"\n"}' updateservice "${NAME}")"
PATCH="{\"spec\":{\"upstream\":\"${POLICY_ENGINE_GRAPH_URI}\"}}"
oc patch clusterversion version -p $PATCH --type merge
```

## Ingress CA

Add the ingress CA to the custom CA bundle so that the call to itself is trusted.
