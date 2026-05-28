# FFS

Connecting to the database does not work when not specifying the hostname for some reason.

```bash
$ psql -U quay-registry-quay-database -d quay-registry-quay-database -W                                                        
Password:                                                                                                                      
psql: error: connection to server on socket "/controller/run/.s.PGSQL.5432" failed: FATAL:  Peer authentication failed for user "quay-registry-quay-database"          

Whereas:

```bash
$ psql -h quay-registry-quay-postgres-rw -U quay-registry-quay-database -d quay-registry-quay-database -W             
Password:                                                                                                                      
psql (18.3 (Debian 18.3-1.pgdg13+1))                                                                                           
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, compression: off, ALPN: postgresql)
```

Why?

```gemini
Without -h: psql defaults to a Unix domain socket connection. Your server is configured to use Peer authentication for these local connections. Peer authentication checks if your current Linux/OS username matches the database username you are trying to use; it ignores passwords.
```

## Testing

Now that I fucking finally have Quay up and running, I can start my test.

Currently quay is up and running in the same state as at ACIC except for the backups.

Todo:

1. Configure the Quay database to use the plugin for backups
    1. Install the plugin
    2. Configure an object store
    3. Modify the cluster to do WAL archiving
    4. Create a scheduled backup
2. Create some content in Quay
3. Destroy and recreate the database cluster from backup
4. Create some more content
5. Set a restore point
6. Create some more content
7. Destroy and recreate the database cluster from backup to the restore point
4. Ensure the content from "6" is missing

If I get bored I could try a point in time restore.

Also need to test moving CNPG instances to new storage classes.


Tidy up doco

### Configure the Quay database to use the plugin for backups

Plugin is already installed.

ObjectStore YAML is created referencing the OBC.

Need to create the openshift-serving-ca secret, will not need to do this at ACIC

```bash
oc -n openshift-storage get configmap openshift-service-ca.crt -o jsonpath="{.data['service-ca\.crt']}" > mcg-internal-ca.cr
oc -n quay create secret generic openshift-serving-ca --from-file=ca.crt=mcg-internal-ca.crt
```

Modify the cluster to add the WAL bits

>!**NOTE** this causes the CNPG cluster to restart

```yaml
  plugins:
  - name: barman-cloud.cloudnative-pg.io
    isWALArchiver: true
    parameters:
      barmanObjectName: quay-db-objectstore
