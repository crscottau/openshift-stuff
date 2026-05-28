# Barman Cloud Plugin

Used for CNPG database backup and WAL archiving

[Barman Cloud Plugin](https://cloudnative-pg.io/plugin-barman-cloud/docs/intro/)

## Installation

Install the definitions in [manifest.yaml](https://github.com/cloudnative-pg/plugin-barman-cloud/blob/main/manifest.yaml). This is downloaded from GitHub and probably should be checked to see if/when it gets updated.

Need to edit the YAML and remove remove the `RunAsUser` and `RunAsGroup` fields from the deplopyment YAML to get the pods to run.

## Configure

The information below relates to using CNPG for Quay and associated backups using ODF MCG as the object store.

Define a bucket and an object store:

```bash
oc apply -f cnpg-quay-objectstore-obc.yaml
oc apply -f cnpg-quay-objectstore.yaml
```

In my test case it is referencing an ODF OBC which automatically creates the secret containing the credentials.

Also need to create a secret conting in the internal CA to avoid SSL handshake errors:

```bash
oc -n openshift-storage get configmap openshift-service-ca.crt -o jsonpath="{.data['service-ca\.crt']}" > mcg-internal-ca.cr
oc -n quay create secret generic openshift-serving-ca --from-file=ca.crt=mcg-internal-ca.crt
```

>**UP TO HERE**

Configuring WAL Archiving

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: quay-registry-quay-postgres
spec:

  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: quay-backups

```
