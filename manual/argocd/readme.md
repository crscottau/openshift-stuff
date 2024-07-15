# ArgoCD

## CLI login (requires web browser)

argocd login openshift-gitops-server-openshift-gitops.apps.5h5xv.dynamic.redhatworkshops.io:443 --sso
argocd login application-gitops-server-application-gitops.apps.fhfb4.dynamic.redhatworkshops.io:443 --sso
argocd proj list

## projects

Every application has to belong to a project.

There is a _default_ project.

A project is a container or grouping of 0 or more applications.

A project == a group

A project is a CRD **appproject**

Restricting applications using projects in 3 different ways:

1. sourceRepos:

    - allow list repositories for a project
    - deny list repositories for a project (prefix !)
    - wildcards can be used, ie: '*' to use all repositories except those in the deny list

    ```
    !https://gitbub.com/bad/repo.git
    '*'
    ```

2. destinations:

    - namespace:
    - server:

        eg: (https://kubernetes.default.svc)

    Can include or exclude namespaces and/or servers
    servers == api URL?
    wildcards can be used

3. clusterResourceWhiteList:

     - group:
       kind:

   namespaceResourceWhitelist:

     - group:
       kind:

    Allow based on resource API name and kind.  Either cluster or namespaced resources.

    There are also cluster and namespace scope deny (black) lists.

## Roles and policies

Projects can have mulitple roles

Roles can have different access granted

Permissions are called policies and are stored within the role

A role policy can only grant access to that role

Policies can have granted wildcard access to apply to all applications in a project.

Roles can have a generated token that can access an external system, ie: GitLab

