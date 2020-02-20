







# Docker入门

# Docker 简介

## 什么是 Docker

Docker 最初是 dotCloud 公司创始人 Solomon Hykes 在法国期间发起的一个公司内部项目，它是基于 dotCloud 公司多年云服务技术的一次革新，并于 2013 年 3 月以 Apache 2.0 授权协议开源，主要项目代码在 GitHub 上进行维护。Docker 项目后来还加入了 Linux 基金会，并成立推动 开放容器联盟（OCI）。

Docker 自开源后受到广泛的关注和讨论，至今其 GitHub 项目 已经超过 5 万 4 千个星标和一万多个 fork。甚至由于 Docker 项目的火爆，在 2013 年底，dotCloud 公司决定改名为 Docker。Docker 最初是在 Ubuntu 12.04 上开发实现的；Red Hat 则从 RHEL 6.5 开始对 Docker 进行支持；Google 也在其 PaaS 产品中广泛应用 Docker。

Docker 使用 Google 公司推出的 Go 语言 进行开发实现，基于 Linux 内核的 cgroup，namespace，以及 AUFS 类的 Union FS 等技术，对进程进行封装隔离，属于 操作系统层面的虚拟化技术。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。最初实现是基于 LXC，从 0.7 版本以后开始去除 LXC，转而使用自行开发的 libcontainer，从 1.11 开始，则进一步演进为使用 runC 和 containerd。

![docker-on-linux](assets/docker-on-linux.png)

> runc 是一个 Linux 命令行工具，用于根据 OCI容器运行时规范 创建和运行容器。

> containerd 是一个守护程序，它管理容器生命周期，提供了在一个节点上执行容器和管理镜像的最小功能集。

​	



## Docker与传统虚拟机的区别

​	Docker 在容器的基础上，进行了进一步的封装，从文件系统、网络互联到进程隔离等等，极大的简化了容器的创建和维护。使得 Docker 技术比虚拟机技术更为轻便、快捷。

​	容器与虚拟机有着类似的资源隔离和分配的优点，但拥有不同的架构方法，容器架构更加便携，高效。

| 特性       | 虚拟机的架构 | 容器的架构     |
| ---------- | ------------ | -------------- |
| 启动       | 分钟级       | 秒级           |
| 性能       | 弱于原生     | 接近原生       |
| 硬盘使用   | 一般为GB     | 一般为MB       |
| 系统支持量 | 一般几十个   | 单机上千个容器 |

​	传统虚拟化是在硬件层面实现虚拟化，需要有额外的虚拟机管理应用和虚拟机操作系统层，而Docker容器是在操作系统层面实现虚拟化，应用进程直接运行于宿主的内核，容器内没有自己的内核，而且也没有进行硬件虚拟，直接复用本地主机操作系统，更加轻量级。

​	**虚拟机的架构**： 每个虚拟机都包括应用程序、必要的二进制文件和库以及一个完整的客户操作系统(Guest OS)，尽管它们被分离，它们共享并利用主机的硬件资源，将近需要十几个 GB 的大小。

​	**容器的架构：** 容器包括应用程序及其所有的依赖，但与其他容器共享内核。它们以独立的用户空间进程形式运行在主机操作系统上。他们也不依赖于任何特定的基础设施，Docker 容器可以运行在任何计算机上，任何基础设施和任何云上。





## 基本概念

Docker 包括三个基本概念

- 镜像（Image）
- 容器（Container）
- 仓库（Repository）
  理解了这三个概念，就理解了 Docker 的整个生命周期。





# 安装Docker

## 安装 Docker CE

> 注意：切勿在没有配置 Docker YUM 源的情况下直接使用 yum 命令安装 Docker.

**卸载旧版本**
旧版本的 Docker 称为 docker 或者 docker-engine，使用以下命令卸载旧版本：

```shell
sudo yum remove docker \
docker-client \
docker-client-latest \
docker-common \
docker-latest \
docker-latest-logrotate \
docker-logrotate \
docker-selinux \
docker-engine-selinux \
docker-engine
```

鉴于国内网络问题，强烈建议使用国内源。

**修改yum源为阿里云**

```shell
yum install -y wget 
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache

yum -y install gcc gcc-c++  cmake curl  nmap  lrzsz unzip zip ntpdate telnet vim tree bash-completion iptables-services ntp dos2unix lsof net-tools sysstat
```

**安装依赖包**

```shell
sudo yum install -y yum-utils device-mapper-persistent-data lvm2
```

**添加Docker软件源**

```shell
wget -O /etc/yum.repos.d/docker-ce.repo  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
或者
#sudo yum-config-manager --add-repo https://mirrors.ustc.edu.cn/docker-ce/linux/centos/docker-ce.repo
```

**关闭测试版本list（只显示稳定版）**

```shell
sudo yum-config-manager --enable docker-ce-edge	
```

**NO.1 直接安装Docker CE （will always install the highest  possible version，可能不符合你的需求）**

```shell
yum install docker-ce -y
```

**NO.2 指定版本安装**

```shell
yum list docker-ce --showduplicates|sort -r  
yum install docker-ce-18.06.3.ce -y
```

**启动 Docker CE**

```shell
sudo systemctl enable docker
sudo systemctl start docker
```

**建立 docker 用户组**

默认情况下，docker 命令会使用 Unix socket 与 Docker 引擎通讯。而只有 root 用户和 docker 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用 root 用户。因此，更好地做法是将需要使用 docker 的用户加入 docker 用户组。

建立 docker 组：

```shell
sudo groupadd docker
```

将当前用户加入 docker 组：s

```shell
sudo usermod -aG docker $USER
```

