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
