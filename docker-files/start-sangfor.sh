#!/bin/bash
/usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor
sleep 1
while true
do
	# 在 EasyConnect 前端启动过程中，会出现 cms client connect failed 的报错，此时应该启动 sslservice.sh。但这个脚本启动得太早也会没有作用……
	[ $(jobs |wc -l) -eq 0 ] &&
	       	(tail -n 0 -f /usr/share/sangfor/EasyConnect/resources/logs/ECAgent.log | grep "\\[Register\\]cms client connect failed" -m 1
		/usr/share/sangfor/EasyConnect/resources/shell/sslservice.sh
		)&
	
	sleep 1
	# 下面这行就是 EasyConnect 的前端了。
	/usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu
	# 清除的残余进程，它们可能会妨碍下次的启动。
	killall CSClient svpnservice
	sleep 4
	# 只要杀不死，就往死里杀（逃……）
	killall CSClient svpnservice -9
	sleep 1
done
