# ACM Observability

## References

[https://docs.google.com/document/d/1mdY6J6Jimsw7A2n7sv9vFjzM2IHD8-Ku9ZNy2iKfgb8/edit?tab=t.0]

[https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/observability/]

[https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/observability/index#observability-pod-capacity-requests]

## Overview

## Requirements

Minimum requirement for 2.7 CPU cores and 12 GB memory requirements.

Recommendation for monitoring 5 clusters is another 0.76 CPU cores and 3.3 GB memory

Most of the StatefulSet pods require persistent storage, default sizes are:

observability-alertmanager, requires 3 X 1G
observability-thanos-compact, requires 1 X 100G
observability-thanos-query-frontend-memcached, no requirement
observability-thanos-receive-default, requires 3 X 100G
observability-thanos-rule, requires 3 X 1G
observability-thanos-store-, no requirement
observability-thanos-store-shard-*, requires 3 X 10G

total is 436G

Object storage is really hard to estimate as it depends on too many variables, such as number of clusters, metrics collected, user workload monitoring, collection intervals and retention. But as a rough back of the napkin estimate, my test system in RHPD is installed with eveyrthing as default (no user workloads included), and:

Deployed 17/3 12:00, shutdown at 17:00 (5 hours)

Started 18/3 9:00, shutdown at 17:00 (8 hours == 13 hours)

3 clusters over ~13 hours = 152MB

This suggests 35MB per cluster over 13 hours, :

- MB/cluster/day
- GB/year

So 500GB would be a good starting size for AFP.

Note: we have no visibility over the application deployment intentions/sizing.

## Recommendations

Given that there is no AFP wide monitoring solution into which OCP could be integrated, we recommend enabling ACM Observability.

## Futures

Once sizing is more accuratly nailed down, adjust data retention as required.

[]

The default monitoring stack can be replaced with a custom monitoring stack using established upstream components (Prometheus agent etc ). This allows for much finer-grained configuration but comes at the cost of increased complexity.

[https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.16/html-single/observability/index#obs-mcoa-intro]

## Alternatives

- Build a separate Prometheus/Grafana monitoring stack.
- Utilise another monitoring tool, such as Zabbix
