The OpenShift API pods and the RHCOS node’s operating system produce audit logs. Audit logs are conditionally forwarded to the Splunk SIEM. This is discussed in detail in the section Audit Logging.
Logs from the OpenShift system pods are categorised by OpenShift as infrastructure logs. Infrastructure logs are maintained in the pods themselves on the running cluster and are not forwarded off the cluster. The logs are automatically rotated based on size and are lost once they have been rotated, or if the pod is killed or restarted.
Logs from the ACIC application pods are categorised by OpenShift as application logs. 
On the test and production clusters, application logs are collected by the Open Telemetry daemon pods and forwarded to an Elasticsearch cluster for analysis and retention.
On the dev cluster, application logs are maintained in the pods themselves on the running cluster and are not forwarded off the cluster. The logs are automatically rotated based on size and are lost once they have been rotated, or if the pod is killed or restarted.
A special case on the development cluster is the logs from the OpenShift Pipeline’s build pods. These logs are forwarded to an object store bucket using the OpenShift Logging and Loki operators. Pipeline logs are retained for 90 days before being automatically pruned.
Patching
Platform patches
An OpenShift update is an automated, over-the-air (OTA) process managed by a set of operators to update the entire platform, including the underlying operating system. Key concepts include the OpenShift Update Service (OSUS), update channels, the update graph, and the roles of the Cluster Version Operator (CVO) and Machine Config Operator (MCO). 
The OSUS provides a hosted API for internet connected clusters. It serves a graph of recommended, tested upgrade paths for specific cluster configurations. The OSUS provides the Update graph which is a directed acyclic graph (DAG) that represents all valid update paths between OpenShift versions. The graph prevents clusters from upgrading to versions with known issues by removing or blocking that update path (known as "edge pruning"). There is a web accessible version of the DAG for checking upgrade paths for disconnected clusters. The application can show a graph visualisation of the update graph by channel, or the shortest update path between two versions by specifying the current OpenShift version and the target OpenShift version.
The CVO is a core cluster operator responsible for overseeing the update process. Once an update is initiated, the CVO downloads the new release image and orchestrates the updates for all other cluster operators in the correct order.
The MCO manages updates to the nodes' operating system and their configurations. It drains pods from nodes, applies the update, reboots the node, and then sets the node status to Ready.
OpenShift categorises releases into streams and channels
•	Y-stream releases: Significant releases that introduce new Kubernetes versions and features (e.g., 4.18.x to 4.19.x). They typically occur about every four months and mark the beginning of a new release's support cycle,
•	Z-stream releases: These are weekly patch updates for a minor version (e.g., 4.19.1 to 4.19.2). They contain bug and security fixes and are generally low-risk with no API changes.
In the hub clusters, the update graph is displayed in the web console and the administrators can choose a valid target version to apply from the GUI. The graph can be displayed as the hub clusters are internet connected via the web proxy.
The workload clusters are not able to access the online Update Graph application, therefore this functionality is not available through the web console. An administrator must use the online update graph application to determine a target version and then issue a CLI command to instruct the CVO to apply the update to the cluster.
After an update has been triggered either from the web console or the CLI, the CVO automatically orchestrates the update. The CVO will update all of the component operators, and then apply updates to the CoreOS operating system on the nodes before finally rebooting the nodes, one at a time. During this time the cluster will continue to be online and the applications should remain available.
Operator patches
An OpenShift operator is an extension to the Kubernetes API which provides a method of packaging, deploying, and managing a containerised application. The operator framework allows for simplified installation and upgrade of an application package. OpenShift Operators can be installed by cluster administrators to provide packaged applications.
Most operators are published with multiple channels, for example Quay and ACM and patch updates are also released within channels. 
For example: Quay publishes channels such as stable-3.13, stable-3.14 and stable-3.15.
Within those channels, Quay releases patches such as 3.15.1, 3.15.2, 3.15.3.
Operators are updated based on the Operator's specific channel and the overall cluster's support cycle, with new patch releases for the latest minor version typically released weekly. The frequency can vary, as some operators may have longer release cadences, and older, more stable minor versions might receive less frequent updates.
If an Operator is set to be automatically updated, then the patch updates (3.15.2 to 3.15.3) will be automatically applied. However, channels will not be automatically updated, an Administrator will need to explicitly change the channel (stable3.14 to stable-3.15).
If an Operator is set to be manually updated, then the patch updates (3.15.2 to 3.15.3) will need to be manually approved by an OpenShift administrator before the automatic update starts.
Backup and Archiving
The installation and configuration of the managed cluster and the operators is managed using OpenShift GitOps using configuration saved in the management GitLab source code repository. The configuration manifests serve as a backup of the runtime state of the OpenShift clusters. The state of any of the hub or workload clusters can largely be recreated by building a new OpenShift cluster and reapplying the configuration from GitLab using the OpenShift GitOps operator. 

GitLab and the GitLab database are backed up using vSphere snapshots outside of the scope of the OpenShift deployment.

The Quay and ACS configuration is stored in databases deployed on the hub clusters by their respective operators. While some of the configuration of these operators is backed up as manifests in GitLab, other configuration is saved in the application databases. These databases are regularly backed up to object storage outside of the cluster.

Both the ACS and Quay databases are backed up to the Departmental Object Storage every day. 

While the ACM configuration is defined as YAML manifests and backed up in GitLab, the ACM configuration is also backed up to object storage every 2 hours to facilitate cross site failover in the event of an outage as discussed above in section ACM. Similarly, the ACS backups are used to facilitate cross site failover. 

The Departmental object storage is backed up ????

