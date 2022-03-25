FROM debian:bookworm-slim

ARG ANDROID_PATCH BUILD_ENV=local MIRROR_URL=http://mirrors.aliyun.com/debian/

COPY ["./build-scripts/pre_build.sh", "./build-scripts/set-mirror.sh", "/tmp/build-scripts/"]

RUN extra_pkg_cross="libxss1 libgconf-2-4" . /tmp/build-scripts/pre_build.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends --no-install-suggests \
        libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 iptables xclip\
        dante-server tigervnc-standalone-server tigervnc-tools dante-server psmisc flwm x11-utils\
        busybox libssl-dev iproute2 tinyproxy-bin $extra_pkg && \
    rm -rf /var/lib/apt/lists/*

ARG EC_URL ELECTRON_URL

COPY ["./build-scripts/install-ec-gui.sh", "./build-scripts/mk-qemu-wrapper.sh", "/tmp/build-scripts/"]

RUN /tmp/build-scripts/install-ec-gui.sh

COPY ./docker-root /

COPY --from=compile ["fake-hwaddr/fake-hwaddr.so", "thread_reuse/build/libthread_reuse.so", "/usr/local/lib/"]

ENV QEMU_ECAGENT_MEM_LIMIT=256 QEMU_THREAD_REUSE=1

VOLUME /root/ /usr/share/sangfor/EasyConnect/resources/logs/

CMD ["start.sh"]
