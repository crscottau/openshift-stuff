# External Secrets Operator and Azre Key Vault

## Install the operator

```bash
oc apply -f eso-ns.yaml
oc apply -f eso-og.yaml
oc apply -f eso-sub.yaml
```

## AKV credentials

### Managed identity

I have not been able to get this to work with a managed identity, needs a service principal

### Service principal

Create (or retrieve) the APP_ID and APP_PASSWORD

```bash
APP_ID=$(az ad app create --display-name "crscottau-eso" --query appId | tr -d \")
echo ${APP_ID}

SERVICE_PRINCIPAL=$(az ad sp create --id ${APP_ID} --query id | tr -d \")
# This failed as it already existed and displayed the ID, so set t explicitly
SERVICE_PRINCIPAL=bcb4a832-7134-4256-9d54-a7e7a4270bc7

az ad app permission add --id ${APP_ID} --api-permissions f53da476-18e3-4152-8e01-aec403e6edc0=Scope --api cfa8b339-82a2-471a-a3c9-0fc0be7a4093
APP_PASSWORD=$(az ad app credential reset --id ${APP_ID} --query password | tr -d \")
echo ${APP_PASSWORD}

VAULT_NAME=crscottau-key-vault
az role assignment create --assignee ${SERVICE_PRINCIPAL} --role "Key Vault Secrets User" --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/openenv-6s24r-ext/providers/Microsoft.KeyVault/vaults/crscottau-key-vault"
```

Create the secret for the ESO operator to use:

`oc -n eso-demo create secret generic azure-secret-sp --from-literal=ClientID=${APP_ID} --from-literal=ClientSecret=${APP_PASSWORD}`

## Secrets

### Secret Store

Create the secret store.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: azure-store-clientid
  namespace: eso-demo
spec:
  provider:
    # provider type: azure keyvault
    azurekv:
      tenantId: "redhat0.onmicrosoft.com"
      # URL of your vault instance, see: 
      vaultUrl: "https://crscottau-key-vault.vault.azure.net"
      authSecretRef:
        # points to the secret that contains
        # the azure service principal credentials
        clientId:
          name: azure-secret-sp
          key: ClientID
        clientSecret:
          name: azure-secret-sp
          key: ClientSecret
```

Or create a cluster secret store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: azure-cluster-secretstore
  namespace: external-secrets-operator
spec:
  provider:
    # provider type: azure keyvault
    azurekv:
      tenantId: "redhat0.onmicrosoft.com"
      # URL of your vault instance, see: 
      vaultUrl: "https://crscottau-key-vault.vault.azure.net"
      authSecretRef:
        # points to the secret that contains
        # the azure service principal credentials
        clientId:
          name: azure-secret-sp
          namespace: external-secrets-operator
          key: ClientID
        clientSecret:
          name: azure-secret-sp
          namespace: external-secrets-operator          
          key: ClientSecret
```

### External secrets

Create a generic secret

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-clientid
  namespace: eso-demo
spec:
  refreshInterval: 10m
  secretStoreRef:
    kind: SecretStore
    name: azure-store-clientid
  target:
    creationPolicy: Owner
    deletionPolicy: Retain
    name: example-azure-secret
  data:
    - secretKey: test
      remoteRef:
        key: test
```

Create a generic secret from the cluster secret store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-cluster
  namespace: eso-demo
spec:
  refreshInterval: 10m
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-cluster-secretstore
  target:
    creationPolicy: Owner
    deletionPolicy: Retain
    name: example-azure-secret-cluster
  data:
    - secretKey: test
      remoteRef:
        key: test
```

Create a TLS certificate

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-cert
  namespace: eso-demo
spec:
  refreshInterval: 10m
  secretStoreRef:
    kind: SecretStore
    name: azure-store-clientid
  target:
    creationPolicy: Owner
    deletionPolicy: Retain
    name: example-azure-keys
    template:
      type: kubernetes.io/tls
      engineVersion: v2
      data:
        tls.crt: "{{ .tls | b64dec | pkcs12cert }}"
        tls.key: "{{ .tls | b64dec | pkcs12key }}"    
  data:
    - secretKey: tls
      remoteRef:
        key: secret/secret-cert
```

Create a TLS certificate from the cluster secret store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-cert-cluster
  namespace: eso-demo
spec:
  refreshInterval: 10m
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-cluster-secretstore
  target:
    creationPolicy: Owner
    deletionPolicy: Retain
    name: example-azure-keys-cluster
    template:
      type: kubernetes.io/tls
      engineVersion: v2
      data:
        tls.crt: "{{ .tls | b64dec | pkcs12cert }}"
        tls.key: "{{ .tls | b64dec | pkcs12key }}"    
  data:
    - secretKey: tls
      remoteRef:
        key: secret/secret-cert
```

I have not been able to get the following to work

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-keys
  namespace: eso-demo
spec:
  refreshInterval: 10m
  secretStoreRef:
    kind: SecretStore
    name: azure-store-clientid
  target:
    creationPolicy: Owner
    deletionPolicy: Retain
    name: example-azure-keys
    template:
      type: kubernetes.io/tls
      engineVersion: v2
      data:
        tls.crt: "{{ .tls | b64dec | pkcs12cert }}"
        tls.key: "{{ .tls | b64dec | pkcs12key }}"    
  data:
    - secretKey: tls
      remoteRef:
        key: key/secret-keys
```

### Cluster External Secrets

These objects enable you to create the same ExternalSecret object in multiple namespaces. 

## Links

[https://external-secrets.io/latest/provider/azure-key-vault/]

[https://balakrishnan-b.medium.com/syncing-secrets-from-azure-key-vault-to-openshift-using-external-secrets-operator-d5f29548c2cd]
