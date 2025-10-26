# Triiger templates

[https://upstreamwithoutapaddle.com/tutorials/tekton-triggers-basics/]



## Trigger with curl

`curl --location --request POST https://el-basic-rw-trigger-listener-route-test.apps.cly1fmmb.westus.aroapp.io --header 'Content-Type: application/json' --data-raw '{"file":"bollocks.txt","text_string":"run from a trigger again"}'`

## Results pruning

### Attempt 1

Tested, but does not appear to be working

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: tekton-results-config-results-retention-policy
  namespace: openshift-pipelines
data:
  defaultRetention: '5'
  runAt: '*/15 * * * *'
```

### Attempt 2

To be tested

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tekton-results-config-results-retention-policy
  namespace: tekton-results
data:
  policies: |
    - name: "prune-failed-in-test"
      selector:
        namespace: "test"
        status: "Failed"        
      maxRetention: "1d" # Retain for 1 day
    - name: "prune-success-in-test"
      selector:
        namespace: "test"
        status: "Succeeded"        
      maxRetention: "2d" # Retain for 2 days
    - name: "default-retention"
      maxRetention: "10d" # Default retention for 10 days
#    - name: "critical-pipelines-retention"
#      selector:
#        namespace: "production"
#        labels:
#          pipeline.tekton.dev/critical: "true"
#      maxRetention: "30d" # Retain for 1 year
#    - name: "failed-runs-short-retention"
#      selector:
#        status: "Failed"
#      maxRetention: "1d" # Retain failed runs for 30 days
#    - name: "default-retention"
#      maxRetention: "5d" # Default retention for 90 days
```

## ADO webhooks

[https://learn.microsoft.com/en-us/azure/devops/service-hooks/services/webhooks?view=azure-devops]
