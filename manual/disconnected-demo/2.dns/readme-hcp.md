# DNS Server

---

NOT REALLY SURE THIS IS REQUIRED FOR HCP

---

<https://www.redhat.com/en/blog/dns-configuration-introduction>

Install bind

`sudo dnf install bind`

Configure the `/etc/named.conf` file to specify the local IP address, disable upstream lookups and allow queries from anywhere:

```conf
        listen-on port 53 { 127.0.0.1; 192.168.24.11; };

        recursion no;

        allow-query     { localhost; any; };
```

Define the forward and reverse zones by updating the names and IP addresses and appending the following to `/etc/named.rfc1912.zones`:

```conf
zone "6hp9c-hcp.dynamic.redhatworkshops.io" IN {
        type master;
        file "6hp9c-hcp.dynamic.redhatworkshops.io.forward.zone";
        allow-update { none; };
};

zone "24.168.192.in-addr.arpa" IN {
        type master;
        file "6hp9c-hcp.dynamic.redhatworkshops.io.reverse.zone";
        allow-update { none; };
};
```


**Note:** Change the domain name to match the supplied demo platform domain and the reverse IP to match the supplied range.

Create the forward and reverse zone files

```bash
$ cat /var/named/6hp9c-hcp.dynamic.redhatworkshops.io.forward.zone
$TTL 1D
@       IN          SOA         customdns.6hp9c-hcp.dynamic.redhatworkshops.io.   root.customdns.6hp9c-hcp.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )     ; minimum
          IN          NS          customdns.6hp9c-hcp.dynamic.redhatworkshops.io.
customdns IN          A           192.168.24.41 
compute-0 IN          A           192.168.24.123 
compute-1 IN          A           192.168.24.124 
compute-2 IN          A           192.168.24.125
api       IN          A           192.168.24.120
*.apps    IN          A           192.168.24.121
```

```bash
$ cat /var/named/6hp9c-hcp.dynamic.redhatworkshops.io.reverse.zone
$TTL 1D
@       IN          SOA         dns.cn96hp9c-hcpvz.dynamic.redhatworkshops.io.   root.dns.6hp9c-hcp.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )    ; minimum
        IN          NS          customdns.6hp9c-hcp.dynamic.redhatworkshops.io.
41      IN          PTR         customdns.6hp9c-hcp.dynamic.redhatworkshops.io.
123     IN          PTR         compute-0.6hp9c-hcp.dynamic.redhatworkshops.io. 
124     IN          PTR         compute-1.6hp9c-hcp.dynamic.redhatworkshops.io. 
125     IN          PTR         compute-2.6hp9c-hcp.dynamic.redhatworkshops.io. 
```

Disable NM updating DNS settings on both VMs:

```bash
$ cat /etc/NetworkManager/conf.d/90-dns-none.conf
sudo 
```

Manually add the DNS server to /etc/resolv.conf on both VMs (in addition to the default)

Start and enable `named`

Restart NetworkManager

Test with nslookup

Allow DNS through the firewall

```bash
sudo firewall-cmd --add-service dns
sudo firewall-cmd --add-service dns --permanent
```
