[TOC]





# 第六单元-Apache（二）



## 6.1 虚拟主机

### 6.1.1 什么是虚拟主机

在一个Apache服务器上可以配置多个虚拟主机，实现一个服务器**提供多站点服务**，**其实就是访问同一个服务器上的不同目录**。**一个服务器主机可以运行多个网站，每个网站都是一个虚拟主机**。

​	

### 6.1.2 虚拟主机类型

Apache虚拟主机的实现方式有3种。

- 基于**IP**的虚拟主机
- 基于**端口**的虚拟主机
- 基于**域名**的虚拟主机





### 6.1.3 VirtualHost参数的意义	

```shell
<VirtualHost *:80>			#服务器ip和端口
    DocumentRoot "/project/code/public/www"	 #站点目录
    ServerName www.cq.com	#域名
    ServerAlias 			#给虚拟主机增加多个域名，上面网址的别名

  <Directory "/project/code/public/www">	#对根目录行为的限制
      Options FollowSymLinks ExecCGI	#followsymlinks表示允许使用符号链接，默认为禁用
      AllowOverride None 	 #表示禁止用户对目录配置文件(.htaccess进行修改)重载，普通站点不建议开启
      Order allow,deny		#是否显示列表 （在发布项目后一般是不启用，对于这个配置，针对DocumentRoot在apachede的默认文件夹外的目录生效。比如下面的例一 ）
      Allow from all
      #Deny from all  	#拒绝所有的访问
      Require all granted
  </Directory>
  
</VirtualHost>
```



### 6.1.3 启用虚拟主机的准备工作

```shell
#安装httpd
yum install httpd -y

#禁用默认的主机模式
vim /etc/httpd/conf/httpd.conf
注释下面这行内容
#DocumentRoot "/var/www/html"
```



## 6.2 基于IP的虚拟主机

### 6.2.1 配置基于IP的虚拟主机

将不同的网站挂在不同的IP上,访问不同的IP,所看到的是不同网站.因为一般服务器没那么多公网IP,而且大家一般都是用域名访问的。所以这个几乎没用。但是考试会考。



#### 6.2.1.1 为主机添加多个IP

```shell
#查看原有IP
ip a

#手动添加ip（注意添加的ip必须与虚机属于同一网络段L）
ip addr add 10.0.0.30/24 dev eth0
或者
ifconfig eth0:0 10.0.0.30		#临时的，重启后失效
```



#### 6.2.1.2 添加虚拟主机配置文件

```shell
cd /etc/httpd/conf.d/

vim virtualhost.conf
#基于IP的虚拟主机配置
<VirtualHost 10.0.0.21:80>
  DocumentRoot "/var/www/bw"
</VirtualHost>

<VirtualHost 10.0.0.30:80>
  DocumentRoot "/var/www/wg"
</VirtualHost>


####创建目录
mkdir -p /var/www/bw
mkdir -p /var/www/wg

####创建测试文件
echo 'this is bw' >>/var/www/bw/index.html
echo 'this is wg' >>/var/www/wg/index.html
```

**测试访问：**

```shell
    /etc/init.d/httpd restart

[root@ c6m01 conf.d]# elinks -source 10.0.0.21:80
this is bw

[root@ c6m01 conf.d]# elinks -source 10.0.0.30:80
this is wg

```



## 6.3 基于端口的虚拟主机

通过访问同一个IP(或者域名)的不同端口来访问到不同的文件。



### 6.3.1 配置基于端口的虚拟主机

**在主配置文件添加监听端口**

```shell
#修改主配置文件
vim /etc/httpd/conf/httpd.conf 
#在原有行Listen 80行的基础上， 在添加一行
Listen 80
Listen 81


#修改虚拟主机配置文件
cd /etc/httpd/conf.d/
vim virtualhost.conf
#基于IP的虚拟主机配置
<VirtualHost 10.0.0.21:80>
  DocumentRoot "/var/www/bw"
</VirtualHost>

<VirtualHost 10.0.0.30:80>
  DocumentRoot "/var/www/wg"
</VirtualHost>


#基于端口的虚拟主机配置
<VirtualHost 10.0.0.21:81>
  DocumentRoot "/var/www/bw"
</VirtualHost>
```

