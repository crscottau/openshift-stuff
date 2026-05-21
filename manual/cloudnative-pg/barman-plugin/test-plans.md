# Testing plans

## Prereqs

Need to add "barman-cloud" to noProxy as it seems to call that without any qualifiers, eg: .svc. This might be something to look further into.

## Initial testing

Need to get barman plugin backups working

So test:

- CNPG operator install in `cnpg-system`
- CNPG cluster created in `cnpg-system`
- Create some form of PostgresDB, maybe simplest to use Quay
- Configure backups to object storage
    - Needs ODF MNG

Creating the following

- CNPG operator in `openshift-operators`
- Download (Barman Cloud plugin manifest)[https://github.com/cloudnative-pg/plugin-barman-cloud/releases/download/v0.12.0/manifest.yaml] from GitHub 
  - Edit the manifest to chnage the namespace from `cnpg-system` to `openshift-operators`
  - Remove the `runAsGroup` and `runAsUser` lines 
  - Apply it and wait for the deployment to start
- Add `barman-cloud` to the cluster's `noProxy` configuration
- Create the barman cloud object store in the `test-db` namespace
- Export the ODF MCG CA from the configmap and import it into a secret fo the objectstore to use
- Create the test database cluster
  - With WAL archiving using the plugin enabled
- Create a backup

The first backup failed for no readily apparent reason and caused the cluster to restart.

The second backup worked and the cluster reports as healthy with the recovery stuff showing as valid:

```bash
Continuous Backup status (Barman Cloud Plugin)
ObjectStore / Server name:      mcg-store/test
First Point of Recoverability:  2026-05-21 00:36:59 EDT
Last Successful Backup:         2026-05-21 00:36:59 EDT
Last Failed Backup:             2026-05-21 00:34:24 EDT
Working WAL archiving:          OK
WALs waiting to be archived:    0
Last Archived WAL:              00000001000000000000000A   @   2026-05-21T04:45:44.295981Z
Last Failed WAL:                000000010000000000000001   @   2026-05-21T04:35:28.229932Z
```

### Recovery 

Recovery appears to involve creating a new cluster and pointing it to the backup object store.

It does not look like rollback is supported,, other than restoring a new cluster and specifying a point in time to stop the roll forward.

A test:

1. Delete the cluster
2. Create a new cluster pointing to the backup object store and specify a point in time

>I AM UP TO HERE

So the restore is not working and returning the really helpful error:

```text
"unexpected failure invoking barman-cloud-wal-archive: exit status 1"
```

I have found this which suggests there is some collision between the backup source and the new cluster:

[https://github.com/cloudnative-pg/cloudnative-pg/issues/7344]

However I have not been able to work past that.

I will try again on Monday

## Troubleshooting

Check the `plugin-barman-cloud` sidecar container for error messages. 

For backups this will be on the pod that is named as the backup source

For recovery this will be on the recovery job pods
