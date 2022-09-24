#!/bin/sh
if [ -n "${ANDROID_PATCH}" ]; then
	groupadd -g 3003 inet && usermod -a -G inet root && usermod -g inet -ou 0 daemon && usermod -g inet -ou 0 _apt
fi &&
if [ "${BUILD_ENV}" = "local" ]; then
	if [ -n "$MIRROR_URL" ]; then
		origin="$(cat /etc/apt/sources.list)"
		default_mirror=http://deb.debian.org/debian
		replaced="$(origin=$origin default_mirror=$default_mirror bash -c 'echo "${origin//$default_mirror /$MIRROR_URL }"')"
		printf %s "$replaced" > /etc/apt/sources.list
	fi
else
	echo "Warning: The BUILD_ENV build argument has been deprecated and will be removed. Please use MIRROR_URL instead." >&2
fi
