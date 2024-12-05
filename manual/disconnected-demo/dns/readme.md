# DNS Server

https://www.redhat.com/en/blog/dns-configuration-introduction

Install bind

Configure the /etc/named.conf file to specify the local IP address and allow queries from anywhere:

```
        listen-on port 53 { 127.0.0.1; 192.168.41.11; };

        allow-query     { localhost; any; };
```        

Define the forward and reverse zones by updating the names and IP addresses and appending the following to /etc/named.rfc1912.zones:

```
zone "vqmpz.dynamic.redhatworkshops.io" IN {
        type master;
        file "vqmpz.dynamic.redhatworkshops.io.forward.zone";
        allow-update { none; };
};

zone "41.168.192.in-addr.arpa" IN {
        type master;
        file "vqmpz.dynamic.redhatworkshops.io.reverse.zone";
        allow-update { none; };
};
```

**Note:** Change the domain name to match the supplied demo platform domain and the reverse IP to match the supplied range.

Create the forward and reverse zone files

```
cat /var/named/vqmpz.dynamic.redhatworkshops.io.forward.zone
$TTL 1D
@       IN          SOA         dns.vqmpz.dynamic.redhatworkshops.io.   root.dns.vqmpz.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )     ; minimum
        IN          NS          dns.vqmpz.dynamic.redhatworkshops.io.
dns     IN          A           192.168.41.11   
mirror  IN          A           192.168.41.13            
master0 IN          A           192.168.41.20    
master1 IN          A           192.168.41.21    
master2 IN          A           192.168.41.22
api     IN          A           192.168.41.201
*.apps  IN          A           192.168.41.202
```

```
cat /var/named/vqmpz.dynamic.redhatworkshops.io.reverse.zone
$TTL 1D
@       IN          SOA         dns.vqmpz.dynamic.redhatworkshops.io.   root.dns.vqmpz.dynamic.redhatworkshops.io. (
                                                                                    0       ; serial
                                                                                    1D      ; refresh
                                                                                    1H      ; retry
                                                                                    1W      ; expire
                                                                                    1H )    ; minimum
        IN          NS          dns.vqmpz.dynamic.redhatworkshops.io.
11      IN          PTR         dns.vqmpz.dynamic.redhatworkshops.io.  
13      IN          PTR         mirror.vqmpz.dynamic.redhatworkshops.io.                
20      IN          PTR         master0.vqmpz.dynamic.redhatworkshops.io. 
21      IN          PTR         master1.vqmpz.dynamic.redhatworkshops.io. 
22      IN          PTR         master2.vqmpz.dynamic.redhatworkshops.io. 
```

Disable NM updating DNS settings on both VMs:

```
cat /etc/NetworkManager/conf.d/90-dns-none.conf
[main]
dns=none
```
Manually add the DNS server to /etc/resolv.conf on both VMs (in addition to the default)

Start and enable named 

Restart NetworkManager

Test with nslookup

Allow DNS through the firewall

```
sudo firewall-cmd --add-service dns
sudo firewall-cmd --add-service dns --permanent
```

