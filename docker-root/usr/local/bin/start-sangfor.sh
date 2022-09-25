#!/bin/bash
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
	rm -f /usr/share/sangfor/EasyConnect/resources/conf/ECDomainFile
	if [ -z "$_EC_CLI" ]; then
		# 在 EasyConnect 前端启动过程中，会出现 cms client connect failed 的报错，此时应该启动 sslservice.sh。但这个脚本启动得太早也会没有作用。
		# (来自 https://blog.51cto.com/13226459/2476193 的线索，感谢文章作者)
		# 进一步研究发现此时应启动 svpnservice 和 CSClient 两个程序
		{
			fake-hwaddr-run /usr/share/sangfor/EasyConnect/resources/bin/ECAgent
			kill $!
		} > >(
				grep '\[Register\]cms client connect failed|ECDomainFile domain socket connect failed' -Em 1 --line-buffered || break
				killall -9 svpnservice CSClient
				# 在某些性能不佳的设备上（尤其是如果使用了 qemu-user 来模拟运行其他架构的 EasyConnect），CSClient 和 svpnservice 启动较慢，
				# 此时有可能 CSClient 启动完成前 ECAgent 就会等待超时、登录失败，因此启动 CSClient 前先将 ECAgent 休眠（发送 STOP 信号），
				# CSClient 启动完成（以 fifo 文件 ECDomainFile 存在为标志）后再解除 ECAgent 休眠（发送 CONT 信号）
				killall -STOP ECAgent
				fake-hwaddr-run /usr/share/sangfor/EasyConnect/resources/bin/svpnservice -h /usr/share/sangfor/EasyConnect/resources &
				fake-hwaddr-run /usr/share/sangfor/EasyConnect/resources/bin/CSClient &
				wait
				until [ -e /usr/share/sangfor/EasyConnect/resources/conf/ECDomainFile ]; do
					sleep 0.1
				done
				killall -CONT ECAgent
				exec cat >/dev/null
			) &

		# 下面这行代码启动 EasyConnect 的前端。
		/usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu
	else
		fake-hwaddr-run /usr/share/sangfor/EasyConnect/resources/bin/ECAgent &
		sleep 1
		fake-hwaddr-run easyconn login -t autologin
		pidof svpnservice > /dev/null || bash -c "exec easyconn login $CLI_OPTS"
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
	killall CSClient svpnservice ECAgent 2> /dev/null
	sleep 4

	# 只要杀不死，就往死里杀
	killall -9 CSClient svpnservice ECAgent 2> /dev/null
done
