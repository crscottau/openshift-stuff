Ref: https://www.redhat.com/en/blog/backup-openshift-applications-using-the-openshift-api-for-data-protection-with-multicloud-object-gateway

oc apply -f oadp-test-app.yaml

oc create secret generic craig-cloud-credentials -n openshift-adp --from-file cloud=credentials-velero

oc apply -f dpa.yaml

oc get BackupStorageLocations -n openshift-adp

oc apply -f backup.yaml

oc get backup -n openshift-adp craig-backup-test -o jsonpath='{.status.phase}'
