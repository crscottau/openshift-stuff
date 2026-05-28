# ACIC notes

## Confluence

Quay page that references the Quay database being made HA through the use of the CNPG operator. 

Reference a subpage

### CNPG Operator

CloudNativePG (CNPG) keeps a Red Hat Quay database highly available in OpenShift by deploying a PostgreSQL cluster with native streaming replication and automated self-healing. If the primary database pod fails, the operator automatically promotes a healthy standby to minimise downtime

The operator creates one primary pod (for read/write operations) and multiple standby pods. Data is streamed in real-time.
Automated Failover: The operator’s built-in instance manager continually monitors pod health. If the primary crashes, CNPG automatically elects and promotes the most synchronized replica.
Self-Healing: If a replica pod fails, CNPG automatically provisions a new pod on an available OpenShift node and resyncs it against the primary.
Zero Data Loss (RPO=0): You can configure the cluster for synchronous replication, ensuring transactions are safely committed to multiple standbys before acknowledging the write.
Connection Routing: CNPG provides internal Kubernetes services (e.g., -rw and -ro endpoints) that automatically route Quay and Clair traffic to the currently active primary or the read-only replicas. 

CloudNativePG
 +4
OpenShift Integration Features
Custom Resources: CNPG is fully managed via Kubernetes custom resources, which fits perfectly into OpenShift's declarative, GitOps-friendly workflows.
Storage Classes: The operator uses OpenShift's dynamic volume provisioning to map Persistent Volume Claims (PVCs) securely to each database instance.
Anti-Affinity: You can enforce strict pod anti-affinity rules to ensure replicas are not placed on the same physical OpenShift worker node, protecting the database against node-level failures.  

#### Node maintenance activity

#### DB creation

#### DB Restore

#### History

### GitLab readmes

#### Monitoring

#### DB creation

#### DB restore

##### Point in time restore

