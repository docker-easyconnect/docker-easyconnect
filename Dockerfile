FROM debian:bookworm-slim

ARG ANDROID_PATCH MIRROR_URL=http://ftp.cn.debian.org/debian/ EC_HOST VPN_TYPE=EC_GUI

COPY ["./build-scripts/config-apt.sh", "./build-scripts/get-echost-names.sh",  "./build-scripts/add-qemu.sh", \
      "/tmp/build-scripts/"]

RUN . /tmp/build-scripts/config-apt.sh && \
    . /tmp/build-scripts/get-echost-names.sh && \
    . /tmp/build-scripts/add-qemu.sh && \
    apt-get update && \
    if [ "ATRUST" = "$VPN_TYPE" ]; then \
        extra_pkgs="libssl1.1 libatk-bridge2.0-0 libgtk-3-0 libgbm1 libqt5x11extras5 procps \
                    libqt5core5a libqt5network5 libqt5widgets5 libldap-2.4-2 stalonetray"; \
    else \
        extra_pkgs="libgtk2.0-0 libdbus-glib-1-2 libgconf-2-4 libnspr4:$EC_HOST libnss3:$EC_HOST"; \
    fi && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        libx11-xcb1 libnss3 libasound2 iptables xclip libxtst6 \
        dante-server tigervnc-standalone-server tigervnc-tools psmisc flwm x11-utils \
        busybox libssl-dev iproute2 tinyproxy-bin libxss1 ca-certificates \
        fonts-wqy-microhei socat $qemu_pkgs $extra_pkgs && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r socks && useradd -r -g socks socks

COPY ["./build-scripts/install-vpn-gui.sh", "./build-scripts/mk-qemu-wrapper.sh", "/tmp/build-scripts/"]

COPY ./docker-root-preinst /

ARG VPN_URL ELECTRON_URL USE_VPN_ELECTRON VPN_DEB_PATH

RUN /tmp/build-scripts/install-vpn-gui.sh

COPY ./docker-root /

COPY --from=hagb/docker-easyconnect:build /results/fake-hwaddr/ /results/fake-getlogin/ /results/tinyproxy-ws/ /results/novnc/ /

#ENV TYPE="" PASSWORD="" LOOP=""
#ENV DISPLAY
#ENV USE_NOVNC=""

ENV PING_INTERVAL=1800

VOLUME /root/ /usr/share/sangfor/EasyConnect/resources/logs/

CMD ["start.sh"]
