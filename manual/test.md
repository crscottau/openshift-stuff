Storage – On Prem
Storage for persistent data is exposed to OpenShift as PVs and accessed by applications via PVCs. The applications do not need to know what storage technology is used to back the persistent volumes. 
The persistent volumes are backed by vSphere datastores that expose storage from the NetApp SAN to vSphere.
Object storage is accessed via the S3 REST API. The applications do not need to know what storage technology is used to back the object storage
Storage – Cloud
No application changes required for OpenShift applications to use cloud storage. Cloud storage CSI drivers could be integrated into on-prem OpenShift clusters. Applications would continue to consume storage using PVCs and PVs, and the S3 API. Applications need not be concerned where that storage comes from. 

