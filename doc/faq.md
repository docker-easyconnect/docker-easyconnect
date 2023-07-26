# 常见问题

## 除宿主机外其他设备无法访问容器的开放端口

见 [路由和开放端口说明](route.md)。

## EasyConnect 中登录以后长时间卡在图标明暗变化的界面（7.6.3 图形界面版），或启动容器后超过三秒宿主机无法连接 socks

尝试运行以下命令，其中`容器名`替换为实际的容器名（`docker container ls` 可见）：

``` bash
docker exec 容器名 busybox ifconfig
```

若输出中没有 `tun0`（EasyConnect）或 `utun7`（aTrust）网络接口，检查容器启动时输出的日志（`docker logs 容器名` 可见）中有无如下提示

```
Failed to create tun interface! Please check whether /dev/net/tun is available.
Also refer to https://github.com/Hagb/docker-easyconnect/blob/master/doc/faq.md.
```

若有，请参照[下一个问题](#user-content-启动容器时输出-docker-error-response-from-daemon-error-gathering-device-information-while-adding-custom-device-devnettun-no-such-file-or-directory-或-failed-to-create-tun-interface)解决；若无，可提交 [issue](https://github.com/Hagb/docker-easyconnect/issues) 中反馈。

## 启动容器时输出 `docker: Error response from daemon: error gathering device information while adding custom device "/dev/net/tun": no such file or directory.` 或 `Failed to create tun interface!`

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

## EasyConnect GUI 版登录失败，界面上提示 `The EasyConnect version is too low`（7.6.3）或 `The client version and server software version is not matching`（7.6.7）.

这是深信服对 EasyConnect 进行了更新，使得客户端的第四级版本号与服务端不匹配所致。X86/amd64 架构重新构建镜像（不使用旧镜像的缓存）即可更新到最新版的 EasyConnect。遇到此问题请在 [#274](https://github.com/Hagb/docker-easyconnect/issues/274) 中向维护者反馈，以便维护者重新构建并上传镜像。

也可以用 `-e DISABLE_PKG_VERSION_XML=1` 参数绕过版本检测从而正常使用，但这也可能会错过深信服发布的安全更新，存在潜在的安全隐患。Arm64、mips64el 架构的 EasyConnect 原生客户端已经不再更新，因此只能配合 `-e DISABLE_PKG_VERSION_XML=1` 参数来使用。

## VNC 版容器中，中文文本无法正常粘帖

详见 [操作 VNC 的剪贴板](./usage.md#操作-vnc-的剪贴板)。

## Rootless podman 的 MAC 地址不固定 / 如何设置设备 MAC 地址

Docker 或 root 下的 podman 运行镜像时可用 `--mac-address=MAC地址` 参数设置 MAC 地址，rootless podman 可用 `FAKE_HWADDR` 环境变量来伪装 MAC 地址（参看 [usage.md 环境变量一节](./usage.md#环境变量)）。
