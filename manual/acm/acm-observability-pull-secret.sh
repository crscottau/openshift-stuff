#!/bin/bash
# Need to copy the pull-secret from openshift-config to make a copy in the observability namespace
DOCKER_CONFIG_JSON=$(oc extract secret/pull-secret -n openshift-config --to=-)
oc create secret generic multiclusterhub-operator-pull-secret \
-n open-cluster-management-observability \
--from-literal=.dockerconfigjson="$DOCKER_CONFIG_JSON" \
--type=kubernetes.io/dockerconfigjson

