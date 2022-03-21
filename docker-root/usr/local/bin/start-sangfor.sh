#!/bin/bash
fake-hwaddr-run() { "$@" ; }
qemu_args=""
if [ -n "$FAKE_HWADDR" ]; then
	if [ "$(dpkg --print-architecture)" = "amd64" ]; then
		fake-hwaddr-run() { LD_PRELOAD=/usr/local/lib/fake-hwaddr.so "$@" ; }
	else
		fake-hwaddr-run() { qemu_args="-E LD_PRELOAD=/usr/local/lib/fake-hwaddr.so" "$@" ; }
	fi
fi
[ -z "$_EC_CLI" ] && /usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor

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
	if [ -z "$_EC_CLI" ]; then
		# 在 EasyConnect 前端启动过程中，会出现 cms client connect failed 的报错，此时应该启动 sslservice.sh。但这个脚本启动得太早也会没有作用……
		# 参考了 https://blog.51cto.com/13226459/2476193 ，在此对作者表示感谢。
		{
			tail -n 0 -f /usr/share/sangfor/EasyConnect/resources/logs/ECAgent.log | grep "\\[Register\\]cms client connect failed" -m 1
			/usr/share/sangfor/EasyConnect/resources/shell/sslservice.sh
		} &

		# 下面这行代码启动 EasyConnect 的前端。
		fake-hwaddr-run /usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu
	else
		fake-hwaddr-run /usr/share/sangfor/EasyConnect/resources/bin/ECAgent &
		sleep 1
		fake-hwaddr-run easyconn login -t autologin
		pidof svpnservice > /dev/null || fake-hwaddr-run bash -c "exec easyconn login $CLI_OPTS"
		# # 重启一下 tinyproxy
		# service tinyproxy restart
		while pidof svpnservice > /dev/null ; do
		       sleep 1
		done
		echo svpn stop!
	fi

	[ -n "$MAX_RETRY" ] && ((MAX_RETRY--))

	# 自动重连
	((MAX_RETRY<0)) && exit

	# 清除的残余进程，它们可能会妨碍下次的启动。
	killall CSClient svpnservice 2> /dev/null
	kill %1 %2 2> /dev/null
	sleep 4

	# 只要杀不死，就往死里杀
	killall -9 CSClient svpnservice 2> /dev/null
done
