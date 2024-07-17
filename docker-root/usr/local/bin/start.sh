#!/bin/bash
eval "$(detect-iptables.sh)"
eval "$(detect-route.sh)"
eval "$(vpn-config.sh)"

forward_ports() {
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
				match_args="$src_args --dport $dport -m addrtype --dst-type LOCAL -i $VPN_TUN"
				iptables -t mangle -A PREROUTING -p tcp $match_args -j MARK --set-mark 2
				iptables -t mangle -A PREROUTING -p udp $match_args -j MARK --set-mark 2
				iptables -t nat -A PREROUTING -p tcp $match_args -j DNAT --to-destination $dst
				iptables -t nat -A PREROUTING -p udp $match_args -j DNAT --to-destination $dst

			done
		else
			echo "Can't append iptables used to forward ports from EasyConnect to host network!" >&2
		fi
	fi
}

start_danted() {
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
        ipv6=$(ip -6 a)
        if [[ $ipv6 ]]; then
                internals="internal: 0.0.0.0 port = 1080\\ninternal: :: port = 1080"
        else

                internals="internal: 0.0.0.0 port = 1080"
        fi
	for iface in $(ip -o addr | sed -E 's/^[0-9]+: ([^ ]+) .*/\1/' | sort | uniq | grep -v "sit\|vir"); do
		externals="${externals}external: $iface\\n"
	done
	externals="${externals}external: $VPN_TUN\\n"
	sed /^internal:/c"$internals" -i /run/danted.conf
	sed /^external:/c"$externals" -i /run/danted.conf
	open_port 1080
	if ip tuntap add mode tun $VPN_TUN; then
		# eth0 need >1s to be ready
		# refer to https://stackoverflow.com/questions/25226531/dante-sever-fail-to-bind-ip-by-interface-name-in-docker-container
		ip addr add 10.0.0.1/32 dev $VPN_TUN
		sleep 2
		/usr/sbin/danted -D -f /run/danted.conf
		ip tuntap del mode tun $VPN_TUN
	else
		echo 'Failed to create tun interface! Please check whether /dev/net/tun is available.' >&2
		echo 'Also refer to https://github.com/Hagb/docker-easyconnect/blob/master/doc/faq.md.' >&2
		exit 1
	fi
}

start_tinyproxy() {
	open_port 8888
	tinyproxy -c /etc/tinyproxy.conf
}

config_vpn_iptables() {
	iptables -t nat -A POSTROUTING -o $VPN_TUN -j MASQUERADE
	open_port 4440
	iptables -t nat -N SANGFOR_OUTPUT
	iptables -t nat -A PREROUTING -j SANGFOR_OUTPUT

	# 拒绝 tun 侧主动请求的连接.
	iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	iptables -A INPUT -i $VPN_TUN -p tcp -j DROP
}

force_open_ports() {
	# 暴露 54530 等用于和浏览器通讯的端口
	tmp_port=20000
	for port in $FORCE_OPEN_PORTS; do
		open_port $port
		open_port $tmp_port
		iptables -t nat -A PREROUTING -p tcp --dport $port -m addrtype --dst-type LOCAL -j REDIRECT --to-port $tmp_port
		socat tcp-listen:$tmp_port,reuseaddr,fork tcp4:127.0.0.1:$port &
		((tmp_port++))
	done
}

