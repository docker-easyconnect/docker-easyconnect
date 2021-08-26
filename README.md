# docker-easyconnect

让深信服开发的**非自由**的 EasyConnect 代理软件运行在 docker 中，并开放 Socks5 供宿主机连接以使用代理。（此外亦可通过 [ip forward 的方式](doc/usage.md#ip-forward) 来使用）

基于 EasyConnect 官方“Linux”版的 deb 包以及 [@shmille](https://github.com/shmilee) 提供的[命令行版客户端 deb 包](https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb)。

另有 [@shmilee](https://github.com/shmilee) 的 [easyconnect-in-docker 方案](https://github.com/shmilee/scripts/tree/master/easyconnect-in-docker)（另见 [#35](https://github.com/Hagb/docker-easyconnect/issues/35)）实现了多 EasyConnect 版本共用容器，其中还有另一个[纯 cli 版本的容器](https://github.com/shmilee/scripts/tree/master/easyconnect-in-docker/only-cli)。

望批评、指正。欢迎提交 issue、PR，包括但不仅限于 bug、各种疑问、代码和文档的改进。

详细用法见于 [doc/usage.md](doc/usage.md)，常见问题见于 [doc/faq.md](doc/faq.md)。

## 简明使用步骤

### 纯命令行版

1. [安装Docker并运行](https://docs.docker.com/get-docker/)；
2.  在终端输入：
	``` bash
	touch ~/.easyconn
	docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 -e EC_VER=7.6.3 -e CLI_OPTS="-d vpnaddress -u username -p password" hagb/docker-easyconnect:cli
	```
	其中 `-e EC_VER=7.6.3` 表示使用 `7.6.3` 版本的 EasyConnect，请根据实际情况修改版本号；
3. 根据提示输入服务器地址、登录凭据；
4. 浏览器（或其他支持的应用）可配置socks5代理（可以通过插件配置），地址 `127.0.0.1`, 端口 `1080`；也可以使用 http 代理，地址 `127.0.0.1`, 端口 `8888`。

### 图形界面版

1. [安装Docker并运行](https://docs.docker.com/get-docker/)；
2. 在终端输入： `docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 hagb/docker-easyconnect:7.6.3`（末尾 EasyConnect 版本号 `7.6.3` 请根据实际情况修改）；
3. 使用vnc客户端连接vnc， 地址：127.0.0.1, 端口: 5901, 密码 xxxx ;
4. 成功连上后你应该能看到easyconnect的登录窗口，填写并登录easyconnect；
5. 浏览器（或其他支持的应用）可配置socks5代理（可以通过插件配置），地址 `127.0.0.1`, 端口 `1080`；也可以使用 http 代理，地址 `127.0.0.1`, 端口 `8888`。


**注意：如果你要将系统代理设置为127.0.0.1:1080而不是单独配置浏览器，请保证docker engine本身不会通过系统代理联网。**

## EasyConnect 版本

[`ec_urls`](ec_urls) 目录中以`版本号.txt`为文件名的文本文件保存了下载链接。（欢迎提交 issue 或 PR）

### 已经过测试的版本

`7.6.3`版（<http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb>）.

`7.6.7`版（<http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb>）.

`7.6.8`版（仅命令行）（<https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb>）.

如果需要测试其他 EasyConnect 版本，可以将该版本的 deb 安装包下载地址写入到文本文件 `ec_urls/版本号.txt` 中，使用[构建说明](doc/build.md#从-dockerfile-构建)中的方法进行构建。

## 拉取

### 从 Docker Hub 上直接获取：

```
docker pull hagb/docker-easyconnect:TAG
```

其中 TAG 可以是如下值（不带 VNC 服务端的 image 比带 VNC 服务端的 image 小）：

- `latest`: 默认值，带 VNC 服务端的`7.6.3`版 image，
- `cli`: 多版本（`7.6.3`, `7.6.7`, `7.6.8`）纯命令行版
- `vncless`: 不带 VNC 服务端的`7.6.3`版 image
- `7.6.3`: 带 VNC 服务端的`7.6.3`版 image
- `vncless-7.6.3`: 不带 VNC 服务端的`7.6.3`版 image
- `7.6.7`: 带 VNC 服务端的`7.6.7`版 image
- `vncless-7.6.7`: 不带 VNC 服务端的`7.6.7`版 image

## 参考资料

登录过程的一个 hack ([docker-root/usr/local/bin/start-sangfor.sh](docker-root/usr/local/bin/start-sangfor.sh))参考了这篇文章：<https://blog.51cto.com/13226459/2476193>。在此对该文作者表示感谢。

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
