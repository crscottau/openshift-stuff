# Keycloak

[https://docs.redhat.com/en/documentation/red_hat_build_of_keycloak/24.0/html/operator_guide/basic-deployment-#basic-deployment-performing-a-basic-red-hat-build-of-keycloak-deployment]

## Install the operator in the target namesapce

```bash
oc apply -f keycloak-test-ns.yaml
oc apply -f rhbk-operator-og.yaml
oc apply -f rhbk-operator-sub.yaml
```

## Create an instance

Create the database, see `../cnpg/keyclock`

Create the keycloak key and certificate pair, ideally using cert-manager

```bash
oc apply -f keycloak-test-certificate.yaml
```

Create the instance

```bash
oc apply -f keycloak.yaml
```
