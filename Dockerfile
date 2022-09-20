FROM debian:bookworm-slim

ARG ANDROID_PATCH BUILD_ENV=local MIRROR_URL=http://ftp.cn.debian.org/debian/

COPY ["./build-scripts/config-apt.sh", "./build-scripts/add-qemu.sh", "/tmp/build-scripts/"]

RUN . /tmp/build-scripts/config-apt.sh && \
    . /tmp/build-scripts/add-qemu.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 iptables xclip\
        dante-server tigervnc-standalone-server tigervnc-tools psmisc flwm x11-utils\
        busybox libssl-dev iproute2 tinyproxy-bin libxss1 libgconf-2-4 $extra_pkg && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r socks && useradd -r -g socks socks

ARG EC_URL ELECTRON_URL

COPY ["./build-scripts/install-ec-gui.sh", "./build-scripts/mk-qemu-wrapper.sh", "/tmp/build-scripts/"]

RUN /tmp/build-scripts/install-ec-gui.sh

COPY ./docker-root /

COPY --from=hagb/docker-easyconnect:build /results/fake-hwaddr/ /results/tinyproxy-ws/ /results/novnc/ /

ENV QEMU_ECAGENT_MEM_LIMIT=256

#ENV TYPE="" PASSWORD="" LOOP=""
#ENV DISPLAY
#ENV USE_NOVNC=""

VOLUME /root/ /usr/share/sangfor/EasyConnect/resources/logs/

CMD ["start.sh"]
