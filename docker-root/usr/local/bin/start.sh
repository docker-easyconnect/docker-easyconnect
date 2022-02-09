#!/bin/bash

[ -n "$CHECK_SYSTEM_ONLY" ] && detect-tun.sh
detect-iptables.sh
. "$(which detect-route.sh)"
[ -n "$CHECK_SYSTEM_ONLY" ] && exit

cp /etc/danted.conf.sample /tmp/danted.conf
externals=""
for iface in $({ ip -f inet -o addr; ip -f inet6 -o addr; } | sed -E 's/^[0-9]+: ([^ ]+) .*/\1/'); do
	externals="${externals}external: $iface\\n"
done
sed s/^#external-lines/"$externals"/ -i /tmp/danted.conf
# 在虚拟网络设备 tun0 打开时运行 danted 代理服务器
[ -n "$NODANTED" ] || (while true
do
sleep 5
[ -d /sys/class/net/tun0 ] && {
	chmod a+w /tmp
	open_port 1080
	su daemon -s /usr/sbin/danted -f /tmp/danted.conf
	close_port 1080
}
done
)&
open_port 8888
tinyproxy -c /etc/tinyproxy.conf

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE

# 拒绝 tun0 侧主动请求的连接.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i tun0 -p tcp -j DROP

# 删除深信服可能生成的一条 iptables 规则，防止其丢弃传出到宿主机的连接
# 感谢 @stingshen https://github.com/Hagb/docker-easyconnect/issues/6
# ( while true; do sleep 5 ; iptables -D SANGFOR_VIRTUAL -j DROP 2>/dev/null ; done )&

if [ -n "$_EC_CLI" ]; then
	ln -s /usr/share/sangfor/EasyConnect/resources/{conf_${EC_VER},conf}
	exec start-sangfor.sh
fi

[ -n "$EXIT" ] && MAX_RETRY=0

# 登录信息持久化处理
## 持久化配置文件夹 感谢 @hexid26 https://github.com/Hagb/docker-easyconnect/issues/21
[ -d ~/conf ] || cp -a /usr/share/sangfor/EasyConnect/resources/conf_backup ~/conf
[ -e ~/easy_connect.json ] && mv ~/easy_connect.json ~/conf/easy_connect.json # 向下兼容
## 默认使用英语：感谢 @forest0 https://github.com/Hagb/docker-easyconnect/issues/2#issuecomment-658205504
[ -e ~/conf/easy_connect.json ] || echo '{"language": "en_US"}' > ~/conf/easy_connect.json

export DISPLAY

if [ "$TYPE" != "X11" -a "$TYPE" != "x11" ]
then
	# container 再次运行时清除 /tmp 中的锁，使 container 能够反复使用。
	# 感谢 @skychan https://github.com/Hagb/docker-easyconnect/issues/4#issuecomment-660842149
	rm -rf /tmp
	mkdir /tmp

	# $PASSWORD 不为空时，更新 vnc 密码
	[ -e ~/.vnc/passwd ] || (mkdir -p ~/.vnc && (echo password | tigervncpasswd -f > ~/.vnc/passwd)) 
	[ -n "$PASSWORD" ] && printf %s "$PASSWORD" | tigervncpasswd -f > ~/.vnc/passwd

	open_port 5901
	tigervncserver :1 -geometry 800x600 -localhost no -passwd ~/.vnc/passwd -xstartup flwm
	DISPLAY=:1

	# 将 easyconnect 的密码放入粘贴板中，应对密码复杂且无法保存的情况 (eg: 需要短信验证登录)
	# 感谢 @yakumioto https://github.com/Hagb/docker-easyconnect/pull/8
	echo "$ECPASSWORD" | DISPLAY=:1 xclip -selection c
fi

exec start-sangfor.sh
