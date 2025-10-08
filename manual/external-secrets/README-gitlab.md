# External Secrets Operator and GitLab

The External Secrets Operator (ESO) can pull secrets from various external sources incluging GitLab project or global variables and Azure Key Vault.

## Import secrets from GitLab

[https://external-secrets.io/v0.7.2/provider/gitlab-variables/]

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
  labels: 
    type: gitlab
type: Opaque 
stringData:
  token: "<PAT>"
```

### Namespaced Secret Store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: external-secrets-ns
  namespace: eso-demo
spec:
  provider:
    # provider type: azure keyvault
    gitlab:
      # URL of your GitLab instance
      Url: "https://gitlab.example.com"
      auth:
        # points to the secret that contains the PAT
        SecretRef:
          name: gitlab-secret
          key: token       
      projectID: "test-project"
      groupIDs: "test-group"
      inheritFromGroups: "**automatically looks for variables in parent groups**"
      environment: "**environment scope goes here**" 
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
    # provider type: azure keyvault
    gitlab:
      # URL of your GitLab instance
      Url: "https://gitlab.example.com"
      auth:
        # points to the secret that contains the PAT
        SecretRef:
          name: gitlab-secret
          key: token       
      projectID: "test-project"
      groupIDs: "test-group"
      inheritFromGroups: "**automatically looks for variables in parent groups**"
      environment: "**environment scope goes here**" 
```

### External secrets

Create the demo namespace

`oc new-project eso-demo`10m

Create a variable named `test` in GitLab and give it some random value, then create a generic secret from the cluster secret store

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
    name: test-secret
    creationPolicy: Owner

  data:
    # name of the key in the secret
  - secretKey: value 
    remoteRef:
      # name of the variable in GitLab
      key: test
```

Validate the created secret:

`oc -n eso-demo get secret test-secret -o jsonpath='{.data.value}'|base64 -d`

Extract a JSON secret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: external-secrets-test-json
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
    name: test-secret-json
    creationPolicy: Owner

  dataFrom:
  - extract:
      # name of the variable in GitLab, key will be the variable name
      key: test
```

Validate the created secret:

`oc -n eso-demo get secret test-secret-json -o jsonpath='{.data.test}'|base64 -d`
