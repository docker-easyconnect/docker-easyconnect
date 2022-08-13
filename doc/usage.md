# 用法

**启动参数里的`--device /dev/net/tun --cap-add NET_ADMIN`是不可少的。** 因为 EasyConnect 要创建虚拟网络设备`tun0`。

## 环境变量

- `CHECK_SYSTEM_ONLY`: 默认为空。设为非空值时检查系统是否满足使用条件后退出。（`docker run --cap-add NET_ADMIN --device /dev/net/tun -e CHECK_SYSTEM_ONLY=1 hagb/docker-easyconnect:TAG`）

- `EXIT`: 默认为空，此时前端退出后会自动重连。不为空时，前端退出后不自动重启。

- `FAKE_HWADDR`: 默认为空，向 EasyConnect 提供的固定网卡 MAC 地址。Podman 在非 root 权限下无法固定虚拟网卡的 MAC 地址，为了防止每次启动容器都要重新提交硬件 ID，可设置该环境变量为某一 MAC 地址（建议使用 podman 先前启动时随机生成的地址或已提交的 MAC 地址），劫持 EasyConnect 使其获取到该固定地址。Docker 默认的情况下 MAC 地址即固定，root 环境下的 podman 可以直接使用 `--mac-address` 参数设置，无需使用 `FAKE_HWADDR`。

- `FORWARD`: 默认为空，用于将 vpn 服务端一侧对客户端虚拟 ip 发起的访问转发到客户端侧的 ip，格式如下（以下所有 ip 均为 ipv4 ip）：

    > [SOURCE_IP:]CONTAINER_PORT:DESTINATION_IP:DESTINATION_PORT

    其中

    - `SOURCE_IP`: 可选项。服务端侧发起连接的 ip 或 ip 段，这些 ip 对容器的 `CONTAINER_PORT` 端口发起的连接允许被转发，为空则服务端侧任意 IP 对容器 `CONTAINER_PORT` 端口发起的连接都会被转发。
    - `CONTAINER_PORT`: 容器接受服务端侧传入连接的端口
    - `DESTINATION_IP`: 转发的目的 ip
    - `DESTINATION_PORT`: 转发的目的端口

    例如：`1010:172.17.0.1:1013` 指服务端侧所有 ip 访问容器的 `1010` 端口会被转发到 `172.17.0.1:1013`；`10.234.0.0/24:172.17.0.1:1013` 指服务端侧 `10.234.0.0/24`（即 `10.234.0.0`~`10.234.0.255`）访问容器的 `1010` 端口会被转发到 `172.17.0.1:1013`；`10.234.0.1:172.17.0.1:1013` 指服务端侧 `10.234.0.1` 访问容器的 `1010` 端口会被转发到 `172.17.0.1:1013`

- `IPTABLES_LEGACY`: 默认为空。设为非空值时强制要求 `iptables-legacy`。

- `MAX_RETRY`: 最大重连次数，默认为空。

- `NODANTED`: 默认为空。不为空时提供 socks5 代理的`danted`将不会启动（可用于和`--net host`参数配合，提供全局透明代理）。

- `SOCKS_USER`: 默认为空，不为空时以此为用户名启用 socks5 代理的密码认证

- `SOCKS_PASSWD`: 默认为空，`SOCKS_USER` 不为空时此变量作为 socks5 代理的密码

### 仅适用于纯命令行版本的环境变量

- `EC_VER`: 指定运行的 EasyConnect 版本，必填

- `CLI_OPTS`: 默认为空，给 `easyconn login` 加上的额外参数，可用参数如下：
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
	例如 `CLI_OPTS="-d 服务器地址 -u 用户名 -p 密码"` 可实现原登录信息失效时自动登录。

### 仅适用于图形界面版本的环境变量

- `DISPLAY`: `$TYPE`为`x11`或使用无 vnc 的 image 时通过该变量来显示 EasyConnect 界面。

- `ECPASSWORD`: 默认为空，使用 vnc 时用于将密码放入粘帖板，应对密码复杂且无法保存的情况 (eg: 需要短信验证登录)。

- `PASSWORD`: 用于设置 vnc 服务的密码，该变量的值默认为空字符串，表示密码不作改变。变量不为空时，密码（应小于或等于 8 位）就会被更新到变量的值。默认密码是`password`.

- `TYPE`（仅适用于带 vnc 的 image）: 如何显示 EasyConnect 前端（目前没有找到纯 cli 的办法）。有以下两种选项:

	- `x11`或`X11`: 将直接通过`DISPLAY`环境变量的值显示 EasyConnect 前端，请同时设置`DISPLAY`环境变量。

	- 其它任何值（默认值）: 将在`5901`端口开放 vnc 服务以操作 EasyConnect 前端。

- `URLWIN`: 默认为空，此时当 EasyConnect 想要调用浏览器时，不会弹窗，若该变量设为任何非空值，则会弹出一个包含链接文本框。

