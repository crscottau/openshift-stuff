# acs-failover

Cronjob that runs 1 or more containers to:

1. Identify and download the latest ACS database backup (s3cmd)
2. Initiate a velero restore of the latest TLS backups (oc)
3. Generate an ACS token for roxctl using the secret password (oc)
4. Restore the database  (roxctl)

Suggests 4 containers and 1 PVC volume `data`

## restore-tls

image: ose-cli

configmap: restore.yaml

volumeMount: /data

Apply the velero restore YAML

Loop waiting on the restore to succeed

## generate-token

image: ose-cli

volumeMount: /data

Extract the admin password from the secret

```bash
oc -n central get secret central-htpasswd -o jsonpath={.data.password} > 
```

>This step has to assume that the database has not ever been restored from SDC, if it has then the default admin password in the secret will be invalid. Maybe I need to allow for a token to be passed in and only try and generate one if it has not been passed in as an environment variable

Or maybe delete and recreate the database, which is annoying as we are using pre-allocated PV/PVCs

So it doesn't like the user:password when passed as a bearer token:

```bash
$ curl -k https://acs-central.apps.hub-pdc.mgmt.cicz.gov.au/v1/apitokens/generate -H "Authorization: Basic YWRtaW46Y0IyaEpRalBtbVBtUzFqT2ZqMWtWMVZJMwo="   {"code":16,"message":"credentials not found: basic: cannot extract identity: failed to identify user with username \"admin\"","details":[],"error":"credentials not found: basic: cannot extract identity: failed to identify user with username \"admin\""}[
```

Auth does work with the password, but the API is wrong (thanks CoPilot)

```bash
$ curl -k https://admin:cB2hJQjPmmPmS1jOfj1kV1VI3@acs-central.apps.hub-pdc.mgmt.cicz.gov.au/v1/apitokens/generate
{"code":3,"message":"token with id 'generate' does not exist: invalid arguments","details":[],"error":"token with id 'generate' does not exist: invalid arguments"}
```

## download-backup

image: s3cmd

volumeMount: /data

## restore database

>Depends on `generate-token` and `download-backup`

