#!/bin/bash
# 确保 tun 可用
# https://github.com/Hagb/docker-easyconnect/issues/59
if ! ip tuntap add mode tun tun0 ; then
	echo 'Failed to operate tun device! Please check whether /dev/net/tun is available.' >&2
	exit 1
fi
