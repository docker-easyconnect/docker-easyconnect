#!/bin/bash
fake-hwaddr-run() { "$@" ; }
[ -n "$FAKE_HWADDR" ] && fake-hwaddr-run() { LD_PRELOAD=/usr/local/lib/fake-hwaddr.so "$@" ; }
[ -z "$_EC_CLI" ] && /usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor
sleep 1
while true
do
	if [ -z "$_EC_CLI" ]; then
		# 在 EasyConnect 前端启动过程中，会出现 cms client connect failed 的报错，此时应该启动 sslservice.sh。但这个脚本启动得太早也会没有作用……
		# 参考了 https://blog.51cto.com/13226459/2476193 ，在此对作者表示感谢。
		{
			tail -n 0 -f /usr/share/sangfor/EasyConnect/resources/logs/ECAgent.log | grep "\\[Register\\]cms client connect failed" -m 1
			fake-hwaddr-run /usr/share/sangfor/EasyConnect/resources/shell/sslservice.sh
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
	killall CSClient svpnservice 2> /dev/null
	kill %1 %2 2> /dev/null
	sleep 4

	# 只要杀不死，就往死里杀
	killall -9 CSClient svpnservice 2> /dev/null
done
