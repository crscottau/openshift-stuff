# ACM failover

This directory contains the jobs and other resources that largely automate the failover within each of the clusters. There is some post fail back cleanup that cannot be easily automated without using something like Ansible to orchestrate; and even then some manual approval gates would be a necessity.

The process assumes that ACM on the primary cluster on SDC is available to facilitate failover testing. If ACM on SDC is not available, then omit the stpes pertaining to that cluster.

Failover requires access to the cluster(s) with cluster administration privileges.

## Failover steps

### SDC/Primary cluster

If the cluster is available:

1. Apply the common resources:

```bash
oc apply -f 1.common-service-account.yaml
oc apply -f 2.common-resources-configmap.yaml
```

2. Run the prep job

```bash
oc apply -f 10.sdc-active-failover-prep-job.yaml
```

This job will:

- Pause the ACM BackupSchedule
- Run an ACM restore to tag resources so they do not get deleted
- Disable the ManagedCluster import annotation to prevent ACM trying to take back control of the workload clusters

### PDC/Standby cluster

1. Apply the common resources:

```bash
oc apply -f 1.common-service-account.yaml
oc apply -f 2.common-resources-configmap.yaml
```

2. Run the failover job

```bash
oc apply -f 20.pdc-standby-failover-job.yaml
```

This job will:

- Restore the ManagedCluster CRDs for the workload clusters from the backup
- Create the ACM BackupSchedule to continue the backup process

This job will initiate the failover. A few minutes after job completion, the workload clusters will go into the `Ready` state in the PDC/Standby ACM. A few minutes after that, they will switch to the `Unknown` state in the SDC/Primary ACM if it is available.

## Failback

After completion of the fail-over test, or when the SDC cluster is restored and ready to take over management of the workload clusters, execute the following steps.

### PDC/Standby cluster

1. Run the fail back prep job

```bash
oc apply -f 30.pdc-standby-failback-prep-job.yaml
```

This job will:

- Pause the ACM BackupSchedule
- Disable the ManagedCluster import annotation to prevent ACM trying to take back control of the workload clusters
- Remove the imported cluster annotation on workload clusters

### SDC/Primary cluster

1. Run the fail back job

```bash
oc apply -f 40.sdc-active-failback-job.yaml
```

This job will:

- Remove the annotation that was preventing the import of workload clusters
- Restore the ManagedCluster CRDs for the workload clusters from the backup
- Enable the ACM BackupSchedule to continue the backup process
- Delete the completed restores 

This job will initiate the failback. A few minutes after job completion, the workload clusters will go into the `Ready` state in the SDC/Primary ACM. A few minutes after that, they will switch to the `Unknown` state in the PDC/Standby ACM.

### PDC cleanup 50

After the clusters have reached the `Ready` state in the SDC/Primary ACM and the `Unknown` state in the PDC/Standby ACM, run this job to cleanup the PDC/Standby ACM.

This job will:

- Delete the Backup
- Delete the ManagedClusters

## Manual cleanup

Delete the jobs and the common resources configmap from the `open-cluster-management-backup` namespace (this is why Ansible might be good) so that the clusters are ready to go the next time fail over is required.
