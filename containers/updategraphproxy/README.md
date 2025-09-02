# OpenShift API Proxy

## Description

Simple python program using Flask to proxy API requests from the ClusterVersion operator to api.openshift.com via an upstream proxy server.

This is only half the problem though as when an update is triggered, the ClusterVersion operator also needs to be able to validate the signatures of the release. See "releasesigsproxy".

## Usage

Build the container and then apply the manifests to create the deployment, service and route

## Configure the cluster

`oc patch clusterversion version --type merge -p '{"spec":{"upstream":"https://updategraphproxy-test.apps.disc.spenscot.ddns.net/api/upgrades_info/v1/graph"}}'`

## Test implementation

Proxy is running in the Harbor VM. The updategraphproxy deployment is configured with this squid proxy (http://192.168.124.10:3128) as the proxy, and the cluster is configured to connect yhe clusteversion to the route of the updategraphproxy pod.
