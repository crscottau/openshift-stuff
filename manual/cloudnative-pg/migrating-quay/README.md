# Migrating Quay

## CNPG cluster

Install the operator

## Quiesce Quay

The database creation will take a backup of the existing Quay DB at the time the cluster YAML is applied. To avoid any data loss, the Quay deployment should be scaled down to prevent any updates occurring during or after the backup and not scaled up until the Quay configuration has been switched so that Quay uses the CNPG cluster.

```bash
oc -n quay scale deployment quay-operator.v3.16.2 --replicas=0
oc -n quay scale deployment quay-registry-quay-app --replicas=0
```

## Create the cluster

```bash
oc -n quay apply -f cnpg-cluster.yaml
```

Connection details are in the secret named `<cnpg-cluster-name>-app`. The required field in the secret is `fqdn-uri`.

```bash
oc -n quay get secret quay-pg-cluster-app -o jsonpath='{.data.fqdn-uri}'|base64 -d
```

A PVC is created for each PostgresQL instance, of the format:

```bash
$  oc -n quay get pvc
NAME                              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
quay-pg-cluster-1                 Bound    pvc-b27a6ddc-f981-4aa1-94d6-ee981f1137ff   50Gi       RWO            thin-csi       <unset>                 10m
quay-pg-cluster-2                 Bound    pvc-cdf060ed-8105-40fe-9cd5-88f45ff86f6c   50Gi       RWO            thin-csi       <unset>                 10m
quay-pg-cluster-3                 Bound    pvc-31c35f47-8d29-44c7-b2ef-7597c420d84c   50Gi       RWO            thin-csi       <unset>                 9m55s
```

At ACIC, these will need to be pre-allocated volumes in the vSphere datastore.

## Connecting

Modify the Quay config.yaml secret `quay-registry-config-bundle` to add the DB_URI field:

```YAML
DB_URI: <value from secret>
```

Modify the QuayRegistry to set the database to be unmanaged by the Operator

```yaml
spec:
  components:
    - kind: clair
      managed: true
    - kind: quay
      managed: true
    - kind: postgres
      managed: false
    - kind: redis
      managed: true
```

Scale up the deployments:

```bash
oc -n quay scale deployment quay-operator.v3.16.2 --replicas=1
```

## Cleanup

Scale the original DB deployment down

Delete the deployment and the PVC, clean up the PV.

Remove the bootstrap and external cluster from the CNPG cluster YAML.

## Failover

For most production environments, the optimal number of instances to use is 3. This configuration typically consists of one primary instance and two standby replicas.

### Why 3 Instances is Recommended

- High Availability (HA): Using 3 instances ensures that even if one instance or a whole availability zone fails, you still have two nodes remaining (one primary and one standby), maintaining a functional cluster with a promotable replica.
- Fault Tolerance: It allows the cluster to survive the loss of a single node without losing high-availability capabilities, as the remaining two instances can still maintain a primary-replica relationship.
- Data Durability (RPO=0): 3 instances are the minimum required to safely implement synchronous replication. This setup allows for a quorum where transactions are only committed after being written to at least one standby, ensuring no data loss (Recovery Point Objective of zero) during a failover.
- Alignment with Kubernetes: Most cloud providers offer 3 availability zones; deploying 3 instances (one per zone) maximizes resilience against data center outages.

### Other Configuration Options

1 Instance (Development/Testing): Suitable for non-critical workloads where high availability is not required. There is no failover or self-healing for a single-instance cluster if the node fails.

2 Instances: Provides basic failover but lacks the quorum needed for safe synchronous replication. If one instance fails, you are left with a single point of failure until the second is restored.

5+ Instances: Used for very high-read workloads or extreme fault tolerance requirements (e.g., surviving the simultaneous loss of two availability zones).

### Why not 2 instances?

While a 2-instance setup provides basic automated failover, it is generally discouraged for production environments due to two critical risks:

- Risk of Data Loss (RPO > 0)

CloudNativePG recommends synchronous replication for high availability, which requires at least one standby to confirm a transaction before it is committed.

The Conflict: If you have only 2 instances (1 primary, 1 standby) and the standby fails, the primary must choose between:

- Pausing all writes to maintain data safety (high durability).
- Continuing without protection, which risks data loss if the primary then fails before a new standby is ready.

The 3-Instance Advantage: With 3 instances, if one standby fails, the primary still has a second standby to maintain synchronous replication, preserving both availability and data safety.

- No Failover During Failures

If you require strict data durability (setting dataDurability: required), CloudNativePG may prevent automated failover in a 2-instance cluster to avoid data loss.

- If the primary fails and the operator cannot confirm that the single standby is fully synchronized, it will not promote that standby to primary. This leaves your database offline until a human intervenes.
- In a 3-instance setup, the operator can often establish a quorum (e.g., 2 out of 3 nodes are healthy) to safely proceed with a failover.

- Limited Maintenance Flexibility

Kubernetes maintenance, like node draining, is riskier with 2 instances. Evicting one pod immediately removes your high-availability safety net, leaving you with a single point of failure until the pod is rescheduled and synchronized.

For these reasons, the CloudNativePG documentation explicitly recommends planning for synchronous replication only in clusters with 3 or more instances.

### Failover time

Q: Why does it take so long to failover if there is an unclean outage of the master replica?

In CloudNativePG, the delay during an unclean outage of the primary replica is usually caused by Kubernetes-level detection timeouts and safety-first reconciliation loops designed to prevent data corruption.

The most common reasons for a "slow" failover include:

- Node Failure Detection (40+ seconds)

If the worker node hosting the primary fails (e.g., a hardware crash or network cut), Kubernetes does not immediately know it's gone.

The node-monitor-grace-period (default 40 seconds) must expire before the Kubernetes Controller Manager marks the node as NotReady. Only after this status change does the CloudNativePG operator initiate the failover process.

- Probe Failure Thresholds (30 seconds)

If the primary pod is still "alive" but PostgreSQL has crashed or is unresponsive:

The Readiness and Liveness probes default to 3 failures with a 10-second interval.

It can take up to 30 seconds for the pod to be officially marked as "Unready," which is the trigger for the operator to start the failover reconciliation.

- Failsafe Shutdown Procedures

Once a failure is detected, the operator enters a two-phase process to ensure a consistent timeline:

Termination Grace Period: The operator first attempts a "fast shutdown" of the old primary to flush any pending Write-Ahead Logs (WAL).

Waiting for WAL Receivers: It waits for all standby replicas to stop their WAL receivers to ensure no more data is being streamed before electing a new leader.

The switchoverDelay: If the old primary is unreachable but the pod hasn't been deleted, the operator may wait for the duration of .spec.switchoverDelay (default 40s) before forcing an "immediate shutdown" and proceeding with promotion.

- Quorum and Durability Checks

If you have failoverQuorum: true or dataDurability: required enabled:

The operator will not promote a replica until it confirms that a quorum of nodes is reachable and that the candidate has all synchronously committed data.

If network issues prevent this confirmation, the failover will pause to protect your data from a "split-brain" scenario.

#### How to Speed It Up

- Tune Probes: Reduce periodSeconds or failureThreshold in .spec.probes.readiness for faster detection of local PostgreSQL failures.
- Adjust switchoverDelay: Lowering this value in your Cluster spec can reduce the wait time during the shutdown phase, though it increases the risk of an unclean shutdown.
- K8s Tuning: In managed environments, you can sometimes adjust node-monitor-grace-period at the cluster level to detect node deaths faster.