- `USE_NOVNC`: 默认为空，不为空时将启动easy-novnc，端口为8080， 可用-p参数转发。

## 服务说明

### Socks5

EasyConnect 创建 `tun0` 后，Socks5 代理会在容器的 `1080` 端口开启。这可用 `-p` 参数转发到 `127.0.0.1` 上。将 `NODANTED` 设为非空值可关闭此功能。

### ip forward

默认开启。可供宿主机通过路由表（将容器地址作为下一跳路由）来设置透明代理，mtu 应与容器内的 `tun0` 保持一致（可通过 `docker exec 容器名 cat /sys/class/net/tun0/mtu` 来获取，一般为 1400）。

如：

```bash
MTU=$(docker exec "$NAME" cat /sys/class/net/tun0/mtu)
ip route add 172.10.0.0/16 via 172.17.0.2 mtu $MTU table 3
ip rule add iif lo table 3
```

可使宿主机通过 vpn 来访问 `172.10.0.0/16`。

### VNC 服务器（仅限带 VNC 的图形界面版）

带 VNC 的版本中，默认情况下环境变量 `TYPE` 留空会在 `5901` 端口开启 VNC 服务器。

### noVNC（仅限带 VNC 的图形界面版）

带 VNC 的版本中，环境变量 `USE_NOVNC` 不留空会在 `8080` 端口开启 noVNC 的web服务。

### 处理 EasyConnect 的浏览器弹窗（仅限图形界面版）

处理成将链接（追加）写入`/root/open-urls`，如果设置了 `URLWIN` 环境变量为非空值，还会弹出一个包含链接的文本框。

### X11 socket（仅限图形界面版）

可以直接使用宿主机的界面来显示 EasyConnect 前端。

容器启动参数中需加入 `-v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/root/.Xauthority -e DISPLAY=$DISPLAY`，且 X 服务器需设置允许容器的连入（如通过命令 `xhost +LOCAL:`）。

### 配置、登录信息持久化

#### 纯命令行版

用 `-v` 参数将宿主机的登录信息**文件**（请确定该文件已存在）挂载到容器的 `/root/.easyconn`，如 `-v $HOME/.easyconn:/root/.easyconn`。

#### 图形界面版
只需要用 `-v` 参数将宿主机的目录挂载到容器的 `/root`。

如 `-v $HOME/.ecdata:/root`。

更换 EasyConnect 版本需要清空其中的 `conf` 目录。

## 用例

以下例子中，开放的 Socks5 在`127.0.0.1:1080`（`-p 127.0.0.1:1080:1080`）。图形界面（X11 socket 和 vnc）两例中，登录信息均保存在`~/.ecdata/`文件夹（`-v $HOME/.ecdata:/root`）

### 纯命令行

下列例子可启动纯命令行的 EasyConnect `7.6.3`（`-e EC_VER=7.6.3`），并且退出后不会自动重启（`-e EXIT=1`）。

``` bash
touch ~/.easyconn
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v $HOME/.easyconn:/root/.easyconn -e EC_VER=7.6.3 -e EXIT=1 -p 127.0.0.1:1080:1080 hagb/docker-easyconnect:cli
```

### tinyproxy
下列例子可启动纯命令行的 EasyConnect `7.6.3` 并且对宿主主机提供 http 代理

``` bash
$ touch ~/.easyconn
$ docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v $HOME/.easyconn:/root/.easyconn -p 127.0.0.1:8888:8888 -e EC_VER=7.6.3 ztongxue/docker-easyconnect-tinyproxy:cli
```

程序内直接使用代理地址 127.0.0.1:8888 即可。例如在 python requests 中使用：

```
requests.get('https://www.hao123.com', proxies={'http': '127.0.0.1:8888'})
```

你也可以改成你需要宿主主机代理端口，例如你想对程序暴露的代理端口为 8118 ，只需要在启动容器的时候，指定一下端口即可。👇
```
$ docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v $HOME/.easyconn:/root/.easyconn -p 127.0.0.1:8118:8888 -e EC_VER=7.6.3 ztongxue/docker-easyconnect-tinyproxy:cli
```

### X11 socket

在当前桌面环境中启动 EasyConnect `7.6.3` 前端，并且该前端退出后不会自动重启（`-e EXIT=1`），EasyConnect 要进行浏览器弹窗时会弹出含链接的文本框（`-e URLWIN=1`）。

``` bash
xhost +LOCAL:
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/root/.Xauthority -e EXIT=1 -e DISPLAY=$DISPLAY -e URLWIN=1 -e TYPE=x11 -v $HOME/.ecdata:/root -p 127.0.0.1:1080:1080 hagb/docker-easyconnect:vncless-7.6.3
xhost -LOCAL:
```

### vnc 

客户端退出会自动重启，VNC 服务器在`127.0.0.1:5901`（`-p 127.0.0.1:5901:5901`），密码为`xxxx`（`-e PASSWORD=xxxx`）。

``` bash
docker run --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 hagb/docker-easyconnect
```

