# docker-easyconnect

让深信服开发的**非自由**的 EasyConnect 代理软件运行在 docker 中，并开放 Socks5 供宿主机连接以使用代理。

## Status

### 已经过测试的版本

`7.6.3.0.86415`版.

其它 TODO...

## Build

```
wget http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb -O docker-files/EasyConnect.deb
docker image build . --tag easyconnect
```

## Usage

**参数里的`--device /dev/net/tun --cap-add NET_ADMIN`是不可少的。** 因为 EasyConnect 要创建虚拟网络设备`tun0`。

### 环境变量

`TYPE`: 有以下两种取值

- `vnc`（默认值）: 将在`5901`端口开放 vnc 服务以操作 EasyConnect 前端。

- `x11`: 将直接通过`DISPLAY`环境变量的值显示 EasyConnect 前端，请同时设置`DISPLAY`环境变量。这个可能更适合于桌面用户。

`DISPLAY`: `$TYPE`为`x11`时通过该变量来现实 EasyConnect 界面。

`PASSWORD`: 用于 vnc 服务的密码，该变量的值默认为空字符串，表示密码不作改变。

给变量赋值（空字符串除外），密码（应小于或等于 8 位）就会被更新到所赋的值。

默认密码是`password`.

### Socks5

EasyConnect 创建`tun0`后，Socks5 代理会在容器的`1080`端口开启。这可用`-p`参数转发到`127.0.0.1`上。

### VNC 服务器

默认情况下，环境变量`TYPE`

### 配置、登陆信息持久化

只需要用`-v`参数将宿主机的目录挂载到容器的 /root 。

如`-v $HOME/.ecdata:/root`。

由此还能实现全自动登陆。

## 例子

### X11 socket

```
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/root/.Xauthority -e DISPLAY=$DISPLAY -e TYPE=x11 -v $HOME/.ecdata:/root -p 127.0.0.1:1080:1080 easyconnect
```

### vnc 

```
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 easyconnect
```

## 已知问题

vnc 下代理软件的图表上右键菜单会在第一次调出以后失灵，直到软件被关闭。

## 参考资料

登陆过程的一个 hack ([docker-files/start-sangfor.sh](docker-files/start-sangfor.sh))参考了这篇文章：<https://blog.51cto.com/13226459/2476193>。对作者表示感谢。

## 版权及许可证

> Copyright © 2020 Hagb (Guo Junyu) <hagb_green@qq.com>
> This work is free. You can redistribute it and/or modify it under the
> terms of the Do What The Fuck You Want To Public License, Version 2,
> as published by Sam Hocevar. See the COPYING file for more details.

可以对这份东西做任何事情。

>        DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
>                    Version 2, December 2004 
>
> Copyright (C) 2004 Sam Hocevar <sam@hocevar.net> 
>
> Everyone is permitted to copy and distribute verbatim or modified 
> copies of this license document, and changing it is allowed as long 
> as the name is changed. 
>
>            DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE 
>   TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION 
>
>  0. You just DO WHAT THE FUCK YOU WANT TO. 
