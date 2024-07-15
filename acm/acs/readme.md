# Stuff

## Generate and retrieve an API token

```
STACKROX_API_TOKEN=$(curl -sk -u "admin:`oc get -n rhacs-operator secret central-htpasswd -oyaml | grep "password" | awk '{print $2}' | base64 -d`" "https://`oc get route -n rhacs-operator central -o jsonpath='{.spec.host}'`/v1/apitokens/generate" -d '{"name":"stackrox_api_token", "role": "Admin"}' | jq -r '.token')
```

## Ping

curl -k -H "Authorization: Bearer ${STACKROX_API_TOKEN}" https://`oc get route -n rhacs-operator central -o jsonpath='{.spec.host}'`:443/v1/ping

# Post a policy
        url: "https://{{ acs_host }}/v1/policies/import"
        headers:
          Authorization: "Bearer {{ acs_token }}"
        method: POST
        body_format: json
        body:
          metadata:
            overwrite: true
          policies: "{{ desired_policy_list }}"


curl -k -X POST -H "Authorization: Bearer ${STACKROX_API_TOKEN}" -H "Accept: application/json" --data '{"policies":[{"id":"1db27d37-2323-4577-8413-605c3bbb983c","name":"EgressFirewall change alert","description":"Alerts on modifications to the EgressFirewall in a project","rationale":"The EgressFirewall should not be modified. Any updates should be immediately flagged.","remediation":"","disabled":false,"categories":["Kubernetes"],"lifecycleStages":["RUNTIME"],"eventSource":"AUDIT_LOG_EVENT","exclusions":[],"scope":[],"severity":"HIGH_SEVERITY","enforcementActions":[],"notifiers":[],"lastUpdated":"2024-02-21T06:30:27.911302839Z","SORTName":"","SORTLifecycleStage":"","SORTEnforcement":false,"policyVersion":"1.1","policySections":[{"sectionName":"Policy Section 1","policyGroups":[{"fieldName":"Kubernetes Resource","booleanOperator":"OR","negate":false,"values":[{"value":"EGRESS_FIREWALLS"}]},{"fieldName":"Kubernetes API Verb","booleanOperator":"OR","negate":false,"values":[{"value":"UPDATE"},{"value":"DELETE"},{"value":"PATCH"},{"value":"GET"}]}]}],"mitreAttackVectors":[{"tactic":"TA0010","techniques":[]}],"criteriaLocked":false,"mitreVectorsLocked":false,"isDefault":false}]}'  https://`oc get route -n rhacs-operator central -o jsonpath='{.spec.host}'`:443/v1/policies/import 


