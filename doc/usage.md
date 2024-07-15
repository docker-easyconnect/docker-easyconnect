# 用法

**启动参数里的`--device /dev/net/tun --cap-add NET_ADMIN`是不可少的。** 因为 VPN 要创建 tun 网络接口。

## 环境变量

- `DISABLE_PKG_VERSION_XML`: 默认为空。设为非空时会阻止 EasyConnect 使用 `pkg_version.xml` 配置文件（通过将其设为 `/dev/null` 的软链接），从而绕过一些客户端和服务端版本不匹配的问题。注意这个选项并不能绕过[第三级](#easyconnect-版本选择)（如 `7.6.3` 中的 `3`）不匹配的问题，只能绕过第四级版本（如 `7.6.7.x` 中的 `x`）不匹配的问题。

- `EXIT`: 默认为空，此时前端退出后会自动重连。不为空时，前端退出后不自动重启，并停止容器。

- `EXIT_LOCK`: 默认为空，此时前端退出后会自动重连。不为空时， 前端退出后不自动重启，循环等待锁释放，当锁文件被删除后才会执行到下一步。

- `FAKE_HWADDR`: 默认为空，向 VPN 提供的固定网卡 MAC 地址。Podman 在非 root 权限下无法固定虚拟网卡的 MAC 地址，为了防止每次启动容器都要重新提交硬件 ID，可设置该环境变量为某一 MAC 地址（建议使用 podman 先前启动时随机生成的地址或已提交的 MAC 地址），劫持 VPN 使其获取到该固定地址。Docker 默认的情况下 MAC 地址即固定，root 环境下的 podman 可以直接使用 `--mac-address` 参数设置，无需使用 `FAKE_HWADDR`。

- `FORWARD`: 默认为空，用于将 vpn 服务端一侧对客户端虚拟 ip 发起的访问转发到客户端侧的 ip，格式如下（以下所有 ip 均为 ipv4 ip）：

    > [SOURCE_IP:]CONTAINER_PORT:DESTINATION_IP:DESTINATION_PORT

    其中

    - `SOURCE_IP`: 可选项。服务端侧发起连接的 ip 或 ip 段，这些 ip 对容器的 `CONTAINER_PORT` 端口发起的连接允许被转发，为空则服务端侧任意 IP 对容器 `CONTAINER_PORT` 端口发起的连接都会被转发。
    - `CONTAINER_PORT`: 容器接受服务端侧传入连接的端口
    - `DESTINATION_IP`: 转发的目的 ip
    - `DESTINATION_PORT`: 转发的目的端口

    例如：`1010:172.17.0.1:1013` 指服务端侧所有 ip 访问容器的 `1010` 端口会被转发到 `172.17.0.1:1013`；`10.234.0.0/24:1010:172.17.0.1:1013` 指服务端侧 `10.234.0.0/24`（即 `10.234.0.0`~`10.234.0.255`）访问容器的 `1010` 端口会被转发到 `172.17.0.1:1013`；`10.234.0.1:1010:172.17.0.1:1013` 指服务端侧 `10.234.0.1` 访问容器的 `1010` 端口会被转发到 `172.17.0.1:1013`

- `IPTABLES_LEGACY`: 默认为空。设为非空值时强制要求 `iptables-legacy`。

- `MAX_RETRY`: 最大重连次数，默认为空。

- `NODANTED`: 默认为空。不为空时提供 socks5 代理的`danted`将不会启动（可用于和`--net host`参数配合，提供全局透明代理）。

- `PING_ADDR`: 默认为空。用于定时 ping 的目的地址（域名、ip 皆可，但需要是 VPN 进行代理的地址），可用于保持 VPN 连接，留空时不做此操作。（服务端可能会配置成无流量通过 VPN 超过一定时间则自动断线，故用此方法可以保持更长时间在线）

- `PING_ADDR_URL`: 默认为空。用于定时 访问 的目的地址（某个网页，或者js/css等资源，但需要是 VPN 进行代理的地址），可用于保持 VPN 连接，留空时不做此操作。（功能和`PING_ADDR`类似，用于部分无法ping的环境进行替代`PING_ADDR`）

- `PING_INTERVAL`: 默认为 1800。单位为秒的 ping `PING_ADDR` 的间隔。

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

- `CLIP_TEXT`: 设置 VNC 内的剪贴板内容，特别是用于设置中文的用户名或者密码以供粘帖。若需多次设置不同的内容，或者在容器启动后操作 VNC 的剪贴板，可参看[操作 VNC 的剪贴板](#操作-vnc-的剪贴板)。

- `DISPLAY`: `$TYPE`为`x11`或使用无 vnc 的 image 时通过该变量来显示图像界面。

- `PASSWORD`: 用于设置 vnc 服务的密码，该变量的值默认为空字符串，表示密码不作改变。变量不为空时，密码（应小于或等于 8 位）就会被更新到变量的值。默认密码是`password`.

- `TYPE`（仅适用于非 `vncless` 的图形界面镜像）: 如何显示图形界面。有以下两种选项:

	- `x11`或`X11`: 将直接通过`DISPLAY`环境变量的值显示前端，请同时设置`DISPLAY`环境变量。

	- 其它任何值（默认值）: 将在`5901`端口开放 vnc 服务以操作前端。

- `URLWIN`: 默认为空，此时当 VPN 前端想要调用浏览器时，不会弹窗，若该变量设为任何非空值，则会弹出一个包含链接的对话框供用户复制。

- `USE_NOVNC`: 默认为空，不为空时将启动 noVNC 服务，可供用户在浏览器中访问 VPN 的图形界面，端口为 8080， 可用 -p 参数转发。

- `VNC_SIZE`: 默认为空，为空时 VNC 服务分辨率为 `1110x620`（7.6.7 版 EasyConnect 登录后的默认窗口尺寸），可设置为自定义的 VNC 分辨率。

## 服务说明

### 代理服务

socks5 和 http 代理会分别在容器的 `1080` 和 `8888` 端口开启，VPN 登录后可用它们来访问 VPN 的网络。这些端口可用 `-p` 参数转发到宿主机的 `127.0.0.1` 上或对外开放（不推荐，对外开放 http、socks5 端口不安全）。

浏览器和一些其他程序可使用这些代理，例如在 python requests 中使用：

```python3
requests.get('https://www.hao123.com', proxies={'http': '127.0.0.1:8888'})
```

### ip forward

宿主机可以通过路由表（将容器地址作为下一跳路由）来设置透明代理，mtu 应与容器内的 `tun0`（EasyConnect）或 `utun7`（aTrust）网络接口保持一致。可通过 `docker exec 容器名 cat /sys/class/net/接口名/mtu` 来获取，一般为 1400（EasyConnect）或 1500（aTrust）。

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

### 处理浏览器弹窗（仅限图形界面版）

处理成将链接（追加）写入`/root/open-urls`，如果设置了 `URLWIN` 环境变量为非空值，还会弹出一个包含链接的文本框。

### X11 socket（仅限图形界面版）

可以直接使用宿主机的界面来显示前端。

容器启动参数中需加入 `-v /tmp/.X11-unix:/tmp/.X11-unix -v ${XAUTHORITY:-~/.Xauthority}:/root/.Xauthority -e TYPE=x11 -e DISPLAY=$DISPLAY`，且 X 服务器需设置允许 root 用户的连入（如通过命令 `xhost +LOCAL:root`）。

### 配置、登录信息持久化

#### 纯命令行版

用 `-v` 参数将宿主机的登录信息**文件**（请确定该文件已存在）挂载到容器的 `/root/.easyconn`，如 `-v $HOME/.easyconn:/root/.easyconn`。

#### 图形界面版

只需要用 `-v` 参数将宿主机的目录挂载到容器的 `/root`。

如 `-v $HOME/.ecdata:/root`。

### web 登录

将容器的 `54530`（EasyConnect）或 `54631`（aTrust） 端口映射到宿主机（加入 `-p 127.0.0.1:端口号:端口号` 参数），之后便可以在宿主机上打开 VPN 服务器的网页进行登录。

这种登录方式可以在不使用 X11 或 VNC 的情况下登录 VPN。

注意，EasyConnect web 登录需要提前在相应浏览器打开 `https://127.0.0.1:54530` 并选择忽略证书错误——此处 EasyConnect 使用了一份自签证书；aTrust 则无此类问题。

### 操作 VNC 的剪贴板

VNC 的剪贴板同步功能可能无法正常同步中文文本，此时可以关闭 VNC 客户端的剪贴板同步功能，并在容器中运行 `set-vnc-clip.sh 文本` 来设置 VNC 的剪贴板，运行 `get-vnc-clip.sh` 来获取 VNC 的剪贴板内容。此外，也可以在容器启动时使用 `-e CLIP_TEXT=文本` 参数来设置 VNC 中的剪贴板内容。

## EasyConnect 版本选择

EasyConnect 客户端大致有以下三种版本

- `7.6.3`：适用于连接 <7.6.7 版本的 EasyConnect 服务端。
- `7.6.7`：适用于连接 >= 7.6.7 版本的 EasyConnect 服务端。
- `cli`：来源于 [@shmille](https://github.com/shmilee) 提供的[命令行版客户端 deb 包](https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb)。适用于所有版本的 EasyConnect 服务端（需配合环境变量参数 `-e EC_VER=7.6.3` 或 `-e EC_VER=7.6.7`），但只有 amd64 版本，只能使用用户名、密码来登录。

## 用例

以下例子中，开放的 Socks5 在`127.0.0.1:1080`（`-p 127.0.0.1:1080:1080`）。图形界面（X11 socket 和 vnc）两例中，登录信息均保存在`~/.ecdata/`文件夹（`-v $HOME/.ecdata:/root`）

### 纯命令行

下列例子可启动纯命令行的 EasyConnect `7.6.7`（`-e EC_VER=7.6.7`），并且退出后不会自动重启（`-e EXIT=1`）。

``` bash
touch ~/.easyconn
docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -ti -v $HOME/.easyconn:/root/.easyconn -e EC_VER=7.6.7 -e EXIT=1 -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 hagb/docker-easyconnect:cli
```

### X11 socket

在当前桌面环境中启动 EasyConnect 前端，并且该前端退出后不会自动重启（`-e EXIT=1`），EasyConnect 要进行浏览器弹窗时会弹出含链接的文本框（`-e URLWIN=1`）。

``` bash
xhost +LOCAL:root
docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -ti -v /tmp/.X11-unix:/tmp/.X11-unix -v $HOME/.Xauthority:/root/.Xauthority -e EXIT=1 -e DISPLAY=$DISPLAY -e URLWIN=1 -e TYPE=x11 -v $HOME/.ecdata:/root -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 hagb/docker-easyconnect:vncless
xhost -LOCAL:root
```

### vnc 

客户端退出会自动重启，VNC 服务器在`127.0.0.1:5901`（`-p 127.0.0.1:5901:5901`），密码为`xxxx`（`-e PASSWORD=xxxx`）。

``` bash
docker run --rm --device /dev/net/tun --cap-add NET_ADMIN -ti -e PASSWORD=xxxx -v $HOME/.ecdata:/root -p 127.0.0.1:5901:5901 -p 127.0.0.1:1080:1080 -p 127.0.0.1:8888:8888 hagb/docker-easyconnect
```

