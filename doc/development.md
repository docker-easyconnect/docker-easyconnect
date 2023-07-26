# 开发说明

## 项目结构一览

```
docker-easyconnect
├─ build-args: 各个版本、架构的编译参数
│  └─ ...
├─ build-scripts:  构建镜像过程中被 Dockerfile 调用的脚本
│  ├─ add-qemu.sh: 确定是否需要安装 qemu、需要安装哪些 qemu 软件包
│  ├─ config-apt.sh:       配置 apt 使用的镜像
│  ├─ get-echost-names.sh: 确认容器的架构与 EC 的架构及相关
│  ├─ install-vpn-gui.sh:  安装 vpn 客户端本体
│  └─ mk-qemu-wrapper.sh:  用 wrapper 替换要用 qemu 模拟的二进制文件
├─ doc: 文档
│  └─ ...
├─ Dockerfile:       VNC 版镜像的 dockerfile
├─ Dockerfile.build: 构建镜像所需的某些程序（多阶段构建的第一阶段）
├─ Dockerfile.cli:   命令行版镜像的 dockerfile
├─ Dockerfile.vncless: 构建无 VNC 的 GUI 版镜像的 docker
├─ docker-root: 要添加到镜像根目录的静态文件
│  ├─ etc
│  │  ├─ danted.conf.sample: danted 配置，容器启动时其副本会被进一步配置
│  │  ├─ tinyproxy.conf:     用于作为 http 代理的 tinyproxy 配置文件
│  │  └─ tinyproxy-novnc.conf: 用于转发（反代）novnc 的 tinyproxy 配置
│  └─ usr
│     ├─ bin
│     │  ├─ loginctl: 供 aTrust 调用
│     │  └─ xdg-open: 用于记录、弹出深信服 VPN 弹出的 URL
│     ├─ local
│     │  └─ bin
│     │     ├─ detect-iptables.sh:  检测 iptables 应该使用 ntf 还是 legacy
│     │     ├─ detect-route.sh:     确定策略路由的方式
│     │     ├─ get-vnc-clip.sh:     供用户调用以获取 VNC 剪贴板内容
│     │     ├─ novnc-easy-novnc.sh: 用 easy-novnc 启动 novnc（见 build.md）
│     │     ├─ novnc-min-size.sh:   用 min-size 方式启动 novnc
│     │     ├─ set-vnc-clip.sh:     供用户调用以设置 VNC 剪贴板内容
│     │     ├─ start-sangfor.sh:    启动深信服 VPN
│     │     ├─ start.sh:            容器入口，初始化、启动多种服务及 VPN
│     │     ├─ test-libs.sh:        用于开发，用于输出给定 elf 缺失的库文件
│     │     ├─ test-sangfor-libs.sh: 用于开发，输出 VPN 本体缺失的库文件
│     │     └─ vpn-config.sh:       用于确定运行 VPN 的方式
│     ├─ sbin
│     │  └─ xtables-echook-multi: iptables 系列命令的 hook
│     └─ share
│         └─ sangfor
│            ├─ EasyConnect
│            │  └─ resources
│            │     └─ shell
│            │         └─ open_browser.sh: 作用同 xdg-open
│            └─ iptables-type: 记录使用 ntf 还是 legacy，默认前者
├─ fake-hwaddr: 用 LD_PRELOAD 伪造 MAC 地址，主要用于 rootless podman
│  ├─ fake-hwaddr.c
│  └─ Makefile
└─ ...
```

## 路由的处理

深信服的 VPN 启动后会启动一个 tun 并设置它的路由表。其中这些路由有可能覆盖我们访问容器端口（socks5 代理、vnc 等）的源地址，导致这些服务向我们回复的数据包被路由到 tun，从而使得这些服务不可用。

为了解决这个问题，容器启动时（此时 VPN 尚未启动）会将路由表备份到路由表 2，之后使用策略路由来让上面提到的数据包走路由表 2，即正确路由到宿主机网络而非 VPN。（见于 [`docker-root/usr/local/bin/detect-route.sh`](../docker-root/usr/local/bin/detect-route.sh)）
