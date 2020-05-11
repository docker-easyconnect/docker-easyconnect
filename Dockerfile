FROM debian:buster

RUN sed -i s/deb.debian.org/mirrors.cqu.edu.cn/ /etc/apt/sources.list &&\
apt-get update && \
apt-get install -y --no-install-recommends --no-install-suggests \
	libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 iptables \
	dante-server tigervnc-standalone-server tigervnc-common dante-server psmisc flwm

COPY ./docker-root /

RUN apt-get update && apt-get install -y --no-install-recommends --no-install-suggests busybox &&\
busybox wget "http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb" -O /tmp/EasyConnect.deb &&\
dpkg -i /tmp/EasyConnect.deb && rm /tmp/EasyConnect.deb && apt-get purge -y busybox --auto-remove

#ENV TYPE="" PASSWORD=""
#ENV DISPLAY

VOLUME /root/

ENTRYPOINT start.sh
