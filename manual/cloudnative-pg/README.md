# ACS and cloudnative PG

## DB migration

The import YAML seems to have successfully created a central DB cluster based o the existing central DB. 

However I need to work out how to label the Job that the Cluster creates as labeeling the cluster didn't work. I managed to get it to work by manually labelling a pod with `app=cluster` to work around the ACS network policies.

## DB connection

Now I am struggling with connecting. From a debug pod I can curl to the service name on port 5432. However from the Central DB pod I cannot use psql to neither resolve the service name nor connect. 

```bash
sh-4.4$ psql -h central-db-cluster-rw.stackrox.svc.cluster.local -p 5432 -U postgres
psql: error: could not translate host name "central-db-cluster-rw.stackrox.svc.cluster.local" to address: Name or service not known
sh-4.4$ psql -h 172.30.29.53 -p 5432 -U postgres
psql: error: could not connect to server: Connection timed out
        Is the server running on host "172.30.29.53" and accepting
        TCP/IP connections on port 5432?
```
