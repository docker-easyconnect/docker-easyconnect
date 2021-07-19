# 开放端口的路由

用 docker 向外开放了端口时，EasyConnect 设置的路由表可能会使开放端口无法被宿主机外的设备直接访问。为了使这些开放端口可被其他设备访问，需要设置恰当的路由策略。（如无此需求可忽略）

可通过在宿主机或容器处设置 iptables 和路由来解决此问题。

## 在宿主机处解决

将传入连接的源地址转换成宿主机地址：

``` bash
iptables -I POSTROUTING -d 容器ip地址 -p tcp -m tcp --dport 容器侧端口号 -j MASQUERADE -t nat
```

其中容器 ip 地址可通过以下命令获得：

```bash
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 容器名
```

## 在容器处解决

宿主机需满足以下条件之一，容器即可自动设置路由策略

- Linux 内核版本不小于 `4.17-rc1`。内核版本可通过 `uname -r` 获取。
- 使用 [`nftables`](https://netfilter.org/projects/nftables/)。可通过在宿主机运行 `sudo iptables -V | grep nf_tables` 的输出是否为空来判断（非空则表明在使用 `nftables`）。
- `iptable_mangle` 和 `xt_mark` 模块被编译进内核或作为模块加载加载。

运行容器时若输出 `Can't find available method to automatically set route for opening ports (refer to https://github.com/Hagb/docker-easyconnect/tree/master/doc/ports.md)` 字样的报错，则说明不满足以上条件。

群辉系统可通过宿主机加载 `iptable_mangle` 和 `xt_mark` 模块来解决：
```bash
sudo insmod /lib/modules/iptable_mangle.ko
sudo insmod /lib/modules/xt_mark.ko
```

其他发行版可尝试
```bash
sudo modprobe iptable_mangle
sudo modprobe xt_mark
```

