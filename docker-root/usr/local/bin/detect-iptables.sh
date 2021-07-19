#!/bin/bash
# 不支持 nftables 时使用 iptables-legacy
## 感谢 @BoringCat https://github.com/Hagb/docker-easyconnect/issues/5
if { [ -z "$IPTABLES_LEGACY" -a -z "$(iptables-legacy-save)" ] && iptables-nft-save ; } 1>/dev/null 2>/dev/null
then
	update-alternatives --set iptables /usr/sbin/iptables-nft
	update-alternatives --set ip6tables /usr/sbin/ip6tables-nft
else
	update-alternatives --set iptables /usr/sbin/iptables-legacy
	update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
fi