退出当前终端并重新登录，进行如下测试。

**测试**

```
docker run hello-world
docker version
```

**卸载**

```
yum remove -y docker-ce
rm -rf /var/lib/docker
```

**添加内核参数**

如果在 CentOS 使用 Docker CE 看到下面的这些警告信息：

```
WARNING: bridge-nf-call-iptables is disabled
WARNING: bridge-nf-call-ip6tables is disabled
```

请添加内核配置参数以启用这些功能。

```
sudo tee -a /etc/sysctl.conf <<-EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl -p
```



## 使用脚本自动安装

在**测试**或**开发环境**中 Docker 官方为了简化安装流程，提供了一套便捷的安装脚本，CentOS 系统上可以使用这套脚本安装，另外可以通过 --mirror 选项使用国内源进行安装：

```
curl -fsSL get.docker.com -o get-docker.sh
sudo sh get-docker.sh --mirror Aliyun
sudo sh get-docker.sh --mirror AzureChinaCloud
```

执行这个命令后，脚本就会自动的将一切准备工作做好，并且把 Docker CE 的稳定(stable)版本安装在系统中。

## 开启实验特性

一些 docker 命令或功能仅当 **实验特性** 开启时才能使用，请按照以下方法进行设置。

**开启 Docker CLI 的实验特性**

编辑 `~/.docker/config.json` 文件，新增如下条目

```json
{
  "experimental": "enabled"
}
```

或者通过设置环境变量的方式：

**Linux/macOS**

```bash
$ export DOCKER_CLI_EXPERIMENTAL=enabled
```

**开启 Dockerd 的实验特性**

编辑 `/etc/docker/daemon.json`，新增如下条目

```json
{
  "experimental": true
}
```



# 使用 Docker 镜像

镜像是 Docker 的三大组件之一。

Docker 运行容器前需要本地存在对应的镜像，如果本地不存在该镜像，Docker 会从镜像仓库下载该镜像。

## 镜像加速器

国内从 Docker Hub 拉取镜像有时会遇到困难，此时可以配置镜像加速器。国内很多云服务商都提供了国内加速器服务，例如：

- [Azure 中国镜像 `https://dockerhub.azk8s.cn`](https://github.com/Azure/container-service-for-azure-china/blob/master/aks/README.md#22-container-registry-proxy)
- [阿里云加速器(需登录账号获取)](https://cr.console.aliyun.com/cn-hangzhou/mirrors)
- [网易云加速器 `https://hub-mirror.c.163.com`](https://www.163yun.com/help/documents/56918246390157312)

> 由于镜像服务可能出现宕机，建议同时配置多个镜像。

**Ubuntu 16.04+、Debian 8+、CentOS 7**

对于使用 [systemd](https://www.freedesktop.org/wiki/Software/systemd/) 的系统，请在 `/etc/docker/daemon.json` 中写入如下内容（如果文件不存在请新建该文件）

```json
cat >/etc/docker/daemon.json<<EOF
{
  "registry-mirrors": [
    "https://dockerhub.azk8s.cn",
    "https://hub-mirror.c.163.com"
  ]
}
EOF
```

> 注意，一定要保证该文件符合 json 规范，否则 Docker 将不能启动。

之后重新启动服务。

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

> 注意：如果您之前查看旧教程，修改了 `docker.service` 文件内容，请去掉您添加的内容（`--registry-mirror=https://dockerhub.azk8s.cn`）。



**检查加速器是否生效**

执行 `docker info`，如果从结果中看到了如下内容，说明配置成功。

```shell
[root@ localhost ~]# docker info|tail -5
Registry Mirrors:
 https://dockerhub.azk8s.cn/
 https://hub-mirror.c.163.com/
Live Restore Enabled: false
```



## 获取镜像

Docker Hub 上有大量的高质量的镜像可以用。

从 Docker 镜像仓库获取镜像的命令是 docker pull。其命令格式为：

```shell
docker pull [选项] [Docker Registry 地址[:端口号]/]仓库名[:标签]
```

具体的选项可以通过 `docker pull --help `命令看到。

镜像名称的格式:

Docker 镜像仓库地址：地址的格式一般是 <域名/IP>[:端口号]。默认地址是 Docker Hub。
仓库名：如之前所说，这里的仓库名是两段式名称，即 <用户名>/<软件名>。对于 Docker Hub，如果不给出用户名，则默认为 library，也就是官方镜像。

举例：

```
docker pull centos:7
```

上面的命令中没有给出 Docker 镜像仓库地址，因此将会从 Docker Hub 获取镜像。而镜像名称是` centos:7`，因此将会获取官方镜像 `library/centos` 仓库中标签为` 7 `的镜像。



## 列出镜像

列出已经下载下来的镜像，可以使用 `docker image ls`或`docker images` 命令。

```shell
[root@ localhost ~]# docker image ls
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
centos              7                   5e35e350aded        3 months ago        203MB
hello-world         latest              fce289e99eb9        13 months ago       1.84kB
[root@ localhost ~]# docker images
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
centos              7                   5e35e350aded        3 months ago        203MB
hello-world         latest              fce289e99eb9        13 months ago       1.84kB
```

列表包含了 `仓库名`、`标签`、`镜像 ID`、`创建时间` 以及 `所占用的空间`。

**镜像体积**

```shell
[root@ localhost ~]# docker system df
TYPE                TOTAL               ACTIVE              SIZE                RECLAIMABLE
Images              2                   1                   203MB               203MB (99%)
Containers          1                   0                   0B                  0B
Local Volumes       0                   0                   0B                  0B
Build Cache         0                   0                   0B                  0B
```















