# Simple artifact signing using Tekton Chains

[https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/1.13/html/securing_openshift_pipelines/using-tekton-chains-for-openshift-pipelines-supply-chain-security]

Tekton will sign artifacts by default via Tekton Chains which is automatically installed with OpenShift Pipelines.

Install cosign

https://docs.sigstore.dev/cosign/system_config/installation/

To setup

1. Create a secret containing the public, private and private key password in OpenShift
`cosign generate-key-pair k8s://openshift-pipelines/signing-secrets`

2. Configure Tekton Chains

Not required.

Probably. In Tim's environment, Tekton was configured to emit signatures to tekton and need to have OCI added:

```yaml
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonConfig
metadata:
  name: config
spec:
  chain:
    artifacts.taskrun.storage: tekton
```

Whereas in mine, it was OCI by default:

```yaml
apiVersion: operator.tekton.dev/v1alpha1
kind: TektonConfig
metadata:
  name: config
spec:
  chain:
    artifacts.taskrun.storage: oci
```

3. Build the artifact using yhe pipeline

4. Verify

```json
$ cosign verify --key cosign.pub --insecure-ignore-tlog quay.io/crscott/pipelines-tutorial/pipelines-vote-api:latest|jq .
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the signature.

Verification for quay.io/crscott/pipelines-tutorial/pipelines-vote-api:latest --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
[
  {
    "critical": {
      "identity": {
        "docker-reference": "quay.io/crscott/pipelines-tutorial/pipelines-vote-api"
      },
      "image": {
        "docker-manifest-digest": "sha256:3576695cb75889c876e93c6a3af692d152c8a9db4928ddea922dacb254371754"
      },
      "type": "cosign container image signature"
    },
    "optional": null
  }
]
```

Can also skip TLS:

`cosign verify --key cosign.pub --insecure-ignore-tlog --allow-insecure-registry=true quay-registry-quay-quay.apps.pfnjv.dynamic.redhatworkshops.io/pipeline-tutorial/pipelines-vote-api:latest`

Verifying the attestation, includes a very long payload:

```json
$ cosign verify-attestation --key cosign.pub --insecure-ignore-tlog --type "https://slsa.dev/provenance/v0.2" quay.io/crscott/pipelines-tutorial/pipelines-vote-api:latest
WARNING: Skipping tlog verification is an insecure practice that lacks transparency and auditability verification for the attestation.

Verification for quay.io/crscott/pipelines-tutorial/pipelines-vote-api:latest --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
{
  "payloadType": "application/vnd.in-toto+json",
  "payload": "eyJfd...lfX19",
  "signatures": [
    {
      "keyid": "SHA256:itpcN/y7NN55LOBLLv7xewKr3kiPUcWIYSMGDnVTsy4",
      "sig": "MEUCIQDIxe2NMF7dieiUSTlc1j4dcBkz0vC1fgynu/FbxpEkuwIgQB1Zqk1Il5eGeAEphc7rmvPOjjU3KNP1LI/du16NsHw="
    }
  ]
}
```

The full kit:

[https://developers.redhat.com/products/trusted-artifact-signer/overview]

## skopeo copy

In order for skopeo copy to copy the signatures, need to make the following change:

```yaml
$ cat /etc/containers/registries.d/default.yaml
default-docker:
  use-sigstore-attachments: true
```
