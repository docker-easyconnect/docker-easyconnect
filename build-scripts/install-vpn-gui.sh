#!/bin/bash
if [ "ATRUST" = "$VPN_TYPE" ]; then
	mv /usr/sbin/sysctl{,.real} &&
	ln -s /usr/sbin/sysctl{-hook,}
fi &&
echo "$VPN_TYPE" > /etc/vpn-type &&
cd /tmp &&
. ./build-scripts/get-echost-names.sh &&
if [ -z "${VPN_DEB_PATH}" ]; then
	busybox wget "${VPN_URL}" -O VPN.deb
else
	busybox wget "${VPN_URL}" -O VPN.zip &&
	busybox unzip -p VPN.zip "${VPN_DEB_PATH}" > VPN.deb &&
	rm VPN.zip
fi &&
dpkg-deb -R VPN.deb / &&
package_name=$(echo $(grep -Po '(?<=Package:).*' /DEBIAN/control)) &&
{ /DEBIAN/preinst || true ; } &&
mkdir /var/lib/dpkg/info/$package_name &&
for file in /DEBIAN/*; do
	cp "$file" /var/lib/dpkg/info/"$package_name.$(basename $file)" &&
	# workaround for aTrust scripts
	cp "$file" /var/lib/dpkg/info/"$(basename $file)"
done &&
/var/lib/dpkg/info/$package_name.postinst &&
for file in /DEBIAN/*; do
	rm /var/lib/dpkg/info/"$(basename $file)"
done &&
rm -r /DEBIAN VPN.deb &&
if [ -e /home/sangfor/ ]; then
	chown sangfor:sangfor -R /home/sangfor/
fi &&

ln -fs /bin/false /usr/sbin/dmidecode &&

if [ "EC_CLI" != "$VPN_TYPE" -a "EC_GUI" != "$VPN_TYPE" ]; then
	exit 0
fi &&

extra_bins=EasyMonitor ./build-scripts/mk-qemu-wrapper.sh &&

rm -f /usr/share/sangfor/EasyConnect/resources/conf/easy_connect.json &&
mv /usr/share/sangfor/EasyConnect/resources/conf/ /usr/share/sangfor/EasyConnect/resources/conf_backup &&

if ! is_echost_foreign &&  [ ! -z "${USE_VPN_ELECTRON}" ] ; then
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
