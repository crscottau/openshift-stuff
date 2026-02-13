# CNPG for Keyclock

## Install

```bash
oc apply -f cnpg-sub.yaml
```

## Create the CNPG cluster

[https://cloudnative-pg.io/docs/1.28/bootstrap#bootstrap-an-empty-cluster-initdb]

1. Specify the namespace (see ../keycloak/README.md)
1. Specify the databasename to be created
1. Specify the username to be created

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: cluster-example-initdb
  namespace: keycloak-test
spec:
  instances: 2

  bootstrap:
    initdb:
      database: keycloak
      owner: keycloak
#      secret:
#        name: app-secret

  storage:
    size: 20Gi
```    


What abut backups?

[https://cloudnative-pg.io/plugin-barman-cloud/docs/concepts]

What about resource requirements? Need to collect some data and do some calculations.

