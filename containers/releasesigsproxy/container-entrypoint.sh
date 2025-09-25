#!/bin/bash

# Substitute allow ACLs and upstream proxy from environment varaibles
envsubst < /etc/squid/squid.conf.template > /tmp/squid/squid.conf

# in case of using cache dir, we need to initialize it
/usr/sbin/squid -d 1 --foreground -f /tmp/squid/squid.conf -z

# now start the squid primary process with supplied options
/usr/sbin/squid -d 1 --foreground -f /tmp/squid/squid.conf $@
