# 构建说明

有三个类型的版本：

- `Dockerfile`: 带 VNC 的图形界面版
- `Dockerfile.vncless`: 不带 VNC 的图形界面版（依赖于 X11 socket）
- `Dockerfile.cli`: 纯命令行版

其中图形界面版一个镜像仅可包含一个 EasyConnect 版本，纯命令行版可包含多个 EasyConnect 版本。

## 构建参数

- `EC_URL`（仅适用于图形界面版）: EasyConnect 的 deb 包下载地址，各版本的下载地址可见于 [../ec\_urls/](../ec_urls/)。
- `ELECTRON_URL`（仅适用于图形界面版）: [electron](https://github.com/electron/electron/releases) 的下载地址，用于在非 amd64 架构中将 EasyConnect 前端自带的 electron 替换成可原生执行的 electron（但亦可用于构建 amd64 镜像），有一些注意事项：

    - `armel`、`armhf`、`arm64`、`mips64el` 架构无需设定该参数，构建脚本中已经预设（有特殊需要可以使用该参数覆盖预设值），`amd64`（`x86_64`）架构可直接使用自带的 electron，也无需设定
    - EasyConnect 自带的 electron 为 v1.6.7 版，为确保兼容性应只使用 v1.x.xx 的镜像

- `EC_763_URL`（仅适用于命令行版）: `7.6.3` 版 EasyConnect 的 deb 包下载地址，默认为 `http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb`，将其设为空值时构建的镜像不包含 `7.6.3` 版的配置文件
- `EC_767_URL`（仅适用于命令行版）: `7.6.7` 版 EasyConnect 的 deb 包下载地址，默认为 `http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_767/EasyConnect_x64_7_6_7_3.deb`，将其设为空值时构建的镜像不包含 `7.6.7` 版的配置文件
- `EC_CLI_URL`（仅适用于命令行版）: [@shmilee](https://github.com/shmilee) 提供的命令行 `7.6.8` 版 deb 包的下载地址，默认为 `https://github.com/shmilee/scripts/releases/download/v0.0.1/easyconn_7.6.8.2-ubuntu_amd64.deb`
- `MIRROR_URL`: Debian 镜像站，默认为 <http://mirrors.aliyun.com/debian/>，设为空则不使用镜像站

## 从 Dockerfile 构建

### 纯命令行

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
docker image build -f Dockerfile.fake-hwaddr -t fake-hwaddr .
docker image build --tag hagb/docker-easyconnect -f Dockerfile.cli .
```

### 带 VNC 服务端

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
docker image build -f Dockerfile.fake-hwaddr -t fake-hwaddr .
EC_VER=7.6.3  # 此变量填写 ec_urls 文件夹中的版本，`7.6.3`或`7.6.7`
docker image build --build-arg EC_URL=$(cat ec_urls/${EC_VER}.txt) --tag hagb/docker-easyconnect -f Dockerfile .
```

### 使用 X11 socket 而无 VNC 服务端

``` bash
git clone https://github.com/hagb/docker-easyconnect.git
cd docker-easyconnect
docker image build -f Dockerfile.fake-hwaddr -t fake-hwaddr .
EC_VER=7.6.3  # 此变量填写 ec_urls 文件夹中的版本，`7.6.3`或`7.6.7`
docker image build --build-arg EC_URL=$(cat ec_urls/${EC_VER}.txt) --tag hagb/docker-easyconnect -f Dockerfile.vncless .
```

