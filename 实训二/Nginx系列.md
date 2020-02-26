[TOC]







# Nginx系列

































# 正向代理

**说明：**

nginx当正向代理的时候，通过代理访问https的网站会失败，而失败的原因是客户端同nginx代理服务器之间建立连接失败，并非nginx不能将https的请求转发出去。因此要解决的问题就是客户端如何同nginx代理服务器之间建立起连接。有了这个思路之后，就可以很简单的解决问题。我们可以配置两个SERVER节点，一个处理HTTP转发，另一个处理HTTPS转发，而客户端都通过HTTP来访问代理，通过访问代理不同的端口，来区分HTTP和HTTPS请求。 

## **1.修改nginx.conf配置文件** 

生成用户密码文件 

```shell
htpasswd ‐c /etc/nginx/passwords wjj 
```

修改nginx 

```shell
http { 
include /etc/nginx/conf.d/*.conf; 
	resolver 8.8.8.8; 
server { 
	listen 90; 
	server_name _; 
	auth_basic "User Authentication"; 
	auth_basic_user_file /etc/nginx/passwords; 
location / { 
	proxy_pass http://$http_host$request_uri; 
		} 
	}
} 
```

重启nginx 



## 2.客户端配置 

**全局的代理设置：** 

```shell
vi /etc/profile 
##代理
export http_proxy=http://用户:密码@ip:port 
export https_proxy=http://用户:密码@ip:port 
export ftp_proxy=http://用户:密码@ip:port 
```

**yum的代理设置：** 

```shell
vi /etc/yum.conf 
proxy=http://username:password@yourproxy:8080/ 
```

**wget的代理设置：** 

```shell
vi /etc/wgetrc 
http_proxy=http://username:password@proxy_ip:port/ 
ftp_proxy=http://username:password@proxy_ip:port/ 
```

## 3.测试代理

**方法一：** 

访问HTTP网站，可以直接这样的方式:

```shell
curl ‐I ‐‐proxy proxy_server‐ip:80 www.baidu.com 
```

**方法二：** 

**使用浏览器访问** 

这里使用的是firefox浏览器

![1582623559546](./assets/1582623559546.png)

![1582623570881](./assets/1582623570881.png)

![1582623578859](./assets/1582623578859.png)

**如何确定访问是不是走的代理那？** 

可以在浏览器上设置好代理后，然后将你代理的nginx关掉，然后重新打开一个网页，会发现测试不可以访问网站了！！

![1582623613946](./assets/1582623613946.png)









# Nginx配置HTTPS

## 什么是https？

HTTP：是互联网上应用最为广泛的一种网络协议，是一个客户端和服务器端请求和应答的标准（TCP），用于从WWW服务器传输超文本到本地浏览器的传输协议，它可以使浏览器更加高效，使网络传输减少。

HTTPS：全称：Hyper Text Transfer Protocol over Secure Socket Layer，则是以安全为目标的HTTP通道，简单讲是HTTP的安全版，即HTTP下加入SSL层，HTTPS的安全基础是SSL，因此加密的详细内容就需要SSL。

HTTPS协议的主要作用可以分为两种：一种是建立一个信息安全通道，来保证数据传输的安全；另一种就是确认网站的真实性。

## 配置过程

首先需要申请一个证书，可以申请一个免费的。

## 证书申请方式

### 阿里云申请

可以使用腾讯云/阿里云，云产品-》域名与网站-》SSL证书管理

![1582247220586](./assets/1582247220586.png)

![1582247253439](./assets/1582247253439.png)

![1582247285596](./assets/1582247285596.png)

![1582248165507](./assets/1582248165507.png)

![1582248190138](./assets/1582248190138.png)

![1582248221007](./assets/1582248221007.png)



![1582248246486](./assets/1582248246486.png)

然后选免费版的，一般免费版有效期是一年，然后填各种信息，提交审核就好了，审核很快的，一个小时工作时间左右吧

审核成功后就可以在证书列表里下载证书了，下载出来是一个压缩包，里面有各种版本的证书：Apache、IIS、Nginx、





### Certbot申请

官网：<https://certbot.eff.org/>

Let’s Encrypt提供了免费的证书申请服务，同时也提供了官方客户端 Certbot，打开首页，就可以得到官方的安装教程。官方教程给出了四种常用服务器和不同的Linux、Unix的安装使用方案，可以说是十分的贴心了。

![6023080-46b89fc91bd3ef7a](./assets/6023080-46b89fc91bd3ef7a.jpg)



### openssl自签证书





## 自签证书测试

### 安装nginx

```shell
yum -y install nginx
```

