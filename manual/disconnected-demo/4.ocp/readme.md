# OpenShift

## OpenShift install

Extract the installer from the mirror registry:

`oc adm release extract --command=openshift-install mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4/openshift-release-dev/ocp-release:4.16.20-x86_64`

Create the install-config.yaml file

Install the cluster

```bash
mkdir cluster
cp install-config.yaml cluster
./openshift-install --dir=./cluster create cluster
```

## Configuration

### Catalogues

Disable default catalogsources

Enable mirrored catalogsources and apply IDMS and ITMS

### Deploy quay

Using the code in aro-gitops/bootstrap*

## Upgrading the disconnected cluster

Mirror the new images into the registry

Apply the updated catalogue source yaml. There is no need to apply the ITMS and IDMS as they will be the same.

List the tags of the ocp-release repository:

```bash
$ skopeo list-tags docker://mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4/openshift-release-dev/ocp-release
{
    "Repository": "mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4/openshift-release-dev/ocp-release",
    "Tags": [
        "4.16.20-x86_64",
        "4.17.4-x86_64"
    ]
}
```

Determine the digest of the required ocp-release tag:

```bash
$ skopeo inspect docker://mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4/openshift-release-dev/ocp-release:4.17.4-x86_64|grep -E '^    "Digest'
    "Digest": "sha256:bada2d7626c8652e0fb68d3237195cb37f425e960347fbdd747beb17f671cf13",
```

Trigger the upgrade:

```bash
$ oc adm upgrade --allow-explicit-upgrade --to-image mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4/openshift-release-dev/ocp-release@sha256:bada2d7626c8652e0fb68d3237195cb37f425e960347fbdd747beb17f671cf13
warning: The requested upgrade image is not one of the available updates. You have used --allow-explicit-upgrade for the update to proceed anyway
Requested update to release image mirror.vqmpz.dynamic.redhatworkshops.io:8443/openshift4/openshift-release-dev/ocp-release@sha256:bada2d7626c8652e0fb68d3237195cb37f425e960347fbdd747beb17f671cf13
```
