# Recovery testing

CNPG uses the barman cloud plugin to take backups and archive WALs to object storage

## Recovery overview

## Recovery tests

### Pre-test

Ensure the CNPG cluster is in continuous backup mode and is archiving WALS. 

### Test restore 1

03:40 UTC - create a new organization `temp-2025060100445` and push an image to it.

03:50 UTC - delete the cluster

04:05 UTC - restore the cluster, update the QUay config secret with the new `FQDN_URI` of the new database cluster

04:10 UTC - ensure Quay is up and that the organization and image exist and can be pulled:

```bash
$ podman pull quay-registry-quay-quay.apps.lwk9m.dynamic.redhatworkshops.io/temp-2025060100445/ubi-minimal:9.6
Trying to pull quay-registry-quay-quay.apps.lwk9m.dynamic.redhatworkshops.io/temp-2025060100445/ubi-minimal:9.6...
Getting image source signatures
Checking if image destination supports signatures
Copying blob 2920d84eafa0 done   | 
Copying config a2c5a85865 done   | 
Writing manifest to image destination
Storing signatures
a2c5a85865a585c3bc8b10f6c269358fdf89fe32be4232885166889d85c76421
```

### Post restore

03:30 UTC - Rename the existing archive directory 

```bash
s3cmd mv s3://quay-backups-cd5f40f1-b76b-4836-90ea-31b50ce0aee1/quay-postgres-cluster-01/ s3://quay-backups-cd5f40f1-b76b-4836-90ea-31b50ce0aee1/quay-postgres-cluster-01.backup2/ --recursive
```

03:35 UTC - Enable WAL archiving and retsore cluster YAML to original state. Causes the CNPG cluster to restart.

03:41 UTC - Ensure the cluster is backup and is WAL archiving

```yaml
Continuous Backup status (Barman Cloud Plugin)
ObjectStore / Server name:      quay-db-objectstore/quay-postgres-cluster-01
First Point of Recoverability:  -
Last Successful Backup:         -
Last Failed Backup:             2026-06-01 19:05:45 EDT
Working WAL archiving:          OK
WALs waiting to be archived:    0
Last Archived WAL:              0000000700000002000000BF   @   2026-06-02T05:41:18.019654Z
Last Failed WAL:                0000000700000002000000BF   @   2026-06-02T05:40:54.328817Z
```

03:42 UTC - take an ondemand backup

```yaml
Continuous Backup status (Barman Cloud Plugin)
ObjectStore / Server name:      quay-db-objectstore/quay-postgres-cluster-01
First Point of Recoverability:  2026-06-02 01:43:42 EDT
Last Successful Backup:         2026-06-02 01:43:42 EDT
Last Failed Backup:             2026-06-01 19:05:45 EDT
Working WAL archiving:          OK
WALs waiting to be archived:    0
Last Archived WAL:              0000000700000002000000BF   @   2026-06-02T05:41:18.019654Z
Last Failed WAL:                0000000700000002000000BF   @   2026-06-02T05:40:54.328817Z
```

Note the new RPO that matches the most recent restore/reset. See subsequent to test to see if we can still go back.

### Test restore point

Testing recovery to a time after one update but before another.

05:58 UTC - Add another organisation `temp-2025060100555` and copy an image to it:

```bash
$ skopeo copy docker://registry.redhat.io/ubi9/ubi-minimal:9.5 docker://quay-registry-quay-quay.apps.lwk9m.dynamic.redhatworkshops.io/temp-2025060100555/ubi-minimal:9.5 --dest-tls-verify=false
Getting image source signatures
Checking if image destination supports signatures
Copying blob 719fed365262 done   | 
Copying config 1510d272eb done   | 
Writing manifest to image destination
Storing signatures
```

06:16 UTC - Create a robot account in the org

>Note: PostgresQL supports creating a recovery point using a PSQL function. I can't see any reason why this would not work but have not tested it.

06:30 UTC - delete cluster

06:3  UTC - restore cluster to:

```yaml
      recoveryTarget:
        # 16:15 AEST == 06:15 UTC
        targetTime: 2026-06-02T06:15:00Z
```

Recovery fails:

