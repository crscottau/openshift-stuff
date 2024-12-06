# Disconnected demo

## DNS

Build the DNS VM following the instructions in **VM**

Clone the VM to mirror

Install and configure bind using the instructios in **dns**

## Install Quay

Download and install:

- oc client
- oc-mirror plugin
- podman

Download:

- mirror-registry

Install the mirror-registry:

`$ ./mirror-registry install --initPassword '2wsx#EDC' --quayHostname mirror.vqmpz.dynamic.redhatworkshops.io --quayRoot ~/quay --quayStorage ~/quay/storage`

Allow firewall access to the registry:

```bash
sudo firewall-cmd --add-port 8443/tcp
sudo firewall-cmd --add-port 8443/tcp --permanent
```

Install the quay CA certificate:

```bash
sudo cp ~/quay/quay-rootCA/rootCA.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust 
```

## Mirror content

```bash
mkdir ~/mirror
cd ~/mirror
```

Copy the RH pull secret to the mirror box as `~/.docker/config.json`

Generate local credentials and append to the above:

`$ podman login -u init --authfile local.json mirror.vqmpz.dynamic.redhatworkshops.io:8443`

Config file:

```bash
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v2alpha1
mirror:
  platform:
    channels:
    - name: stable-4.16
      minVersion: 4.16.20
      maxVersion: 4.16.20
    graph: true
  operators:
    - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.16
      packages:
       - name: quay-operator
#      - name: cluster-logging
#      - name: advanced-cluster-management
#      - name: multicluster-engine
#      - name: rhacs-operator
#      - name: openshift-gitops-operator
  additionalImages:
  - name: registry.redhat.io/openshift4/ose-cli:v4.15
  - name: registry.redhat.io/rhel8/support-tools:latest
```

Mirror

`$ oc mirror --config imageset-config.yaml --workspace file:///home/lab-user/mirror/workspace docker://mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4 --v2`

## Issues

### push fails with permissions error

Pushing images to the registry fails with the following internal error:

```bash
nginx stdout | 2024/12/05 00:36:44 [error] 74#0: *19 upstream prematurely closed connection while reading response header from upstream, client: 192.168.41.1, server: _, request: "POST /v2/test/support-tools/blobs/uploads/ HTTP/1.1", upstream: "http://unix:/tmp/gunicorn_registry.sock:/v2/test/support-tools/blobs/uploads/", host: "mirror.vqmpz.dynamic.redhatworkshops.io:8443"                                                                                          
nginx stdout | 192.168.41.1 (-) - - [05/Dec/2024:00:36:44 +0000] "POST /v2/test/support-tools/blobs/uploads/ HTTP/1.1" 502 363 "-" "containers/5.32.2 (github.com/containers/image)" (0.031 1317 0.020 : 0.011)                                                                                                                                                                       
gunicorn-web stdout | 2024-12-05 00:36:44,874 [172] [INFO] [gunicorn.access] 192.168.41.1 - - [05/Dec/2024:00:36:44 +0000] "GET /quay-registry/static/502.html HTTP/1.0" 308 363 "-" "containers/5.32.2 (github.com/containers/image)"
...
gunicorn-registry stdout | PermissionError: [Errno 13] Permission denied: '/datastorage/uploads'                             
nginx stdout | 2024/12/05 00:36:45 [error] 74#0: *22 upstream prematurely closed connection while reading response header from upstream, client: 192.168.41.1, server: _, request: "POST /v2/test/support-tools/blobs/uploads/ HTTP/1.1", upstream: "http://unix:/tmp/gunicorn_registry.sock:/v2/test/support-tools/blobs/uploads/", host: "mirror.vqmpz.dynamic.redhatworkshops.io:8443"          
```

Feels like the `Permission denied: '/datastorage/uploads'` is the problem.

The mapped directory (`/home/lab-user/quay/storage`) has the correct SELinux type.

Disabling SELinux does not help, so something else is going on here.

For now, cloned the VM so I can investigate later and re-install quay using the default storage location.

### push fails with permissions error again

Found I had to login  to the quay UI and generate an ecrypted password, then login from the podman CLI and generate an auth file. After adding the new auth string to the `~/.docker/config.json`, I was able to mirror.