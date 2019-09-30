[TOC]







# 第四单元 FTP服务



## 4.1 FTP 服务概述

**FTP** 是`File Transfer Protocol`（**文件传输协议**）的英文简称，它**工作在OSI模型的第七层**，TCP模型的第四层上，即传输，使用TCP传输而不是UDP，这样FTP客户在和服务器建立连接前就要经过一个被广为熟知的”三次握手”的过程，它带来的意义在于客户与服务器之间的连接是可靠的，而且是面向连接，为数据的传输提供了可靠的保证。

FTP服务使用FTP协议（文件传输协议）来进行**文件的上传和下载**，可以非常方便的进行远距离的文件传输，还支持断点续传功能，可以大幅度地减小CPU和网络带宽的开销，并实现相应的安全控制。



ps:主动模式要求客户端和服务器端同时打开并且监听一个端口以建立连接。在这种情况下，客户端由于安装了防火墙会产生一些问题。所以，创立了被动模式。被动模式只要求服务器端产生一个监听相应端口的进程，这样就可以绕过客户端安装了防火墙的问题。

FTP和NFS、Samba ：三大文件共享服务器。

FTP软件：**vsftpd**,wu-ftp,proftp等

最常用的FTP服务器架设使用vsftpd软件 ：安全“ very secure”



### 4.1.1 FTP两种工作模式及原理

ftp协议的连接方式有两种，一种是命令连接，一种是数据连接，而ftp的数据连接模式也有两种，一种是主动模式，一种是被动模式。

FTP会话连接时包含了两个通道，一个叫**控制通道，端口号21**；一个叫**数据通道，端口号20**。 

控制通道：控制通道是和FTP服务器进行沟通的通道，连接FTP，**发送FTP指令都是通过控制通道来完成的**。 

数据通道：数据通道是和FTP服务器进行**文件传输或者列表的通道**。



FTP协议中，**控制连接均有客户端发起**，而数据连接有两种工作方式：PORT方式和PASV方式

1.FTP的PORT（主动模式）和PASV（被动模式）

(1) PORT（主动模式）

PORT中文称为主动模式，工作的原理： 

FTP客户端连接到FTP服务器的21端口→发送用户名和密码登录，登录成功后要list列表或者读取数据时→客户端随机开放一个端口（1024以上）→发送 PORT命令到FTP服务器，告诉服务器客户端采用**主动模式**并开放端口→FTP服务器收到PORT主动模式命令和端口号后，通过服务器的20端口和客户端开放的端口连接，发送数据，原理如下图：

![1567049809488](assets/1567049809488.png)



(2) PASV（被动模式）

PASV是Passive的缩写，中文成为被动模式，工作原理：

FTP客户端连接到FTP服务器的21端口→发送用户名和密码登录，登录成功后要list列表或者读取数据时→发送PASV命令到FTP服务器→ 服务器在本地随机开放一个端口（1024以上）→然后把开放的端口告诉客户端， 客户端再连接到服务器开放的端口进行数据传输，原理如下图：

![1567049833778](assets/1567049833778.png)






​	

### 4.1.2 vsftpd软件

#### 4.1.2.1 vsftpd简介

软件：vsftpd

服务名：vsftpd

配置文件：/etc/vsftpd/vsftpd.conf



#### 4.1.2.2 安装vsftpd服务端和客户端

```shell
yum install -y vsftpd   #服务端
yum install -y lftp		#客户端
/etc/init.d/vsftpd start
chkconfig vsftpd on

# 关闭防火墙和Selinux
service iptables stop
setenforce 0
sed -i '/^SELINUX=/s#SELINUX=.*#SELINUX=disabled#g' /etc/sysconfig/selinux
```



#### 4.1.2.3 配置文件结构

