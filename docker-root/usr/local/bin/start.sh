#!/bin/bash

# 不支持 nftables 时使用 iptables-legacy
# 感谢 @BoringCat https://github.com/Hagb/docker-easyconnect/issues/5
if { iptables-nft -L 1>/dev/null 2>/dev/null ;}
then
	update-alternatives --set iptables /usr/sbin/iptables-nft
	update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
else
	update-alternatives --set iptables /usr/sbin/iptables-legacy
	update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
fi

# 在虚拟网络设备 tun0 打开时运行 proxy 代理服务器
[ -n "$NODANTED" ] || (while true
do
sleep 5
[ -d /sys/class/net/tun0 ] && danted
done
)&

# 登陆信息持久化处理
rm /usr/share/sangfor/EasyConnect/resources/conf/easy_connect.json
## 默认使用英语：感谢 @forest0 https://github.com/Hagb/docker-easyconnect/issues/2#issuecomment-658205504
[ -e ~/easy_connect.json ] || echo '{"language": "en_US"}' > ~/easy_connect.json
ln -s ~/easy_connect.json /usr/share/sangfor/EasyConnect/resources/conf/easy_connect.json

export DISPLAY

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

# 拒绝 tun0 侧主动请求的连接.
iptables -I INPUT -p tcp -j REJECT
iptables -I INPUT -i eth0 -p tcp -j ACCEPT
iptables -I INPUT -i lo -p tcp -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# issue#6
while true; do sleep 5 ; iptables -D SANGFOR_VIRTUAL -j DROP ; done

if [ "$TYPE" != "X11" -a "$TYPE" != "x11" ]
then
	# container 再次运行时清除 /tmp 中的锁，使 container 能够反复使用。
	# 感谢 @skychan https://github.com/Hagb/docker-easyconnect/issues/4#issuecomment-660842149
	rm -rf /tmp
	mkdir /tmp

	# $PASSWORD 不为空时，更新 vnc 密码
	[ -e ~/.vnc/passwd ] || (mkdir -p ~/.vnc && (echo password | tigervncpasswd -f > ~/.vnc/passwd)) 
	[ -n "$PASSWORD" ] && printf %s "$PASSWORD" | tigervncpasswd -f > ~/.vnc/passwd

	tigervncserver :1 -geometry 800x600 -localhost no -passwd ~/.vnc/passwd -xstartup flwm
	DISPLAY=:1
fi

exec start-sangfor.sh
