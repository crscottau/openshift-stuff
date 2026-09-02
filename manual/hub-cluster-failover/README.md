# Hub cluster failover

[DR & HR Designs](https://confluence.corp.cicz.gov.au:8443/spaces/ESES/pages/278364572/DR+HA+Designs)

[OpenShift GitOps failover](https://confluence.corp.cicz.gov.au:8443/spaces/ESES/pages/248284493/OpenShift+GitOps+failover)

[ACS failover](https://confluence.corp.cicz.gov.au:8443/spaces/ESES/pages/248283510/ACS+failover)

[ACM failover configuration](https://confluence.corp.cicz.gov.au:8443/spaces/ESES/pages/248284342/ACM+failover+Configuration)

## Overview

Hub cluster failover refers to running the management services that are normally active in the SDC/Active hub cluster to the PDC/Standby hub cluster.

Failover will be triggered manually. If the SDC/Active cluster is still available, the services will need to be disabled in that cluster first and then enabled on the PDC/Standby cluster.

The services and their failover type are:

| Service | Running on | Availability | Failover |
| -------- | -------- | -------- |
| ACM | Both clusters | active/standby | to PDC/Standby |
| ACS | Both clusters | active/standby | to PDC/Standby |
| OpenShift GitOps | Both clusters | active/standby | to PDC/Standby |
| Quay | Both clusters | active/active | not required |
| OpenBao | Both clusters | active/active | not required |

### Dependencies

The following supporting services are required for failover:

- AD for authentication services
- GitLab
- BitBucket
- S3 object storage

### Failover steps

If SDC/Active is available, execute a job on SDC/Active to disable ACM, ACS and OpenShift GitOps

Execute a job on PDC/Standby to:

- Enable ACM, ACS and OpenShift GitOps
- Update GitLab to change the SecuredClusters config to point to the active ACS Central on PDC/Standby (alternative, use an F5 endpoint for ACS)

### Fail back steps

Execute a job on PDC/Standby to disable ACM, ACS and OpenShift GitOps

Execute a job on SDC/Active to:

- Enable ACM, ACS and OpenShift GitOps
- Update GitLab to change the SecuredClusters config to point to the active ACS Central on SDC/Active (alternative, use an F5 endpoint for ACS)

## Components

### ACM

>Need to sort out/test the ArgoCD thing with the `cleanupBeforeRestore: CleanupRestored` parameter on the restore. Currently doesn't seem to be an issue.

#### Failover

https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.17/html/business_continuity/business-cont-overview#keep-hub-active-restore-prepare

If SDC/Active is available, then prepare the ACM in the SDC/Active cluster.

On SDC/Active:

1. Pause the backup schedule on the SDC/Active cluster

```bash
oc -n open-cluster-management-backup patch backupschedule schedule-acm --type=merge --patch='{"spec":{"paused": true}}'
```

2. Tag the SDC/Active hub cluster resources with the backup annotation (if a restore is required on the SDC/Active ACM. prevents delete as they are tagged as part of the latest backup). This is done by running a restore.

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Restore
metadata:
 name: restore-acm-pre-failover
 namespace: open-cluster-management-backup
spec:
 cleanupBeforeRestore: None
 veleroManagedClustersBackupName: latest
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

3. Disable import for managed clusters on SDC/Active, prevents the SDC/Active cluster from importing them once the PDC/Standby cluster takes over

```bash
for _MC in $(oc get managedcluster -l local-cluster!=true -o name)
do 
  echo ${_MV}
  oc annotate ${_MC} import.open-cluster-management.io/disable-auto-import=''
done
```

>If there is some need to remove the ManagedClusters from SDC/Active permanently, delete the `ManagedCluster` resources from SDC/Active - IF AND ONLY IF THEY ARE IN UNKNOWN STATE

On PDC/Standby:

3. Then restore ALL the resources on the PDC/Standby cluster by patching the existing restore:

```bash
oc -n open-cluster-management-backup patch restore restore-acm-passive-sync --type merge --patch '{"spec":{"veleroManagedClustersBackupName":"latest","syncRestoreWithNewBackups": false}}'
```

The clusters should magically appear in the UI:

- on SDC/Active as `Unknown`
- on PDC/Standby as `Ready` and be manageable.

#### New backups

If ACM on SDC/Active will be unavailable for an extended period of time, then the BackupSchedule resource should be created on the PDC/Standby cluster so any changes are captured.

>Maybe its worth creating this anyway given we need to restore to get the clusters back into being managed by SDC/Active (I think) **TEST**

#### Failback

If ACM on SDC/Active was only unavailable for a short period of time, i.e. a DR failover test, then failback is relatively simple.

On PDC/Standby: 

1. Delete the restore as once it has `Finished`, it cannot be restarted:

```yaml
oc -n open-cluster-management-backup delete restore restore-acm-passive-sync 
```

2. Disable import for managed clusters on PDC/Standby, prevents the PDC/Standby cluster from importing them once the SDC/Active cluster takes over

```bash
for _MC in $(oc get managedcluster -l local-cluster!=true -o name)
do 
  echo ${_MC}
  oc annotate ${_MC} import.open-cluster-management.io/immediate-import-
  oc annotate ${_MC} import.open-cluster-management.io/disable-auto-import=''
done
```

On SDC/Active:

3. Enable import for managed clusters on SDC/Active

```bash
for _MC in $(oc get managedcluster -l local-cluster!=true -o name)
do 
  echo ${_MC}
  oc annotate ${_MC} import.open-cluster-management.io/immediate-import-
  oc annotate ${_MC} import.open-cluster-management.io/disable-auto-import-
done
```

4. Run the restore on the SDC/Active cluster to enable the ManagedClusters

```yaml
apiVersion: cluster.open-cluster-management.io/v1beta1
kind: Restore
metadata:
 name: restore-acm
 namespace: open-cluster-management-backup
spec:
  cleanupBeforeRestore: None
  veleroManagedClustersBackupName: latest
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

4. Re-enable the backupschedule

```bash
oc -n open-cluster-management-backup patch backupschedule schedule-acm --type=merge --patch='{"spec":{"paused": false}}'
```

5. Delete the restores

```bash
oc -n open-cluster-management-backup delete restore restore-acm-pre-failover
oc -n open-cluster-management-backup delete restore restore-acm-failback
```

On PDC: 

6. Once SDC/Active has taken back control, delete the workload `ManagedCluster` resources from PDC/Standby.

```bash
for _MC in $(oc get managedcluster -l local-cluster!=true -o name)
do 
  echo ${_MV}
  oc delete ${_MC}
done
```

#### Notes

If ACM on SDC/Active was unavailable for an extended period of time and backups were enabled:

1. Pause the backup schedule on the PDC/Standby cluster
2. Disable import for managed clusters on PDC/Standby, prevents the PDC/Standby cluster from importing them once the SDC/Active cluster takes over
3. Then restore ALL the resources on the SDC/Active cluster.

Once SDC/Active has taken back control, delete the workload `ManagedCluster` resources from PDC/Standby.

### ACS

#### Pre-requisites

- Access to the backup ACS console with admin privileges
- Management server (Linux or Windows) with the `oc` client, the `roxctl` CLI tool and an `s3` client installed

#### Failover

To failover:

1. On the PDC/Standby ACS, login as an admin and generate an API token with **Admin** privileges that can be used to restore the backup. Download the token and save it to a file on the machine to be used for the restore.

2. Using the s3 client (e.g. s3cmd), extract the latest ACS Central DB backup from the object store:

```bash
s3cmd ls s3://acic-openshift-acs-s3/backups/
s3cmd get s3://acic-openshift-acs-s3/backups/backup_2026-08-24T14:00:00.zip
```

3. Use the roxctl utility to restore the backup on PDC

```bash
roxctl central db restore backup_2026-08-24T14:00:00.zip --endpoint https://acs-central.apps.hub-pdc.mgmt.cicz.gov.au --token-file <token>
```

4. Use the following OpenShift ADP `Restore` CRD on the PDC/Standby server to restore the latest TLS secret backups.

```yaml
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: acs-tls-restore
  namespace: openshift-adp
spec:
  excludedResources:
    - nodes
    - events
    - events.events.k8s.io
    - backups.velero.io
    - restores.velero.io
    - resticrepositories.velero.io
    - csinodes.storage.k8s.io
    - volumeattachments.storage.k8s.io
    - backuprepositories.velero.io
  itemOperationTimeout: 0h10m0s
  scheduleName: acs-tls-backup
```

5. Restart the pods in the `Central` namesapce on the PDC/Standby cluster:

```bash
oc -n central delete pods --all
```

6. Update the SecuredCluster resources in each workload cluster (path: <project-name>/acs-secured-cluster/10-devcs-sdc-secured-cluster.yaml) to reference the new endpoint: `https://acs-central.apps.hub-pdc.mgmt.cicz.gov.au`.

>Should this be automated? Maybe ...

#### New backups

If ACS on SDC/Active will be unavailable for an extended period of time, then a new scheduled backup integration should be created to capture any changes to the database and an OADP BackupSchedule created to capture any new TLS certificates.

1. Create the ACS backup in the UI.

2. Create the OADP BackupSchedule using the resources in <GITLAB>

#### Failback

If ACS on SDC/Active was only unavailable for a short period of time, i.e. a DR failover test, then failback is relatively simple.

1. Update the `SecuredCluster` resources in each workload cluster to reference the original endpoint: `https://acs-central.apps.hub-sdc.mgmt.cicz.gov.au`.

2. Delete the workload clusters from the ACS instance in PDC

If ACS on SDC/Active was unavailable for an extended period of time and backups were enabled:

1. On the SDC/Active ACS, login as an admin and generate an API token with **Admin** privileges that can be used to restore the backup. Download the token and save it to a file on the machine to be used for the restore.

2. Using the s3 client (e.g. s3cmd), extract the latest ACS Central DB backup from the object store:

```bash
s3cmd ls s3://acic-openshift-acs-s3/backups/
s3cmd get s3://acic-openshift-acs-s3/backups/backup_2026-08-24T14:00:00.zip
```

3. Use the roxctl utility to restore the backup on SDC

```bash
roxctl central db restore backup_2026-08-24T14:00:00.zip --endpoint https://acs-central.apps.hub-sdc.mgmt.cicz.gov.au --token-file <token>
```

4. Use the following OpenShift ADP `Restore` CRD on the SDC/Active server to restore the latest TLS secret backups.

```yaml
apiVersion: velero.io/v1
kind: Restore
metadata:
  name: acs-tls-restore
  namespace: openshift-adp
spec:
  excludedResources:
    - nodes
    - events
    - events.events.k8s.io
    - backups.velero.io
    - restores.velero.io
    - resticrepositories.velero.io
    - csinodes.storage.k8s.io
    - volumeattachments.storage.k8s.io
    - backuprepositories.velero.io
  itemOperationTimeout: 0h10m0s
  scheduleName: acs-tls-backup
```

5. Restart the pods in the `Central` namespace on the SDC/Active cluster:

```bash
oc -n central delete pods --all
```

6. Update the SecuredCluster resources in each workload cluster (path: <project-name>/acs-secured-cluster/10-devcs-sdc-secured-cluster.yaml) to reference the original endpoint: `https://acs-central.apps.hub-sdc.mgmt.cicz.gov.au`.

>Should this be automated? Maybe ...

7. Delete the workload clusters from the ACS instance in PDC

### OpenShift GitOps

#### Failover

#### Failback