![1567654139941](assets/1567654139941.png)



**测试访问：**

```shell
/etc/init.d/httpd restart

[root@ c6m01 conf.d]# elinks -source 10.0.0.21:80
this is bw

[root@ c6m01 conf.d]# elinks -source 10.0.0.21:81
this is bw
```





## 6.4 基于域名的虚拟主机

这是一种最通用的情况,已经给服务器设置了多个域名，然后希望访问不同的域名来访问不同的网站文件。



### 6.4.1 配置基于域名的虚拟主机

```shell
cd /etc/httpd/conf.d/
vim virtualhost.conf
#基于域名拟主机配置
<VirtualHost 10.0.0.21:80>
  DocumentRoot "/var/www/bw"
  ServerName    www.bw.com		#此处添加ServerName并配置域名
</VirtualHost>

<VirtualHost 10.0.0.30:80>
  DocumentRoot "/var/www/wg"		#此处添加ServerName并配置域名
  ServerName    www.wg.com
</VirtualHost>

#基于IP的虚拟主机配置
<VirtualHost 10.0.0.21:80>
  DocumentRoot "/var/www/bw"
</VirtualHost>

<VirtualHost 10.0.0.30:80>
  DocumentRoot "/var/www/wg"
</VirtualHost>


#基于端口的虚拟主机配置
<VirtualHost 10.0.0.21:81>
  DocumentRoot "/var/www/bw"
</VirtualHost>
```



### 6.4.2 添加本地hosts解析并测试

```shell
vim /etc/hosts

127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.0.0.21 www.bw.com
10.0.0.30 www.wg.com
```

**测试访问域名：**

```shell
/etc/init.d/httpd restart

[root@ c6m01 conf.d]# elinks -source www.bw.com
this is bw

[root@ c6m01 conf.d]# elinks -source www.wg.com
this is wg

```





## 6.5 认证授权和访问控制

**ip访问控制：**
目录控制语句以<Directory 目录名>开头；以</Directory>结束。
先允许后拒绝，默认拒绝所有：Order allow,deny
先拒绝后允许，默认允许所有：Order deny,allow
AllowOverride None：不允许覆盖，即不允许从根目录向子目录覆盖。即默认情况下拒绝从根目录下向子目录访
问，如果要看根目录下的一个子目录，必须先打开子目录的访问权限。
Order allow，deny：访问控制的顺序，先匹配允许，再匹配拒绝，默认拒绝。
Allow from all：表示允许任何地址访问。
Allow from 172.18.49.0/24
Deny from 172.18.49.102

**用户身份认证授权**

主要参数：

```
Authtype 		是认证类型 Basic apache自带的基本认证
Authname 		认证名字，是提示你输入密码的对话框的提示语
Authuserfile 	是存放认证用户的文件
require user 	用户名 允许指定的一个或多个用户访问，如果认证文件里面还有其他用户，还是不能访问
require valid-user 所有认证文件里面的用户都可以访问
require group 		组名 授权给一个组，较少用
```

配置：

```
useradd tom
htpasswd -c /etc/httpd/webpasswd tom

cd /etc/httpd/conf.d
vim virtualhost.conf
#基于IP的虚拟主机配置
<VirtualHost 10.0.0.21:80>
  DocumentRoot "/var/www/bw"
  ServerName    www.bw.com
  <Directory /var/www/bw>
  AuthType Basic
  AuthName Password
  AuthUserFile /etc/httpd/webpasswd
  require user tom
  </Directory>
</VirtualHost>
```



![1567671235083](assets/1567671235083.png)



绑定windows下hosts

**测试：www.bw.com**

![1567672000036](assets/1567672000036.png)

