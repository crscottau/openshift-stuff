# Agent notes

## Encryption

[https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/installing_an_on-premise_cluster_with_the_agent-based_installer/installing-with-agent-based-installer]


## VLAN

[https://docs.redhat.com/en/documentation/openshift_container_platform/4.12/html-single/installing_an_on-premise_cluster_with_the_agent-based_installer/index#agent-install-sample-config-bonds-vlans_preparing-to-install-with-agent-based-installer]

## Adding nodes

[https://docs.redhat.com/en/documentation/openshift_container_platform/4.19/html/nodes/working-with-nodes#adding-node-iso-yaml_adding-node-iso]

## Mirror

```yaml
imageDigestSources:
- mirrors:
  - mirror.spenscot.ddns.net:8443/openshift4/openshift-release-dev/ocp-v4.0-art-dev
  source: quay.io/openshift-release-dev/ocp-v4.0-art-dev
- mirrors:
  - mirror.spenscot.ddns.net:8443/openshift4/openshift-release-dev/ocp-release
  source: quay.io/openshift-release-dev/ocp-release
```

## Device

```yaml
hosts: 
  - hostname: disc
    interfaces:
      - name: enp1s0
        macAddress: 52:54:00:00:00:50
    rootDeviceHints: 
      deviceName: /dev/vda
    networkConfig: 
      interfaces:
        - name: enp1s0
          type: ethernet
          state: up
          mac-address: 52:54:00:00:00:50
          ipv4:
            enabled: true
            address:
              - ip: 192.168.124.50
                prefix-length: 23
            dhcp: false
      dns-resolver:
        config:
          server:
            - 192.168.124.1
      routes:
        config:
          - destination: 0.0.0.0/0
            next-hop-address: 192.168.124.1
            next-hop-interface: enp1s0
            table-id: 254
```
