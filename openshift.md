# OpenShift

- [OpenShift](#openshift)
  - [Login to the nodes](#login-to-the-nodes)
    - [Run oc when logged onto a node](#run-oc-when-logged-onto-a-node)
    - [Find the IP address a node should have](#find-the-ip-address-a-node-should-have)
  - [Unable to delete a project](#unable-to-delete-a-project)
  - [Approve pending CRSs](#approve-pending-crss)
  - [Reboot a node](#reboot-a-node)
  - [Start a debug pod](#start-a-debug-pod)
  - [Set/unset default storage class](#setunset-default-storage-class)
  - [Find the VIP configuration (etc) of a cluster](#find-the-vip-configuration-etc-of-a-cluster)
  - [Updating a disconnected cluster](#updating-a-disconnected-cluster)
  - [Working with registries](#working-with-registries)
    - [Installing crane](#installing-crane)
    - [List release images](#list-release-images)
    - [Get the SHA256](#get-the-sha256)
    - [Trigger upgrade](#trigger-upgrade)
    - [Schedule an upgrade](#schedule-an-upgrade)
    - [Cancel an upgrade](#cancel-an-upgrade)
    - [Generate signature ConfigMap](#generate-signature-configmap)
    - [Rebuild an index in a mirror](#rebuild-an-index-in-a-mirror)
    - [Querying the catalogues for mirroring](#querying-the-catalogues-for-mirroring)
    - [Changing the oc-mirror cache directory](#changing-the-oc-mirror-cache-directory)
    - [Inspecting the index container](#inspecting-the-index-container)
    - [Poking the Quay API](#poking-the-quay-api)
    - [Extracting openshift-install from the mirrored content](#extracting-openshift-install-from-the-mirrored-content)
    - [Local registry access](#local-registry-access)
    - [How the oc-mirror command and how it uses the registry URLs](#how-the-oc-mirror-command-and-how-it-uses-the-registry-urls)
    - [Get the size of a registry](#get-the-size-of-a-registry)
    - [Mirror locations on node disk](#mirror-locations-on-node-disk)
  - [OpenShift recovery files](#openshift-recovery-files)
  - [Audit log policiies](#audit-log-policiies)
  - [Gatekeeper](#gatekeeper)
  - [JSON Stuff](#json-stuff)
    - [Loop through all pods and find stuff](#loop-through-all-pods-and-find-stuff)
    - [Various](#various)
    - [When jq is not available](#when-jq-is-not-available)
    - [Some advanced searching](#some-advanced-searching)
  - [Internal Image registry](#internal-image-registry)
    - [With RWO storage](#with-rwo-storage)
  - [Install not progressing, master nodes not ready](#install-not-progressing-master-nodes-not-ready)
  - [Extract openshift-install from registry](#extract-openshift-install-from-registry)
  - [Enable debugoc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.19-admissionregistration-v1beta1-api-removals-in-4.20":"true"}}' --type=merge](#enable-debugoc--n-openshift-config-patch-cm-admin-acks---patch-dataack-419-admissionregistration-v1beta1-api-removals-in-420true---typemerge)
    - [OpenShift authentication](#openshift-authentication)
    - [VMWare CSI driver](#vmware-csi-driver)
  - [Changing the domain name](#changing-the-domain-name)
  - [OADP](#oadp)
    - [Alias the velero command](#alias-the-velero-command)
  - [Extract the default ingress CA](#extract-the-default-ingress-ca)
  - [Decode machine config bundles](#decode-machine-config-bundles)
  - [Alias for events](#alias-for-events)
  - [Get default ingress router CA cert](#get-default-ingress-router-ca-cert)
  - [Online Graph API](#online-graph-api)
  - [Granular RBAC](#granular-rbac)
  - [Command completion](#command-completion)
  - [Override cluster proxy for an Operator](#override-cluster-proxy-for-an-operator)
  - [ARO upstream DNS server](#aro-upstream-dns-server)
  - [CoreOS image](#coreos-image)
  - [Monitor machine config updates](#monitor-machine-config-updates)

## Login to the nodes

`$ ssh -i <path to cluster cert> core@ip-address`

### Run oc when logged onto a node

```bash
$ sudo -i
# export KUBECONFIG=/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost-recovery.kubeconfig
# oc get co
```

### Find the IP address a node should have

```bash
sudo cat /etc/systemd/system/kubelet.service.d/20-nodenet.conf
```

## Unable to delete a project

`$ oc describe project <project-name>`

The output should explain what it is waiting on to be deleted/finalised.

Patch each of those to clear the finalizers:

`$ oc patch configmap/rook-ceph-mon-endpoints -p '{"metadata":{"finalizers":[]}}' --type=merge`

Or: [https://access.redhat.com/solutions/4165791](https://access.redhat.com/solutions/4165791)

## Approve pending CRSs

```bash
$ oc get csr
csr-44cs5  3h2m .....  Pending

$ oc get csr -o json | jq -r '.items[] | select(.status == {}) | .metadata.name' | xargs oc adm certificate approve
```

Or

`watch "oc get csr && oc get csr|awk '/Pending/ {print $1}'|xargs -i oc adm certificate approve {}"`

## Reboot a node

```bash
$ oc adm drain <node-name> --ignore-daemonsets=true --delete-emptydir-data --force=true
$ oc debug node/<node-name> 
chroot /host
sudo systemctl reboot
```

## Start a debug pod

`$ oc run -it debug-pod --image notshiny.spenscot.ddns.net:8443/ocp4/oce-cli:v4.13 --command -- /bin/bash`

Note: `-t` ==  'Force a pseudo-terminal to be allocated'

`oc new-app --name httpd --image registry.redhat.io/ubi9/httpd-24:1`

`oc create deployment httpd --image registry.redhat.io/ubi9/httpd-24:1`

## Set/unset default storage class

`oc patch storageclass <my-sc> -p '{"metadata": {"annotations": {"storageclass.kubernetes.io/is-default-class": "true"}}}'`

## Find the VIP configuration (etc) of a cluster

`oc get infrastructures.config.openshift.io/cluster -o yaml`

## Updating a disconnected cluster

```bash
oc adm upgrade -allow-explicit-upgrade -to-image mirror.example.com.au:8443/ocp4/openshift/release-images@sha256:45a396b169974dcbd8aae481c647bf55bcf9f0f8f6222483d407d7cec450928d
```

## Working with registries

### Installing crane

### List release images

`crane ls notshiny.spenscot.ddns.net:8443/ocp4/openshift/release-images`

or

`skopeo list-tags docker://mirror.spenscot.ddns.net:8443/openshift4/openshift-release-dev/ocp-release`

### Get the SHA256

The SHA256 can be used to explicitly name a release to apply in a disconnected environment

```bash
$ crane digest notshiny.spenscot.ddns.net:8443/ocp4/openshift/release-images:4.12.18-x86_64
sha256:8465e416a403cec2e6887c8aebe783b976f46f81d513890f17037b652b143de5
```

or

```bash
$ skopeo inspect docker://harbor.spenscot.ddns.net/quay/openshift-release-dev/ocp-release:4.20.25-x86_64|grep Digest
    "Digest": "sha256:490002f6d1363683178f4b9999f52602588f3cb75a9267a190fdfdee06e2db7a",
            "Digest": "sha256:4348899fa4910c81b110a0f2c4818daf666325f893b093cbd1e3c1691403f06c",
            "Digest": "sha256:a389dcabd776bf179bc16e2bbf430fd747730e772beeede87f3823ec075e16e4",
            "Digest": "sha256:6eade11f3e7cb9b517aa4d5c555701025c95c187a6849d1e95ecd9cc0df91aa8",
            "Digest": "sha256:eb68715b816e510203ccbebfa25f3eae87629603c2cf41922cca5aa1b453865e",
            "Digest": "sha256:a5a6cbe0973c7faa53a277ac807e19c39c0c88ea0973cad4a9148a976d1477e6",
```

### Trigger upgrade

`oc adm upgrade --allow-explicit-upgrade --to-image mirror.spenscot.ddns.net:8443/openshift4/openshift-release-dev/ocp-release@sha256:bada2d7626c8652e0fb68d3237195cb37f425e960347fbdd747beb17f671cf13 --force=true`

### Schedule an upgrade

```bash
OCP_UPGRADE_TO=$(oc get clusterversion version -o \
   jsonpath='{.status.availableUpdates[0].version}')

cat <<EOF | oc apply -f -
---
apiVersion: upgrade.managed.openshift.io/v1alpha1
kind: UpgradeConfig
metadata:
  name: managed-upgrade-config
  namespace: openshift-managed-upgrade-operator
spec:
  type: "ARO"
  upgradeAt: $(date -u --iso-8601=seconds --date "+1 day")
  PDBForceDrainTimeout: 60
  capacityReservation: true
  desired:
    channel: "stable-4.13"
    version: "${OCP_UPGRADE_TO}"
EOF
```

### Cancel an upgrade

If the upgrade hasn't started, it may be possible to cancel it:

```bash
oc adm upgrade --clear
```

(https://access.redhat.com/solutions/7032365)

### Generate signature ConfigMap

If not using `oc mirror` or `oc adm mirror`, ie: proxying the registries through a Quay, Nexus or Artifactory, then the release image signatures ConfigMap will need to be manually built.

```bash
OCP_RELEASE=4.19.7
ARCHITECTURE=x86_64
DIGEST="$(oc adm release info quay.io/openshift-release-dev/ocp-release:${OCP_RELEASE}-${ARCHITECTURE} | sed -n 's/Pull From: .*@//p')"
DIGEST_ALGO="${DIGEST%%:*}"
DIGEST_ENCODED="${DIGEST#*:}"
SIGNATURE_BASE64=$(curl -s "https://mirror.openshift.com/pub/openshift-v4/signatures/openshift/release/${DIGEST_ALGO}=${DIGEST_ENCODED}/signature-1" | base64 -w0 && echo)
cat >checksum-${OCP_RELEASE}.yaml <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: release-image-${OCP_RELEASE}
  namespace: openshift-config-managed
  labels:
    release.openshift.io/verification-signatures: ""
binaryData:
  ${DIGEST_ALGO}-${DIGEST_ENCODED}: ${SIGNATURE_BASE64}
EOF
echo $OCP_RELEASE
echo $DIGEST
cat checksum-${OCP_RELEASE}.yaml
```

### Rebuild an index in a mirror

```dockerfile
# Containerfile
FROM registry:5000/openshift4/redhat/redhat-operator-index:v4.14
RUN opm serve /configs --cache-dir=/tmp/cache --cache-only
CMD ["serve", "/configs", "--cache-dir", "/tmp/cache"]
```

```bash
# Commands to run
podman build . -t registry:5000/openshift4/redhat/redhat-operator-index:v4.14
podman push registry:5000/openshift4/redhat/redhat-operator-index:v4.14
```

### Querying the catalogues for mirroring

```bash
oc mirror list operators --catalogs --version=4.15
oc mirror list operators --catalog=registry.redhat.io/redhat/redhat-operator-index:v4.15 --package=openshift-gitops-operator
```

### Changing the oc-mirror cache directory

`export OC_MIRROR_CACHE=/mnt/cache`

### Inspecting the index container

```bash
oc get pods -n openshift-marketplace
oc -n openshift-marketplace rsh redhat-operators-xm66t
ls -l /configs
```

Or Manually explore an Operator Catalog (e.g. Red Hat, Community, Certified)

Manually explore an Operator Catalog (e.g. Red Hat, Community, Certified)
`podman run --rm -it --entrypoint=/bin/sh registry.redhat.io/redhat/redhat-operator-index:v4.12`

It's better to "image mount" because "run" the image doesn't provide `jq` or `yq`

```bash
podman pull registry.redhat.io/redhat/redhat-operator-index:v4.12
podman unshare
cd $(podman image mount registry.redhat.io/redhat/redhat-operator-index:v4.12)
ls configs
for i in $(jq --raw-output '. | select( .schema | contains("olm.package")) | .name' configs/*/catalog.json); do echo "    - name: $i" | tee -a ~/imageset-config.yaml.all-operators; done
jq .name configs/*/catalog.json
```python3 -c "import sys, json; print(json.load(sys.stdin)['kubectlBundle'])"

**list available operators**

```bash
oc mirror list operators --version 4.12 --catalog registry.redhat.io/redhat/redhat-operator-index:v4.12
ls configs/
```

**browse the metadata of an Operator**
`jq . configs/advanced-cluster-management/catalog.json | less -i`

Ref: <https://hackmd.io/@johnsimcall/Sk1gG5G6o>

### Poking the Quay API

I wanted to find a way to delete all of the Quay images and start over, without changing my CA certificate, or doing ./mirror-registry uninstall ... I found that I could create a Quay "super user" token and use that on the command line. Apparently tokens are deprecated, but I couldn't figure out how to make a Robot Account work for me. First create a new Organization. I called mine "adminorg", then follow the instructions to create a token.

my TOKEN is 40 characters - a robot account's password/"token" is 64 characters
`export TOKEN="abcdefghijklmnopqrstuvwxyz0123456789ABCD"`

sad that this query doesn't list repos as "org/repo"
`curl -s -X GET -H "Authorization: Bearer $TOKEN" 'https://jcall-testing.dota-lab.iad.redhat.com:8443/api/v1/repository?public=true' | jq --raw-output '.repositories[].name'`

must delete "org/repo" instead of "repo"
`curl -s -X DELETE -H "Authorization: Bearer $TOKEN" 'https://jcall-testing.dota-lab.iad.redhat.com:8443/api/v1/repository/advanced-cluster-security/rhacs-operator-bundle'`

list all of the organizations, except the "adminorg" which holds my $TOKEN
`curl -s -X GET -H "Authorization: Bearer $TOKEN" "https://jcall-testing.dota-lab.iad.redhat.com:8443/api/v1/superuser/organizations/" | jq --raw-output '.organizations[].name' | grep -v adminorg`

deleting the org removes all repos
`curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "https://jcall-testing.dota-lab.iad.redhat.com:8443/api/v1/superuser/organizations/advanced-cluster-security"`

delete all of the orgs -- DANGER!!!

```bash
for ORG in $(curl -s -X GET -H "Authorization: Bearer $TOKEN" 'https://jcall-testing.dota-lab.iad.redhat.com:8443/api/v1/superuser/organizations/' | jq --raw-output '.organizations[].name' | grep -v adminorg ); do
  echo "Deleting \"$ORG\" organization..."
  curl -s -X DELETE -H "Authorization: Bearer $TOKEN" "https://jcall-testing.dota-lab.iad.redhat.com:8443/api/v1/superuser/organizations/$ORG"
done
```

Ref: [ttps://hackmd.io/@johnsimcall/Sk1gG5G6o]<https://hackmd.io/@johnsimcall/Sk1gG5G6o>

### Extracting openshift-install from the mirrored content

`$ oc adm release extract --command=openshift-install mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4/openshift-release-dev/ocp-release:4.16.20-x86_64`

### Local registry access

To authenticate to the local registry:

```bash
$ podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false default-route-openshift-image-registry.apps-crc.testing
Login Succeeded!
```

Example pull:

`$ podman pull default-route-openshift-image-registry.apps-crc.testing/test/devfile-sample-go-basic@sha256:50d59da053a86509ef9ea661ee21cce58631c30f305f1806cae728c9dfb3c632 --tls-verify=false`

### How the oc-mirror command and how it uses the registry URLs

With imageURL set to quay.skynet/openshift and mirror to quay.skynet  it creates the following request in Quay:

`gunicorn-registry stdout | 2024-07-29 17:37:01,458 [336] [INFO] [gunicorn.access] 172.17.0.1 - - [29/Jul/2024:17:37:01 +0000] "POST /v2/oc-mirror/blobs/uploads/ HTTP/1.1" 401 112 "-" "go-containerregistry/v0.15.2"
nginx stdout | 172.17.0.1 (-) - - [29/Jul/2024:17:37:01 +0000] "POST /v2/oc-mirror/blobs/uploads/ HTTP/1.1" 401 112 "-" "go-containerregistry/v0.15.2" (0.001 1259 0.002)`

This fails because repository library/oc-mirror doesn't exist. Again, if the namespace name is omitted, then Quay assumes library as the namespace. Repos cannot live outside of namespaces. If I try to mirror to quay.skynet/openshift then one'd assume it would interpret openshift as the namespace name, but it doesn't do that:

`gunicorn-registry stdout | 2024-07-29 17:38:07,052 [335] [INFO] [gunicorn.access] 172.17.0.1 - - [29/Jul/2024:17:38:07 +0000] "POST /v2/openshift/blobs/uploads/ HTTP/1.1" 401 112 "-" "go-containerregistry/v0.15.2"`

Again, there is no namespace, hence library is assumed and since it doesn't exist, this request fails. Setting imageURL to just quay.skynet and mirroring to quay.skynet/openshift creates a correct request towards Quay:

`nginx stdout | 172.17.0.1 (-) - - [29/Jul/2024:17:40:14 +0000] "POST /v2/openshift/oc-mirror/blobs/uploads/ HTTP/1.1" 202 0 "-" "go-containerregistry/v0.15.2" (0.061 1220 0.061)`

but the problem is oc-mirror  cannot parse the namespace name from the config, it expects it there so it errors out with missing reference. The solution is to set imageURL to point to QUAY_HOSTNAME/NAMESPACE/repo and then in oc-mirror command to set docker://QUAY_HOSTNAME/namespace . That way oc-mirror can parse references properly and Quay is satisfied because you provided the namespace where repos should live.

In my case:

```YAML
kind: ImageSetConfiguration
apiVersion: mirror.openshift.io/v1alpha2
storageConfig:
  registry:
    imageURL: quay.skynet/redhat/openshift
    skipTLS: false
mirror:
  platform:
    channels:
    - name: stable-4.16
      type: ocp
  operators:
  - catalog: registry.redhat.io/redhat/redhat-operator-index:v4.17
    packages:python3 -c "import sys, json; print(json.load(sys.stdin)['kubectlBundle'])"
    - name: serverless-operator
      channels:
      - name: stable
  additionalImages:
  - name: registry.redhat.io/ubi8/ubi:latest
  helm: {}
```

with command: `oc mirror --config mirror.yaml docker://quay.skynet/redhat`

### Get the size of a registry

Tricky

### Mirror locations on node disk

`/etc/containers/registries.conf`

## OpenShift recovery files

_From: Michael Washer_

Located on the nodes at:

```bash
./static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-int.kubeconfig
/etc/kubernetes/static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/lb-int.kubeconfig
./static-pod-resources/kube-apiserver-certs/secrets/node-kubeconfigs/localhost-recovery.kubeconfig
```

If you can access any one node then you can get these files and these allow API access to the cluster without needing to login

<https://michael-washer.com/posts/2022/01/creating-hidden-super-users-in-openshift/>

## Audit log policiies

<https://docs.openshift.com/container-platform/4.12/security/audit-log-policy-config.html>

- WriteRequestBodies (best)
- AllRequestBodies (too much data 200MB per log entry lol)

## Gatekeeper

Kyverno/Gatekeeper

<https://github.com/open-policy-agent/gatekeeper>

## JSON Stuff

### Loop through all pods and find stuff

```bash
for namespace in `oc get namespaces | awk '!/NAME/ {print $1}'`
do 
  echo $namespace
  for pod in `oc get -n ${namespace} pods | awk '!/NAME/ {print $1}'`
  do
    echo ">>> $pod"
    echo -n "---"
    oc get -n $namespace pod/$pod -o jsonpath="{.status.containerStatuses[*]}" 
  done
done
```

### Various

`$ oc get subscription --all-namespaces --no-headers -o json | jq -r '.items[] | (.metadata.name + ": " + .spec.installPlanApproval)'`

`$ oc get node --no-headers -o json | jq -r '.items[] | (.metadata.name + " - CPU: " + .status.capacity.cpu + ", Memory: " + .status.capacity.memory)'|sort`

`$ oc get pod --all-namespaces --sort-by='.metadata.name' -o json | jq -r '[.items[] | {pod_name: .metadata.name, containers: .spec.containers[] | [ {container_name: .name, memory_requested: .resources.requests.memory, cpu_requested: .resources.requests.cpu} ] }]' | jq 'sort_by(.containers[0].cpu_requested)'`

`$ oc get pod --all-namespaces --field-selector spec.nodeName=control-1-ru2.dslab.defence.gov.au --sort-by='.metadata.name' -o json | jq -r '[.items[] | {pod_name: .metadata.name, containers: .spec.containers[] | [ {container_name: .name, memory_limit: .resources.limits.memory, cpu_limit: .resources.limits.cpu} ] }]' | jq 'sort_by(.containers[0].memory_limit)'`

`$ oc get pod --all-namespaces --field-selector spec.nodeName=control-1-ru2.dslab.defence.gov.au --sort-by='.metadata.name' -o json | jq -r '[.items[] | {pod_name: .metadata.name, containers: .spec.containers[] | [ {container_name: .name, memory_limit: .resources.limits.memory, cpu_limit: .resources.limits.cpu} ] }]' | jq 'sort_by(.containers[0].cpu_limit)'`

### When jq is not available

Using `python3` when `jq` is not available:

`oc get pod test -o json | python3 -c "import sys, json; print(json.load(sys.stdin)['name'])"`

`oc -n openshift-console get pod -o json | python3 -c "import sys, json; result = json.load(sys.stdin); print([item['metadata']['name'] for item in result['items']])"`

### Some advanced searching 

Not yet really worked through this

`oc -n rhacs get central central -o jsonpath='{.status.conditions[?(@.type=="Deployed")].status}'`

## Internal Image registry

`oc edit configs.imageregistry.operator.openshift.io -n openshift-image-registry`

### With RWO storage

Create a PVC for the registry:

```YAML
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-pvc-imageregistry
  namespace: openshift-image-registry
  annotations:
    imageregistry.openshift.io: "true"
spec:
  accessModes:
  - ReadWriteOnce
  volumeMode: Filesystem
  resources:
    requests:
      storage: 100Gi
  storageClassName: thin-csi
```

Patch the image registry to use the PVC, set the rollout strategy and set the management state:

```bash
oc patch configs.imageregistry.operator.openshift.io/cluster --type "merge" --patch '{"spec":{"storage":{"pvc":{"claim": "csi-pvc-imageregistry"}}}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"rolloutStrategy":"Recreate"}}'
oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Managed"}}'
```

## Install not progressing, master nodes not ready

<https://redhat-internal.slack.com/archives/C68TNFWA2/p1704221879638939>

`oc adm taint node <nodename> node.cloudprovider.kubernetes.io/unitialized:NoSchedule-`

Most likely caused by a missing permission for the vSphere service account, even if they have vSphere **admin** privileges.  Still have not found which one though.

## Extract openshift-install from registry

```bash
$ oc adm release extract -a pull-secret.json --command=openshift-install \
notshiny.spenscot.ddns.net:8443/ocp4/openshift-release:4.14.22-x86_64
```

## Enable debugoc -n openshift-config patch cm admin-acks --patch '{"data":{"ack-4.19-admissionregistration-v1beta1-api-removals-in-4.20":"true"}}' --type=merge

### OpenShift authentication

Enable:
`$ oc patch authentications.operator.openshift.io --type=json -p '[{"op": "replace", "path": "/spec/logLevel", "value": "Debug" }]'`

Revert:

### VMWare CSI driver

`$ oc patch authentications.operator.openshift.io --type=json -p '[{"op": "replace", "path": "/spec/logLevel", "value": "Normal" }]'`

Enable:
`$ oc patch clustercsidriver/csi.vsphere.vmware.com --type=json -p '[{"op": "replace", "path": "/spec/logLevel", "value": "TraceAll" }]'`

Logs to the controller pod:
`$ oc logs vmware-vsphere-csi-driver-controller-67f6b88f9-jtkg5 csi-driver`

Note that this will dump the vSphere password into the logs. The logs should include all datastores that are being checked for accessibility and also indicate whether the above permissions are setup correctly.

To revert:
`$ oc patch clustercsidriver/csi.vsphere.vmware.com --type=json -p '[{"op": "replace", "path": "/spec/logLevel", "value": "Normal" }]'`

## Changing the domain name

<https://access.redhat.com/solutions/4853401>

<https://access.redhat.com/articles/regenerating_cluster_certificates>

Update the Ingress with the new domain:

`oc patch ingress.config.openshift.io cluster --type merge --patch '{"spec":{"host":"alertmanager-main-openshift-monitoring.apps.ocp4.spenscot.ddns.net"}}'`

This will take care of oauth and the console, and will apply to new routes

Manually patch the other routes:

```bash
oc -n openshift-gitops patch route kam --patch '{"spec":{"host":"kam-openshift-gitops.apps.ocp4.spenscot.ddns.net"}}'
oc -n openshift-gitops patch route openshift-gitops-server --patch '{"spec":{"host":"openshift-gitops-server-openshift-gitops.apps.ocp4.spenscot.ddns.net"}}'
oc -n openshift-ingress-canary patch route canary --type merge --patch '{"spec":{"host":"canary-openshift-ingress-canary.apps.ocp4.spenscot.ddns.net"}}'
oc -n openshift-monitoring patch route alertmanager-main --type merge --patch '{"spec":{"host":"alertmanager-main-openshift-monitoring.apps.ocp4.spenscot.ddns.net"}}'
oc -n openshift-monitoring patch route prometheus-k8s --type merge --patch '{"spec":{"host":"prometheus-k8s-openshift-monitoring.apps.ocp4.spenscot.ddns.net"}}'
oc -n openshift-monitoring patch route prometheus-k8s-federate --type merge --patch '{"spec":{"host":"prometheus-k8s-federate-openshift-monitoring.apps.ocp4.spenscot.ddns.net"}}'
oc -n openshift-monitoring patch route thanos-querier --type merge --patch '{"spec":{"host":"thanos-querier-openshift-monitoring.apps.ocp4.spenscot.ddns.net"}}'
```

Take a copy of the existing IngressCOntroller:

`oc -n openshift-ingress-operator get ingresscontroller default -o yaml > IngressController.yaml`

Edit to remove unwanted bits, then delete and recreate:

```bash
oc -n openshift-ingress-operator delete ingresscontroller default
oc apply -f ingresscontroller.yaml
```

## OADP

### Alias the velero command

`alias velero='oc -n openshift-adp exec deployment/velero -c velero -it -- ./velero'`

## Extract the default ingress CA

Use openssl:

```bash
$ openssl s_client -connect console-openshift-console.apps.disc.spenscot.ddns.net:443 -showcerts
Certificate chain
 0 s:CN=*.apps.disc.spenscot.ddns.net
   i:CN=ingress-operator@1732573310
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Nov 25 22:21:51 2024 GMT; NotAfter: Nov 25 22:21:52 2026 GMT
-----BEGIN CERTIFICATE-----
...
fEXy9ZlgBRvKNmLsxR7mISkEFXgh
-----END CERTIFICATE-----
 1 s:CN=ingress-operator@1732573310
   i:CN=ingress-operator@1732573310
   a:PKEY: rsaEncryption, 2048 (bit); sigalg: RSA-SHA256
   v:NotBefore: Nov 25 22:21:49 2024 GMT; NotAfter: Nov 25 22:21:50 2026 GMT
-----BEGIN CERTIFICATE-----
...
-----END CERTIFICATE-----
```

Certificate "1" is the CA, copy this into a file and test:

`curl --cacert ca-bundle.crt -k https://console-openshift-console.apps.disc.spenscot.ddns.net`

## Decode machine config bundles

If urlencodes, then:

```bash
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
urldecode server%2099…..5%0A
```

if compressed with gzip, then copy the string out from the source excluding `data:;base64,`. For example:

```yaml
        - contents:
            compression: gzip
            source: 'data:;base64,H4sIAAAAAAAC/1yRza7...gAA'
          mode: 420
          overwrite: true
          path: /etc/chrony.conf
```

Decode with:

`echo H4sIAAAAAAAC/1yRza7...gAA | base64 -d | gzip d`

[https://access.redhat.com/solutions/7059628]

## Alias for events

`alias events='oc get events --sort-by=".lastTimestamp" -n $1'`

## Get default ingress router CA cert

`oc -n openshift-ingress-operator get secret router-ca -o jsonpath='{.data.tls\.crt}'|base64 -d`

## Online Graph API

`curl https://api.openshift.com/api/upgrades_info/v1/graph?channel=stable-4.18 | jq .`

`curl -v -G https://api.openshift.com/api/upgrades_info/v1/graph -d "channel=stable-4.18"`

## Granular RBAC

Permissions can be applied to specific instances of resources through the `rules.resourceName` field. However it is of limited value as wildcards can not be specified.

As an example, AFP wanted to limit write access to specific pipeline and pipeline run instances in a given namespace based on roles.  For example, in the namesapce `test`:

- team 1 can only update pipelines and pipelineruns belonging to the test1 application
- team 2 can only update pipelines and pipelineruns belonging to the test2 application

This can be paritally achieved.  

1. The `Cluster Role: Edit` can be used to give the teams edit access as this includes the ability to update all tekton resources in the namespaces. Tekton has a webhook that monitor ClusterRoles that provide edit or view access to a namesapce and inject the tekton resources into these roles.
2. A custom namespaced edit role will need to be created and granted to both teams that does not include update access to the tekton reosurces
3. Both teams need to have `get/list/watch` access to all pipeline resources in the namespace in order to list the available resources through the CLI and UI (it looks like a failure to list a particular instance will prevent the list for a subset of the resources from completing)
4. Custom edit rules for each team can be created that grant update access to stattically named pipelines, eg: `test1-build-pipeline`, `test2-build-pipeline`) using the `resourceNames` field can be bound to each group to allow update access to the pipeline. However, access cannot be granted to pipelineruns as (by default) the pipelineruns are dynamically named (eg: `test1-build-pipeline-242md7`). It would be possible if pipeline runs were triggered manually in the UI and named manually, implying that each pipeline run would need to be deleted before the next could run and it wiyuld not be poissible to take advantage of integration where pipelines are started by a git trigger.

Not really all that useful.

## Command completion

```bash
$ cat ~/.bashrc
...
load_completion() {
  cmd=$1
  if command -v "$cmd" %> /dev/null; then
    source <("$cmd" completion bash)
  fi
}

load_completion oc
load_completion kubectl
load_completion virtctl
load_completion roxctl
```

## Override cluster proxy for an Operator

When using the following instructions to override the cluster proxy for an operator:

https://docs.redhat.com/en/documentation/openshift_container_platform/4.17/html/operators/administrator-tasks#olm-configuring-proxy-support

Then the noProxy needs to include the pod network, the service network, 127.0.0.1, .cluster.local, .svc along with the local cluster domain as they do not get added automagically.

## ARO upstream DNS server

```bash
cat /etc/resolv.conf.dnsmasq
```

## CoreOS image

The openshift-install will extract it form the mirrored content and stash it:

```base
INFO Base ISO obtained from release and cached at [~/.cache/agent/image_cache/coreos-x86_64.iso]
```

## Monitor machine config updates

```yaml
oc -n openshift-machine-config-operator logs machine-config-controller-xxx-yyy
oc -n openshift-machine-config-operator logs machine-config-daemon-zzz
```
