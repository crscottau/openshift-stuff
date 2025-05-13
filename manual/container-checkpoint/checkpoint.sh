#!/bin/bash

TOKEN=$(oc whoami -t )
OPENSHIFT_API_URL=$(oc whoami --show-server)
NODE_SSH_KEY=/home/crscott/Documents/prog/openshift/agent-sno/ocp_sno_ed25519

# Variables that define the node, namespace, pod and container
NODE_NAME=single
NAMESPACE_NAME=test
POD_NAME=test
CONTAINER_NAME=test-shite

# Generate the container checkpoint
echo "Taking checkpoint"
CMD="curl -k -s -X POST --header \"Authorization: Bearer ${TOKEN}\" ${OPENSHIFT_API_URL}/api/v1/nodes/${NODE_NAME}/proxy/checkpoint/${NAMESPACE_NAME}/${POD_NAME}/${CONTAINER_NAME}"
CHECKPOINT=$(eval ${CMD}|jq -r .items[0])
echo ${CHECKPOINT}

# Extract the checkpoint, after updaing permissions
## Struggling to get the automatic extraction to work ATM
## Option 1 - start a oc debug node in the backgroup and use oc rsync to extract the image (prefixing it with /host)
## Option 2 - below. The core user doe snot have read access to the checkpoint directory
#NODE_IP=$(oc get node ${NODE_NAME} -o json|jq -r '.status.addresses[] | select(.type == "InternalIP") | .address')
#echo $NODE_IP
#ssh -i ${NODE_SSH_KEY} core@${NODE_IP} sudo chmod 644 ${CHECKPOINT}
#scp -i ${NODE_SSH_KEY} core@${NODE_IP}:${CHECKPOINT} .
#ls -l ./${CHECKPOINT}
