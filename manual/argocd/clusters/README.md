# Connecting a child cluster to a central OpenShift GitOps instance

The procedure is for adding a child OpenShift cluster to an OpenShift GitOps instance. This is typically when a centralised OpenShift GitOps instance manages the configuration of or applications on separate _child_ clusters. 

In the instructions below:

- _parent cluster_: refers to the OpenShift cluster where the managing OpenShift GitOps instance is running
- _child cluster_: refers to the OpenShift cluster being managed by the parwent

## Process

The process consists of creating a service account and associated artefacts on the _child cluster_. A secret on the _parent cluster_ will reference the cluster and connect using this service account credentials.

### Child cluster

Create a namespace (**cluster-config-gitops**) for the service account:

`oc apply -f child-cluster-config-gitops-ns.yaml`

Create the cluster role (**cluster-config-gitops**) which will allow the service account to configure the cluster:

`oc apply -f child-cluster-config-gitops-clusterrole.yaml`

Create the service account (**openshift-gitops-parent-sa**):

`oc apply -f child-cluster-config-sa.yaml`

Create a service account token secret:

`oc apply -f child-cluster-config-sa-secret.yaml`

Bind the service account to the clusterrole:

`oc apply -f child-cluster-config-sa-crb.yaml`

The following steps populate the template JSON file **argo-cd-cluster-auth-template.json** to create data to be used in a secret that will be created on the _parent cluster_. The details extracted are the bearer token and CA certificate extracted from the service account token secret on the _child cluster_. The commands produce a file that will need to be copied to a machine that has access to the _parent cluster_ API.

```bash
SERVICE_ACCOUNT=$(oc -n cluster-config-gitops get secret openshift-hub-sa-token -o "jsonpath={.data['ca\.crt']}")
BEARER_TOKEN=$(oc -n cluster-config-gitops get secret openshift-hub-sa-token -o "jsonpath={.data['token']}" | base64 -d)

jq --arg bearerToken "$BEARER_TOKEN" --arg caData "$SERVICE_ACCOUNT" '.bearerToken = $bearerToken | .tlsClientConfig.caData = $caData' ./argo-cd-cluster-auth-template.json > config.json
```

### Parent cluster

On the _parent cluster_, create the OpenShift GitOps cluster secret:
```bash
oc -n openshift-gitops create secret generic child-cluster-ssecret \
    --from-file=config.json --from-literal=name=child-cluster \
    --from-literal=server=https://api.child.domain.com.au:6443 && \
```

Annotate the secret as an OpenShift GitOps cluster:
`oc -n openshift-gitops label secret child-cluster-sa argocd.argoproj.io/secret-type=cluster `

Don't forget to delete the temporary file _config.json_ as it contains credentials for a service account with cluster admin provileges.
