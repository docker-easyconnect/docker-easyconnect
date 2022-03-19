#!/bin/bash
if [ "${BUILD_ENV}" = "local" ]; then
	if [ -n "$MIRROR_URL" ]; then
		origin="$(cat /etc/apt/sources.list)"
		default_mirror=http://deb.debian.org/debian
		replaced="${origin//$default_mirror/$MIRROR_URL}"
		printf %s "$replaced" > /etc/apt/sources.list
	fi
else
	echo "Warning: The BUILD_ENV build argument has been deprecated and will be removed. Please use MIRROR_URL instead." >&2
fi
