# 构建说明

有三个类型的版本：

- `Dockerfile`: 带 VNC 的图形界面版
- `Dockerfile.vncless`: 不带 VNC 的图形界面版（依赖于 X11 socket）
- `Dockerfile.cli`: 纯命令行版

其中图形界面版一个镜像仅可包含一个 EasyConnect 版本，纯命令行版可包含多个 EasyConnect 版本。

## 构建参数

- `EC_HOST`: EasyConnect deb 包的架构，默认为空表示 deb 包架构与容器运行的架构一致；以 Debian 包管理器的架构名可准，可选项为：`aarch64`、`amd64`、`armel`、`armhf`、`i386`、`misp64el`。
- `ELECTRON_URL`（仅适用于图形界面版）: [electron](https://github.com/electron/electron/releases) 的下载地址，用于在非 amd64 架构中将 EasyConnect 前端自带的 electron 替换成可原生执行的 electron（使用 qemu 时原生 electron 可以减小翻译开销；来自 EasyConnect 的 electron 在 Debian bookworm 上有段错误的现象），有一些注意事项：

    - `armel`、`armhf`、`arm64`、`mips64el`、`amd64`、`i386` 架构无需设定该参数，构建脚本中已经预设（有特殊需要可以使用该参数覆盖预设值）
    - EasyConnect 自带的 electron 为 v1.6.7 版，为确保兼容性应只使用 v1.x.xx 的镜像
    - 暂不适用于 aTrust

- `EC_763_URL`（仅适用于命令行版）: `7.6.3` 版 EasyConnect 的 deb 包下载地址，默认为 `http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb`，将其设为空值时构建的镜像不包含 `7.6.3` 版的配置文件
- `EC_767_URL`（仅适用于命令行版）: `7.6.7` 版 EasyConnect 的 deb 包下载地址，默认为 `http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb`，将其设为空值时构建的镜像不包含 `7.6.7` 版的配置文件
- `EC_CLI_URL`（仅适用于命令行版）: [@shmilee](https://github.com/shmilee) 提供的命令行 `7.6.8` 版 deb 包的下载地址，默认为 `https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb`
- `MIRROR_URL`: Debian 镜像站，默认为 <http://ftp.cn.debian.org/debian/>，设为空则使用默认镜像站
- `USE_EC_ELECTRON`（仅适用于图形界面版）: 默认为空，是否使用来自 EasyConnect 的 electron，不为空时使用来自 EasyConnect 的 electron.
- `VPN_DEB_PATH`（仅适用于图形界面版）: 默认为空。非空时表示 `VPN_URL` 是一个 zip 包的地址（见<https://github.com/Hagb/docker-easyconnect/issues/25#issuecomment-1233369467>），而 `VPN_DEB_PATH` 则是 zip 包中的 deb 包的路径。
- **`VPN_TYPE`**：默认为 `EC_GUI`。构建 aTrust 镜像时，需要将该参数设为 `ATRUST`。
- **`VPN_URL`**（仅适用于图形界面版）: EasyConnect 的 deb 包下载地址（`VPN_DEB_PATH` 非空时则是包含 deb 包的 zip 包下载地址），各版本的下载地址可见于 [../build-args/](../build-args/)。


### `Dockerfile.build` 构建参数

- `EC_HOST`: EasyConnect deb 包的架构，同上文
- `MIRROR_URL`: Debian 镜像站，同上文
- `TINYPROXY_COMMIT`: 构建支持 websocket 的 [tinyproxy](https://github.com/tinyproxy/tinyproxy) 的 commit.
- `NOVNC_METHOD`: 提供 noVNC 服务的方式，默认为 `min-size`，可选选项有

    - `min-size`: 最小化镜像体积的方式，通过 busybox、tinyproxy 和 [C 语言版的 websockify](https://github.com/novnc/websockify-other) 来实现
    - `easy-novnc`: 使用 [easy-novnc](https://github.com/pgaskin/easy-novnc)，由 easy-novnc 直接提供所有所需服务

## 从 Dockerfile 构建

### 纯命令行

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
docker image build -f Dockerfile.build -t hagb/docker-easyconnect:build --build-arg EC_HOST=amd64 .
docker image build --tag hagb/docker-easyconnect -f Dockerfile.cli --build-arg EC_HOST=amd64 .
```

### 带 VNC 服务端

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
docker image build $(cat build-args/7.6.7-amd64.txt) -f Dockerfile.build -t hagb/docker-easyconnect:build .
docker image build $(cat build-args/7.6.7-amd64.txt) --tag hagb/docker-easyconnect -f Dockerfile .
```

### 使用 X11 socket 而无 VNC 服务端

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
docker image build $(cat build-args/7.6.7-amd64.txt) -f Dockerfile.build -t hagb/docker-easyconnect:build .
docker image build $(cat build-args/7.6.7-amd64.txt) --tag hagb/docker-easyconnect -f Dockerfile.vncless .
```

