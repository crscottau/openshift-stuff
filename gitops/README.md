# Configuring a cluster

## Overview

Manually apply the filers in gitops/bootstrap (not including subdirectories).

File #4 applies the contents of the gitops/bootstrap/applications

These files reference the apps

## Issues

- **RESOLVED** Sync waves are not working
- **RESOLVED** Admin privileges in Argo, ie: cluster-admin user can not see the applications created under kubeadmin
- cert-manager doesn't play well in Argo

### Sync waves

sync waves do not appear to be honoured.  For example: ACM application fails to install as there is no multicluster hub CRD at the start.  

The sync waves are specified to install:

1. Namespace
2. Operator group and subscription
3. Multiclusterhub

Weirdly, it all works fine if I manually sync the resources in that order.

**Resolution**

Missing piece was that ArgoCD will try and do a dry-run before installing anything. The dry-run fails as the CRD is not yet created.  Add the following to the resources that have new CRDs:

```
  annotations:
    argocd.argoproj.io/sync-wave: "10"
    argocd.argoproj.io/sync-options: "SkipDryRunOnMissingResource=true"
```

Still need a sync-wave > 0 so that it delays creating the CRD. No other resources need a sync-wave.

### Admin privileges

cluster-admin user can not see the applications created under kubeadmin

**Resolution**

ArgoCD has a pre-mapping of admin privileges to the OCP group cluster-admins. In my test environment, added this group for my user and bound it to the cluster-admin role.

### cert-manager

Doesn't play well in Argo, it ends up in __Out Of Sync__ state as all of the CRDs it creates, eg: cert-manager-webhook, clusterissuers.cert-manager.io and certificates.cert-manager.io, as unknown and if one syncs with purge enabled, it breaks cert-manager completely. 

Might be better to apply cert-manager using Ansible as part of the "bootstrap"

And will likely be better to apply ingress and API certs as ACM policies rather than GitOps applications. Mainly because the GitOps application ends up being out of sync as more resources get created.

## To do


## Thoughts

How to get the CA cert from the new cluster to be used in the playbook:

`$ oc get configmap -n openshift-kube-apiserver  kube-root-ca.crt -o yaml > kube-root-ca.crt`

**kustomize**

