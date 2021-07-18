#!/bin/bash
# 确保 tun 可用 https://github.com/Hagb/docker-easyconnect/issues/59
ip tuntap add mode tun tun0 && ip tuntap del mode tun tun0 || \
	echo 'Failed to operate tun device! Please check whether /dev/net/tun is available.' >&2
