#!/bin/bash
[ -z "$_EC_CLI" ] && /usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor
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
		/usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu
	else
		/usr/share/sangfor/EasyConnect/resources/bin/ECAgent > /dev/null 2> /dev/null  & sleep 1 &
		[ -n "$NO_HEARTBEAT" ] && {
			tail -n 0 -f /usr/share/sangfor/EasyConnect/resources/logs/ECAgent.log | grep "<Type>HEARTBEAT</Type>" -m 1 > /dev/null
			busybox killall ECAgent
		} &
		easyconn login
		while pidof svpnservice > /dev/null ; do
		       sleep 1
		done
		echo svpn stop!
	fi

	# 是否自动重启
	[ -n "$EXIT" ] && exit

	# 清除的残余进程，它们可能会妨碍下次的启动。
	killall CSClient svpnservice 2> /dev/null
	kill %1 %2 2> /dev/null
	sleep 4

	# 只要杀不死，就往死里杀
	killall -9 CSClient svpnservice 2> /dev/null
done
