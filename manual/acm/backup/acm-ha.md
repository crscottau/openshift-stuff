# ACM HA

## Overview

ACM has been installed in both hub OpenShift clusters. The ACM installation in the SDC hub cluster is considered the "primary" ACM and will be generally used to manage the workload clusters. The ACM installation in the PDC hub cluster is considered the "standby" ACM and will be available but will not have any connected clusters to manage. If there is a problem or disaster affecting the SDC cluster, then ACM can be "failed over" so that the PDC ACM instance takes over the role of managing the workload clusters.

The primary and standby ACM instances are kept in sync via ACM backups. When the “cluster-backup” configuration is enabled, ACM automatically installs the ACM Cluster Backup and Restore application that uses the OpenShift API for Data Protection (OADP) Operator for backups to and restores from an S3 compatible object store. The primary ACM instance is configured to take backups of the primary ACM instance to the shared object storage bucket every 2 hours. 

The standby ACM instance is configured for an hourly restore of all the configuration from the backup on the shared object storage bucket except for the ManagedCluster configuration that describes what clusters are managed by ACM. This means that both ACM instances have the same configuration except that the primary ACM instance continues to manage the clusters and the standby ACM instance is not aware of any managed clusters. 

The “cluster-backup” configuration creates ACM governance policies to monitor the status of the backups and restores and will report any violation that would indicate the backup/restore process is failing or has a problem.

Refer to: [ACM failover Configuration]<http://pvsasp14.crimtracagency.corporate:9081/display/ESES/ACM+failover+Configuration>

## Setup

### ACM Cluster Backup and Restore application

Install the ACM Cluster backup and Restore application on both the primary and standby hub clusters by editing the following YAML configuration for the **Advanced Cluster Management operator > MultiClusterHub** instance.

Add the following annotation to change the CatalogSource to the local mirror:

```yaml
metadata:
  annotations:
    installer.open-cluster-management.io/oadp-subscription-spec: '{"channel": "stable-1.0","installPlanApproval": "Automatic","name":
      "redhat-oadp-operator","source": "redhat-operators","sourceNamespace": "openshift-marketplace"}'
```

Enable the cluster-backup application

```yaml
spec:
  overrides:
    components:
    ...
    - enabled: true
      name: cluster-backup
```

Edit the **Advanced Cluster Management operator > MultiClusterEngine** instance to enable the Managed Service Account:

```yaml
apiVersion: multicluster.openshift.io/v1
kind: MultiClusterEngine
metadata:
  name: multiclusterengine
spec:
  overrides:
    components:
    ...
    - enabled: true
      name: managedserviceaccount
    ...
```

Once this configuration has been applied, the OADP Operator will be installed in the open-cluster-management-backup namespace. OADP needs to be configured with the details of the destination object store for the backups.

### Backup location configuration

Create the following configuration on both of the hub clusters.

1. Create a temporary text file containing the credentials for OADP to authenticate to the object storage bucket:

```text
[backupStorage]
aws_access_key=<access_key>
aws_secret_access_key=<access_key_secret>
```

Where:

- <access_key> is the key for access to the object storage bucket
- <access_key_secret> is the secret associated with that key

2. Create a secret containing the temporary credentials file:

`oc -n open-cluster-management-backup create secret generic cloud-credentials --from-file=cloud=<temporary-file-name>`

Delete the file after creating the secret.

3. Create the OADP DataProtectionApplication (DPA) to be used by both the backup and the restore:

```yaml
apiVersion: oadp.openshift.io/v1alpha1
kind: DataProtectionApplication
metadata:
  # The name must be short
  name: acm-dpa
  namespace: open-cluster-management-backup
spec:
  configuration:
    velero:
      defaultPlugins:
      - openshift
      - aws
    restic:
      enable: false
  backupLocations:
    - name: default
      velero:
        provider: aws
        default: true
        objectStorage:
          bucket: acic-openshift-acm-s3
          prefix: hub
          # The ACIC CA certificate base64 encoded
          caCert: <encoded-acic-ca-cert>
        config:
          s3Url: <object-storage-endpoint>
          s3ForcePathStyle: "true"
          region: local
          profile: "backupStorage"
        credential:
          name: cloud-credentials
          key: cloud
```
		  
where:
- <encoded-acic-ca-cert> is the base64 encoded string representation of the ACIC root CA certificate
- <object-storage-endpoint> is the URL of the object storage endpoint:
    - PDC: https://sg-vip-mgmt-pdc.mgmt.cicz.gov.au:10444
    - SDC: https://sg-vip-mgmt-sdc.mgmt.cicz.gov.au:10448
	
