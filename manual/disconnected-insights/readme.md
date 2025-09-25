# Disconnected insights

The ACIC has 2 management clusters that are allowed to access certain external URLs via a proxy. These clusters are able to access the internet URL(s) to determine the available update paths are displayed in the UI as they would be for a fully online cluster. The issue is with the other (workload) clusters that are not allowed to access the internet at all. They want to be able to see the available updates in the UI in the same fashion as they see them for the management clusters, however they do not want the administrative burden of having to buld (and regularly rebuild) a local graph container to be used by the OpenShift Update Server operator.

There are 2 domains and a number of URLs:

The graph API is at:
[https://api.openshift.com/api/upgrades_info/v1/graph?arch=amd64&channel=stable-4.17]

This can be hacked by using an nginx or haproxy container that would run in the management clusters that would accept the URL request from the OpenShift clusters and forward the request to api.openshift.com. This haproxy/nginx instance would forward the request from the management cluster to api.openshift.com and then return the results to the workload clusters.

I am not sure if this actually works though, in my initial test - it looked like the it also needed to access the insights URLs (as shown in the configmap).

## nginx config

```bash
# cat /etc/nginx/conf.d/api.conf 
server {
  listen        8008;
  server_name   _;

  location / {
    proxy_http_version 1.1;
    proxy_ssl_name api.openshift.com;
    proxy_ssl_server_name on;
    proxy_pass https://api.openshift.com;
  }

  access_log /var/log/nginx/api.log;
  error_log /var/log/nginx/api.log;
}
```