```shell
vsftpd的核心文件和目录：
/etc/pam.d/vsftpd 			#基于PAM认证的vsftpd验证配置文件
/etc/logrotate.d/vsftpd 	#日志轮转备份配置文件
/etc/rc.d/init.d/vsftpd 	#vsftpd启动脚本，供server调用
/etc/vsftpd 				#vsftpd的主目录
/etc/vsftpd/ftpusers 		#默认的黑名单
/etc/vsftpd/user_list 		#指定允许使用vsftpd的用户列表文件
/etc/vsftpd/vsftpd.conf 	#vsftpd主配置文件
/var/ftp 					#vsftpd默认共享目录(匿名用户的根目录)
/etc/vsftpd/vsftpd_conf_migrate.sh 	#是vsftpd操作的一些变量和设置脚本
```

vsftp传输方式默认是PORT模式

```
port_enable=YES|NO
```

**vsftp提供3种远程的登录方式：** 
（1）匿名用户登录方式 
　　就是不需要用户名和密码。就能登录到服务器vsftp（默认只有下载权限）
（2）本地用户方式 
　　需要帐户名和密码才能登录。而且，这个帐户名和密码，都是在你linux系统里面，已经有的用户。 
（3）虚拟用户方式 
　　同样需要用户名和密码才能登录。但是和上面的区别就是，这个用户名和密码，在你linux系统中是没有的(没有该用户帐号)

#### 4.1.2.4 vsftpd默认配置

```shell
[root@ c6m01 vsftpd]# cp vsftpd.conf{,.bak}
[root@ c6m01 vsftpd]# egrep -v '^$|^#' vsftpd.conf
anonymous_enable=YES
local_enable=YES
write_enable=YES
cal_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES
```

#### 4.1.2.5 常见参数含义

```shell
use_localtime=YES          #ftp时间和系统同步,如果启动有错误，请注销
reverse_lookup_enable=NO   #添加此行，解决客户端登陆缓慢问题
listen_port=21    		   #默认无此行，ftp端口为21
anonymous_enable=NO　　  	  #禁止匿名用户
local_enable=YES		   #设定本地用户可以访问
write_enable=YES         	#全局设置，是否容许写入
local_umask=022 			#设定上传后文件的权限掩码
local_root=/home/tom		#本地用户ftp根目录，默认是本地用户的家目录
local_max_rate=0			#本地用户最大传输速率（字节）。0为不限制
anon_upload_enable=NO 		#禁止匿名用户上传。
anon_mkdir_write_enable=NO  #禁止匿名用户建立目录
connect_from_port_20=YES 	#设定端口20进行数据连接
chown_uploads=NO 			#设定禁止上传文件更改宿主
pam_service_name=vsftpd 	#设定PAM服务下Vsftpd的验证配置文件名，PAM验证将参考/etc/pam.d/下
userlist_enable=YES    		#设为YES的时候，如果一个用户名是在userlist_file参数指定的文件中，那么在要求他们输入密码之前，会直接拒绝他们登陆
tcp_wrappers=YES  是否支持tcp_wrapper
idle_session_timeout=300    #超时设置
data_connection_timeout=1    #空闲1秒后服务器断开
```

**测试访问：**

**验证结果：匿名用户权限：默认只可以下载**

Windows资源管理器输入：ftp://10.0.0.21/

![1567064195437](assets/1567064195437.png)

测试上传的权限：

![1567064263921](assets/1567064263921.png)

测试删除权限：

![1567064311632](assets/1567064311632.png)





## 4.2 匿名用户登录

### 4.2.1 匿名用户常用参数

```shell
anon_root=/var/ftp				#匿名用户默认共享目录
anon_upload_enable=YES 			#启用匿名用户上传文件的功能（文件夹不成）
anon_mkdir_write_enable=YES 	#开放匿名用户写和创建目录的权限（管理员权限）
anon_other_write_enable=YES 	#允许匿名用户重命名，删除

[root@ c6m01 vsftpd]# cat vsftpd.conf
#匿名用户权限相关
anonymous_enable=YES
anon_root=/var/ftp
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES
####
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES

[root@ c6m01 ftp]# /etc/init.d/vsftpd restart
```

### 4.2.1 测试匿名用户登录

所在文件夹要有写入权限 例如：`chmod -R o+w /var/ftp/ `

匿名用户家目录/var/ftp权限是755，这个权限是不能改变的。

