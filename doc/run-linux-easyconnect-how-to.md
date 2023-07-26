# 如何运行“Linux”版 EasyConnect (`7.6.3.0.86415`版)

这是对“Linux”版 EasyConnect `7.6.3.0.86415`版（<http://download.sangfor.com.cn/download/product/sslvpn/pkg/linux_01/EasyConnect_x64.deb>）的折腾记录，听说在更新的版本里面有一些问题已经被修复了，但是我没有测试条件。欢迎使用其他版本的朋友进行反馈。

以下内容在容器中测试过。其他情况下应该也行得通，但是没有完全测试过。（欢迎在别的环境下成功以这种方法运行的朋友提交 PR）

经实测，在debian9系统的阿里云服务器上和deepin15.11的桌面版均可正常运行。

## 依赖项

EasyConnect 有一些依赖项，但它的`deb`包中依赖信息什么都没写。

Debian 下可以用以下命令安装依赖：
```
apt-get install -y --no-install-recommends --no-install-suggests \
        libgtk2.0-0 libx11-xcb1 libxtst6 libnss3 libasound2 libdbus-glib-1-2 iptables
```
（其他发行版欢迎 PR）。

## 如何运行

在启动前端前应在 root 下运行：
```
/usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor
```

用`/usr/share/sangfor/EasyConnect/EasyConnect --enable-transparent-visuals --disable-gpu`或安装包自带的图标可以启动前端，前端不需要 root 权限。

普遍反映的一个问题是，前端登录后，vpn 没有生效就退出了。<https://blog.51cto.com/13226459/2476193>中说明了需要在登录过程中运行（不能提前运行，否则会被识别为已登录）`/usr/share/sangfor/EasyConnect/resources/shell/sslservice.sh`。

进一步观察发现，`sslservice.sh`相关程序（实际上是`/usr/share/sangfor/EasyConnect/resources/bin/`中的`CSClient`和`svpnservice`）在登录时建立虚拟网络接口`tun0`，通过该设备能够访问到 vpn。这些程序未运行时，前端登录后`/usr/share/sangfor/EasyConnect/resources/logs/ECAgent.log`中会不断产生报错直到一会儿后前端退出：
```
[YYYY-MM-dd HH:mm:ss][E][  21][ 165][ConnectDomainSock][cms] /usr/share/sangfor/EasyConnect/resources/conf/ECDomainFile domain socket connect failed, errno:2.
[YYYY-MM-dd HH:mm:ss][E][  21][ 114][Register]cms client connect failed.
```

这个错误不会引起前端的立即退出（但如果得不到解决，前端会在非正确登录后一会儿自行关闭），在报错期间运行`sslservice.sh`能够让前端正确登录。

于是可以检测该日志文件，检测到这种报错时启动`/usr/share/sangfor/EasyConnect/resources/shell/sslservice.sh`。

可以用以下这个`bash`脚本来做到：
```
#!/bin/bash
while true
do
	tail -n 0 -f /usr/share/sangfor/EasyConnect/resources/logs/ECAgent.log | grep "\\[Register\\]cms client connect failed" -m 1
	/usr/share/sangfor/EasyConnect/resources/shell/sslservice.sh
	sleep 2
done
```

可以和`/usr/share/sangfor/EasyConnect/resources/bin/EasyMonitor`一同在启动前端前以 root 权限运行。

正确登录的前端退出后，`CSClient`和`svpnservice`也会自行关闭，不影响下一次的使用。

## 在 docker 中运行的权限问题

一开始测试时，发现 EasyConnect 没有权限创建`tun0`，遂加`--privileged`参数运行，创建成功。

可以用`--device /dev/net/tun --cap-add NET_ADMIN`来代替`--privileged`，这样给的权限不至于过大。

## 其它坑

EasyConnect 的日志存放在`/usr/share/sangfor/EasyConnect/resources/logs`，部分登录信息存放在`/usr/share/sangfor/EasyConnect/resources/conf/easy_connect.json`，该文件由前端创建，保存了登录凭据。

`/usr/share/sangfor/EasyConnect/resources/conf/`目录的权限默认为`rwxrwxrwx`，但默认情况下`easy_connect.json`文件创建时权限为`rw-r--r--`。在某些情形下这可能会存在权限问题。
