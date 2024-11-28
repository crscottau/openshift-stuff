# VMWare VM

Create a VM based on the available RHEL9.x VM templates

Add a NIC

Reboot in single user mode: 

`linux ... rw init=/bin/bash`

Change root passwd

Set to autorelabel: 

`touch /.autorelabel`

Reboot: 

`/sbin/reboot -f`

Login and configure NIC: 

`nmcli connection modify ens192 connection.autoconnect yes`

Start the network: 

`nmcli connection up ens192` 

Create a lab-user account in the wheel group

ssh to the box from the demo platform bastion host

Extend the root filesystem:

```
sudo parted -s -a opt /dev/sda "resizepart 3 100%"
sudo parted /dev/sda print
sudo pvresize /dev/sda3
sudo lvextend -l 100%FREE /dev/rhel/root
sudo xfs_growfs /dev/rhel/root
lsblk
```

Set the hostname:

`sudo hostnamectl set-hostname dns.hfqcj.dynamic.redhatworkshops.io`

Register the host with RHEL9:

`subscription-manager register --username crscott@redhat.com --password ******** --auto-attach`

Clone the VM