![1567065435709](assets/1567065435709.png)





## 4.3 本地用户默认配置

### 4.3.1 创建本地用户tom并设置密码

如果tom用户已存在则不需要创建

```shell
useradd   tom
echo '123456'|passwd --stdin tom
```

### 4.3.2 本地用户常用参数

```shell
local_enable=YES	#设定本地用户可以访问
write_enable=YES	#全局设置，是否容许写入（无论是匿名用户还是本地用户，若要启用上传权限的话，就要开启他）
local_umask=022 	#设定上传后文件的权限掩码
local_root=/home/tom		#本地用户ftp根目录，默认是本地用户的家目录
local_max_rate=0			#本地用户最大传输速率（字节）。0为不限制
```

### 4.3.3 测试本地用户上传下载

**使用winscp客户端**

![1567330500061](assets/1567330500061.png)



![1567330557462](assets/1567330557462.png)











## 4.4 FTP客户端

### 4.4.1 Linux下FTP客户端

```shell
1. yum install -y lftp

在linux端使用ftp或者lftp命令登录vsftpd服务
lftp使用介绍
lftp 是一个功能强大的下载工具，它支持访问文件的协议: ftp, ftps, http, https, hftp, fish.(其中ftps和https需要在编译的时候包含openssl库)。lftp的界面非常想一个shell: 有命令补全，历史记录，允许多个后台任务执行等功能，使用起来非常方便。它还有书签、排队、镜像、断点续传、多进程下载等功能。

2. lftp登录：

lftp ftp://user:password@site:port 
lftp user:password@site:port 
lftp site -p port -u user,password 
lftp site:port -u user,password

3. lftp常用命令：
ls  	显示远端文件列表(!ls 显示本地文件列表)。 
cd  	切换远端目录(lcd 切换本地目录)。 
get 	下载远端文件。 
mget 	下载远端文件(可以用通配符也就是 *)。 
pget 	使用多个线程来下载远端文件, 预设为五个。 
mirror 	下载/上传(mirror -R)/同步 整个目录。 
put 	上传文件。 
mput 	上传多个文件(支持通配符)。 
mv 		移动远端文件(远端文件改名)。 
rm 		删除远端文件。 
mrm 	删除多个远端文件(支持通配符)。 
mkdir 	建立远端目录。 
rmdir 	删除远端目录。 
pwd 	显示目前远端所在目录(lpwd 显示本地目录)。 
du 		计算远端目录的大小 
! 		执行本地 shell的命令(由于lftp 没有 lls, 故可用 !ls 来替代) 
lcd 	切换本地目录 
lpwd 	显示本地目录 
alias 	定义别名 
bookmark 	设定书签。 
exit 		退出ftp
```

注意点：

1. ftp只能上传和下载文件，不能对文件夹进行操作，如果想上传/下载文件夹需要进行压缩/解压缩操作

2. ftp服务器登录通常使用匿名登录方式(用户名：anonymous，匿名用户只能在指定目录范围内登录)

3. lftp第三方ftp客户端，可以进行目录操作

![1567869702118](assets/1567869702118.png)



### 4.4.2 Windows下FTP客户端

1.个人喜欢xftp和winscp工具。

2.windows自带的资源管理器也可以登录ftp

![1567330816772](assets/1567330816772.png)



## 4.5 FTP限速等参数	

```shell
max_clients=50 	#设置vsftpd允许的最大连接数，默认值为0，表示不受限制。若设置为100时，则同时允许有100个连接，超出的将被拒绝。只有在standalone模式运行才有效。 
max_per_ip=10 	#设置每个IP允许与FTP服务器同时建立连接的数目。默认值为0，表示不受限制。只有在standalone模式运行才有效。 
anon_max_rate=10M 	#设置匿名登入者使用的最大传输速度，单位为B/s，0表示不限制速度。默认值为0。 
local_max_rate=10M 	#本地用户使用的最大传输速度，单位为B/s，0表示不限制速度。预设值为0。 
```

![QQ图片20190904233419](assets/QQ图片20190904233419.jpg)

