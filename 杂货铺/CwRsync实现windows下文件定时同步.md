







# cwRsync实现windows下文件定时同步



- cwRsync实现windows下文件定时同步
  - 一、安装配置 Rsync 服务端
    - [Window版服务端：](#window版服务端)
  - [二、安装配置 Rsync 客户端](#二-安装配置-rsync-客户端)



官网：http://rsync.samba.org/

Linux版下载：http://rsync.samba.org/download.html

Windows版下载：https://www.itefix.no/i2/cwrsync-get 选(Free Edition 免费版)

客户端：cwRsyncServer-v4.1.0

服务端：cwRsync-v4.1.0

## 一、安装配置 Rsync 服务端

### Window版服务端：

1. 点击服务端程序进行安装，安装过程中提示输入服务端程序以服务运行时的用户名和密码。可自定义，也可用默认的用户名密码(如：administrator)。
2. 安装完成之后，进入程序安装目录根目录，打开配置文件（如：C:\Program Files (x86)\ICW\rsyncd.conf ），进入配置。

```bash
uid = 0 
gid = 0 
use chroot = false
strict modes = false
log file = rsyncd.log
pid file = rsyncd.pid
read only = yes
list = no
port = 18173
auth users= rsyncuser
secrets file = rsyncd.crt

# Module definitions
# Remember cygwin naming conventions : c:\work becomes /cygwin/c/work
#

[www]
path = /cygdrive/c/www
read only = false
transfer logging = yes
hosts allow = 192.168.1.2
hosts deny = 0.0.0.0/0
```

3.在安装目录C:\Program Files (x86)\ICW 下创建rsyncd.secrets密码文件，里面内容为 用户名:密码

```bash
rsyncuser:rsyncuser
```

修改rsyncd.secrets权限为600

```bash
"C:\Program Files (x86)"\ICW\bin\chmod.exe 600 rsyncd.crt
```

4.启动rsync服务 运行---cmd---services.msc---RsyncServer

## 二、安装配置 Rsync 客户端

1. 安装Rsync客户端程序，直至安装完成。
2. 测试服务器Rsync的连通性。在Rsync客户端所在计算机telnet Rsync服务端所在计算的相应地址和端口

telnet 192.168.1.20 18173

客户端推送示例：

```
d:\tools\cwRsync_5.7.1_x86_Free\bin
rsync -avz --port=18173 /cygdrive/d/Amer_Sports_DMS 192.168.88.31::amer
```

排除多个目录推送

```
d:
cd tools/cwRsync_5.7.1_x86_Free/bin
rsync -avz --port=18173 --exclude-from 'exclude_amer.txt' /cygdrive/d/Amer_Sports_DMS 172.22.22.175::amer
```

exclude_amer.txt在

```
d:/tools/cwRsync_5.7.1_x86_Free/bin目录下
```

exclude_amer.txt内容是

```
APP_HOME/temp/*
APP_HOME/inputData/*
webapps/ROOT/tempdownload/*
webapps/ROOT/exportlog/*
```