# cert-manager

## Generate CA key and certificate

```bash
openssl genrsa -out rootCA2.key 2048
openssl req -x509 -new -nodes -key rootCA.key -sha256 -days 30 -subj "/CN=vqmpz.dynamic.redhatworkshops.io/" -out rootCA.pem
```

Convert to p12 for Windows

`openssl pkcs12 -export -inkey rootCA.key -in rootCA.pem -ut rootCA.p12`

## CA secret

`oc -n cert-manager-operator create secret tls ca-root-secret --key=rootCA.key --cert=rootCA.pem`

## To Do

Remove common name from certificates, in both overlays and base

Need to overlay the spec.servingCerts.namedCertificates.[names] field to API URI

Remove :6443 from dnsNames
