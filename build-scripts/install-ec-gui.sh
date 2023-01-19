#!/bin/bash
cd /tmp &&
. ./build-scripts/get-echost-names.sh &&
if [ -z "${EC_DEB_PATH}" ]; then
	busybox wget "${EC_URL}" -O EasyConnect.deb
else
	busybox wget "${EC_URL}" -O EasyConnect.zip &&
	busybox unzip -p EasyConnect.zip "${EC_DEB_PATH}" > EasyConnect.deb &&
	rm EasyConnect.zip
fi &&
if is_echost_foreign; then
	dpkg-deb -R EasyConnect.deb / &&
	/DEBIAN/postinst &&
	rm -r /DEBIAN &&
	extra_bins=EasyMonitor ./build-scripts/mk-qemu-wrapper.sh
else
	dpkg -i EasyConnect.deb
fi &&
rm EasyConnect.deb &&

rm -f /usr/share/sangfor/EasyConnect/resources/conf/easy_connect.json &&
mv /usr/share/sangfor/EasyConnect/resources/conf/ /usr/share/sangfor/EasyConnect/resources/conf_backup &&

if ! is_echost_foreign &&  [ ! -z "${USE_EC_ELECTRON}" ] ; then
	exit 0
fi &&

declare -A ELECTRON_URLS &&

# v1.8 以下的 electron 无官方 arm64、mips64el 构建
# armhf 在 v1.8.2-beta4 到 v1.8.8 无法渲染：https://github.com/electron/electron/issues/11797
ELECTRON_URLS=(
	[amd64]=https://github.com/electron/electron/releases/download/v1.8.8/electron-v1.8.8-linux-x64.zip
	[i386]=https://github.com/electron/electron/releases/download/v1.8.8/electron-v1.8.8-linux-ia32.zip
	[armhf]=https://github.com/electron/electron/releases/download/v1.7.16/electron-v1.7.16-linux-armv7l.zip
	[arm64]=https://github.com/electron/electron/releases/download/v1.8.8/electron-v1.8.8-linux-arm64.zip
	[mips64el]=https://github.com/electron/electron/releases/download/v1.8.8/electron-v1.8.8-linux-mips64el.zip
) &&
if [ -z "${ELECTRON_URL}" ]; then
	ELECTRON_URL="${ELECTRON_URLS[$(dpkg --print-architecture)]}"
fi &&
busybox wget "${ELECTRON_URL}" -O electron.zip &&
busybox unzip electron.zip -od /usr/share/sangfor/EasyConnect/ &&
rm electron.zip &&
mv /usr/share/sangfor/EasyConnect/{electron,EasyConnect}
