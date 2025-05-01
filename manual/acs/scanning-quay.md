# Scanning images in Quay

## ACS

It's all a bit confusing.

<https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/4.7/html/integrating/integrate-with-image-vulnerability-scanners#integrate-with-qcr-scanner_integrate-with-image-vulnerability-scanners>

Looking at the ACS documentation it states:

"You can integrate Red Hat Advanced Cluster Security for Kubernetes with Quay Container Registry for scanning images."

That seems to suggest that ACS can scan images in Quay.

I tried to setup quay.io integrations of type "Registry+Scanner" following those instructions, it is not entirely clear to me what the endpoint should be.

The dialogue asks for an OAuth token. In Quay, an OAuth token belongs to an organisation/namespace. But if I put in the endpoint from the browser, the test works, but the **System Health > Image Integration** section reports errors like:

`scanning "quay-image-registry.apps.hub-sdc.mgmt.cicz.gov.au/internal-developer-sandpit/sinper/cve-2025-29927:latest" with scanner "Internal-registry-redhat-io": invalid character '<' looking for beginning of value`

I have tried various permutations including the API endpoint of the organisation/namespace but none of them pass the test.

If I put in the URL of Quay itself, again the test passes but the **System Health > Image Integration** section reports errors:

`scanning "quay-image-registry.apps.hub-sdc.mgmt.cicz.gov.au/internal-developer-sandpit/sinper/cve-2025-29927:latest" with scanner "internal-registry-redhat-io-2": unexpected status code 404 when retrieving image scan for {id:"sha256:fe66d277b37f24664cb25389c6205ae941d0339577b93550104c01ba97058abe" name:{registry:"quay-image-registry.apps.hub-sdc.mgmt.cicz.gov.au" remote:"internal-developer-sandpit/sinper/cve-2025-29927" tag:"latest" full_name ...` 

... continues with a full dump of all the image layers and a whole bunch of CVE data in (invalid) JSON format (132KB of data)

I also created an integration of type "Red Hat" pointing to the Quay Route and specifying the username/password as specified in the cluster pull secret. This tests ok, and does nto report errors in **System Health**. But what does it actually do? If it is scanning Quay, where do you go to see the scan results?

## Clair

So, moving on to Clair

I can enable Clair and the database in the Quay registry instance. the DB gets created and the Clair pods appear. They report lots of stuff in their logs that indicate:

1. The Clair database can not be updated not surprisingly

`{"level":"error","component":"libvuln/updates/Manager.Run","error":"Get \"https://osv-vulnerabilities.storage.googleapis.com/ecosystems.txt\": EOF","time":"2025-05-01T06:08:52Z","message":"failed constructing factory, excluding from run"}`

The documentation seems to suggest you have to have a Clair instance in a connected environment in order to extract the updates from that so they can be imported into disconnected environment???

Also: what does the following statement mean:

`Currently, Clair enrichment data is CVSS data. Enrichment data is currently unsupported in disconnected environments.`

https://docs.redhat.com/en/documentation/red_hat_quay/3.14/html-single/red_hat_quay_operator_features/index#clair-disconnected-environments

2. 404 errors 

```JSON
{"level":"info","manifest":"sha256:ed54e53134f610dc76181765ebbb6a744acff4465d47e7863b10957eb073fe57","request_id":"d0c4f02ad2dac3d0","component":"indexer/controller/Controller.Index","state":"CheckManifest","time":"2025-05-01T06:08:55Z","message":"manifest to be scanned"}
{"level":"info","request_id":"d0c4f02ad2dac3d0","component":"indexer/controller/Controller.Index","manifest":"sha256:ed54e53134f610dc76181765ebbb6a744acff4465d47e7863b10957eb073fe57","state":"FetchLayers","time":"2025-05-01T06:08:55Z","message":"layers fetch start"}
{"level":"warn","request_id":"d0c4f02ad2dac3d0","component":"indexer/controller/Controller.Index","manifest":"sha256:ed54e53134f610dc76181765ebbb6a744acff4465d47e7863b10957eb073fe57","state":"FetchLayers","error":"fetcher: encountered errors: error realizing layer sha256:3059f6068401e6b82194cb486bf75573bd18356796e1010a73d575704723cc31: unexpected status code: 404 Not Found (body starts: \"<?xml version=\\\"1.0\\\" encoding=\\\"UTF-8\\\"?>\\n<Error><Code>NoSuchKey</Code><Message>The specified key does not exist.</Message><Resource>/acic-openshift-quay-pdc-s3/datastorage/registry/sha256/30/3059f6068401e6b82194cb486bf75573bd18356796e1010a73d575704723cc31?X-\")","time":"2025-05-01T06:08:55Z","message":"layers fetch failure"}
```

And then where do the results of the scans appear?
