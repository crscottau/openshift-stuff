OpenShift platform patching
Updates to the OpenShift platform are categorised into streams and channels. Y-stream releases (for example 4.18 to 4.19) introduce new Kubernetes versions and features. They typically occur about every four months and mark the beginning of a new release's support cycle. Z-stream releases are weekly patch updates for a minor version (e.g., 4.19.1 to 4.19.2). They contain bug and security fixes and are generally low-risk with no API changes. Both Y-stream and Z-stream releases can be applied to the entire cluster, including the RHCOS node operating system patches, with a single command.
OpenShift administrators must choose to apply both Y-stream and Z-stream releases manually.
OpenShift Operator patching
Updates to the OpenShift operators are categorised into channels and patches. Updates to channels (for example Quay channel stable-3.13 to stable 3.14) introduce new features. Patches are released within a channel, for example Quay 3.13.5 to 3.13.6). 
Operators can be set to automatic or manual updates.
Automatic updates means that patches within a channel are automatically applied by the OpenShift Cluster Operator Lifecycle Manager. Updates typically have a negligable impact on the running workloads. 
Manual updates mean that patches must be approved by an OpenShift Administrator once they have become available. This allows administrators to schedule when an Operator update is applied to avoid any possible impact to running workloads. 
For a channel update, an OpenShift administrator must manually change the Operators channel from the CLI or web UI.
Patching applications
In a containerised environment, application patching can refer to patching the source code and to patching the base container image and any other sources used to build the application such as npm. 
The base container images are updated by the maintainer on a regular cadence. For example, the UBI images are rebuilt by Red Hat when a Critical or Important CVE is released as soon as possible, typically within hours or days.  Bug fixes and lower priority CVE fixes in the base images are released on a standardised 6 week cadence. The other sources, such as npm, are also updated regularly by the community of developers that maintain those packages.
The packages that are used by the builds are vetted and then imported into the local Quay registries or other package repositories such as Nexus. Once the updated packages have been imported, the applications that use those packages can be rebuilt by triggering a new PipelineRun in OpenShift Pipelines for the application. A new PipelineRun is triggered either by the approval of a merge request of the application source code in BitBucket or manually through the OpenShift web console. The new container image is pushed to the internal Quay registry where it can be tested and then ultimately released into production.
Similarly, when an application's code is patched, the application can be rebuilt in the same way.
Versions N, N-1 policy

The ACSC Essential Eight policy for Maturity Level 3 states that the version of an “operating system” must be either the current (N) or previous available release (N-1). This requirement is specified under Test ID ML3-PO-09: The latest release, or the previous release, of operating systems are used. 
The Example Essential Eight assessment test plan can be accessed via:
https://www.cyber.gov.au/business-government/asds-cyber-security-frameworks/essential-eight/essential-eight-assessment-process-guide
