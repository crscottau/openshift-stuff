# OpenShift API Proxy

## Description

Simple python program using Flask to proxy requests to api.openshift.com via an upstream proxy server

## Usage

Build the container and then apply the manifests to create the deployment, service and route

## Configure the cluster

`oc patch clusterversion version --type merge -p '{"spec":{"upstream":"https://updategraphproxy-test.apps.disc.spenscot.ddns.net/api/upgrades_info/v1/graph"}}'`
