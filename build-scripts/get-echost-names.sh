#!/bin/sh
if [ -z "$EC_HOST" -o "$(dpkg --print-architecture)" = "$EC_HOST" ]; then
	ecgccpkg=build-essential
	ecprefix=
	ec_cc=gcc
	is_echost_foreign=
	is_echost_foreign() { false; }
else
	case "$EC_HOST" in
		i386 )
			ecqemu=qemu-i386
			ecgccpkg=crossbuild-essential-i386
			ecprefix=i386-linux-gnu ;;
		amd64 )
			ecqemu=qemu-x86_64
			ecgccpkg=crossbuild-essential-amd64
			ecprefix=x86_64-linux-gnu ;;
		armhf )
			ecqemu=qemu-arm
			ecgccpkg=crossbuild-essential-armhf
			ecprefix=arm-linux-gnueabihf ;;
		arm64 )
			ecqemu=qemu-aarch64
			ecgccpkg=crossbuild-essential-arm64
			ecprefix=aarch64-linux-gnu ;;
		mips64el )
			ecqemu=qemu-mips64el
			ecgccpkg=crossbuild-essential-mips64el
			ecprefix=mips64el-linux-gnuabi64 ;;
		* )
			echo "Unsupported platform ${EC_HOST}" >&2
			false ;;
	esac &&
	ec_cc=${ecprefix}-gcc &&
	is_echost_foreign=1 &&
	is_echost_foreign() { true; }
fi
