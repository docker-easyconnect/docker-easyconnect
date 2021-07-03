# docker-easyconnect

让深信服开发的**非自由**的 EasyConnect 代理软件运行在 docker 中，并开放 Socks5 供宿主机连接以使用代理。

这个 image 基于 EasyConnect 官方“Linux”版的 deb 包以及 [@shmille](https://github.com/shmilee) 提供的[命令行版客户端 deb 包](https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb)。

[如何运行“Linux”版 EasyConnect (`7.6.3.0.86415`版) (doc/run-linux-easyconnect-how-to.md)](doc/run-linux-easyconnect-how-to.md)是这次折腾的总结。

另有 [@shmilee](https://github.com/shmilee) 的 [easyconnect-in-docker 方案](https://github.com/shmilee/scripts/tree/master/easyconnect-in-docker)（另见 [#35](https://github.com/Hagb/docker-easyconnect/issues/35)）实现了多 EasyConnect 版本共用容器，其中还有另一个[纯 cli 版本的容器](https://github.com/shmilee/scripts/tree/master/easyconnect-in-docker/only-cli)。

如果希望使用全局代理，可参考 [记折腾容器化 EasyConnect 的全局透明代理](https://hagb.name/2020/06/26/easyconnect-proxy.html) 一文设置宿主机路由（或许有更好的办法，欢迎反馈）。

望批评、指正。欢迎提交 issue、PR，包括但不仅限于 bug、各种疑问、代码和文档的改进。

## 简明使用步骤

### 纯命令行版

1. [安装Docker并运行](https://docs.docker.com/get-docker/)；
2.  在终端输入：
	``` bash
	touch ~/.easyconn
	docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v $HOME/.easyconn:/root/.easyconn -p 127.0.0.1:1080:1080 -e EC_VER=7.6.3 hagb/docker-easyconnect:cli
	```
	其中 `-e EC_VER=7.6.3` 表示使用 `7.6.3` 版本的 EasyConnect，请根据实际情况修改版本号；
3. 根据提示输入服务器地址、登陆凭据；
4. 浏览器单独配置socks5代理（可以通过插件配置），地址: 127.0.0.1, 端口: 1080
5. 此时你应该就可以通过浏览器连接到内网了。

### 图形界面版

1. [安装Docker并运行](https://docs.docker.com/get-docker/)；
2. 在终端输入： `docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 hagb/docker-easyconnect:7.6.3`（末尾 EasyConnect 版本号 `7.6.3` 请根据实际情况修改）；
3. 使用vnc客户端连接vnc， 地址：127.0.0.1, 端口: 5901, 密码 xxxx ;
4. 成功连上后你应该能看到easyconnect的登陆窗口，填写并登陆easyconnect；
5. 浏览器单独配置socks5代理（可以通过插件配置），地址: 127.0.0.1, 端口: 1080
6. 此时你应该就可以通过浏览器连接到内网了。

**注意：如果你要将系统代理设置为127.0.0.1:1080而不是单独配置浏览器，请保证docker engine本身不会通过系统代理联网。**


## EasyConnect 版本

[`ec_urls`](ec_urls) 目录中以`版本号.txt`为文件名的文本文件保存了下载链接。（欢迎提交 issue 或 PR）

### 已经过测试的版本

`7.6.3`版（<http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb>）.

`7.6.7`版（<http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb>）.

`7.6.8`版（<https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb>）.

### 其他

请通过设置下文叙述的`EC_URL`变量进行测试，欢迎提交 issue 或 PR.

## Pull or build

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

### 从 Dockerfile 构建

#### 纯命令行

``` bash
git clone https://github.com/hagb/docker-easyconnect.git --branch cli
cd docker-easyconnect
docker image build --tag hagb/docker-easyconnect -f Dockerfile.cli .
```

#### 带 VNC 服务端

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
EC_VER=7.6.3  # 此变量填写 ec_urls 文件夹中的版本，`7.6.3`或`7.6.7`
docker image build --build-arg EC_URL=$(cat ec_urls/${EC_VER}.txt) --tag hagb/docker-easyconnect -f Dockerfile .
```

#### 使用 X11 socket 而无 VNC 服务端

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
EC_VER=7.6.3  # 此变量填写 ec_urls 文件夹中的版本，`7.6.3`或`7.6.7`
docker image build --build-arg EC_URL=$(cat ec_urls/${EC_VER}.txt) --tag hagb/docker-easyconnect -f Dockerfile.vncless .
```

如果需要测试[`ec_urls`](ec_urls)目录中尚未包含的 EasyConnect 版本，可以将该版本的 deb 安装包下载地址写入到文本文件`ec_urls/版本号.txt`中，或者直接将地址赋予编译变量`EC_URL`（以上文为例则是用该地址替换`$(cat ec_urls/${EC_VER}.txt)`）

## Usage

**参数里的`--device /dev/net/tun --cap-add NET_ADMIN`是不可少的。** 因为 EasyConnect 要创建虚拟网络设备`tun0`。

### 构建参数

- `EC_URL`（仅适用于图形界面版）: EasyConnect 的 deb 包下载地址
- `EC_763_URL`（仅适用于命令行版）: `7.6.3` 版 EasyConnect 的 deb 包下载地址，默认为 `http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb`，将其设为空值时构建的镜像不包含 `7.6.3` 版的配置文件
- `EC_767_URL`（仅适用于命令行版）: `7.6.7` 版 EasyConnect 的 deb 包下载地址，默认为 `http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb`，将其设为空值时构建的镜像不包含 `7.6.7` 版的配置文件
- `EC_CLI_URL`（仅适用于命令行版）: [@shmilee](https://github.com/shmilee) 提供的命令行 `7.6.8` 版 deb 包的下载地址，默认为 `https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb`

### 环境变量

- `TYPE`（仅适用于带 vnc 的 image）: 如何显示 EasyConnect 前端（目前没有找到纯 cli 的办法）。有以下两种选项:

	- `x11`或`X11`: 将直接通过`DISPLAY`环境变量的值显示 EasyConnect 前端，请同时设置`DISPLAY`环境变量。

	- 其它任何值（默认值）: 将在`5901`端口开放 vnc 服务以操作 EasyConnect 前端。

- `DISPLAY`（仅适用于图形界面版）: `$TYPE`为`x11`或使用无 vnc 的 image 时通过该变量来显示 EasyConnect 界面。

- `PASSWORD`（仅适用于图形界面版）: 用于设置 vnc 服务的密码，该变量的值默认为空字符串，表示密码不作改变。变量不为空时，密码（应小于或等于 8 位）就会被更新到变量的值。默认密码是`password`.

- `URLWIN`（仅适用于图形界面版）: 默认为空，此时当 EasyConnect 想要调用浏览器时，不会弹窗，若该变量设为任何非空值，则会弹出一个包含链接文本框。

- `EXIT`: 默认为空，此时前端退出后会自动重连。不为空时，前端退出后不自动重启。

- `MAX_RETRY`: 最大重连次数，默认为空。

- `NODANTED`: 默认为空。不为空时提供 socks5 代理的`danted`将不会启动（可用于和`--net host`参数配合，提供全局透明代理）。

- `ECPASSWORD`（仅适用于图形界面版）: 默认为空，使用 vnc 时用于将密码放入粘帖板，应对密码复杂且无法保存的情况 (eg: 需要短信验证登陆)。

- `IPTABLES_LEGACY`: 默认为空。设为非空值时强制要求 `iptables-legacy`。**在 Windows 的 docker 和部分其他环境下须开启，详见[已知问题](#已知问题)**

- `EC_VER`（仅适用于纯命令行版）: 指定运行的 EasyConnect 版本，必填

- `CLI_OPTS`（仅适用于纯命令行版）: 默认为空，给 `easyconn login` 加上的额外参数，可用参数如下：
	```
	-d vpn address, make sure it's assigned and the format is right, like "199.201.73.191:443"
	-t login type, "pwd" means username/password authentication
	               "cert" means certificate authentication
	-u username
	-p password
	-c certificate path
	-m password for certificate
	-l certificate used to be authentication
	```
	例如 `CLI_OPTS="-d 服务器地址 -u 用户名 -p 密码"` 可实现原登陆信息失效时自动登陆。
### Socks5

EasyConnect 创建`tun0`后，Socks5 代理会在容器的`1080`端口开启。这可用`-p`参数转发到`127.0.0.1`上。

### VNC 服务器

带 VNC 时，默认情况下，环境变量`TYPE`留空会在`5901`端口开启 VNC 服务器。

### 处理 EasyConnect 的浏览器弹窗（仅限图形界面版）

处理成将链接（追加）写入`/root/open-urls`，如果设置了`URLWIN`环境变量为非空值，还会弹出一个包含链接的文本框。

### 配置、登陆信息持久化

#### 纯命令行版
用 `-v` 参数将宿主机的登陆信息**文件**（请确定该文件已存在）挂载到容器的 `/root/.easyconn`，如 `-v $HOME/.easyconn:/root/.easyconn` .

#### 图形界面版
只需要用`-v`参数将宿主机的目录挂载到容器的 /root 。

如`-v $HOME/.ecdata:/root`。

由此还能实现全自动登陆。

## 例子

以下例子中，开放的 Socks5 在`127.0.0.1:1080`（`-p 127.0.0.1:1080:1080`）。图形界面（X11 socket 和 vnc）两例中，登录信息均保存在`~/.ecdata/`文件夹（`-v $HOME/.ecdata:/root`）

### 纯命令行

下列例子可启动纯命令行的 EasyConnect `7.6.3`（`-e EC_VER=7.6.3`），并且退出后不会自动重启（`-e EXIT=1`）。

``` bash
touch ~/.easyconn
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v $HOME/.easyconn:/root/.easyconn -e EC_VER=7.6.3 -e EXIT=1 -p 127.0.0.1:1080:1080 hagb/docker-easyconnect
```

### X11 socket

下面这个例子可以在当前桌面环境中启动 EasyConnect 前端，并且该前端退出后不会自动重启（`-e EXIT=1`），EasyConnect 要进行浏览器弹窗时会弹出含链接的文本框（`-e URLWIN=1`）。

``` bash
xhost +LOCAL:
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/root/.Xauthority -e EXIT=1 -e DISPLAY=$DISPLAY -e URLWIN=1 -e TYPE=x11 -v $HOME/.ecdata:/root -p 127.0.0.1:1080:1080 hagb/docker-easyconnect
xhost -LOCAL:
```

### vnc 

下面这个例子中，前端退出会自动重启前端，VNC 服务器在`127.0.0.1:5901`（`-p 127.0.0.1:5901:5901`），密码为`xxxx`（`-e PASSWORD=xxxx`）。

``` bash
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 hagb/docker-easyconnect
```

## 已知问题

### 除宿主机外其他设备无法访问容器的开放端口

见 [路由和开放端口说明](doc/route.md)。

### 出现多条报错：`Couldn't load match 'state':No such file or directory` 或 `ip: RTNETLINK answers: Operation not permitted`

此为运行环境不支持 nft 且未被容器脚本检测出来所致。可以通过设置环境变量 `IPTABLES_LEGACY` 为 `1` 明确让容器使用 legacy iptables 来解决。

### `Failed to login in with this user account, for a user is online!`

该问题在`7.6.3`版上有出现，`7.6.7`版上未知。

有时登陆时卡一小会儿，然后弹出`Failed to login in with this user account, for a user is online!`的窗口，但实际上同一账号并没有其他客户端同时在线。点击`OK`后 EasyConnect 退出。

在 docker 命令行内临时删去设置`EXIT`环境变量的`-e EXIT=`参数（如果有），在弹窗发生后点击`OK`，使客户端重启，重启后问题消失。

### 无法显示中文

原因是 image 内无中文字体。可以通过修改 EasyConnect 前端的语言为英语来绕过中文显示的问题。也可以安装或挂载中文字体进容器中。

详见 [#2](https://github.com/Hagb/docker-easyconnect/issues/2)。

## 参考资料

登陆过程的一个 hack ([docker-root/usr/local/bin/start-sangfor.sh](docker-root/usr/local/bin/start-sangfor.sh))参考了这篇文章：<https://blog.51cto.com/13226459/2476193>。在此对该文作者表示感谢。

## 版权及许可证

> Copyright © 2020 contributors
>
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
