# 路由和开放端口说明

## TL;DR

用 docker 向外开放了端口时，EasyConnect 设置的路由表可能会使开放端口无法被宿主机外的设备直接访问。为了使这些开放端口可被其他设备访问，需要设置恰当的路由策略。（如无此需求可忽略）

宿主机应满足以下条件的至少一条：

- Linux 内核版本不小于 `4.17-rc1`。内核版本可通过 `uname -r` 获取。
- 使用 [`nftables`](https://netfilter.org/projects/nftables/)。可通过 `sudo iptables -V | grep nf_tables` 输出是否为空来判断（非空则表明在使用 `nftables`）。
- `iptable_mangle` 和 `xt_mark` 模块被编译进内核或作为模块加载加载。

可通过以下命令来快速检查（其中 `TAG` 替换成实际使用的 tag）
``` bash
docker run --cap-add NET_ADMIN -e DETECT_ROUTE_ONLY=1 hagb/docker-easyconnect:TAG
```

若输出 `Can't find available method to automatically set route for opening ports (refer to https://github.com/Hagb/docker-easyconnect/tree/master/doc/ports.md)` 字样的报错，则说明不满足以上条件。

群辉系统可通过加载 `iptable_mangle` 和 `xt_mark` 模块来解决：
```bash
sudo insmod /lib/modules/iptable_mangle.ko
sudo insmod /lib/modules/xt_mark.ko
```