```bash
$ oc -n quay logs quay-postgres-cluster-01-1-full-recovery-4bwgw -f | tee /tmp/recover.log
Defaulted container "full-recovery" out of: full-recovery, bootstrap-controller (init), plugin-barman-cloud (init)
{"level":"info","ts":"2026-06-02T06:34:32.513925616Z","msg":"Starting webserver","logging_pod":"quay-postgres-cluster-01-1-full-recovery","address":"localhost:8010","hasTLS":false}
{"level":"info","ts":"2026-06-02T06:34:32.615483078Z","msg":"Restore through plugin detected, proceeding...","logging_pod":"quay-postgres-cluster-01-1-full-recovery"}
{"level":"error","ts":"2026-06-02T06:34:41.896326471Z","msg":"Error while restoring a backup","logging_pod":"quay-postgres-cluster-01-1-full-recovery","error":"rpc error: code = Unknown desc = encountered an error while checking the presence of first needed WAL in the archive: generic error code encountered while executing barman-cloud-wal-restore","stacktrace":"github.com/cloudnative-pg/machinery/pkg/log.(*logger).Error\n\tpkg/mod/github.com/cloudnative-pg/machinery@v0.4.0/pkg/log/log.go:125\ngithub.com/cloudnative-pg/cloudnative-pg/internal/cmd/manager/instance/restore.restoreSubCommand\n\tinternal/cmd/manager/instance/restore/restore.go:79\ngithub.com/cloudnative-pg/cloudnative-pg/internal/cmd/manager/instance/restore.(*restoreRunnable).Start\n\tinternal/cmd/manager/instance/restore/restore.go:62\nsigs.k8s.io/controller-runtime/pkg/manager.(*runnableGroup).reconcile.func1\n\tpkg/mod/sigs.k8s.io/controller-runtime@v0.24.0/pkg/manager/runnable_group.go:260"}
{"level":"info","ts":"2026-06-02T06:34:41.896550558Z","msg":"Stopping and waiting for non leader election runnables"}
{"level":"info","ts":"2026-06-02T06:34:41.896568146Z","msg":"Stopping and waiting for leader election runnables"}
{"level":"info","ts":"2026-06-02T06:34:41.896657304Z","msg":"Stopping and waiting for warmup runnables"}
{"level":"info","ts":"2026-06-02T06:34:41.896723798Z","msg":"Webserver exited","logging_pod":"quay-postgres-cluster-01-1-full-recovery","address":"localhost:8010"}
{"level":"info","ts":"2026-06-02T06:34:41.8967793Z","msg":"Stopping and waiting for caches"}
{"level":"info","ts":"2026-06-02T06:34:41.896848385Z","msg":"Stopping and waiting for webhooks"}
{"level":"info","ts":"2026-06-02T06:34:41.896871968Z","msg":"Stopping and waiting for HTTP servers"}
{"level":"info","ts":"2026-06-02T06:34:41.896883734Z","msg":"Wait completed, proceeding to shutdown the manager"}
{"level":"error","ts":"2026-06-02T06:34:41.896907796Z","msg":"restore error","logging_pod":"quay-postgres-cluster-01-1-full-recovery","error":"while restoring cluster: rpc error: code = Unknown desc = encountered an error while checking the presence of first needed WAL in the archive: generic error code encountered while executing barman-cloud-wal-restore","stacktrace":"github.com/cloudnative-pg/machinery/pkg/log.(*logger).Error\n\tpkg/mod/github.com/cloudnative-pg/machinery@v0.4.0/pkg/log/log.go:125\ngithub.com/cloudnative-pg/cloudnative-pg/internal/cmd/manager/instance/restore.NewCmd.func1\n\tinternal/cmd/manager/instance/restore/cmd.go:101\ngithub.com/spf13/cobra.(*Command).execute\n\tpkg/mod/github.com/spf13/cobra@v1.10.2/command.go:1015\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\tpkg/mod/github.com/spf13/cobra@v1.10.2/command.go:1148\ngithub.com/spf13/cobra.(*Command).Execute\n\tpkg/mod/github.com/spf13/cobra@v1.10.2/command.go:1071\nmain.main\n\tcmd/manager/main.go:71\nruntime.main\n\t/opt/hostedtoolcache/go/1.26.3/x64/src/runtime/proc.go:290"}
```

### Test restore to "archived" backups
