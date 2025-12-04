Static Image scanning
Clair will scan all images that reside in Quay and report on vulnerabilities in the Quay web interface. Admins and developers can drill down into the vulnerability report for an image to get further details on any vulnerabilities that Clair has found in the image and if they are marked as fixable. 
The ACS scanner can also be configured to scan “inactive” images, that is images that are not currently in use in the clusters. ACS must be configured with an image name and tag for it to be scanned if it is an inactive image. 
 Runtime scanning
ACS periodically scans all active images in all of the managed clusters every 4 hours and updates the image scan results to reflect the latest vulnerability definitions. Active images are the images that are deployed to the workload clusters in the environment. ACS automatically configures registry integrations for active images by using the image pull secrets discovered in secured clusters.