Verify that the DPA has been created correctly by querying the BackupStorageLocation CRD:

```bash
$ oc -n open-cluster-management-backup get backupstoragelocation
NAME      PHASE       LAST VALIDATED   AGE   DEFAULT
default   Available   12s              42d   true
```

### Create the Scheduled Backup

On the primary cluster (SDC), create the scheduled backup:

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: BackupSchedule
metadata:
  name: schedule-acm
  namespace: open-cluster-management-backup
spec:
  veleroSchedule: 0 */2 * * *    # Run backup every 2 hours
  veleroTtl: 4h                  # Optional: delete backups after 120h. If not specified, default is 720h
  useManagedServiceAccount: true # Auto Import Managed Clusters
```

Creating this BackupSchedule will trigger an immediate backup and then another backup run every 2 hours. Confirm that the backups are configured and working:

```bash
# Confirm that the backups are scheduled
$ oc -n open-cluster-management-backup get BackupSchedules
NAME           PHASE     MESSAGE
schedule-acm   Enabled   Velero schedules are enabled
 
# Confirm that the backups are running
$ oc -n open-cluster-management-backup get backups -o custom-columns="NAME":.metadata.name,"PHASE":.status.phase,"TIMESTAMP":.metadata.creationTimestamp
NAME                                            PHASE       TIMESTAMP
...
acm-credentials-schedule-20250429000049         Completed   2025-04-29T00:00:49Z
acm-credentials-schedule-20250429020049         Completed   2025-04-29T02:00:49Z
...
acm-managed-clusters-schedule-20250429000049    Completed   2025-04-29T00:00:49Z
acm-managed-clusters-schedule-20250429020049    Completed   2025-04-29T02:00:49Z
...
acm-resources-generic-schedule-20250429000049   Completed   2025-04-29T00:00:49Z
acm-resources-generic-schedule-20250429020049   Completed   2025-04-29T02:00:49Z
...
acm-resources-schedule-20250429000049           Completed   2025-04-29T00:00:49Z
acm-resources-schedule-20250429020049           Completed   2025-04-29T02:00:49Z
acm-validation-policy-schedule-20250429020049   Completed   2025-04-29T02:00:49Z
```

### Create the Scheduled Restore

On the standby cluster (PDC), create the scheduled restore:

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Restore
metadata:
  name: restore-acm-passive-sync
  namespace: open-cluster-management-backup
spec:
  syncRestoreWithNewBackups: true # restore when there are new backups
  restoreSyncInterval: 60m        # checks for backups every 10 minutes
  # Set to None to prevent the restore from removing ArgoCD
  #cleanupBeforeRestore: CleanupRestored
  cleanupBeforeRestore: None
  veleroManagedClustersBackupName: skip
  veleroCredentialsBackupName: latest
  veleroResourcesBackupName: latest
  # Exclude ArgoCD resources from the restore
  excludedResources:
    - backup.velero.io
    - velero.io
    - gitopscluster.apps.open-cluster-management.io
    - analysisrun.argoproj.io
    - analysistemplate.argoproj.io
    - application.argoproj.io
    - applicationset.argoproj.io
    - appproject.argoproj.io
    - argocd.argoproj.io
    - clusteranalysistemplate.argoproj.io
    - experiment.argoproj.io
    - notificationsconfiguration.argoproj.io
    - rollout.argoproj.io
    - rolloutmanager.argoproj.io
    - scale.argoproj.io
  excludedNamespaces:
    - open-cluster-management-backup
```

>NOTE: The ACM Backup and Restore application also backs up OpenShift-GitOps resource by default. The OpenShift-GitOps applications and configuration in excluded from the Restore to prevent the primary OpenShift-GitOps instance configuration overriding the standby OpenShift-GitOps instance configuration.

Creating the Restore will trigger an immediate restore and then another restore will run every hour. Confirm that the restoress are configured and working:

```bash
$ oc -n open-cluster-management-backup get restore restore-acm-passive-sync
NAME                       PHASE     MESSAGE
restore-acm-passive-sync   Enabled   Velero restores have run to completion, restore will continue to sync with new backups
 
$ oc -n open-cluster-management-backup get restore.velero.io -o custom-columns="NAME":.metadata.name,"PHASE":.status.phase,"TIMESTAMP":.metadata.creationTimestamp
...
restore-acm-passive-sync-acm-credentials-schedule-20250429020049         Completed   2025-04-29T02:09:44Z
restore-acm-passive-sync-acm-credentials-schedule-20250429040049         Completed   2025-04-29T04:09:50Z
...
restore-acm-passive-sync-acm-resources-generic-schedule-20250429020049   Completed   2025-04-29T02:09:44Z
restore-acm-passive-sync-acm-resources-generic-schedule-20250429040049   Completed   2025-04-29T04:09:50Z
...
restore-acm-passive-sync-acm-resources-schedule-20250429020049           Completed   2025-04-29T02:09:44Z
restore-acm-passive-sync-acm-resources-schedule-20250429040049           Completed   2025-04-29T04:09:50Z
```

