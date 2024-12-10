# Proxy

<https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/deploying_web_servers_and_reverse_proxies/configuring-the-squid-caching-proxy-server_deploying-web-servers-and-reverse-proxies>

## Install and configure

`sudo dnf install squid`

Edit `/etc/squid/squid.conf`:

- remove all superfluous `acl localnet` entries
- remove all superfluous `acl Safe_ports` entries

Open port 3128 in the firewall:

```bash
sudo firewall-cmd --add-port 3128/tcp
sudo firewall-cmd --add-port 3128/tcp --permanent
```

**Note:** To ge it to work I had to edit `/etc/resolv.conf` and comment out the local DNS

Test:

`curl -O -L "https://www.redhat.com/index.html" -x "192.168.41.11:3128"`

### Allowlist the Red Hat registries

Add the following to `/etc/squid/squid.conf`:

```conf
acl whitelist dstdomain registry.redhat.io access.redhat.com quay.io cdn.quay.io cdn01.quay.io cdn02.quay.io cdn03.quay.io
http_access allow whitelist
```

I can't get this to work, in the end I configured:

```conf
acl denylist dstdomain api.openshift.com infogw.api.openshift.com
http_access deny denylist
```

## Configure OCP for the proxy

```yaml
  httpProxy: 'http://192.168.41.11:3128'
  httpsProxy: 'http://192.168.41.11:3128'
  noProxy: '192.168.41.0/24,.vqmpz.dynamic.redhatworkshops.io,.infra.demo.redhat.com'
```
