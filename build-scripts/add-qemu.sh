#!/bin/sh
if [ "$(dpkg --print-architecture)" != "amd64" ]; then
	dpkg --add-architecture amd64 && extra_pkg="qemu-user libc6:amd64 libstdc++6:amd64"
fi
