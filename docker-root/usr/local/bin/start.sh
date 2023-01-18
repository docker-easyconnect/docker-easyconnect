#!/bin/bash

[ -n "$CHECK_SYSTEM_ONLY" ] && detect-tun.sh
eval "$(detect-iptables.sh)"
eval "$(detect-route.sh)"
[ -n "$CHECK_SYSTEM_ONLY" ] && exit

if [ -n "$FORWARD" ]; then
	if iptables -t mangle -A PREROUTING -m addrtype --dst-type LOCAL -j MARK --set-mark 2; then
		iptables -t mangle -D PREROUTING -m addrtype --dst-type LOCAL -j MARK --set-mark 2
		iptables -t nat -A POSTROUTING -p tcp -m mark --mark 2 -j MASQUERADE
		ip rule add fwmark 2 table 2
		format_error() { echo Format error in \""$rule"\": "$@" >&2 ; }
		for rule in $FORWARD; do
			array=(${rule//:/ })
			case ${#array[@]} in
				3) src_args="" ;;
				4) src_args="-s ${array[0]}" ;;
				*) format_error; continue ;;
			esac
			dst=${array[-2]}:${array[-1]}
			dport=${array[-3]}
			match_args="$src_args --dport $dport -m addrtype --dst-type LOCAL -i tun0"
			iptables -t mangle -A PREROUTING -p tcp $match_args -j MARK --set-mark 2
			iptables -t mangle -A PREROUTING -p udp $match_args -j MARK --set-mark 2
			iptables -t nat -A PREROUTING -p tcp $match_args -j DNAT --to-destination $dst
			iptables -t nat -A PREROUTING -p udp $match_args -j DNAT --to-destination $dst

		done
	else
		echo "Can't append iptables used to forward ports from EasyConnect to host network!" >&2
	fi
fi

cp /etc/danted.conf.sample /run/danted.conf

if [[ -n "$SOCKS_PASSWD" && -n "$SOCKS_USER" ]];then
	id $SOCKS_USER &> /dev/null
	if [ $? -ne 0 ]; then
		useradd $SOCKS_USER
	fi

	echo $SOCKS_USER:$SOCKS_PASSWD | chpasswd
	sed -i 's/socksmethod: none/socksmethod: username/g' /run/danted.conf

	echo "use socks5 auth: $SOCKS_USER:$SOCKS_PASSWD"
fi

internals=""
externals=""
for iface in $(ip -o addr | sed -E 's/^[0-9]+: ([^ ]+) .*/\1/' | sort | uniq | grep -v "lo\|sit\|vir"); do
        internals="${internals}internal: $iface port = 1080\\n"
        externals="${externals}external: $iface\\n"
done
sed /^internal:/c"$internals" -i /run/danted.conf
sed /^external:/a"$externals" -i /run/danted.conf
# 在虚拟网络设备 tun0 打开时运行 danted 代理服务器
[ -n "$NODANTED" ] || (while true
do
sleep 5
open_port 1080
[ -d /sys/class/net/tun0 ] && {
	chmod a+w /tmp
	/usr/sbin/danted -f /run/danted.conf
}
done
)&
open_port 8888
tinyproxy -c /etc/tinyproxy.conf

iptables -t nat -A POSTROUTING -o tun0 -j MASQUERADE
open_port 4440
iptables -t nat -N SANGFOR_OUTPUT
iptables -t nat -A PREROUTING -j SANGFOR_OUTPUT

# 拒绝 tun0 侧主动请求的连接.
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i tun0 -p tcp -j DROP

# 删除深信服可能生成的一条 iptables 规则，防止其丢弃传出到宿主机的连接
# 感谢 @stingshen https://github.com/Hagb/docker-easyconnect/issues/6
# ( while true; do sleep 5 ; iptables -D SANGFOR_VIRTUAL -j DROP 2>/dev/null ; done )&


[ -n "$EXIT" ] && export MAX_RETRY=0

if [ -n "$_EC_CLI" ]; then
	ln -fs /usr/share/sangfor/EasyConnect/resources/{conf_${EC_VER},conf}
	exec start-sangfor.sh
fi

# 登录信息持久化处理
## 持久化配置文件夹 感谢 @hexid26 https://github.com/Hagb/docker-easyconnect/issues/21
[ -d ~/conf ] || cp -a /usr/share/sangfor/EasyConnect/resources/conf_backup ~/conf
[ -e ~/easy_connect.json ] && mv ~/easy_connect.json ~/conf/easy_connect.json # 向下兼容
## 默认使用英语：感谢 @forest0 https://github.com/Hagb/docker-easyconnect/issues/2#issuecomment-658205504
## 使 7.6.7 上系统被识别为 Linux：https://github.com/Hagb/docker-easyconnect/issues/174
[ -e ~/conf/easy_connect.json ] ||
	echo '{"version" : "0.0.2","language": "en_US","build_type": "release","sys_type": "linux"}' > ~/conf/easy_connect.json

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

	# 环境变量USE_NOVNC不为空时，启动 easy-novnc
	if [ -n "$USE_NOVNC" ]; then
		open_port 8080
		novnc
	fi
fi

exec start-sangfor.sh
