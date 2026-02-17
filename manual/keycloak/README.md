# Keycloak

## Links

[https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/24.0/html/operator_guide/basic-deployment-#basic-deployment-performing-a-basic-red-hat-build-of-keycloak-deployment]

[https://cloudnative-pg.io/docs/1.28/bootstrap#bootstrap-an-empty-cluster-initdb]

## Database

### Operator

Install the Cloudnative PG Operator

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: cloudnative-pg
  namespace: openshift-operators
spec:
  channel: stable-v1
  installPlanApproval: Automatic
  name: cloudnative-pg
  source: certified-operators
  sourceNamespace: openshift-marketplace
```

### Create the CNPG cluster

1. Specify/create the namespace
2. Specify the databasename to be created
3. Specify the username to be created

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: keycloak-pg-cluster
  namespace: keycloak-test
spec:
  instances: 2

  bootstrap:
    initdb:
      database: keycloak
      owner: keycloak

  storage:
    size: 50Gi
```

This will create a PostgresQL cluster with 2 instances/replicas and a secret (named `<keycloak-cluster>-app`) containing the details of the connection including the host name, username and password:

```bash
$ oc -n keycloak-test get secret
NAME                              TYPE                       DATA   AGE
...
keycloak-pg-cluster-app           kubernetes.io/basic-auth   11     4d3h
```

## Install the operator in the target namesapce

```yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: rhbk-operator
  namespace: keycloak-test
spec:
  targetNamespaces:
  - keycloak-test
  upgradeStrategy: Default
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: rhbk-operator
  namespace: keycloak-test
spec:
  channel: stable-v26.4
  installPlanApproval: Automatic
  name: rhbk-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

## Keycloak instance

Create the instance.

Note that the `spec.db.host` field can be found in the same CNPG secret `host` field that the username and password are sourced from in the YAML below.

Change the hostname to suit the cluster FQDN.

```yaml
apiVersion: k8s.keycloak.org/v2alpha1
kind: Keycloak
metadata:
  name: keycloak
  namespace: keycloak-test
spec:
  db:
    host: keycloak-pg-cluster-rw
    passwordSecret:
      key: password
      name: keycloak-pg-cluster-app
    usernameSecret:
      key: username
      name: keycloak-pg-cluster-app
    vendor: postgres
  hostname:
    hostname: keycloak.apps.example.com
  http:
    httpEnabled: true
  instances: 1
  proxy:
    headers: xforwarded
```

This will create a Keycloak instance accessible at the hostname specified. The initial admin username and password wil lbe in a secret named similarly to: `keycloak-initial-admin`.
