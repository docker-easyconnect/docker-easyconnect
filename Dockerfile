FROM debian:buster-slim

RUN sed -i s/deb.debian.org/mirrors.cqu.edu.cn/ /etc/apt/sources.list &&\
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 iptables xclip\
        dante-server tigervnc-standalone-server tigervnc-common dante-server psmisc flwm x11-utils\
        xdotool \
        busybox && \
    ln -s "$(which busybox)" /usr/local/bin/ip

ARG EC_URL

RUN cd tmp &&\
    busybox wget "${EC_URL}" -O EasyConnect.deb &&\
    dpkg -i EasyConnect.deb && rm EasyConnect.deb

COPY ./docker-root /

#ENV TYPE="" PASSWORD="" LOOP=""
#ENV DISPLAY

VOLUME /root/

CMD ["start.sh"]
