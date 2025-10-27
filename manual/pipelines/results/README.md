# Tekton results

## CLI

### tkn

`tkn --namespace test pr list`

### opc

The `opc` tool is included in the archive with the `tkn` tool.

Create a pass through route:

```yaml
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: tekton-results-api-route
  namespace: openshift-pipelines
spec:
  port:
    targetPort: 8080
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: passthrough
  to:
    kind: Service
    name: tekton-results-api-service
    weight: 100
```

Then use `opc` to display results.

`opc results list test --addr tekton-results-api-route-openshift-pipelines.apps.disc.spenscot.ddns.net:443 --sa pipeline --insecure`

## Results pruning

Being tested

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tekton-results-config-results-retention-policy
  namespace: tekton-results
data:
  defaultRetention: '30d'
  policies: |
    - name: "prune-failed-in-test"
      selector:
        matchNamespaces: 
          - "test"
        matchStatuses: 
          - "Failed"        
      retention: "1d" # Retain for 1 day
    - name: "prune-success-in-test"
      selector:
        matchNamespaces: 
          - "test"
        matchStatuses: 
          - "Succeeded"        
      retention: "2d" # Retain for 1 day
  runAt: '0 */1 * * *'
```

[https://github.com/tektoncd/results/blob/6bbc309f684f12f7861da9d666cc04448965ee0a/docs/retention-policy-agent/README.md?plain=1#L4]
