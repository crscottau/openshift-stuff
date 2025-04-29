hub-cluster-gitops
-----

The files (and instructions) within this directory enable you to add a child OpenShift 
cluster configuration to the OpenShift (read 'cluster configuration') GitOps instance.

## Process

On the **hub cluster** that you want to use to manage the child cluster you will need to:

* Create the (ArgoCD) child cluster Secret
* Create the (ArgoCD) GitLab repository Secret 
* Apply the (ArgoCD) manifests within this directory

### Creating the (ArgoCD) child cluster Secret

For the hub cluster to be able to manage resources on the child cluster ArgoCD/OpenShift GitOps needs to have a 
Secret which contains the credentials of the service account to use for the child cluster.

1. On the **child cluster**, extract the credentials from the service account Secret with:
    ```shell
    SERVICE_ACCOUNT=$(oc -n cluster-config-gitops get secret openshift-hub-sa-token \
        -o "jsonpath={.data['ca\.crt']}") && \

    BEARER_TOKEN=$(oc -n cluster-config-gitops get secret openshift-hub-sa-token \
        -o "jsonpath={.data['token']}" | base64 -d) && \

    jq --arg bearerToken "$BEARER_TOKEN" --arg caData "$SERVICE_ACCOUNT" \
        '.bearerToken = $bearerToken | .tlsClientConfig.caData = $caData' \
        ./argo-cd-cluster-auth-template.json > /tmp/config
    ```

2. Switch context to the hub cluster: `oc config use-context <YOUR_HUB_CLUSTER_CONTEXT_NAME>`
3. On the **HUB cluster**, create the ArgoCD cluster Secret with:
    ```shell
    oc -n openshift-gitops create secret generic child-cluster-sa \
        --from-file=/tmp/config --from-literal=name=child-cluster \
        --from-literal=server=https://api.q82ls.dynamic.redhatworkshops.io:6443 && \

    oc -n openshift-gitops label secret child-cluster-sa argocd.argoproj.io/secret-type=cluster && \
    rm /tmp/config
    ```

### Creating the (ArgoCD) repository Secret

For the hub cluster to be able to retrieve the manifests (read yaml files) from GitLab ArgoCD/OpenShift GitOps 
needs to have a Secret which contains the credentials to use when pulling from the GitLab repository.

1. Create the secret:
    ```shell
    oc -n openshift-gitops create secret generic gitlab-child-config-repo \
        --from-literal=username=<DEPLOY_KEY_USERNAME> --from-literal=password=<DEPLOY_TOKEN> \
        --from-literal=url=<github> \
        --from-literal=type=git --from-literal=project=child
    ```
2. Label the secret:
    ```shell
    oc -n openshift-gitops label secret gitlab-child-config-repo argocd.argoproj.io/secret-type=repository
    ```

