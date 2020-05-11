#!/bin/bash

# 在虚拟网络设备 tun0 打开时运行 proxy 代理服务器
(while true
do
sleep 5
[ -d /sys/class/net/tun0 ] && danted
done
)&

# 登陆信息持久化处理
rm /usr/share/sangfor/EasyConnect/resources/conf/easy_connect.json
touch ~/easy_connect.json
ln -s ~/easy_connect.json /usr/share/sangfor/EasyConnect/resources/conf/easy_connect.json

export DISPLAY

if [ "$TYPE" != "X11" -a "$TYPE" != "x11" ]
then
	# 安全起见 vnc 不能从 tun0 处访问
	iptables -I INPUT  -p tcp --dport 5901 -j REJECT
	iptables -I INPUT  -i eth0 -p tcp --dport 5901 -j ACCEPT
	iptables -I INPUT  -i lo -p tcp --dport 5901 -j ACCEPT
	
	# $PASSWORD 不为空时，更新 vnc 密码
	[ -e ~/.vnc/passwd ] || (mkdir -p ~/.vnc && (echo password | tigervncpasswd -f > ~/.vnc/passwd)) 
	[ -n "$PASSWORD" ] && printf %s "$PASSWORD" | tigervncpasswd -f > ~/.vnc/passwd

	tigervncserver :1 -geometry 800x600 -localhost no -passwd ~/.vnc/passwd -xstartup flwm
	DISPLAY=:1
fi

exec start-sangfor.sh
