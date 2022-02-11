#!/bin/bash
# 设置策略路由使宿主机外的机器能够访问容器提供的服务
## 将路由表 main 备份到路由表 2
(
ip route flush table 2
IFS="
"
for i in $(ip route show); do IFS=' '; ip route add $i table 2 ; done
)
## 确定策略路由方式
ip rule add iif lo table 2 sport 1080
if ip rule show iif lo table 2 | grep sport >/dev/null ; then
	open_port() { ip rule add iif lo table 2 sport $1; }
	close_port() { ip rule del iif lo table 2 sport $1; }
elif iptables -t mangle -A OUTPUT -j MARK --set-mark 1 -p tcp --sport 1080 2>/dev/null ; then
	iptables -t mangle -D OUTPUT -j MARK --set-mark 1 -p tcp --sport 1080
	ip rule add fwmark 1 table 2
	open_port() { iptables -t mangle -I OUTPUT -j MARK --set-mark 1 -p tcp --sport $1; }
	close_port() { iptables -t mangle -D OUTPUT -j MARK --set-mark 1 -p tcp --sport $1; }
else
	open_port() { true; }
	close_port() { true; }
	echo "Can't find available method to automatically set route for opening ports"\
	     "(refer to https://github.com/Hagb/docker-easyconnect/tree/master/doc/route.md)" >&2

fi
ip rule del iif lo sport 1080 table 2

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
