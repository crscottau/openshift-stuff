#!/bin/bash

TYPES=("openshift-apiserver" "kube-apiserver" "oauth-apiserver" "oauth-server")
NODES=$(oc get nodes --no-headers|awk '/control-plane/ {print $1}')

for TYPE in ${TYPES[@]}
do
  rm -f ${TYPE}-audit.log
done


for NODE in ${NODES}
do
  echo ${NODE}
  for TYPE in ${TYPES[@]}
  do
    oc adm node-logs ${NODE} --path=${TYPE}/audit.log >> ${TYPE}-audit.log
  done
done