### Verifying Backups and Restores in Object Storage

The ACM backups and restores can also be inspected using an S3 browser or command line tool:

```bash
# Check top level directories
$ s3cmd ls s3://acic-openshift-acm-s3/hub/
  DIR  s3://acic-openshift-acm-s3/hub/backups/
  DIR  s3://acic-openshift-acm-s3/hub/restores/
 
# List backups                         
$ s3cmd ls s3://acic-openshift-acm-s3/hub/backups/|grep 20250429
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-credentials-schedule-20250429000049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-credentials-schedule-20250429020049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-credentials-schedule-20250429040049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-managed-clusters-schedule-20250429000049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-managed-clusters-schedule-20250429020049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-managed-clusters-schedule-20250429040049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-resources-generic-schedule-20250429000049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-resources-generic-schedule-20250429020049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-resources-generic-schedule-20250429040049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-resources-schedule-20250429000049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-resources-schedule-20250429020049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-resources-schedule-20250429040049/
  DIR  s3://acic-openshift-acm-s3/hub/backups/acm-validation-policy-schedule-20250429040049/
 
# List restores                         
$ s3cmd ls s3://acic-openshift-acm-s3/hub/restores/|grep 20250429
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-credentials-schedule-20250429000049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-credentials-schedule-20250429020049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-credentials-schedule-20250429040049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-resources-generic-schedule-20250429000049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-resources-generic-schedule-20250429020049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-resources-generic-schedule-20250429040049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-resources-schedule-20250429000049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-resources-schedule-20250429020049/
  DIR  s3://acic-openshift-acm-s3/hub/restores/restore-acm-passive-sync-acm-resources-schedule-20250429040049/
```

## Fail over process
 
If the primary ACM becomes unavailable due to an outage or disaster, then ACM can be failed over.

>NOTE: Only one ACM should be managing the managed clusters at any given time. Do not fail over to the standby unless the primary ACM is down.

### Pre-requisites

The term "target ACM" refers to the ACM instance that is to become active as a result of the fail over.

The following accesses and items are required to fail over:
- Admin access to the OpenShift cluster

### Procedure

Use the following procedure to fail over

1. Login to the standby cluster console UI or CLI.

2. Check that all restores have finished successfully:

```bash
$ oc -n open-cluster-management-backup get restore restore-acm-passive-sync
NAME                       PHASE     MESSAGE
restore-acm-passive-sync   Enabled   Velero restores have run to completion, restore will continue to sync with new backups
``` 

3. Delete the existing restore resource
`oc delete restore restore-acm-passive-sync -n open-cluster-management-backup`

4. Create a new restore to restore the ManagedClusters

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Restore
metadata:
  name: restore-acm-passive-activate
  namespace: open-cluster-management-backup
spec:
  cleanupBeforeRestore: CleanupRestored
  veleroManagedClustersBackupName: latest
  veleroCredentialsBackupName: skip
  veleroResourcesBackupName: skip
```
  
>NOTE: The veleroManagedClustersBackupName will be set to latest so that the latest available restore will be used on the new hub cluster. The other parameters are set to skip as the data contained in them has already been restored via scheduled restore process.

> NOTE: The cleanupBeforeRestore parameter is important as it will ensure that only the most recent information from the specified backup is restored on the hub cluster. It will clear all data on the new hub before restoring it to a state consistent with the most recent backup version.

Once this resource is created, the data will be immediately restored in the new hub cluster, and the managed OpenShift clusters will be imported and shown as Ready in the dashboard. It may take a few minutes for the managed clusters to display the Ready status as the resources in the open-cluster-management-agent and open-cluster-management-agent-addon namespaces will be reconfigured.

5. Check the restore activation status:

```bash
$ oc -n open-cluster-management-backup get restore restore-acm-passive-activate
NAME                            PHASE     MESSAGE
restore-acm-passive-activate    Enabled   Velero restores have run to completion
```

## Fail back

The method of failing back to the primary ACM instance will depend on whether any changes have been made to the ACM configuration while the standby instance was managing the clusters.

If no changes were made, the managed cluster definitions can be deleted from the standby ACM instance and the primary ACM instance restarted.

If changes have been made then an ad-hoc one-time backup of the running configuration will need to be taken using OADP and restored on the primary instance to migrate the updated configuration.