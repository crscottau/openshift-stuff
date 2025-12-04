Containerising Applications
There are a number of principles that should be considered when containerising an application:
1.	One application per container
Include only one application or application component per container. Limiting containers in this way will ultimately benefit by:
•	Reducing potential library compatibility issues,
•	Increasing visibility into container health,
•	Making horizontal scaling easier,
•	Enabling easier reuse of containers,
•	Improving project organisation, especially when orchestrating multiple containers,
•	Minimising debugging times by limiting the complexity of individual containers.

2.	Containers should be stateless and immutable
Containers should be kept stateless by storing persistent data outside of the container on persistent storage. Stateless containers can be destroyed or rebuilt as needed without losing crucial information.
An immutable container should not be modified while it exists. If the container, or content within the container, needs to be updated then destroy it and deploy a new image. This ensures that containers remain identical when deployed across multiple environments. It also makes rolling back to previous images easier if problems are discovered within more recent versions.
3.	Reduce image size as much as possible
Optimise container performance by reducing the image size as much as possible.
Smaller images tend to be less complex and rely on fewer dependencies to run. In addition, smaller images tend to have less bloat and a reduced potential attack surface for malicious actors.
Remove unnecessary tools from the containers. For example, do not include tools for debugging purposes or network tracing tools. Ensure the container only includes the tools required to meet the functional requirements.
4.	Maximise security posture
Like any application, containers can act as an additional attack surface that malicious actors can exploit to gain access to sensitive systems, information, or even the entire OpenShift cluster. The following guidelines can help to build secure containers that reduce the attack surface:
Use un-privileged containers and do not run container processes as root. Running containers with restricted privileges is the default in OpenShift. 
Review the results of the integrated automated vulnerability scanning to identify potential vulnerabilities, and apply remediations and fixes to resolve these security holes as they arise.
5.	Build logging and monitoring into the container architecture
Monitoring systems are crucial to ensure containers remain healthy. Utilise logging and performance profiling systems to identify application or performance.
6.	Use approved base images and packages
Use approved base images for security and reliability, as they are vetted, regularly updated, and scanned for vulnerabilities. Approved images provide a secure, standardised, and reproducible foundation for containers, reducing the attack surface and the risk of using compromised software.
Application Probes
Liveness probes are used to determine if an application is running and healthy. They are essential for maintaining application availability by enabling OpenShift to detect when an application is in a broken or hung state and then attempt to take corrective action by restarting the container. If a liveness probe fails, OpenShift will temporarily remove the pod from the service load balancers until it passes the probe again.
Readiness probes are used to determine if an application is ready to handle traffic. This is crucial during application start up or after deployments when some initialisation processes might still be running. OpenShift will not start routing traffic to pods that are not ready to serve requests.
Liveness probes and readiness probes can be HTTP, TCP, or Exec based.


