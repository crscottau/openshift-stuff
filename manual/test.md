Infrastructure – On Prem
The OpenShift clusters are being deployed to VMWare vSphere environment where the OpenShift nodes are deployed as VMWare virtual machines and storage for the node disks and persistent volumes is presented to the cluster via vSphere datastores.
Future clusters could be deployed to bare metal servers or other hypervisors using ACM and these clusters could continue to be managed by the existing ACM and ACS deployments in the hub clusters. Alternatively, ACM and ACS could be deployed to new clusters on bare metal or other hypervisors and take over the role of managing the existing and deploying new clusters.
New OpenShift clusters on different platforms are functionally the same as the same code base is used on multiple platforms and hypervisors. Applying the post install configuration using OpenShift GitOps and IaC principles would also work in the same way.
Infrastructure – Cloud
OpenShift runs anywhere. The same code base is used for on-prem OpenShift clusters as for cloud based OpenShift clusters and also for the managed service offerings (ROSA on AWS and ARO on Azure). Applying the post install configuration using OpenShift GitOps and IaC principles would also work in the same way. An application built for on-prem OpenShift can simply be deployed to cloud based OpenShift. 
 
