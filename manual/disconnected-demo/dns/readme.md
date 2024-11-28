# DNS Server

https://www.redhat.com/en/blog/dns-configuration-introduction

Install bind

Configure the /etc/named.conf file to specify the local IP address and allow queries from anywhere

Define the forward and reverse zones by appending the following to /etc/named.rfc1912.zones:

```
zone "hfqcj.dynamic.redhatworkshops.io" IN {
        type master;
        file "hfqcj.dynamic.redhatworkshops.io.forward.zone";
        allow-update { none; };
};

zone "23.168.192.in-addr.arpa" IN {
        type master;
        file "hfqcj.dynamic.redhatworkshops.io.reverse.zone";
        allow-update { none; };
};
```

**Note:** Change the domain name to match the supplied demo platform domain and the reverse IP to match the supplied range.

Create the forward and reverse zone files

```
cat /var/named/hfqcj.dynamic.redhatworkshops.io.forward.zone
$TTL 1D
@       IN          SOA         dns.hfqcj.dynamic.redhatworkshops.io.   root.dns.hfqcj.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )     ; minimum
        IN          NS          dns.hfqcj.dynamic.redhatworkshops.io.
dns     IN          A           192.168.23.11   
mirror  IN          A           192.168.23.13            
master0 IN          A           192.168.23.20    
master1 IN          A           192.168.23.21    
master2 IN          A           192.168.23.22
api     IN          A           192.168.23.201
*.apps  IN          A           192.168.23.202
```

```
cat /var/named/hfqcj.dynamic.redhatworkshops.io.reverse.zone
$TTL 1D
@       IN          SOA         dns.hfqcj.dynamic.redhatworkshops.io.   root.dns.hfqcj.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )    ; minimum
        IN          NS          dns.hfqcj.dynamic.redhatworkshops.io.
11      IN          PTR         dns.hfqcj.dynamic.redhatworkshops.io.  
13      IN          PTR         mirror.hfqcj.dynamic.redhatworkshops.io.                
20      IN          PTR         master0.hfqcj.dynamic.redhatworkshops.io. 
21      IN          PTR         master1.hfqcj.dynamic.redhatworkshops.io. 
22      IN          PTR         master2.hfqcj.dynamic.redhatworkshops.io. 
```

Disable NM updating DNS settings:

```
cat /etc/NetworkManager/conf.d/90-dns-none.conf
[main]
dns=none
```
Manually add the DNS server to /etc/resolv.conf on both VMs (in addition to the default)

Start and enable named 

Test with nslookup

Allow DNS through the firewall

```
sudo firewall-cmd --add-service dns
sudo firewall-cmd --add-service dns --permanent
```

