# External Secrets Operator and Bitwarden

The External Secrets Operator (ESO) can pull secrets from various external sources incluging GitLab project or global variables and Azure Key Vault.

## Bitwarden support using webhook provider

[https://external-secrets.io/latest/examples/bitwarden/]

## Bitwarden CLI container

Create the secret containing the credentials. Note that you need to use the API key to login and then the master password to unlock the vault.

The client ID and the client secret come from the [Web Vault](https://vault.bitwarden.com/#/settings/security/security-keys) under **Settings > Security > Keys > API Key**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bitwarden-cli
  namespace: bitwarden
data:
  BW_CLIENTID: **********
  BW_CLIENTSECRET: **********
  BW_HOST: **********
  BW_PASSWORD: **********
type: Opaque
```

Deploy the pod

```yaml
oc apply -f bitwarden-cli-deploy.yaml
oc apply -f bitwarden-cli-service.yaml
```

Also create the network policy to only allow the External Secrets operator to connect:

```bash
oc apply -f bitwarden-cli-netpol.yaml
```

## Install

```bash
oc apply -f eso-ns.yaml
oc apply -f eso-og.yaml
oc apply -f eso-sub.yaml
```

Create the ESO OperatorConfig:

```bash
oc apply -f eso-operator.yaml
```

## Create the cluster secret stores

There are different ClusterSecretStore instances for the diferent data types in BitWarden

```bash
oc apply -f bitwarden-cluster-secret-stores.yaml
```

## Create example secrets

```bash
oc apply -f bitwarden-cluster-secret-stores.yaml
```

## Issues

The upstream release (2.0.0) helm chart will not install via Argo. For some reason it tries to create privileged pods (user: 1000) whereas helm directly does not. However since the OLM version (0.11.0) works it probably doesn't matter too much.

Not sure what happens after login timeout, theoretically the Liveness probe should fail leading to pod restart but ...

Sends a lot of emails everytime the CLI re-establishes it connection.
