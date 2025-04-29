# Quay Organisation Mirror

The Quay mirroring feature is currently only configurable at the repository level; there is no organisation/namespace mirroring capability. This is an issue as the number of repsoitories that need to be mirrored in the ACIC is dynamic. Using the default mirror capability would mean manually configuring mirroring everytime a new repository is created for a new application.

The interim solution to this is to regularly run a job in the PDC OpenShift cluster to mirror the repositories from the primary Quay (SDC) to the stanby Quay (PDC). There will be one job per organisation to be mirrored. The organisations to mirror are:
- internal-registry-redhat-io
- internal-docker-io
- internal-acic-images
- internal-developer-sandpit

>[!NOTE]
>Maybe not the last one??

A future release of Quay is likely to include the capability to mirror organisations. Once that has been implemented and tested this interim process can be retired.

For more information see the [Interim Quay Organisation Mirroring](http://pvsasp14.crimtracagency.corporate:9081/display/ESES/Quay%3A+Mirroring+Internal+Organisations) Confluence page.

## Prerequisites

### OAuth Token

Each organisation to be mirrored in both the source and destination registries will need an OAuth Application created and a Token that the API can use to authenticate to the cluster. An API application token belongs to a user and so should be generated under a service account. Note that while the token can be generated on behalf of another user by an admin user, the assigned user still needs to login to accept and retrieve the token value. An OAuth Application token has a 10 year lifespan.

Generate a token from the Organisation page under **Applications**. Click the **Create New Application** button and enter a descriptive name for the application, eg: `quay-mirror-cronjob`.  Then click on the new application name and navigate to **Generate Token**. Enter the required permissions:

- If you are generating a token on the active Quay instance on SDC, the required permission will be **View all visible repositories**.
- If you are generating a token on the standby Quay instance on PDC, the required permissions will be **Administer Repositories and Create Repositories**.

You can ignore the warning about the OAuth redirect. Click **Generate Access Token** and authorise the application (if prompted). 

Once generated, copy the token and save it in the key database as it cannot be retrieved again.

### Robot Account

The destination organisation where the mirror repositories are set up also requires a robot account with Write permissions to be included in the repository mirroring configuration.

To create a Robot account in the mirrored organisation, navigate to the **Robots** page and click **Create Robot Account**.Create a new Robot account with a meaningful name, eg: `quay_mirror_robot` and assign **Write** permissions to any existing repositories. The robot account will also need Write access granted to new Repositories via the Default Permissions page.

### Quay Service Account

The credentials for the Quay service account are required to setup the mirror configuration on the destination repositories.

## Deployment

To deploy the resources on the PDC cluster to run the quay mirror configuration jobs you will need to:
1. (First time only) Create the namespace: `oc create ns acic-quay-org-mirror`
2. (If it does not exist or is out of date) Create the `quay-credentials` Secret, see details below
3. Create or update the `quay-source-api-tokens` Secret for each organisation being mirrored, see details below
4. Create or update the `quay-destination-api-tokens` Secret for each organisation being mirrored, see details below
5. Update the `quay-robot-name` for each organisation being mirrored, see details below
6. Apply/create the resources in the cluster, this can be done one of two ways:
   1. (Preferred) Using the `acic-quay-org-mirror` ArgoCD application (see below for setup details), or
   2. Manually apply the contents of this repository: `oc -n acic-quay-org-mirror apply -k .`

### Creating the `quay-credentials` Secret

Create the `quay-credentials` Secret in the `acic-quay-org-mirror` namespace where the mirror configurations jobs will be run:
```bash
oc -n acic-quay-org-mirror create secret generic quay-credentials \
--from-literal=quay_username=<quay_service_account_name> 
--from-literal=quay_password=<quay_service_account_password>
```

where:

<quay_service_account_name> is the name of the service account used by OpenShift to pull images from the source Quay on SDC

<quay_service_account_password> is the password of that service account

### Creating the source `quay-source-api-tokens` Secret

The job to setup mirroring requires an API token entry in the `quay-source-api-tokens` Secret for each organisation to be mirrored that contains the API token on the source Quay on SDC hub cluster.

For the first organisation, create the Secret in the acic-quay-org-mirror namespace where the mirror configurations jobs will be run.

```bash
oc -n acic-quay-org-mirror create secret generic quay-source-api-tokens \
--from-literal=<organisation_name>=<api_token_value>
```

where:

<organisation_name> is the name of the organisation to be mirrored on the source Quay registry on PDC

<api_token_value> is the API token from the source Quay registry on the SDC hub cluster.

For each subsequent organisation to mirror, update the `quay-source-api-tokens` Secret in the `acic-quay-org-mirror` namespace where the mirror configurations jobs will be run. The secret can be updated either in the GUI by clicking **Actions > Edit Secret**, or by using the `oc patch` command from the CLI:

```bash
oc -n acic-quay-org-mirror patch secret quay-source-api-tokens \
-p '{"stringData": {"<organisation_name>": "<api_token_value>"}}'
```

where:

<organisation_name> is the name of the organisation to be mirrored on the source Quay registry on PDC

<api_token_value> is the API token from the source Quay registry on the SDC hub cluster.

For each subsequent organisation to mirror, update the `quay-destination-api-tokens` Secret in the `acic-quay-org-mirror` namespace where the mirror configurations jobs will be run. The secret can be updated either in the GUI by clicking **Actions > Edit Secret**, or by using the `oc patch` command from the CLI as shown above.

### Creating the destination `quay-source-api-tokens` Secret

The job to setup mirroring requires an API token entry in the quay-destination-api-tokens Secret for each organisation to be mirrored that contains the API token on the source Quay on SDC hub cluster.

For the first organisation, create the Secret in the acic-quay-org-mirror namespace where the mirror configurations jobs will be run.

```bash
oc -n acic-quay-org-mirror create secret generic quay-destination-api-tokens \
--from-literal=<organisation_name>=<api_token_value>
```
where:
<organisation_name> is the name of the organisation to be mirrored
<api_token_value> is the API token from the organisation on the destination Quay registry on PDC
<robot_name> is the name of the robot account on the destination organisation on the Quay registry on PDC

## Setting up the jobs

### Setting up the `acic-quay-org-mirror` ArgoCD application

1. Create the `gitlab-image-transfer-repo` Secret so ArgoCD can access the repository:

    ```shell
    oc -n openshift-gitops create secret generic gitlab-quay-registry-mirror-repo \
            --from-literal=username=<DEPLOY_KEY_USERNAME> --from-literal=password=<DEPLOY_TOKEN> \
            --from-literal=url=https://pifmm-vsp-pms01.mgmt.cicz.gov.au/openshiftclusterconfigurations/quay-organisation-mirror.git \
            --from-literal=type=git
    ```

2. Label the ArgoCD Secret:
    ```shell
    oc -n openshift-gitops label secret  gitlab-quay-registry-mirror-repo argocd.argoproj.io/secret-type=repository
    ```

3. Apply/create the `acic-quay-org-mirror` ArgoCD application:

    ```shell
    oc apply -f acic-quay-org-mirror-application.yaml
    ```

4. Login to the ArgoCD User interface and 'Sync' the application.

## Hand Commands

### kustomize commands

```shell
# Apply the 'internal-registry-redhat-io' resources
oc apply -k ./overlays/internal-registry-redhat-io/

# Delete from a cluster
oc delete -k ./overlays/internal-registry-redhat-io/
```

## Mirroring configuration job parameters

The generated CronJob for each organisation has the following parameters passed in the `quay-mirror-config` ConfigMap that can be configured/changed if required:

- `SOURCE_REGISTRY=quay-image-registry.apps.hub-sdc.mgmt.cicz.gov.au`: the name of source registry
- `DESTINATION_REGISTRY=quay-image-registry.apps.hub-pdc.mgmt.cicz.gov.au`: the name of destination registry
- `TAG_GLOB='[ "*" ]'`: the regex to select the tags to be mirrored
- `SYNC_INTERVAL=600`: how often to run the synchronisation (in seconds)
- `DRY_RUN=false`: If true, do not make any changes
- `DEBUG=false`: If true, enables debug logging
- `RECREATE_MIRROR_CONFIG=false`: If true, recreates the existing mirror config. This would be useful if `<quay_service_account_password>` needs to be updated.

The ConfigMap is configured in the `base/kustomization.yaml` file.


