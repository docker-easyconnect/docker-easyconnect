#!/bin/sh
. /etc/os-release &&
if [ -n "${ANDROID_PATCH}" ]; then
	groupadd -g 3003 inet && usermod -a -G inet root && usermod -g inet -ou 0 daemon && usermod -g inet -ou 0 _apt
fi &&
# use qemu-user >= 8.0.0 which fixes https://gitlab.com/qemu-project/qemu/-/issues/866
echo "\
Package: *
Pin: release n=trixie
Pin-Priority: 1

Package: qemu-user
Pin: release n=trixie
Pin-Priority: 990" > /etc/apt/preferences.d/qemu &&
echo "deb $MIRROR_URL trixie main
deb $MIRROR_URL $VERSION_CODENAME main
deb http://deb.debian.org/debian-security $VERSION_CODENAME-security main
deb $MIRROR_URL bullseye main
deb http://deb.debian.org/debian-security bullseye-security main
" > /etc/apt/sources.list &&
rm -rf /etc/apt/sources.list.d
