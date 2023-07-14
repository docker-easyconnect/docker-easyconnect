#!/bin/bash
# 设置策略路由使宿主机外的机器能够访问容器提供的服务
## 将路由表 main 备份到路由表 2
(
ip route flush table 2
IFS="
"
for i in $(ip route show); do IFS=' '; ip route add $i table 2 ; done
)
## 回包路由
ip rule add iif $VPN_TUN table 2
## 确定策略路由方式
ip rule add iif lo table 2 sport 1080
if ip rule show iif lo table 2 | grep sport >/dev/null ; then
	echo 'open_port() { ip rule add iif lo table 2 sport $1; }'
	echo 'close_port() { ip rule del iif lo table 2 sport $1; }'
elif iptables -t mangle -A OUTPUT -j MARK --set-mark 1 -p tcp --sport 1080 2>/dev/null ; then
	iptables -t mangle -D OUTPUT -j MARK --set-mark 1 -p tcp --sport 1080
	ip rule add fwmark 1 table 2
	echo 'open_port() { iptables -t mangle -I OUTPUT -j MARK --set-mark 1 -p tcp --sport $1; }'
	echo 'close_port() { iptables -t mangle -D OUTPUT -j MARK --set-mark 1 -p tcp --sport $1; }'
else
	echo 'open_port() { true; }'
	echo 'close_port() { true; }'
	echo "Can't find available method to automatically set route for opening ports"\
	     "(refer to https://github.com/Hagb/docker-easyconnect/tree/master/doc/route.md)" >&2

fi
ip rule del iif lo sport 1080 table 2

