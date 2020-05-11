#!/bin/bash
/usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor
sleep 1
while true
do
	# 在 EasyConnect 前端启动过程中，会出现 cms client connect failed 的报错，此时应该启动 sslservice.sh。但这个脚本启动得太早也会没有作用……
	# 参考了 https://blog.51cto.com/13226459/2476193 ，在此对作者表示感谢。
	[ $(jobs |wc -l) -eq 0 ] &&
	       	(tail -n 0 -f /usr/share/sangfor/EasyConnect/resources/logs/ECAgent.log | grep "\\[Register\\]cms client connect failed" -m 1
		/usr/share/sangfor/EasyConnect/resources/shell/sslservice.sh
		)&
	
	# 下面这行代码启动 EasyConnect 的前端。
	/usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu

	# 清除的残余进程，它们可能会妨碍下次的启动。
	killall CSClient svpnservice
	sleep 4

	# 只要杀不死，就往死里杀
	pidof CSClient && killall -9 CSClient
       	pidof svpnservice && killall svpnservice -9
done
