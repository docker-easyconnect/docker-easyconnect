#!/bin/sh
su daemon -s /bin/sh -c "exec websockify --daemon 127.0.0.1:8082 127.0.0.1:5901"
busybox httpd -u daemon:daemon -p 127.0.0.1:8081 -h /usr/local/share/novnc
exec tinyproxy -c /etc/tinyproxy-novnc.conf
