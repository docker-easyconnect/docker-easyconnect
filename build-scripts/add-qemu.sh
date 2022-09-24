#!/bin/sh
if is_echost_foreign; then
	dpkg --add-architecture $EC_HOST && qemu_pkgs="qemu-user libc6:$EC_HOST libstdc++6:$EC_HOST"
fi
