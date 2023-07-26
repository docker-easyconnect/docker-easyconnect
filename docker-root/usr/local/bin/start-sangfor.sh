#!/bin/bash
eval "$(vpn-config.sh)"
fake-hwaddr-run() { "$@" ; }
if [ -n "$FAKE_HWADDR" ]; then
	fake-hwaddr-run() { LD_PRELOAD=/usr/local/lib/fake-hwaddr.so "$@" ; }
fi

while true
do
	vpn_daemon
	vpn_ui

	[ -n "$MAX_RETRY" ] && ((MAX_RETRY--))

	LOCK_FILE="/tmp/EXIT_LOCK"

	# 等待后端服务结束
	[ -n "$EXIT_LOCK" ] && touch "$LOCK_FILE" && {
		printf "\n\n\n当前前端服务已退出, 由于EXIT_LOCK设置, 暂不执行重启. 执行重启请执行:\n\ndocker exec -it %s rm -f %s\n\n" "$HOSTNAME" "$LOCK_FILE"
		echo "等待中"
		while :
		do
			sleep 1
			echo -e '\e[1A\e[K等待中.'
			sleep 1
			echo -e '\e[1A\e[K等待中..'
			sleep 1
			echo -e '\e[1A\e[K等待中...'
			[ ! -e "$LOCK_FILE" ] && break
		done
	}

	# 自动重连
	((MAX_RETRY<0)) && exit

	# 清除的残余进程，它们可能会妨碍下次的启动。
	killall $VPN_PROCS 2> /dev/null
	sleep 4

	# 只要杀不死，就往死里杀
	killall -9 $VPN_PROCS 2> /dev/null
done
