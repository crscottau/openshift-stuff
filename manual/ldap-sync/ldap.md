# LDAP sync

## 01-ldap-sync-sa-cr-crb.yaml

---
kind: ServiceAccount
apiVersion: v1
metadata:
  name: ldap-group-syncer
  namespace: ldap-sync
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: ldap-group-syncer
rules:
  - apiGroups:
      - ''
      - user.openshift.io
    resources:
      - groups
    verbs:
      - get
      - list
      - create
      - update
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: ldap-group-syncer
subjects:
  - kind: ServiceAccount
    name: ldap-group-syncer              
    namespace: ldap-sync
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ldap-group-syncer                
---

## 01-ldap-group-syncer-cm.yaml

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: ldap-group-syncer
  namespace: ldap-sync
data:
  sync.yaml: |  
    kind: LDAPSyncConfig
    apiVersion: v1
    url: ldaps://ldap.domain.com:636
    bindDN: "CN=svc-openshift-ldap,DC=domain,DC=au"
    bindPassword:
      file: "/etc/secrets/bindPassword"
    ca: /etc/ldap-ca/ca.crt
    groupUIDNameMapping:
      "CN=sysadmins,DC=domain,DC=au": admins
    augmentedActiveDirectory:
      groupsQuery:
        derefAliases: never
        pageSize: 0
      groupUIDAttribute: dn
      groupNameAttributes: [ cn ]
      usersQuery:
        baseDN: "DC=domain,DC=au"
        scope: sub
        derefAliases: never
        filter: (objectclass=person)
        pageSize: 0
      userNameAttributes: [ sAMAccountName ]
      groupMembershipAttributes: [ "memberOf:1.2.840.113556.1.4.1941:" ] 

## 03-ldap-groups-config-map.yaml

---
kind: ConfigMap
apiVersion: v1
metadata:
  name: ldap-groups-config-map
  namespace: ldap-sync
data:
  groups.txt: | 
    CN=sysadmins,DC=domain,DC=au

## 10-ldap-group-syncer-cronjob.yaml

---
kind: CronJob
apiVersion: batch/v1
metadata:
  name: ldap-group-syncer
  namespace: ldap-sync
spec:                                                                                
  # At minute 1 and 31 of every hour to avoid congestion with common cron scheules
  schedule: "1,31 * * * *"                                                           
  concurrencyPolicy: Forbid
  jobTemplate:
    spec:
      backoffLimit: 0
      ttlSecondsAfterFinished: 1800                                                  
      template:
        spec:
          containers:
            - name: ldap-group-sync
              image: "registry.redhat.io/openshift4/ose-cli:latest"
              command:
                - "/bin/bash"
                - "-c"
                - "oc adm groups sync --whitelist=/etc/config/groups.txt --sync-config=/etc/config/sync.yaml --confirm" 
              volumeMounts:
                - mountPath: "/etc/config/sync.yaml"
                  name: "ldap-sync-volume"
                  subPath: sync.yaml
                - mountPath: "/etc/secrets"
                  name: "ldap-bind-password"
                - mountPath: "/etc/ldap-ca"
                  name: "ldap-ca"
                - mountPath: "/etc/config/groups.txt"
                  name: "ldap-groups"
                  subPath: groups.txt
          volumes:
            - name: "ldap-sync-volume"
              configMap:
                name: "ldap-group-syncer"
            - name: "ldap-bind-password"
              secret:
                secretName: "ldap-secret"                                           
            - name: "ldap-ca"
              configMap:
                name: "acic-ldap-ca"
            - name: "ldap-groups"
              configMap:
                name: "ldap-groups-config-map"    
          restartPolicy: "Never"
          terminationGracePeriodSeconds: 30
          activeDeadlineSeconds: 500
          dnsPolicy: "ClusterFirst"
          serviceAccountName: "ldap-group-syncer"

## Bind password secret

kind: Secret
apiVersion: v1
metadata:
  name: ldap-secret
  namespace: ldap-sync
data:
  bindPassword: 
type: Opaque