init_vpn_config() {
	if [ "EC_CLI" = "$_VPN_TYPE" ]; then
		ln -fs /usr/share/sangfor/EasyConnect/resources/{conf_${EC_VER},conf}
	fi

	if [ "EC_GUI" = "$_VPN_TYPE" ]; then
		# 登录信息持久化处理
		## 持久化配置文件夹 感谢 @hexid26 https://github.com/Hagb/docker-easyconnect/issues/21
		cp -r /usr/share/sangfor/EasyConnect/resources/conf_backup/. ~/conf/
		rm -f ~/conf/ECDomainFile
		[ -e ~/easy_connect.json ] && mv ~/easy_connect.json ~/conf/easy_connect.json # 向下兼容
		mkdir -p /usr/share/sangfor/EasyConnect/resources/conf/
		cd ~/conf/

		## 不再假定 /root 的文件系统（可能从宿主机挂载）支持 unix sock（用于 ECDomainFile），因此不直接使用
		for file in *; do
			## 通过软链接减小拷贝量
			ln -s ~/conf/"$file" /usr/share/sangfor/EasyConnect/resources/conf/"$file"
		done
		cd -
		[ -n "$DISABLE_PKG_VERSION_XML" ] && ln -fs /dev/null /usr/share/sangfor/EasyConnect/resources/conf/pkg_version.xml

		sync_ec2volume() {
			cd /usr/share/sangfor/EasyConnect/resources/conf/
			[ -n "$DISABLE_PKG_VERSION_XML" ] && rm pkg_version.xml
			for file in *; do
				[ -r "$file" -a ! -L "$file" -a "ECDomainFile" != "$file" ] && cp -r "$file" ~/conf/
			done
			cd ~/conf/
			for file in *; do
				[ ! -e /usr/share/sangfor/EasyConnect/resources/conf/"$file" ] && {
					rm -r "$file"
				}
			done
		}
		## 容器退出时将配置文件同步回 /root/conf。感谢 @Einskai 的点子
		trap "sync_ec2volume; exit;" SIGINT SIGQUIT SIGSTOP SIGTSTP SIGTERM
	else
		trap "exit;" SIGINT SIGQUIT SIGSTOP SIGTSTP SIGTERM
	fi
}

start_tigervncserver() {
	# $PASSWORD 不为空时，更新 vnc 密码
	[ -e ~/.vnc/passwd ] || (mkdir -p ~/.vnc && (echo password | tigervncpasswd -f > ~/.vnc/passwd)) 
	[ -n "$PASSWORD" ] && printf %s "$PASSWORD" | tigervncpasswd -f > ~/.vnc/passwd

	VNC_SIZE="${VNC_SIZE:-1110x620}"

	open_port 5901
	tigervncserver "$DISPLAY" -geometry "$VNC_SIZE" -localhost no -passwd ~/.vnc/passwd -xstartup flwm
	stalonetray -f 0 2> /dev/null &

	if [ -n "$ECPASSWORD" ]; then
		echo "ECPASSWORD has been deprecated, because of the confusion of its name." >&2
		echo "Use CLIP_TEXT instead." >&2
	fi

	[ -z "$CLIP_TEXT" ] && CLIP_TEXT="$ECPASSWORD"

	# 将 easyconnect 的密码放入粘贴板中，应对密码复杂且无法保存的情况 (eg: 需要短信验证登录)
	# 感谢 @yakumioto https://github.com/Hagb/docker-easyconnect/pull/8
	echo "$CLIP_TEXT" | DISPLAY=:1 xclip -selection c

	# 环境变量USE_NOVNC不为空时，启动 easy-novnc
	if [ -n "$USE_NOVNC" ]; then
		open_port 8080
		novnc
	fi

}

keep_pinging() {
	[ -n "$PING_ADDR" ] && while sleep $PING_INTERVAL; do
		busybox ping -c1 -W1 -w1 "$PING_ADDR" >/dev/null 2>/dev/null
	done &
}

# 部分服务器禁ping，用wget一个网页的url代替
keep_pinging_url() {
	[ -n "$PING_ADDR_URL" ] && while sleep $PING_INTERVAL; do
		timeout 10 busybox wget -q --spider "$PING_ADDR_URL" 2>/dev/null
	done &
}

# container 再次运行时清除 /tmp 中的锁，使 container 能够反复使用。
# 感谢 @skychan https://github.com/Hagb/docker-easyconnect/issues/4#issuecomment-660842149
for f in /tmp/* /tmp/.*; do
	[ "/tmp/.X11-unix" != "$f" ] && rm -rf -- "$f"
done

ulimit -n 1048576 # https://github.com/Hagb/docker-easyconnect/issues/245 @rikaunite
forward_ports &
start_danted &
start_tinyproxy &
config_vpn_iptables &
force_open_ports &
keep_pinging &
keep_pinging_url &
if [ -z "$DISPLAY" ]
then
	export DISPLAY=:1
	start_tigervncserver &
fi

init_vpn_config
wait

[ -n "$EXIT" ] && export MAX_RETRY=0
start-sangfor.sh &
wait $!

if [ "EC_GUI" = "$_VPN_TYPE" ]; then
	sync_ec2volume
fi
