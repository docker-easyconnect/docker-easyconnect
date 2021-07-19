# 常见问题

## 除宿主机外其他设备无法访问容器的开放端口

见 [路由和开放端口说明](route.md)。

## `docker: Error response from daemon: error gathering device information while adding custom device "/dev/net/tun": no such file or directory.` 或 `Failed to operate tun device! Please check whether /dev/net/tun is available.`

请确保 `tun` 模块编译进内核或加载为内核模块。

群辉系统可用以下命令来加载该模块：

``` bash
sudo insmod /lib/modules/tun.ko
```

其他发行版可尝试

``` bash
sudo modprobe tun
```

## `Failed to login in with this user account, for a user is online!`

该问题在`7.6.3`版上有出现，`7.6.7`版上未知。

有时登录时卡一小会儿，然后弹出`Failed to login in with this user account, for a user is online!`的窗口，但实际上同一账号并没有其他客户端同时在线。点击`OK`后 EasyConnect 退出。

在 docker 命令行内临时删去设置`EXIT`环境变量的`-e EXIT=`参数（如果有），在弹窗发生后点击`OK`，使客户端重启，重启后问题消失。

## 无法显示中文

原因是 image 内无中文字体。可以通过修改 EasyConnect 前端的语言为英语来绕过中文显示的问题。也可以安装或挂载中文字体进容器中。

详见 [#2](https://github.com/Hagb/docker-easyconnect/issues/2)。

