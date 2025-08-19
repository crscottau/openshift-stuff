# DNS Server

<https://www.redhat.com/en/blog/dns-configuration-introduction>

Install bind

`sudo dnf install bind`

Configure the `/etc/named.conf` file to specify the local IP address, disable upstream lookups and allow queries from anywhere:

```conf
        listen-on port 53 { 127.0.0.1; 192.168.41.11; };

        recursion no;

        allow-query     { localhost; any; };
```

Define the forward and reverse zones by updating the names and IP addresses and appending the following to `/etc/named.rfc1912.zones`:

```conf
zone "vqmpz.dynamic.redhatworkshops.io" IN {
        type master;
        file "cn9vz.dynamic.redhatworkshops.io.forward.zone";
        allow-update { none; };
};

zone "18.168.192.in-addr.arpa" IN {
        type master;
        file "cn9vz.dynamic.redhatworkshops.io.reverse.zone";
        allow-update { none; };
};
```

Also need to add this zone so the cluster can find the vSphere servers when using an install type of IPI

```conf
zone "infra.demo.redhat.com" IN {
        type master;
        file "infra.demo.redhat.com.forward.zone";
        allow-update { none; };
};

#zone "41.168.192.in-addr.arpa" IN {
#        type cn9vz;
#        file "vqmpz.dynamic.redhatworkshops.io.reverse.zone";
#        allow-update { none; };
#};
```

**Note:** Change the domain name to match the supplied demo platform domain and the reverse IP to match the supplied range.

Create the forward and reverse zone files

```bash
$ cat /var/named/cn9vz.dynamic.redhatworkshops.io.forward.zone
$TTL 1D
@       IN          SOA         dns.cn9vz.dynamic.redhatworkshops.io.   root.dns.vqmpz.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )     ; minimum
          IN          NS          dns.cn9vz.dynamic.redhatworkshops.io.
dns       IN          A           192.168.18.10 
mirror    IN          A           192.168.18.20
control-0 IN          A           192.168.18.100     
control-1 IN          A           192.168.18.101     
control-2 IN          A           192.168.18.102
compute-0 IN          A           192.168.18.120 
compute-1 IN          A           192.168.18.121 
compute-2 IN          A           192.168.18.122
api       IN          A           192.168.18.201
*.apps    IN          A           192.168.18.202
```

```bash
$ cat /var/named/cn9vz.dynamic.redhatworkshops.io.reverse.zone
$TTL 1D
@       IN          SOA         dns.cn9vz.dynamic.redhatworkshops.io.   root.dns.cn9vz.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )    ; minimum
        IN          NS          dns.cn9vz.dynamic.redhatworkshops.io.
10      IN          PTR         dns.cn9vz.dynamic.redhatworkshops.io.
20      IN          PTR         mirror.cn9vz.dynamic.redhatworkshops.io.
100     IN          PTR         control-0.cn9vz.dynamic.redhatworkshops.io. 
101     IN          PTR         control-1.cn9vz.dynamic.redhatworkshops.io. 
102     IN          PTR         control-2.cn9vz.dynamic.redhatworkshops.io. 
120     IN          PTR         compute-0.cn9vz.dynamic.redhatworkshops.io. 
121     IN          PTR         compute-1.cn9vz.dynamic.redhatworkshops.io. 
122     IN          PTR         compute-2.cn9vz.dynamic.redhatworkshops.io. 
```

Also need to add this zone so the cluster can find the vSphere servers when using an install type of IPI

```bash
$ cat /var/named/infra.demo.redhat.com.forward.zone
$TTL 1D
@       IN          SOA         dns.infra.demo.redhat.com.   root.dns.vinfra.demo.redhat.com. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )     ; minimum
           IN       NS          dns.infra.demo.redhat.com.
dns        IN       A           192.168.41.11   
vcsnsx-vc  IN       A           169.60.246.8  
esxi-01000 IN       A           169.48.185.197
esxi-01001 IN       A           169.48.185.199
esxi-01002 IN       A           169.48.185.194
```

Disable NM updating DNS settings on both VMs:

```bash
$ cat /etc/NetworkManager/conf.d/90-dns-none.conf
[main]
dns=none
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
