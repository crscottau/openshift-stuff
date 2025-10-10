# External Secrets Operator and GitLab

The External Secrets Operator (ESO) can pull secrets from various external sources incluging GitLab project or global variables and Azure Key Vault.

## Import secrets from GitLab

[https://external-secrets.io/v0.7.2/provider/gitlab-variables/]

## GitLab

Create a secret in GitLab at the _group_ or _project_ level under **Settings > CI/CD > Variables**

Generate a Personal Access Token (PAT) under your Avatar: **Edit profile > Personal access tokens** with permissions:

- read_api
- read_registry

glpat-B-wmRT45zojVtgWgMUE2bm86MQp1OmlkcTR2Cw.01.1205nh5go

## Install

```bash
oc apply -f eso-ns.yaml
oc apply -f eso-og.yaml
oc apply -f eso-sub.yaml
```

Create the ESO OperatorConfig:

```yaml
apiVersion: operator.external-secrets.io/v1alpha1
kind: OperatorConfig
metadata:
  name: cluster
  namespace: external-secrets-operator
spec: {}
```

## Create the secret store

Create the secret for the ESO operator to use containing a PAT:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-secret
  namespace: external-secrets-operator
  labels: 
    type: gitlab
type: Opaque 
stringData:
  token: "..."
```

### Namespaced Secret Store

```yaml
kind: Project
apiVersion: project.openshift.io/v1
metadata:
  name: eso-demo
```

### Cluster secret store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: external-secrets-cluster
  namespace: external-secrets-operator
spec:
  provider:
    gitlab:
      # URL of your GitLab instance
      url: "https://gitlab.com"
      auth:
        # points to the secret that contains the PAT
        SecretRef:
          accessToken:
            name: gitlab-secret
            key: token
            namespace: external-secrets-operator
      # ID of the project from Settings > general            
      projectID: 75161988
#      groupIDs: 
#      - crscottau-group
      inheritFromGroups: true
#      environment: "**environment scope goes here**" 
```

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: external-secrets-local
  namespace: eso-demo
spec:
  provider:
    gitlab:
      # URL of your GitLab instance
      url: "https://gitlab.com"
      auth:
        # points to the secret that contains the PAT
        SecretRef:
          accessToken:
            name: gitlab-secret
            key: token
      # ID of the project from Settings > general
      projectID: "75161988"
      inheritFromGroups: true
#      environment: "**environment scope goes here**" 
```

### External secrets

Create the demo namespace

```yaml
kind: Project
apiVersion: project.openshift.io/v1
metadata:
  name: eso-demo
```

Create a variable named `gitlab_test` in GitLab and give it some random value, then create a generic secret from the cluster secret store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: external-secrets-test
  namespace: eso-demo
spec:
  # Interval of time the Secret will be synchronized from Azure
  refreshInterval: 10m

  # Name of the SecretStore
  secretStoreRef:
    kind: ClusterSecretStore
    name: external-secrets-cluster

  # Name of the Secret to be created
  target:
    name: gitlab-secret
    creationPolicy: Owner

  data:
    # name of the key in the secret
  - secretKey: gitlab_test 
    remoteRef:
      # name of the variable in GitLab
      key: gitlab_test
```

Validate the created secret:

`oc -n eso-demo get secret gitlab-secret -o jsonpath='{.data.gitlab_test}'|base64 -d`

Extract a group secret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: external-secrets-group-test
  namespace: eso-demo
spec:
  # Interval of time the Secret will be synchronized from Azure
  refreshInterval: 10m

  # Name of the SecretStore
  secretStoreRef:
    kind: ClusterSecretStore
    name: external-secrets-cluster

  # Name of the Secret to be created
  target:
    name: gitlab-secret-group
    creationPolicy: Owner

  dataFrom:
  - extract:
      # name of the variable in GitLab, key will be the variable name
      key: gitlab_test_group
```

Validate the created secret:

`oc -n eso-demo get secret gitlab-secret-group -o jsonpath='{.data.test}'|base64 -d`

> **__NOTE__** not currently working! The variable is not being found.

```text
{"level":"error","ts":1760058782.6108477,"msg":"Reconciler error","controller":"externalsecret","controllerGroup":"external-secrets.io","controllerKind":"ExternalSecret","ExternalSecret":{"name":"external-secrets-group-test","namespace":"eso-demo"},"namespace":"eso-demo","name":"external-secrets-group-test","reconcileID":"79419b80-05f4-4f81-91e3-b04be9c9301d","error":"error retrieving secret at .data[0], key: gitlab_test_group, err: 404 Not Found",..."}
```