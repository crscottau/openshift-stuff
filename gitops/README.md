# Configuring a cluster

## Overview

Manually apply the filers in gitops/bootstrap (not including subdirectories).

File #4 applies the contents of the gitops/bootstrap/applications

These files reference the apps

## Issues

- Sync waves are not working
- Admin privileges in Argo, ie: cluster-admin user can not see the applications created under kubeadmin
- cert-manager doesn't play well in Argo

### Sync waves

sync waves do not appear to be honoured.  For example: ACM application fails to install as there is no multicluster hub CRD at the start.  

The sync waves are spcified to install:

1. Namespace
2. Operator group and subscription
3. Multiclusterhub

Weirdly, it all works fine if I manually sync the resources in that order.

### Admin privileges

cluster-admin user can not see the applications created under kubeadmin

### cert-manager

Doesn't play well in Argo, it ends up in __Out Of Sync__ state as all of the CRDs it creates, eg: cert-manager-webhook, clusterissuers.cert-manager.io and certificates.cert-manager.io, as unknown and if one syncs with purge enabled, it breaks cert-manager completely. 

Might be better to apply cert-manager using Ansible as part of the "bootstrap"

## To do


## Thoughts

**kustomize**

