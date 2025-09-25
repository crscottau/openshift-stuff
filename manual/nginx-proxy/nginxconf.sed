# Change user directive to work with OpenShift (comment it out since we'll run as non-root)
s/^user[[:space:]]\+[^;]*;/#user nginx;/

# Change pid file location to be writable by non-root user
s|^pid[[:space:]]\+[^;]*;|pid /tmp/nginx.pid;|

# Remove the default server block that listens on port 80
/^    server {$/,/^    }$/d

# Add include directive for our configuration files in the http block
/include \/etc\/nginx\/conf.d\/\*.conf;/a\
    include /opt/app-root/etc/nginx.d/*.conf;\
    include /opt/app-root/etc/nginx.default.d/*.conf;

