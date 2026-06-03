# Deploy demo

VMWare IBM cloud

## Deloy task

### Inputs

- OpenShift version
- IP range
- Cluster name

### Steps

- Download openshift install
- Unpack openshift install to `.local/bin`
- Download openshift client
- Unpack openshift install to `.local/bin`
- Copy vSphere certs and `update-ca-trust`
- Copy `install-config.yaml` and update Cluster name, IP and vSphere username and passwords
- Create cluster directory and copy `install-config.yaml`
- Start the install

Optional

- Install squid