```

Create the backup schedule and an immediate backup

### Test data

13:10 create user admin

13:11 create user craig

13:12 create organizations

13:14 push ubi9/ubi:9.7

13:15 create team developers

13:18 push ubi/ubi-minimal:9.7

13:20 push home-assistant, failed. Repo exists but no tags

13:35 push ubi9/ubi:9.7-1

13:36 create robot account in home-assistant

### Delete cliuster and restore

#### Attempt 1

When restoring, need to turn off ther WAL archiving plugin as the backup fails with a WAL archiving location collision. I tried renaming the cluster but then the restore would not work as it could not find the backups.

Also, need to update the Quay DB_URI with the new JDBC URI from the new CNPG secret.

This did not roll forward past the most recent backup, only restored up to that point.

#### Attempt 2

When restoring, renamed the cluster and included the old cluster name as the `serverName` parameter in the `externalCluster` block.

Also, need to update the Quay DB_URI with the new JDBC URI from the new CNPG secret.

The restore said it was apply WAL files but again did not appear to roll forward past the most recent backup, only restored up to that point.

Also, unable to pull as https://s3.openshift-storage.svc:443 is not available externally. Unsure if this is related to the restore but seems unlikely.

### Restart

15:29 create user admin

15:29 create organizations

15:31 push ubi9/ubi:9.7

Try to pull the image back out of the Quay and get the same error:

```text
Trying to pull quay-registry-quay-quay.apps.lwk9m.dynamic.redhatworkshops.io/ubi9/ubi:9.7...
Error: unable to copy from source docker://quay-registry-quay-quay.apps.lwk9m.dynamic.redhatworkshops.io/ubi9/ubi:9.7: parsing image configuration: Get "https://s3.openshift-storage.svc:443/quay-bucket-4e039481-5299-403a-81b8-7f61dc04a807/datastorage/registry/sha256/70/70320523e741a31f06b4e026822317a9e8d36da91c5a2d70b6d35b995fa1518f?AWSAccessKeyId=fFiLMbgzkIybPiOJNl80&Signature=5RR3I17HIULmpAHo04A3p424VqA%3D&Expires=1779687947": dial tcp: lookup s3.openshift-storage.svc: no such host
```

Need to enable the feature to proxy storage requests through Quay's nginx

```yaml
FEATURE_PROXY_STORAGE: true
```

Also needed to update the config secret to replace the minio `RadosGWStorage` with `RHOCSStorage` to get around a 404 error on pull.

>**So now I have a working test environment.**

#### TEst data

As of 8:36 Quay has:

- 4 organizations
  - ubi9
    - 2 repos, 3 tags
  - library
    - 1 repo, 1 tag
  - admin
  - craig
- 2 users
- 1 robot account in the ubi9 repo

Backup of all this is at 9:00

#### Recovery attempt #1

9:05 Create a robot account in the library org

9:10 Delete the cluster

9:20 Recreate the cluster using recovery, name incremented to *-01

9:22 Cluster available

9:28 Update `ScheduledBackup` 

9:30 Update Quay config secret with new DB_URI

9:33 Quay pods enter `Running 1/1` state

Check data

All data recovered including the robot account created at 9:05 after the latest backup, **ie: WAL roll forward worked!**

However, unable to pull images. Checked logs and all looked ok.

9:46 tried again and it was able to pull so may have just been a bit premature.

9:49 ScheduledBackup has not triggered, last backup of `00` is still pending

9:50 Delete pending backup

9:51 New backup taken

At some point the quay-backups bucket will need to be cleaned up to remove the `00`' cluster backups and WAL archives.

### Backup retention

Backups are automatically deleted according to retention, although not immediately.

## Point in time recovery

14:38 AEST Create a new organization "bollocks2" (Thu May 28 04:38:40 AM UTC 2026)

14:46 Check the status and observe

```bash
Working WAL archiving:          OK
WALs waiting to be archived:    0
Last Archived WAL:              000000050000000200000076   @   2026-05-28T04:46:55.016526Z
Last Failed WAL:                00000005.history           @   2026-05-28T04:54:34.07717Z
```

14:49 Delete the cluster

 Restore the cluster specifying:

```yaml
  bootstrap:
    recovery:
      source: quay-backup-source
      database: quay-registry-quay-database
      encoding: UTF8
      localeCType: C
      localeCollate: C
      owner: quay-registry-quay-database
      recoveryTarget:
        # 14:30 AEST == 04:30 UTC
        targetTime: 2026-05-28T04:30:00Z
```

So restoring has not worked to the target time as the last recovery point was:

```text
{"level":"info","ts":"2026-05-28T04:09:35.510723072Z","logger":"postgres","msg":"record","logging_pod":"quay-postgres-cluster-01-1-full-recovery","record":{"log_time":"2026-05-28 04:09:35.510 UTC","process_id":"56","session_id":"6a17bff1.38","session_line_num":"25","session_start_time":"2026-05-28 04:09:21 UTC","virtual_transaction_id":"165/0","transaction_id":"0","error_severity":"LOG","sql_state_code":"00000","message":"last completed transaction was at log time 2026-05-28 01:27:06.67675+00","backend_type":"startup","query_id":"0"}}
{"level":"info","ts":"2026-05-28T04:09:35.510736512Z","logger":"postgres","msg":"record","logging_pod":"quay-postgres-cluster-01-1-full-recovery","record":{"log_time":"2026-05-28 04:09:35.510 UTC","process_id":"56","session_id":"6a17bff1.38","session_line_num":"26","session_start_time":"2026-05-28 04:09:21 UTC","virtual_transaction_id":"165/0","transaction_id":"0","error_severity":"FATAL","sql_state_code":"F0000","message":"recovery ended before configured recovery target was reached","backend_type":"startup","query_id":"0"}}
```

Taking out the recovery point allowed the restore to compleete but it is missing `bollocks2`.

It doesn't look like it will roll forward past the failed WAL, maybe it needs a new base backup. Need to retest.
