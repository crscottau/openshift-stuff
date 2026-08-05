# Unix bits

- [Unix bits](#unix-bits)
  - [AIX](#aix)
    - [IPCS](#ipcs)
    - [Kill processes](#kill-processes)
    - [Sort ps](#sort-ps)
    - [Loop](#loop)
    - [Delete log files older than 30 days](#delete-log-files-older-than-30-days)
    - [Find and sort by file size](#find-and-sort-by-file-size)
    - [Find greater then 1000k](#find-greater-then-1000k)
  - [LDAP](#ldap)
  - [MQ Series](#mq-series)
  - [TAM](#tam)
  - [WebSEAL](#webseal)
  - [CVS](#cvs)
  - [VI](#vi)
  - [Caching Proxy](#caching-proxy)
  - [IP Trace](#ip-trace)
  - [Cygwin](#cygwin)
  - [Windows Registry Editor Version 5.00](#windows-registry-editor-version-500)
  - [AIX user admin](#aix-user-admin)
  - [Tunnelling](#tunnelling)
  - [crontab](#crontab)
  - [Writing to blocks](#writing-to-blocks)
  - [Changing a disk](#changing-a-disk)
  - [DNS Resolution](#dns-resolution)
  - [Checking physical memory](#checking-physical-memory)
  - [Convert EBCDIC to ASCII](#convert-ebcdic-to-ascii)
  - [Mounting Windows shares from command line](#mounting-windows-shares-from-command-line)
  - [Tracking I/O usage](#tracking-io-usage)
  - [How to fix the putty sudo X11 invalid magic cookie issue](#how-to-fix-the-putty-sudo-x11-invalid-magic-cookie-issue)
  - [Adding a new disk to a LV](#adding-a-new-disk-to-a-lv)
  - [Command to detect new SCSI disks without reboot](#command-to-detect-new-scsi-disks-without-reboot)
  - [List all physical volumes associated to a volume group](#list-all-physical-volumes-associated-to-a-volume-group)
  - [SELinux](#selinux)
  - [IP ROUTE](#ip-route)
  - [Debug Load Library failures](#debug-load-library-failures)
  - [Simple TCP Listener that dumps to console](#simple-tcp-listener-that-dumps-to-console)
  - [Extract rpm contents](#extract-rpm-contents)
  - [systemd](#systemd)
  - [CSV files](#csv-files)
  - [Journalctl](#journalctl)
  - [Manipulate Create Date](#manipulate-create-date)
  - [Exclude directories from a find](#exclude-directories-from-a-find)
  - [Query an iSCSI device](#query-an-iscsi-device)
  - [Print the partition table](#print-the-partition-table)
  - [Find out who is using a mount point](#find-out-who-is-using-a-mount-point)
  - [Find large files](#find-large-files)
  - [When did I boot](#when-did-i-boot)
  - [Set vi tab to 2 spaces](#set-vi-tab-to-2-spaces)
  - [Reset root password on Red Hat KVM image](#reset-root-password-on-red-hat-kvm-image)
  - [Split single yaml](#split-single-yaml)
  - [List samba users](#list-samba-users)
  - [keepalived](#keepalived)
  - [Create a file](#create-a-file)
  - [Group lines in vim](#group-lines-in-vim)
  - [s3cmd](#s3cmd)
  - [Find files modified on a given day](#find-files-modified-on-a-given-day)
  - [Create group shared directory](#create-group-shared-directory)
  - [Static IP with nmcli](#static-ip-with-nmcli)

## AIX

### IPCS

`ipcs|grep mqm|more`

### Kill processes

```bash
{ps/greps to display task list}|awk '{print $2}'|xargs -i kill -9 {}
	eg: ps -ef|grep [w]asadmin|awk '{print $2}'|xargs -i kill -9 {}
```

### Sort ps

`ps aux|sort -rn +3|head`

### Loop

```bash
while true
do 
clear 3
ps -ef|grep [w]asexe|wc -l
sleep 3
done
```

### Delete log files older than 30 days

`find /path -name 'log.*' -mtime +30 -exec rm {} \;`

### Find and sort by file size

```bash
find . -xdev -ls | sort -nk 7
find . -size +2048 -ls |sort -r +6
```

### Find greater then 1000k

`find / -size +1000k -print -xdev -ls`

## LDAP

```bash
ldapsearch -h <hostname> -b o=hic objectclass=*
ldapadd -h <hostname> -D cn=root -w <password> -v -f <filename.ldif>
ldapmodify -h <hostname> -D cn=root -w <password> -v -f <filename.ldif>
ldapcfg -u cn=root -p <newpassword> ! Back up /etc/slapd32.conf before changing cn=root password
ldapsearch -h <hostname> -p 389 -b cn=monitor -s base objectclass=*
ldapsearch -s base -b cn=monitor objectclass=*
ldapsearch -D cn=root -w newpass -s base -b cn=monitor objectclass=*
```

## MQ Series

error logs are in /var/mqm/error

config is in /var/mqm/mqs.ini

```bash
<QueueManager> shutdown
<QueueManager> startup

runmqsc
dis q(ARC.LOGGING.QUEUE) all
clear ql(ARC.LOGGING.QUEUE)    !!! CAUTION - BRUTAL
```

delete a queue, from runmqsc

`DELETE QL (ARC.LOGGING.QUEUE)`

create a queue, from runmqsc

copy and paste the appropriate definition from /home/mqm/definitions/MQCNPP2/qarc001.def

Trace MQ

```bash
trace -a -j30D,30E -o trace.file
trcstop
trcrpt -t mqmtop/lib/amqtrc.fmt trace.file > report.file
```

Recover a Queue

`rcrmqobj -m MQCNPP2 -t q ARC.LOGGING.QUEUE`

(based on message [AMQ7472: Object ARC.LOGGING.QUEUE, type queue damaged.] in qmgr error log /var/mqm/qmgrs/MQCNPP2/errors/AMQERR01.LOG)

## TAM

/etc/pd/pd is a wrapper for /opt/PolicyDirector/bin/pd_start

pd takes parameters: start|stop|status

pd also sets up environment variables for pd_start 

Note: SO USE IT

pdconfig - post installation configuration
pdconfig - show current configuration

```bash
sudo pdadmin -a sec_master
server list
server task <servername> list
server task <servername> show <junctionname>
server task <servername> stats list
server task <servername> stats get <component> (ie: pdweb.threads)

user list
user modify <username> password <newpassword>
```

WebSEAL junctions can be limited to a percentage of the total number of worker threads, this is via the junction configuration.

LDAP is only used for authentication - WebSEAL has a very small authentication overhead.

TAM key database file password is by default the same as the name of the key database file

## WebSEAL

Run `/opt/pdweb/bin/pdweb_start status` (to check the status of WEBSEAL)

Trace:

```bash
server task webseald-server trace set pdweb.debug 9 file path=/tmp/pdweb.debug
server task webseald-server trace set pdweb.debug 0
```

## CVS

```bash
export CVSROOT=:ext:vulcan:/cmcvs
export CVS_RSH=ssh
```

To retrieve files

```bash
cvs get <project name> 
cvs checkout <project name>
```

To update a file, simply edit the file and then 

`cvs update <filename>`

To commit changes

`cvs commit <filename>`

e.g.

```bash
cvs get hiccfg
cd hiccfg/configitems
vi <filename>
cvs update <filename>
cvs commit <filename>
```

To add a file

```bash
cvs add <filename>
cvs commit <filename>
```

e.g.

```bash
cd hiccfg/configitems
vi <newfile>
cvs add <newfile>
cvs commit
```

To view the history for a file

cvs rlog <path/file>

e.g.

`cvs rlog hiccfg/auth_config/shudder/admin.config`

(yes, unfortunately you always need to specify the full path)

To retrieve a specific version

`cvs export -D <date> <path/filename>`

Help (note use two minus signs)

```bash
cvs --help
cvs --commands
cvs add --help
cvs rlog --help
etc
```

## VI

Global find/replace:  `:1,$s/up/right/`

## Caching Proxy

Add these two lines to the ibmproxy.conf file, the two lines I think can be added pretty much anywhere, I usally add them under the Logging directives.

```bash
TraceLog /tmp/cpTrace.txt
TraceModule all
```

to actually get trace the ibmproxy must be started with this:

`ibmproxy -debug -vv`

or 

`ibmproxy -debug -mtv`

However since ibmproxy uses CBR, you need to have the LIBPATH set up correctly.  The LIBPATH is set up correctly in /etc/rc.ibmproxy.  I would suggest getting the rc.ibmproxy changed on all AIX boxes so that you have a SUDOMENU option start ibmproxy in debug mode.  Change the rc.ibmproxy to something like this:  

```bash
if [[ "$1" = "stop" ]]
then
        echo "Stopping ibmproxy"
        for x in $(eval ps -efa |grep ibmproxy |grep -v rc.ibmproxy|grep -v grep
 |awk '{print $2}')
        do
          kill $x
        done
else if [[ "$1" = "debug" ]]
then 

        sleep 15   # This is in case cbrserver is still starting
        /usr/sbin/ibmproxy -debug -vv
        rc=$?
fi
else

        sleep 15   # This is in case cbrserver is still starting
        /usr/sbin/ibmproxy
        rc=$?
fi
```

and get an option added to SUDOMENU to do /etc/rc.ibmproxy debug

You need to test the above, when you start ibmproxy with -vv -debug options, when I did it from command line, it just is in the foreground on your session.  If you Control C out, then it will terminate.

Then in the future if you need to do Caching Proxy tracing, you can use the SUDOMENU option to edit the ibmproxy.conf file to add the two trace lines above, then use the sudomenu debug start method for rc.ibmproxy.

## IP Trace

On AIX, as root, you can do an iptrace, issue cmd

`iptrace fred`

this will start a process, and write IP trace info to fred in /tmp.

After running what ever it is you are trying to trace, stop the trace by doing 

`ps -efa | grep iptrace`

and kill the iptrace process

Then format the trace via cmd:

`ipreport fred > /tmp/fred.txt`

## Cygwin

`mount -b -s 'c:\Program Files' /pf`

## Windows Registry Editor Version 5.00

```bash
[HKEY_CURRENT_USER\Software\Microsoft\Windows NT\CurrentVersion\Winlogon]
"Shell"="c:\\cygwin\\bin\\ssh-agent c:\\windows\\explorer.exe"
```

## AIX user admin

Fix too many failed logins:

`chsec -f /etc/security/lastlog -a "unsuccessful_login_count=0" -s  'username'   `

## Tunnelling

`ssh -AtL 5555:tdcmon01:5555 tdcmon01 "ssh -AgL 5555:tdcwm001:5555 tdcwm001"`

## crontab

```bash
*     *   *   *    *  command to be executed
-     -    -    -    -
|     |     |     |     |
|     |     |     |     +```- day of week (1 - 7) (monday = 1)
|     |     |     +```--- month (1 - 12)
|     |     +```----- day of month (1 - 31)
|     +```------- hour (0 - 23)
+```--------- min (0 - 59)	
```

## Writing to blocks

`dd of=/dev/hda1 bs=512 count=1 skip=x < /dev/urandom`

where x is the number of blocks to skip

## Changing a disk

1. copy the data from the old disk to the new disk mounted somewhere:

`rsync -xav / /mnt/`

2. do a grub install:

`grub-install --root-directory=/mnt /dev/hdx`
  
note that the hdx drive needs to be in the /boot/grub/device.map.

this can also be done using grub:

```bash
grub 
grub> root (hd2,x) 
grub> setup (hd2) 
grub> quit
```

3. Swap out the disks and restart
   
## DNS Resolution

use /etc/netsvc.conf - a line to say hosts=bind
if hosts=local,bind will use hosts first....

## Checking physical memory

Linux

```bash
cat /proc/meminfo | grep MemTotal
/sbin/swapon -s
free -m
```

AIX

```bash
/usr/sbin/lsattr -E -l sys0 -a realmem
/usr/sbin/lsps -s
```

Free Linux Cache

sync; echo 3 > /proc/sys/vm/drop_caches

## Convert EBCDIC to ASCII

`find . -type f -print|xargs -i dd conv=ascii if={} of={}.asc`

## Mounting Windows shares from command line

The command (run as root) for a guest-accessible share:

`mount -t cifs -o guest,uid=client_user,gid=users //x.x.x.x/share /path_to/mount`

server requiring authentication, use:

`mount -t cifs -o username=server_user,password=secret,uid=client_user,gid=users //x.x.x.x/share /path_to/mount`

## Tracking I/O usage

```bash
echo 1 > /proc/sys/vm/block_dump
dmesg -c | perl iodump
```

To turn it off:

`echo 0 > /proc/sys/vm/block_dump`

## How to fix the putty sudo X11 invalid magic cookie issue

`putty x11 proxy MIT-MAGIC-COOKIE-1 data did not match`

logon as user1

```bash
xauth list
echo $DISPLAY

sudo su - user2
export DISPLAY=...
```

to match above

```bash
xauth list
xauth add ....
```

to match above

## Adding a new disk to a LV

```bash
$ fdisk /dev/sdd1
n - new partition
etc

$ pvcreate /dev/sdd1
$ vgextend VolGroup00 /dev/sdd1
$ lvcreate --size 3000 --name logVol06 VolGroup00
$ lvs
$ mkfs -t ext3 /dev/VolGroup00/LogVol06
$ mkdir /var/log/sdebi
$ mount /dev/VolGroup00LogVol06 /var/log/sdebi
$ vi /etc/fstab
/dev/VolGroup00LogVol06 /var/log/sdebi ext3 defaults 1 2
```

## Command to detect new SCSI disks without reboot

`echo "- - -" > /sys/class/scsi_host/host0/scan`

## List all physical volumes associated to a volume group

`pvdisplay -C --separator '  |  ' -o pv_name,vg_name`

## SELinux

```bash
getenforce
setenforce [0|1]
```

## IP ROUTE

`ip route add default via 10.10.0.2`

## Debug Load Library failures

`export LD_DEBUG=files`

## Simple TCP Listener that dumps to console

`nc -l -k -p 5000`

## Extract rpm contents

`rpm2cpio install/post/dsmrpms/DSM-MicrosoftSQL-7.3-20160908133313.noarch.rpm | sudo cpio -idmv`

## systemd

<https://www.linux.com/learn/understanding-and-using-systemd>

Show what services are known and their startup state:

```bash
systemctl list-unit-files --type=service

# systemctl start [name.service]
# systemctl stop [name.service]
# systemctl restart [name.service]
# systemctl reload [name.service]
$ systemctl status [name.service]
# systemctl is-active [name.service]
$ systemctl list-units --type service --all
```

## CSV files

`column -t -s ',' var/log/systemStabMon/2018/01/08/iostat_sda`

## Journalctl

`journalctl -xe --no-tail --no-pager > /tmp/journalctl.log`

## Manipulate Create Date

```bash
start=$(ls|wc -l)
for file in *; do touchdate=$(date -v-${start}d +%Y%m%d); touch -t $touchdate $file; start=$((start -1)); done
```

## Exclude directories from a find

`find /store -not \( -path /store/ariel -prune \) -not \( -path /store/postgres -prune \) -not \( -path /store/acl_descriptors -prune \) -not \( -path /store/flowlogs -prune \) -print|grep -i centos`

## Query an iSCSI device

```bash
ll /sys/class/iscsi_session/session1/device/
../../../session1

dmesg | grep SCSI
```

## Print the partition table

`parted /dev/sdb print`

## Find out who is using a mount point

`fuser -m /transient`

to find out who is holding that mount pount, then grep on the PID

## Find large files

`find . -xdev -type f -size +100M -exec ls -lh {} \;`

## When did I boot

`who -b`

## Set vi tab to 2 spaces

`autocmd FileType yaml setlocal ai ts=2 sw=2 et`

## Reset root password on Red Hat KVM image

`virt-customize -a /home/crscott/Downloads/rhel-8.5-x86_64-kvm.qcow2 --root-password password:2wsx#EDC`

## Split single yaml 

`awk '/^..name:/{file=$2 ".yaml"} !/^-/{temp=temp $0 "\n"} /^-/{print temp>file; close(file); temp=""}' inputFile`

## List samba users

Password file is:

`/var/lib/samba/private/passdb.tdb`

List users:

`sudo pdbedit -L -v`

## keepalived

```bash
$ sudo dnf install -y keepalived httpd
$ cat /var/www/html/index.html
This is 'A' - rhel8a
$ cat /etc/keepalived/keepalived.conf 
vrrp_instance VI_1 {
    state MASTER
    interface enp1s0
    virtual_router_id 51
    priority 255
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass Passw0rd
    }
    virtual_ipaddress {
        192.168.122.88
    }
}
$ sudo firewall-cmd --add-service http
$ sudo firewall-cmd --add-rich-rule='rule protocol value="vrrp" accept'
$ sudo firewall-cmd --runtime-to-permanent
$ sudo systemctl enable --now httpd
$ sudo systemctl enable --now keepalived
```

## Create a file

```bash
cat <<__EOF > test.sh
echo hello World!
__EOF
```

```bash
$ sudo tee /var/repos/microshift-local/microshift.toml > /dev/null <<EOF
id = "microshift-local"
name = "MicroShift local repo"
type = "yum-baseurl"
url = "file:////var/repos/microshift-local/"
check_gpg = false
check_ssl = false
system = false
EOF
```

## Group lines in vim

Mere every 4 lines into 1 line:

`:g/$/j4`

## s3cmd

`s3cmd --host=s3-openshift-storage.apps.mxhgm.dynamic.redhatworkshops.io:443 --host-bucket=loki-bucket --access_key "m5MAl3A9iySFkNYbvCeU" --secret_key "+RIiuc+Z3G1WvEeN+MEZHtMJuBUEnpzHNxfKOepc" ls s3://loki-bucket`

## Find files modified on a given day

`find ~ -type f -newermt 2024-10-10 ! -newermt 2024-10-11|grep -Ev '.var|.cache'`

## Create group shared directory

```bash
sudo chgrp ocp-admins /opt/openshift
sudo chmod g+rwx /opt/openshift
sudo chmod g+s /opt/openshift
sudo setfacl -d -m u::rwX -m g::rwX /home/openshift
```

## Static IP with nmcli

```bash
sudo nmcli conn mod enp7s0 ipv4.method manual ipv4.addr "192.168.124.10" ipv4.gateway "192.168.124.1" ipv4.dns "192.168.124.1" ipv4.method manual connection.autoconnect yes
sudo nmcli conn up
```

## Resize a filesystem 

`$ sudo -1`

The disk has 45G unused

```bash
$ lsblk
[sudo] password for crscott: 
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sr0            11:0    1 1024M  0 rom  
vda           252:0    0  120G  0 disk 
├─vda1        252:1    0    1G  0 part /boot
└─vda2        252:2    0   74G  0 part 
  ├─rhel-root 253:0    0   70G  0 lvm  /
  └─rhel-swap 253:1    0  3.9G  0 lvm  [SWAP]
```

Increase the partiton size

```bash
$ parted /dev/vda
GNU Parted 3.5
Using /dev/vda
Welcome to GNU Parted! Type 'help' to view a list of commands.
(parted) print                                                            
Model: Virtio Block Device (virtblk)
Disk /dev/vda: 129GB
Sector size (logical/physical): 512B/512B
Partition Table: msdos
Disk Flags: 

Number  Start   End     Size    Type     File system  Flags
 1      1049kB  1075MB  1074MB  primary  xfs          boot
 2      1075MB  80.5GB  79.4GB  primary               lvm

(parted) resizepart 2 100%                                                
(parted) quit                                                             
Information: You may need to update /etc/fstab.
```
Resize the PV

```bash
$ pvresize /dev/vda2
Physical volume "/dev/vda2" changed
1 physical volume(s) resized or updated / 0 physical volume9s0 not resized

$ pvs 
PV         VG   Fmt  Attr PSize    PFree  
/dev/vda2  rhel lvm2 a--  <119.00g <45.05g
```

Check the LV size

```bash
$ lvdisplay
  --- Logical volume ---
  LV Path                /dev/rhel/root
  LV Name                root
  VG Name                rhel
  LV UUID                EPJsWh-EBAx-QA6x-bYYO-y2qZ-JUOZ-X2l6Al
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2025-01-28 16:03:14 +1100
  LV Status              available
  # open                 1
  LV Size                70.00 GiB
  Current LE             17920
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
```

Resize the LV

`lvresize -l +100%FREE /dev/rhel/root`

Check again

```bash
$ lvdisplay
  --- Logical volume ---
  LV Path                /dev/rhel/root
  LV Name                root
  VG Name                rhel
  LV UUID                EPJsWh-EBAx-QA6x-bYYO-y2qZ-JUOZ-X2l6Al
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2025-01-28 16:03:14 +1100
  LV Status              available
  # open                 1
  LV Size                <115.05 GiB
  Current LE             29452
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
```

Grow the filesystem

`xfs_growfs /dev/rhel/root | tee growfs`

