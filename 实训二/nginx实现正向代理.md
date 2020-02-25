[TOC]



# nginx实现正向代理

**说明：**

nginx当正向代理的时候，通过代理访问https的网站会失败，而失败的原因是客户端 

同nginx代理服务器之间建立连接失败，并非nginx不能将https的请求转发出去。因此要解 

决的问题就是客户端如何同nginx代理服务器之间建立起连接。有了这个思路之后，就可以 

很简单的解决问题。我们可以配置两个SERVER节点，一个处理HTTP转发，另一个处理 

HTTPS转发，而客户端都通过HTTP来访问代理，通过访问代理不同的端口，来区分HTTP 

和HTTPS请求。 

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

![1582623559546](assets/1582623559546.png)

![1582623570881](assets/1582623570881.png)

![1582623578859](assets/1582623578859.png)

**如何确定访问是不是走的代理那？** 

可以在浏览器上设置好代理后，然后将你代理的nginx关掉，然后重新打开一个网 

页，会发现测试不可以访问网站了！！

![1582623613946](assets/1582623613946.png)