FROM debian:bookworm-slim

ARG ANDROID_PATCH BUILD_ENV=local MIRROR_URL=http://mirrors.aliyun.com/debian/

COPY ["./build-scripts/pre_build.sh", "./build-scripts/set-mirror.sh", "/tmp/build-scripts/"]

RUN extra_pkg_cross="libxss1 libgconf-2-4" . /tmp/build-scripts/pre_build.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 iptables xclip\
        dante-server tigervnc-standalone-server tigervnc-tools psmisc flwm x11-utils\
        busybox libssl-dev iproute2 tinyproxy-bin $extra_pkg && \
    rm -rf /var/lib/apt/lists/*

RUN groupadd -r socks && useradd -r -g socks socks

ARG EC_URL ELECTRON_URL

COPY ["./build-scripts/install-ec-gui.sh", "./build-scripts/mk-qemu-wrapper.sh", "/tmp/build-scripts/"]

RUN /tmp/build-scripts/install-ec-gui.sh

COPY ./docker-root /

COPY --from=hagb/docker-easyconnect:build /results/fake-hwaddr/ /

ENV QEMU_ECAGENT_MEM_LIMIT=256

RUN busybox wget https://github.com/pgaskin/easy-novnc/releases/download/v1.1.0/easy-novnc_linux-64bit -O /usr/bin/easy-novnc &&\
    chmod +x /usr/bin/easy-novnc

#ENV TYPE="" PASSWORD="" LOOP=""
#ENV DISPLAY
#ENV USE_NOVNC=""

VOLUME /root/ /usr/share/sangfor/EasyConnect/resources/logs/

CMD ["start.sh"]
