# ACM failover test

## Test clusters on RHPD

Primary:	h7f4d	https://console-openshift-console.apps.cluster-jdvjb.dyn.redhatworkshops.io
Standby:	8g2wm	https://console-openshift-console.apps.cluster-p9228.dyn.redhatworkshops.io
workload1:	k7l52	https://console-openshift-console.apps.cluster-5wk55.dyn.redhatworkshops.io

## Install steps

### Operators

On the primary and standby, install:

- ACM Operator
- ACS Operator
- OpenShift GitOps
- Web Terminal

On the workload cluster, install:

- ACS Operator
- Web Terminal

### Instances

On the primary and standby, create a MultiClusterHub

```yaml
apiVersion: operator.open-cluster-management.io/v1
kind: MultiClusterHub
metadata:
  name: multiclusterhub
  namespace: open-cluster-management
spec:
  availabilityConfig: High
  localClusterName: local-cluster
  overrides:
    components:
      - configOverrides: {}
        enabled: true
        name: app-lifecycle
      - configOverrides: {}
        enabled: true
        name: cluster-lifecycle
      - configOverrides: {}
        enabled: true
        name: console
      - configOverrides: {}
        enabled: true
        name: grc
      - configOverrides: {}
        enabled: true
        name: insights
      - configOverrides: {}
        enabled: true
        name: multicluster-engine
      - configOverrides: {}
        enabled: true
        name: multicluster-observability
      - configOverrides: {}
        enabled: true
        name: search
      - configOverrides: {}
        enabled: true
        name: submariner-addon
      - configOverrides: {}
        enabled: true
        name: volsync
      - configOverrides: {}
        enabled: true
        name: cluster-backup
      - configOverrides: {}
        enabled: false
        name: fine-grained-rbac
      - configOverrides: {}
        enabled: false
        name: siteconfig
      - configOverrides: {}
        enabled: false
        name: cnv-mtv-integrations
```

### Configuration

### Workload cluster

resources to create the ArgoCD repo

```yaml
kind: Namespace
apiVersion: v1
metadata:
  name: cluster-config-gitops
```

```yaml
kind: ServiceAccount
apiVersion: v1
metadata:
  name: cluster-config-gitops-sa
  namespace: cluster-config-gitops
```

```yaml
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cluster-config-gitops-cluster-admin
subjects:
  - kind: ServiceAccount
    name: cluster-config-gitops-sa
    namespace: cluster-config-gitops
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: cluster-config-gitops-token
  namespace: cluster-config-gitops
  annotations:
    kubernetes.io/service-account.name: cluster-config-gitops-sa
type: kubernetes.io/service-account-token
```

### Standby cluster

Create the banner application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: banner
  namespace: openshift-gitops
spec:
  destination:
    namespace: openshift-gitops
    server: https://kubernetes.default.svc
  project: default
  source:
    path: test-banner/standby
    repoURL: https://github.com/crscottau/openshift-stuff.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      enabled: true
      prune: false
      selfHeal: true
```

### Primary cluster

Create the banner application

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: banner
  namespace: openshift-gitops
spec:
  destination:
    namespace: openshift-gitops
    server: https://kubernetes.default.svc
  project: default
  source:
    path: test-banner/primary
    repoURL: https://github.com/crscottau/openshift-stuff.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      enabled: true
      prune: false
      selfHeal: true
```

#### Primary and standby cluster

Create the workload cluster secret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: workload1-cluster
  namespace: openshift-gitops
stringData:
  config: |
    {
      "bearerToken": "<TOKEN-FROM-SA-SECRET>",
      "tlsClientConfig": {
      "insecure": false,
      "caData": "<BASE64_CA_CERT-FROM-SA-SECRET>"	
	}
  name: workload1
  server: <workload-cluster-5wk55api-endpoint>

type: Opaque
```

Create the following applications:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: acm-acs-securedcluster-policy
  namespace: openshift-gitops
spec:
  destination:
    namespace: openshift-operators
    server: https://kubernetes.default.svc
  project: default
  source:
    path: acm-acs-securedcluster-policy
    repoURL: https://github.com/crscottau/ocp-gitops.git
    targetRevision: HEAD
  syncPolicy:
    automated: {}
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: workload-banner
  namespace: openshift-gitops
spec:
  destination:
    namespace: cs-test
    server: https://api.cluster-5wk55.dyn.redhatworkshops.io:6443
  project: default
  source:
    path: test-banner/workload
    repoURL: https://github.com/crscottau/openshift-stuff.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      enabled: true
      prune: false
      selfHeal: true
    syncOptions:
    - CreateNamespace=true	  
```

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: workload-httpd
  namespace: openshift-gitops
spec:
  destination:
    namespace: cs-test
    server: https://api.cluster-5wk55.dyn.redhatworkshops.io:6443
  project: default
  source:
    path: apps/httpd-deployment/base
    repoURL: https://github.com/crscottau/openshift-stuff.git
    targetRevision: HEAD
  syncPolicy:
    automated:
      enabled: true
      prune: false
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

## Import cluster

Import the workload cluster(s) into ACM
