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

Patch the CNPG database cluster to enable WAL Archiving to the ObjectStore. Noting that in the new build instructions this will be included in the original cluster creation YAML.

```yaml
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: quay-postgres
spec:

  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: quay-backups

```

>**NOTE:** This causes the cluster to restart without doing a switchover

```gemini
CloudNativePG triggers a switchover and rolling restart because modifying the backup and WAL archive specifications in your Cluster manifest alters core PostgreSQL configuration parameters (like archive_command). The operator detects this change and initiates a switchover to safely apply and verify the new archiving settings across the pods.
```

Create a `ScheduledBackup`, with immediate set to true

```bash
oc apply -f 
```

This should result in a healthy cluster with consistent recovery points:

```bash
Cluster Summary
Name                     quay/quay-postgres-cluster-01
System ID:               7643720592492965928
PostgreSQL Image:        ghcr.io/cloudnative-pg/postgresql:18.3-system-trixie
Primary instance:        quay-postgres-cluster-01-1
Primary promotion time:  2026-05-28 03:10:35 +0000 UTC (21m3s)
Status:                  Cluster in healthy state 
Instances:               3
Ready instances:         3
Size:                    426M
Current Write LSN:       2/75000110 (Timeline: 5 - WAL File: 000000050000000200000075)

Continuous Backup status (Barman Cloud Plugin)
ObjectStore / Server name:      quay-db-objectstore/quay-postgres-cluster-01
First Point of Recoverability:  2026-05-26 20:30:01 EDT
Last Successful Backup:         2026-05-27 20:30:01 EDT
Last Failed Backup:             -
Working WAL archiving:          OK
WALs waiting to be archived:    0
Last Archived WAL:              000000050000000200000074   @   2026-05-28T03:31:25.180299Z
Last Failed WAL:                000000050000000200000073   @   2026-05-28T03:26:06.294127Z
```

## Recovery

CloudnativePG only supports restoring a cluster by deleting and recreating it from the backup location. This will restore the latest available backup and roll-forward transactions to the latest consistent state in the WAL archives.

To recover a cluster, edit the YAML to add the following stanzas:

```yaml
  # Restore from the latest backup
  bootstrap:
    recovery:
      source: quay-backup-source
      database: quay-registry-quay-database
      encoding: UTF8
      localeCType: C
      localeCollate: C
      owner: quay-registry-quay-database

  # Reference the backup objectstore
  externalClusters:
    - name: quay-backup-source
      plugin:
        name: barman-cloud.cloudnative-pg.io
        parameters:
          barmanObjectName: quay-db-objectstore
          serverName: quay-postgres        
```

And comment out the WAL archiving section. This is because the new cluister cannot be recreated due to the WAL archiving directory existing; it throws an error.

```yaml
 # Enable WAL archiving to the Barman Cloud plugin
#  plugins:
#  - enabled: true
#    isWALArchiver: true
#    name: barman-cloud.cloudnative-pg.io
#    parameters:
#      barmanObjectName: quay-db-objectstore
```

Apply the modified YAML and wait for the cluster to rtestore the database and get the cluster going.

```bash
oc apply -f cnpg-quay-cluster-recovery.yaml
```

This will create a new cluster from the backups and WALs in the object store. It will restore the backup and roll-forward to the most recent consistent state.

### Update Quay

The quay `quay-registry-config-bundle` secret will need to be updated to replace the `DB_URI` with the `FQDN_URI` value from new `quay-postgres-app` secret so that Quay can connect to the restored database.

## CNPG cluster cleanup

### Restore original settings

Once the cluster has been restored, the original configuration can be reapplied to reset the cluster CRD to the original state. That is, remove the `externalCluster` section and reset the `bootstrap` section to the original values.

### Re-enable WAL archiving

Once the cluster has been restored, WAL archiving can be re-enabled by adding the WAL archiving stanza back into the cluster definition:

```yaml
  # Enable WAL archiving to the Barman Cloud plugin
  plugins:
  - enabled: true
    isWALArchiver: true
    name: barman-cloud.cloudnative-pg.io
    parameters:
      barmanObjectName: quay-db-objectstore
```

>**NOTE:** This causes the cluster to restart without doing a switchover

## Point in time recovery

CloudnativePG supports recovery to a point in time.
