# Network Policy thoughts

[AdminNetworkPolicy](https://ovn-kubernetes.io/features/network-security-controls/admin-network-policy/#adminnetworkpolicy-sample-api)

## Overview

The network policy objects are tiered and evaluated in tier order:

Tier 1. AdminNetworkPolicy - Cluster-wide policies that cannot be over-ridden by 2 or 3. However they can specify `pass` (in addition to `deny` or `allow` ) a decision down the hierarchy

Tier 2. NetworkPolicy - Namespaced scoped.

Tier 3. BaselineAdminNetworkPolicy - Single cluster-wide instance that applies if not other rules have been applied.

## AdminNetworkPolicy

## NetworkPolicy

The NetworkPolicies defined in `atest-network-policies` are designed to demonstrate:

- Allows access between all pods within the namespace
- Allows access to OpenShift DNS
- Allows access to the ingress router endpoint
- Allows access to an external HTTP server

## BaselineAdminNetworkPolicy

There does not seem to be a way to setup a deny all policy, but allow from same namespace as the `from:` must specify a namespace or namespace selector that can only be explicit values.

However setting a default deny for everything prevents any communications, meaning the developers **must** include a NetworkPolicy to specify explicit allows.

The `base-admin-network-policy.yaml` applies the policy to namnespaces identified with the label `type: workload`. The namespace could be added as part of the new project template; only a someone with cluster level permissions could amend the label.

The `base-admin-network-policy-full.yaml` applies the policy to namespaces that are not "system" namespaces. These are defimned explicitly in the list and are the openshift* and kube* namespaces plus a few extras. The issue with this is that when new "system" namespaces are added, either through plaform updates or through deploying new operators, then the BANP needs to be updated.

## Testing

```bash
# rsh into a pod 
oc -n atest-pre02 rsh httpd-785688cb4c-dz28w
# Test connection to a route
sh-5.1$ curl -k --connect-timeout 5 https://httpds-atest-pre01.apps.disc.spenscot.ddns.net
Hello
sh-5.1$ 
# Test connection to a service in another namespace
sh-5.1$ curl --connect-timeout 5 http://httpd.atest-pre01.svc.cluster.local:8080
curl: (28) Connection timed out after 5001 milliseconds
# Test connection to a service in this namespace
sh-5.1$ curl --connect-timeout 5 http://httpd.atest-pre02.svc.cluster.local:8080
Hello
sh-5.1$ 
# Test connection to a pod in another namespace
sh-5.1$ curl --connect-timeout 5 http://10.128.0.13:8080
curl: (28) Connection timed out after 5001 milliseconds
# Test connection to a different pod in this namespace
sh-5.1$ curl --connect-timeout 5 http://10.128.0.65:8080
Hello
sh-5.1$ 
# Test connection to self
sh-5.1$ curl --connect-timeout 5 http://10.128.0.63:8080
Hello
sh-5.1$ 
# Test connection to an external endpoint
sh-5.1$ curl --connect-timeout 5 http://192.168.124.56
HELLO from RHEL10
sh-5.1$ 
```
