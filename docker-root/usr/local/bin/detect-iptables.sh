#!/bin/bash
# 不支持 nftables 时使用 iptables-legacy
## 感谢 @BoringCat https://github.com/Hagb/docker-easyconnect/issues/5
if {
	[ -z "$IPTABLES_LEGACY" -a -z "$(xtables-legacy-multi iptables-save)" ] &&
	xtables-nft-multi iptables-save &&
	xtables-nft-multi iptables -A INPUT -j ACCEPT &&
	xtables-nft-multi iptables -D INPUT -j ACCEPT; } 1>/dev/null 2>/dev/null
then
	iptables_type=nft
else
	iptables_type=legacy
fi
echo "$iptables_type" > /etc/iptables-type

for exec in /usr/sbin/iptables{-nft,-legacy,}{-save,-restore,}; do
	ln -fs /usr/sbin/xtables-echook-multi "$exec"
done

echo "export ECHACK_NOWARN=1"

