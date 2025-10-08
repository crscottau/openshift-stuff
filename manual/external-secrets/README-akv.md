# External Secrets Operator and Azure Key Vault

## AKV credentials

### Managed identity

I have not been able to get this to work with a managed identity, needs a service principal

### Service principal

Create (or retrieve) the APP_ID and APP_PASSWORD

```bash
APP_ID=$(az ad app create --display-name "crscottau-eso" --query appId | tr -d \")
echo ${APP_ID}
```

```bash
SERVICE_PRINCIPAL=$(az ad sp create --id ${APP_ID} --query id | tr -d \")
# This failed as it already existed and displayed the ID, so set it explicitly
SERVICE_PRINCIPAL=bcb4a832-7134-4256-9d54-a7e7a4270bc7
```

Add pernmission to the keyvault for the AKV API

```bash
az ad app permission add --id ${APP_ID} --api-permissions f53da476-18e3-4152-8e01-aec403e6edc0=Scope --api cfa8b339-82a2-471a-a3c9-0fc0be7a4093
APP_PASSWORD=$(az ad app credential reset --id ${APP_ID} --query password | tr -d \")
echo ${APP_PASSWORD}
```

Add Key Vault Secrets role to the SP

`az role assignment create --assignee ${SERVICE_PRINCIPAL}$ --role "Key Vault Reader" --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCEGROUP}"`

Create the keyvault

```bash
LOCATION=eastasia
RESOURCEGROUP=openenv-qxk7x
KEYVAULT_NAME=${RESOURCEGROUP}-keyvault
az keyvault create --location ${LOCATION} --name ${KEYVAULT_NAME} --resource-group ${RESOURCEGROUP}
```

## Install the operator

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

Create the secret for the ESO operator to use:

`oc -n external-secrets-operator create secret generic azure-secret-sp --from-literal=ClientID=${APP_ID} --from-literal=ClientSecret=${APP_PASSWORD}`

### Namespaced Secret Store

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
      vaultUrl: "https://openenv-qxk7x-keyvault.vault.azure.net"
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

### Cluster secret store

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
      vaultUrl: "https://openenv-qxk7x-keyvault.vault.azure.net"
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

## Import secrets from AKV

### External secrets

Create the demo namespace

`oc new-project eso-demo`

Create a secret named `test` in AKV and give it some random value, then create a generic secret from the cluster secret store

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-cluster
  namespace: eso-demo
spec:
  # Interval of time the Secret will be synchronized from Azure
  refreshInterval: 10m

  # Name of the SecretStore
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-cluster-secretstore

  # Name of the Secret to be created
  target:
    name: example-azure-secret
    creationPolicy: Owner

  data:
  # name of the SECRET in the Azure KV (no prefix is by default a SECRET type)
  - secretKey: value
    remoteRef:
      key: test
```

Validate the created secret:

`oc -n eso-demo get secret example-azure-secret -o jsonpath='{.data.value}'|base64 -d`

Create a certificate in AKV named `secret-cert-pkcs12` of type `PKCS12` - adding SAN etc, then create an ExternalSecret to create a TLS secret in ARO.

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-cert-pkcs12
  namespace: eso-demo
spec:
  refreshInterval: 10m
  secretStoreRef:
    kind: ClusterSecretStore
    name: azure-cluster-secretstore
  target:
    creationPolicy: Owner
    deletionPolicy: Retain
    name: example-azure-keys-pkcs12
    template:
      type: kubernetes.io/tls
      engineVersion: v2
      data:
        tls.crt: "{{ .tls | b64dec | pkcs12cert }}"
        tls.key: "{{ .tls | b64dec | pkcs12key }}"    
  data:
    - secretKey: tls
      remoteRef:
        key: secret/secret-cert-pkcs12
```

Validate:

`oc -n eso-demo get secret example-azure-keys-pkcs12 -o jsonpath='{.data.tls\.crt}'|base64 -d|openssl x509 -noout -text`

Create a certificate in AKV named `secret-cert` of type `PEM`, then create an ExternalSecret to create a TLS secret in ARO.


```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: example-azure-cert-cluster
  namespace: eso-demo
spec:
  refreshInterval: 10m
  secretStoreRef:example-azure-key
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
        tls.crt: "{{ .tls | pemCertificate }}"
        tls.key: "{{ .tls | pemPrivateKey }}"    
  data:
    - secretKey: tls
      remoteRef:
        key: secret/secret-cert
```

I have not been able to get this to work, according to the doc, those 2 functions have been removed and replaced with pkcs12* functions so I guess the certificate format in AKV needs to be PKCS12.

[https://external-secrets.io/latest/guides/templating/]

I have also not been able to get ExternalSecrets to work with AKV keys, only certificates. Not 100% sure of the difference anyway.

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

## Troubleshooting

View the logs of the deployment/cluster-external-secrets pod(s)

## Links

[https://external-secrets.io/latest/provider/azure-key-vault/]

[https://balakrishnan-b.medium.com/syncing-secrets-from-azure-key-vault-to-openshift-using-external-secrets-operator-d5f29548c2cd]
