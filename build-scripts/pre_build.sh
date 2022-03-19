#!/bin/sh
if [ -n "${ANDROID_PATCH}" ]; then
	groupadd -g 3003 inet && usermod -a -G inet root && usermod -g inet -ou 0 daemon && usermod -g inet -ou 0 _apt
fi &&
/tmp/build-scripts/set-mirror.sh &&
extra_pkg='' &&
if [ "$(dpkg --print-architecture)" != "amd64" ]; then
	dpkg --add-architecture amd64 && extra_pkg="$extra_pkg_cross qemu-user libc6:amd64 libstdc++6:amd64"
fi
