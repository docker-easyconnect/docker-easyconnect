# 常见问题

## 除宿主机外其他设备无法访问容器的开放端口

见 [路由和开放端口说明](route.md)。

## EasyConnect 中登录以后长时间卡在图标明暗变化的界面（7.6.3 图形界面版），或显示登录成功超过十秒但宿主机无法连接 socks（命令行版或 7.6.7 图形界面版）

尝试运行以下命令，其中`容器名`替换为实际的容器名（`docker container ls` 可见）：

``` bash
docker exec 容器名 busybox ifconfig
```

若输出中没有 `tun0` 网络设备，再尝试以下命令，其中 TAG 替换为实际使用镜像的标签：

``` bash
docker run --cap-add NET_ADMIN --device /dev/net/tun -e CHECK_SYSTEM_ONLY=1 hagb/docker-easyconnect:TAG
```

若出现报错 `Failed to operate tun device! Please check whether /dev/net/tun is available`，参看[下一个问题](#启动容器时输出-docker-error-response-from-daemon-error-gathering-device-information-while-adding-custom-device-devnettun-no-such-file-or-directory)，依然无法解决请提交 [issue](https://github.com/Hagb/docker-easyconnect/issues) 进行反馈。

## 启动容器时输出 `docker: Error response from daemon: error gathering device information while adding custom device "/dev/net/tun": no such file or directory.` 或 `Failed to create tun device!`

请确保 `tun` 模块编译进内核或加载为内核模块。

群辉系统可用以下命令来加载该模块：

``` bash
sudo insmod /lib/modules/tun.ko
```

其他发行版可尝试

``` bash
sudo modprobe tun
```

## EasyConnect 登录失败，提示 `Failed to login in with this user account, for a user is online!`

该问题在`7.6.3`版上有出现，`7.6.7`版上未知。

有时登录时卡一小会儿，然后弹出`Failed to login in with this user account, for a user is online!`的窗口，但实际上同一账号并没有其他客户端同时在线。点击`OK`后 EasyConnect 退出。

在 docker 命令行内临时删去设置`EXIT`环境变量的`-e EXIT=`参数（如果有），在弹窗发生后点击`OK`，使客户端重启，重启后问题消失。

## 在 arm64、mips64el 架构上 EasyConnect 无法导入证书

将 `.p12` 后缀的证书文件拷贝到容器的 `/usr/share/sangfor/EasyConnect/resources/user_cert/` 目录。
