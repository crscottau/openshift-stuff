# Keycloak to AD

https://www.dell.com/community/en/conversations/developer-blog/openshift-sso-with-keycloak-active-directory/647f9e39f4ccf8a8de2cc1ae




## Retreive the keycloak cert

`echo | openssl s_client -showcerts -connect keycloak-keycloak.apps.ocp4.spenscot.ddns.net:443 2>&1 | sed --quiet '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > keycloak.crt`

This is the certificate I used for my cert-manager ca-issuer

## IDP

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: custom-ca-keycloak
  namespace: openshift-config
data:
  ca.crt: |
    -----BEGIN CERTIFICATE-----
    MIIDMzCCAhugAwIBAgIUHg4S6QcVPYav815xeJTVHZaxTyEwDQYJKoZIhvcNAQEL
    BQAwKTEaMBgGA1UEAwwRc3BlbnNjb3QuZGRucy5uZXQxCzAJBgNVBAYTAkFVMB4X
    DTI0MDUwNjIyMTYwOFoXDTI1MDQyNzIyMTYwOFowKTEaMBgGA1UEAwwRc3BlbnNj
    b3QuZGRucy5uZXQxCzAJBgNVBAYTAkFVMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8A
    MIIBCgKCAQEAwS8Z2RHoGKWyd6sOakNvBkSr6+7a4oOhaPOBecKwYEaONEZA9h3C
    wN556puwkyicd6JrMxLcmTvgpjwdABcN6INY7LjejQ16CoMEUBquKizn42rNDn8C
    qyZ9P8x/n7MrxG6Dzviiz9QczmVKmHiAp0Ehl1B/LpQnagCFocAl5/LAq+FmN//n
    hiYulH7exOJwTCE/j+jTJ5lFAF8e/waeQ1krPi2xls9Jysfd/vzaWc57c/xtYQHz
    1YFJ6MHx6kVJiFQWZqvmna1GC0uU/G+fPuijb21hB+F7weXk04JoRd19T76W8yV2
    1cNZT3DKBhaoHduXKUUrMEfEOT8m3U2lEQIDAQABo1MwUTAdBgNVHQ4EFgQUI0Gz
    +FxVZVfO6XK4JMFGD6MLFqUwHwYDVR0jBBgwFoAUI0Gz+FxVZVfO6XK4JMFGD6ML
    FqUwDwYDVR0TAQH/BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEATjzOctqxviZK
    4k7iX461J2dljIVoDKWfrkHLfsD2xCMn8JxvoI+SeUFSgSBYwBtKN2zynAneMbt0
    Op+Q2eiBZT+3nKba9Nl9nUnYZHAu6QOSyciaYLC+RUBbgk8TLsoBT/QmmBpD3uqz
    sECHnsXtLtlgrt99fw8CYiH1+04oc2jGXgwVwBnMlEQPLnN/t2rmE/Z+1O4fUfID
    Siqx9VuWHUKwHyiZCYq4p3hPesMwC40SH5UXUi2lhplwA5CGYnkkj4Av1PgAsvct
    qqNkGfS6fFGuOMe5F6UdgyEJvAzQNH7Pk06c6C1jAxYRxi1rLHldyVI9q2peB4ph
    9eXgl/RaXQ==
    -----END CERTIFICATE-----
    -----BEGIN CERTIFICATE-----
    MIIC5DCCAcygAwIBAgIQN6s7dZC+9UNzuYR23VaXpTANBgkqhkiG9w0BAQsFADAp
    MRowGAYDVQQDDBFzcGVuc2NvdC5kZG5zLm5ldDELMAkGA1UEBhMCQVUwHhcNMjQx
    MjIzMDI1NjMxWhcNMjUwMzIzMDI1NjMxWjAoMSYwJAYDVQQDDB0qLmFwcHMub2Nw
    NC5zcGVuc2NvdC5kZG5zLm5ldDBZMBMGByqGSM49AgEGCCqGSM49AwEHA0IABJSG
    iqhr6NLuvcODNQemZ2gpBKt25/Tg/HCOawufMGBdf5/zMGuUjF8Nvru8iFjaYiUk
    BrYhKURym9JIPBmogx+jgdMwgdAwDgYDVR0PAQH/BAQDAgWgMAwGA1UdEwEB/wQC
    MAAwHwYDVR0jBBgwFoAUI0Gz+FxVZVfO6XK4JMFGD6MLFqUwgY4GA1UdEQSBhjCB
    g4IdKi5hcHBzLm9jcDQuc3BlbnNjb3QuZGRucy5uZXSCNWNvbnNvbGUtb3BlbnNo
    aWZ0LWNvbnNvbGUuYXBwcy5vY3A0LnNwZW5zY290LmRkbnMubmV0gitvYXV0aC1v
    cGVuc2hpZnQuYXBwcy5vY3A0LnNwZW5zY290LmRkbnMubmV0MA0GCSqGSIb3DQEB
    CwUAA4IBAQApnwPahGLhceLncGrPIeKsh60w+brKy6JHflyX7tl1ujgjgRnqAk4X
    jLsU0Z4B+k6ZG9Lg5iGOdo4/NAjtaKs4rLUMOR5KZywYvuHJtQbPKXefDJIhUTSb
    +DNmTtmYgpZjtMe69vM4mSIQcm79SQPqiJP7PFh1e5MZH2ZIl7VvkDYimkeXGu9F
    cDKkc0Edri7e98+2syk7YDdMSwojM0T1lJcW611Bs0bkSa4dv4T8IfnxEKioVqM3
    IX7ri4HaGT3EJ9d90WRhpNlnQFZ5v0fGH7YUXkE25tErqlRH66DCplK82uLXjALD
    5k5WSVOTjid6PE1fIYtfUeQe3w13Uwdo
    -----END CERTIFICATE-----
```  

```yaml
    - mappingMethod: claim
      name: keycloak
      openID:
        ca:
          name: custom-ca-keycloak
        claims:
          email:
            - email
          name:
            - name
          preferredUsername:
            - preferred_username
        clientID: mylab-local
        clientSecret:
          name: openid-client-secret-7tvw9
        extraScopes: []
        issuer: 'https://keycloak.apps.ocp4.spenscot.ddns.net/realms/mylab'
      type: OpenID
```
