#!/bin/bash

# 不支持 nftables 时使用 iptables-legacy
# 感谢 @BoringCat https://github.com/Hagb/docker-easyconnect/issues/5
if { [ -z "$IPTABLES_LEGACY" ] && iptables-nft -L 1>/dev/null 2>/dev/null ;}
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

# https://github.com/Hagb/docker-easyconnect/issues/20
# https://serverfault.com/questions/302936/configuring-route-to-use-the-same-interface-for-outbound-traffic-as-that-of-inbo
iptables -t mangle -I OUTPUT -m state --state ESTABLISHED,RELATED -j CONNMARK --restore-mark
iptables -t mangle -I PREROUTING -m connmark ! --mark 0 -j CONNMARK --save-mark
iptables -t mangle -I PREROUTING -m connmark --mark 1 -j MARK --set-mark 1
iptables -t mangle -I PREROUTING -i eth0 -j CONNMARK --set-mark 1
(
IFS="
"
for i in $(ip route show); do
	IFS=' '
	ip route add $i table 2
done
ip rule add fwmark 1 table 2
)

# 登陆信息持久化处理
## 持久化配置文件夹 感谢 @hexid26 https://github.com/Hagb/docker-easyconnect/issues/21
[ -d ~/conf ] || cp -a /usr/share/sangfor/EasyConnect/resources/conf_backup ~/conf
[ -e ~/easy_connect.json ] && mv ~/easy_connect.json ~/conf/easy_connect.json # 向下兼容
## 默认使用英语：感谢 @forest0 https://github.com/Hagb/docker-easyconnect/issues/2#issuecomment-658205504
[ -e ~/conf/easy_connect.json ] || echo '{"language": "en_US"}' > ~/conf/easy_connect.json

export DISPLAY

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

# 拒绝 tun0 侧主动请求的连接.
iptables -I INPUT -p tcp -j REJECT
iptables -I INPUT -i eth0 -p tcp -j ACCEPT
iptables -I INPUT -i lo -p tcp -j ACCEPT
iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# 删除深信服可能生成的一条 iptables 规则，防止其丢弃传出到宿主机的连接
# 感谢 @stingshen https://github.com/Hagb/docker-easyconnect/issues/6
( while true; do sleep 5 ; iptables -D SANGFOR_VIRTUAL -j DROP 2>/dev/null ; done )&

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

	# 将 easyconnect 的密码放入粘贴板中，应对密码复杂且无法保存的情况 (eg: 需要短信验证登陆)
	# 感谢 @yakumioto https://github.com/Hagb/docker-easyconnect/pull/8
	echo "$ECPASSWORD" | DISPLAY=:1 xclip -selection c
fi

exec start-sangfor.sh
