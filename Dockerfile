FROM debian:buster

COPY docker-files/EasyConnect.deb /tmp/

RUN sed -i s/deb.debian.org/mirrors.cqu.edu.cn/ /etc/apt/sources.list &&\
apt-get update && \
apt-get install --yes libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 iptables \
dante-server tigervnc-standalone-server dante-server psmisc &&\
dpkg -i /tmp/EasyConnect.deb 

COPY docker-files/start.sh docker-files/start-sangfor.sh /usr/local/bin/
COPY docker-files/sockd.conf /etc/danted.conf
RUN chmod +x /usr/local/bin/start.sh /usr/local/bin/start-sangfor.sh 

ENV TYPE vnc
ENV PASSWORD ""


VOLUME /root/

ENTRYPOINT start.sh
