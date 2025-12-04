DevOps Pipelines
Applications will be built in the dev cluster using OpenShift Pipelines (Tekton) and deployed using OpenShift GitOps (ArgoCD). 
CI/CD pipelines are a component of the DevOps methodology; a set of ideas and practices that fosters collaboration between developers and IT operations teams.
CI refers to continuous integration, which includes building, testing, and merging code. CD refers to continuous delivery, which includes automatically releasing software to a repository. CD can also refer to continuous deployment, which adds the step of automatically deploying software to production.
A CI/CD pipeline guides the process of software development through a path of building, testing, and deploying code. Automating the processes that support CI/CD helps minimise human error and maintains a consistent process for how software is released. Pipelines can include tools for compiling code, unit tests, code analysis, security, and packaging the code into a container image for deployment.
Pipeline Workflow
The following is a diagram and description of the steps to build an example application using OpenShift Pipelines.
 
Figure 17: A typical build pipeline
Developers will check source code updates into BitBucket and then submit a merge request. Once that merge request is approved, BitBucket will use web hook request to the OpenShift Pipelines Event Listener for the application. The Event Listener will trigger a pipeline run using the commit hash from BitBucket and values coded in the application’s Trigger YAML manifest. 
In the example, the following steps will be executed:
•	fetch-source - clone the code from BitBucket using the commit hash into a local workspace which is mapped to a PVC. 
•	npm-dependencies – gather any NodeJS Package Manager (NPM) dependencies
•	npm-test – run npm test on the code
•	npm-build – build the application
•	create-image – package the application into a container, sign the image and push to a temporary location in the container registry
•	scan-image – ACS scan he image for vulnerabilities
•	check-image – check the image for compliance with any ACS policies
•	sonarqube-scan – performa cod quality analysis using SonarQube
•	skopeo-copy-image – copy the image to the internal ACIC image location in the container registry
If a step fails, the subsequent builds will not continue.
Note: these steps will vary depending on what type of application is being built, for example, a Java application or a NodeJS application.
Release managers will deploy (or re-deploy) the application using the new container image via OpenShift GitOps to the appropriate test or production clusters.
