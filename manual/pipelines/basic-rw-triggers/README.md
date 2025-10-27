# Triiger templates

[https://upstreamwithoutapaddle.com/tutorials/tekton-triggers-basics/]

## Trigger with curl

`curl --location --request POST https://el-basic-rw-trigger-listener-route-test.apps.disc.spenscot.ddns.net --header 'Content-Type: application/json' --data-raw '{"file":"bollocks.txt","text_string":"run from a trigger again"}'`

## PR pruning

Cluster wide

```yaml
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonConfig
metadata:
  name: config
spec:
  pruner:
    Resources:  # The resource types to which the pruner applies
      - taskrun 
      - pipelinerun
    keep: 5 #The number of recent resources  to keep
    schedule: "*/3 * * * *"
```

At the namespace

```yaml
kind: Namespace
apiVersion: v1
#...
spec:
 annotations:
   operator.tekton.dev/prune.resources: "taskrun, pipelinerun"
   operator.tekton.dev/prune.keep: "2"
```

## ADO webhooks

[https://learn.microsoft.com/en-us/azure/devops/service-hooks/services/webhooks?view=azure-devops]
