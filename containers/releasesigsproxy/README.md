# Release Signatures Proxy

## Description

The ClusterVersion operator makes API calls to api.openshift.com to build the update path, this can be via an API proxy container (see updategraphproxy).

When an update is triggered, the ClusterVersion operator needs to be able to validate the signatures of the release by downloading them from: 
[]

In a disconnected environment, the signatures for a given desired release can be manually built into a ConfigMap and applied to the cluster.

Alternatively, a proxy container can be used that talks to an upstream proxy to allow access to pull the signatures.

`ClusterVersion -> Local squid proxy container -> External squid proxy -> [https://mirror.openshift.com]`

or similarely:

`ClusterVersion -> Remote squid proxy container -> External squid proxy -> [https://mirror.openshift.com]`

The proxy container is currently limited to only proxy requests for [https://mirror.openshift.com].

## Usage

Build the container and then apply the manifests to create the deployment, service and route.

Add environment variables for the proxy URL plus any required authentication.

## Configure the cluster

Patch the ClusterVersion operator deployment with the proxy environment variables.

```yaml
            - name: HTTPS_PROXY
              value: 'http://releasesigsproxy.apps.<cluster>.<domain>:3128'
            - name: NO_PROXY
              value: <string>
```

## Test the container

`podman run -d -p 3128:3128 --name releasesigsproxy -e ALLOWED_ACLS="acl ocpdisc src 192.168.124.0/24" -e PROXY_HOST=192.168.124.10 -e PROXY_PORT=3128 -e PROXY_USER=me -e PROXY_PASSWORD=bollocks localhost/releasesigsproxy:0.1`

## Current status

The squid container works fine on RHEL10 on the 192.168.124.0/24 network:

`rhel10/curl -> rhel10/container:3128 -> harbor/squid:3128 -> https://mirror.openshift.com`

The squid container works fine when running on OCP when accessed via the service IP:

`coreos/curl -> OCP/service:3128 -> harbor/squid:3128 -> https://mirror.openshift.com`

However I get a 503 when accessing it via the route:

```text
curl -I -x http://releasesigsproxy-test.apps.disc.spenscot.ddns.net:80 https://mirror.openshift.com
HTTP/1.0 503 Service Unavailable
pragma: no-cache
cache-control: private, max-age=0, no-cache, no-store
content-type: text/html

curl: (56) Received HTTP code 503 from proxy after CONNECT
```

Looking at the docs:

The route is not admitted as squid is responding with a 400 to the HTTP HEAD request. The route does not appear to support the TCP CONNECT.

Therefore will either need to run squid externally to the clusters, or in the cluster with a MetalLB front end.





            - name: HTTPS_PROXY
              value: 'http://192.168.124.56:3128'
            - name: NO_PROXY
              value: .spenscot.ddns.net,.svc,192.168.124.0/24,10.128.0.0/14,172.30.0.0/16