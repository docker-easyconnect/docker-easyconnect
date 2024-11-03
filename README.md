# docker-easyconnect

让深信服开发的**非自由**的 VPN 软件 EasyConnect 或 aTrust 运行在 docker 中，提供 [socks5 和 http 代理](doc/usage.md#代理服务)服务和[网关](doc/usage.md#ip-forward)供宿主机连接使用。

本项目基于 EasyConnect 官方“Linux”版的 deb 包、[@shmille](https://github.com/shmilee) 提供的[命令行版客户端 deb 包](https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb)、aTrust 官方“Linux”版 deb 包，这些 deb 包的版权归深信服（Sangfor）所有，请不要滥用本项目。本项目**不是**深信服官方项目。

**招募项目维护者，有兴趣可在 [#275](https://github.com/docker-easyconnect/docker-easyconnect/issues/275) 下回复。**

欢迎批评、指正，提交 issue、PR，包括但不仅限于 bug、各种疑问、代码和文档的改进。

详细用法见于 [doc/usage.md](doc/usage.md)，常见问题见于 [doc/faq.md](doc/faq.md)，自行构建可参照构建说明 [doc/build.md](doc/build.md)。

## 简明使用步骤

使用下述方式登录后，可以通过 `127.0.0.1:1080`、`127.0.0.1:8888` 分别访问 [socks5 和 http 代理](doc/usage.md#代理服务)。

### 纯命令行版 EasyConnect（amd64 架构）

注意，纯命令行版本仅支持下列登录方式：用户名+密码、硬件特征码。

1. [安装Docker并运行](https://docs.docker.com/get-docker/)；
2.  在终端输入：
	``` bash
	docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -ti -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 -e EC_VER=7.6.3 -e CLI_OPTS="-d vpnaddress -u username -p password" hagb/docker-easyconnect:cli
	```
	其中 `-e EC_VER=7.6.7` 表示使用 `7.6.7` 版本的 EasyConnect，请根据实际情况修改版本号（选择 `7.6.7` 或 `7.6.3`，详见 [EasyConnect 版本选择](doc/usage.md#easyconnect-版本选择)）；
3. 根据提示输入服务器地址、登录凭据。

### 图形界面版 EasyConnect（x86、amd64、arm64、mips64el 架构）

1. [安装Docker并运行](https://docs.docker.com/get-docker/)；
2. 在终端输入： `docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -e URLWIN=1 -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 hagb/docker-easyconnect:7.6.7`（末尾 EasyConnect 版本号 `7.6.7` 请根据实际情况修改；arm64 和 mips64el 架构需要加入 `-e DISABLE_PKG_VERSION_XML=1` 参数）；
3. 使用vnc客户端连接vnc， 地址：`127.0.0.1`，端口: 5901, 密码 xxxx；
4. 成功连上后你应该能看到 EasyConnect 的登录窗口，填写登录凭据并登录，若需要 web 登录可参看 [web 登录](doc/usage.md#web-登录)。

### 图形界面版 aTrust（amd64、arm64、mips64el 架构）

1. [安装Docker并运行](https://docs.docker.com/get-docker/)；
2. 在终端输入： `docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -e URLWIN=1 -v $HOME/.atrust-data:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 -p 127.0.0.1:54631:54631 --sysctl net.ipv4.conf.default.route_localnet=1 hagb/docker-atrust`；
3. 使用vnc客户端连接vnc， 地址：127.0.0.1，端口: 5901, 密码 xxxx；
4. 成功连上后你应该能看到 aTrust 的登录窗口；若需要 web 登录，在宿主机的浏览器打开 aTrust 弹出的网址网址登录即可；若需要无人值守的自动化登录和保活，请[参见此处](https://github.com/kenvix/aTrustLogin)。


## 拉取

### 从 Docker Hub 上直接获取：

```
docker pull hagb/docker-easyconnect:TAG
```

其中 TAG 可以是如下值（不带 VNC 服务端的 image 比带 VNC 服务端的 image 小）：

- `latest`: 默认值，带 VNC 服务端的`7.6.7`版 image，
- `cli`: 多版本（`7.6.3`, `7.6.7`, `7.6.8`）纯命令行版
- `vncless`: 不带 VNC 服务端的`7.6.7`版 image
- `7.6.3`: 带 VNC 服务端的`7.6.3`版 image
- `vncless-7.6.3`: 不带 VNC 服务端的`7.6.3`版 image
- `7.6.7`: 带 VNC 服务端的`7.6.7`版 image
- `vncless-7.6.7`: 不带 VNC 服务端的`7.6.7`版 image

## 参考资料

登录过程的一个 hack ([docker-root/usr/local/bin/start-sangfor.sh](docker-root/usr/local/bin/start-sangfor.sh))参考了这篇文章：<https://blog.51cto.com/13226459/2476193>。在此对该文作者表示感谢。

## 其他 EasyConnect 相关项目

- [@shmilee](https://github.com/shmilee) 的 [easyconnect-in-docker 方案](https://github.com/shmilee/scripts/tree/master/easyconnect-in-docker)（另见 [#35](https://github.com/Hagb/docker-easyconnect/issues/35)）实现了多 EasyConnect 版本共用容器
- [ultranity/minimal-EasyConnect](https://github.com/ultranity/minimal-EasyConnect): minimal EasyConnect CLI in docker-alpine
- [Mythologyli/ZJU-Connect](https://github.com/Mythologyli/ZJU-Connect): ZJU RVPN 客户端的 Go 语言实现
- [zhangt2333/actions-easyconnect](https://github.com/zhangt2333/actions-easyconnect): Github Actions: run code with EasyConnect VPN
- [CoolSpring8/rwppa](https://github.com/CoolSpring8/rwppa): 将浙江大学网页版 RVPN 模拟为本地 HTTP 代理 - (ZJU) RVPN Web Portal Proxy Adapter

## 版权及许可证

> Copyright © 2020 contributors
>
> This work is free. You can redistribute it and/or modify it under the  
> terms of the Do What The Fuck You Want To Public License, Version 2,  
> as published by Sam Hocevar. See the COPYING file for more details. 
>
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
