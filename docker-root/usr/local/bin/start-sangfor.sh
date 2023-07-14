#!/bin/bash
eval "$(vpn-config.sh)"
fake-hwaddr-run() { "$@" ; }
if [ -n "$FAKE_HWADDR" ]; then
	fake-hwaddr-run() { LD_PRELOAD=/usr/local/lib/fake-hwaddr.so "$@" ; }
fi

# 对 qemu-user 内存泄漏 https://gitlab.com/qemu-project/qemu/-/issues/866 的一个 workaround
# 在 ECAgent 超过一定内存时杀掉它，经试验并不会对 vpn 服务造成很大影响
# https://github.com/Hagb/docker-easyconnect/issues/128#issuecomment-1074058067
[ -e /usr/local/libexec/qemu-hack ] && {
	page_size=$(getconf PAGESIZE)
	while true; do
		rss_pages=0
		for pid in $(pidof ECAgent); do
			statm=($(cat /proc/$pid/statm))
			((rss_pages+=statm[1]))
		done
		((rss_size_mb=rss_pages*page_size/1024/1024))
		if ((rss_size_mb>QEMU_ECAGENT_MEM_LIMIT)); then
			killall ECAgent
			echo "ECAgent spend memory $rss_size_mb MB > $QEMU_ECAGENT_MEM_LIMIT MB! Kill ECAgent!" >&2
		fi
		sleep 15
	done
} &

sleep 1

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
	killall CSClient svpnservice ECAgent 2> /dev/null
	sleep 4

	# 只要杀不死，就往死里杀
	killall -9 CSClient svpnservice ECAgent 2> /dev/null
done
