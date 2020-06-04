[TOC]







# Nginx 系列

[TOC]



# nginx 编译安装

**1、nginx有哪些优点**

- 更快
  这表现在两个方面：一方面，在正常情况下，单次请求会得到更快的响应； 另一方在高峰期（如有数以万计的并发请求），Nginx可以比其他Web服务器更快地响应请

- 高扩展性
  Nginx的设计极具扩展性，它完全是由多个不同功能、不同层次、不同类型且耦合度极
  低的模块组成。因此，当对某一个模块修复Bug或进行升级时，可以专注于模块自身，无须
  在意其他。

- 高可靠性
  Nginx的高可靠性来自于其核心框架代码
  的优秀设计、模块设计的简单性;官方提供的常用模块都非常稳定，每个worker进程
  相对独立，master进程在1个worker进程出错时可以快速“拉起”新的worker子进程提供服务。
- 低内存消耗
  一般情况下，10000个非活跃的HTTP Keep-Alive连接在Nginx中仅消耗2.5MB的内存，
- 单机支持10万以上的并发连接
  理论上，Nginx支持的并发连接上限取决于内存，10万远未封顶。
- 热部署
  master管理进程与worker工作进程的分离设计，使得Nginx能够提供热部署功能，即可以
  在7×24小时不间断服务的前提下，升级Nginx的可执行文件。并且也支持不停止服务就
  更新配置项、更换日志文件等功能
- 环境要求:
  linux系统内核需要2.6及以上版本才能使用epoll模型.
  而在Linux上使用select或poll来解决事件的多路复用，是无法解决高并发压力问题
  的



**2、安装GCC与dev库**

- GCC编译器:`yum install gcc gcc-c++ -y`
- 正则表达式PCRE库:`yum install -y pcre pcre-devel`
- zlib压缩库:`yum install -y zlib zlib-devel`
- OpenSSL开发库:`yum install -y openssl openssl-devel`



**3、部署**

```bash
groupadd  nginx
useradd -M -s /sbin/nologin -g nginx  nginx
yum -y install zlib zlib-devel gcc-c++ libtool  openssl openssl-devel  wget pcre pcre-devel
wget http://nginx.org/download/nginx-1.18.0.tar.gz
tar -zxvf nginx-1.18.0.tar.gz
cd nginx-1.18.0
./configure \
--prefix=/usr/local/nginx \
--user=nginx \
--group=nginx \
--with-file-aio \
--with-threads \
--with-http_addition_module \
--with-http_auth_request_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_gunzip_module \
--with-http_gzip_static_module \
--with-http_mp4_module \
--with-http_random_index_module \
--with-http_realip_module \
--with-http_secure_link_module \
--with-http_slice_module \
--with-http_ssl_module \
--with-http_stub_status_module \
--with-http_sub_module \
--with-http_v2_module \
--with-mail \
--with-mail_ssl_module \
--with-stream \
--with-stream_realip_module \
--with-stream_ssl_module \
--with-stream_ssl_preread_module 

make && make install
echo 'export PATH=/usr/local/nginx/sbin/:$PATH' >>/etc/profile
source /etc/profile
```

**4、configure的命令参数**
列出configure包含的参数:./configure --help

通用配置选项解释

| 选项                  | 解释                                                         |
| :-------------------- | :----------------------------------------------------------- |
| --prefix=PATH         | Nginx 安装的根路径，所有其他的安装路径都要依赖于该选项       |
| --sbin-path=PATH      | 指定nginx 二进制文件的路径。如果没有指定，那么这个路径会 依赖于 prefix 选项 |
| --conf-path=PATH      | 如果在命令行没有指定配置文件，那么将会通过这里指定的路径，nginx 将会去那里查找它的配置文件 |
| --error-log-path=PATH | 指定错误文件的路径，nginx 将会往其中写入错误日志文件，除非有其他的配置 |
| --pid-path=PATH       | 指定的文件将会写入nginx master进程的pid通常卸载/var/run/目录下 |
| --lock-path=PATH      | 共享储存器互斥锁文件的路径                                   |
| --user=USER           | worker进程运行的用户                                         |
| --group=GROUP         | worker进程运行的用户组                                       |
| --with-file-aio       | 为FreeBSD 4.3+和linux 2.6.22+系统启用异步I/O                 |
| --with-debug          | 这个选项用于调试日志,在生产环境的系统中不推荐使用该选项      |

临时路径配置选项

| 选项                              | 解释                                                         |
| :-------------------------------- | :----------------------------------------------------------- |
| --error-log-path=PATH             | 错误日志的默认路径                                           |
| --http-log-path=PATH              | http 访问日志的默认路径                                      |
| --http-client-body-temp-path=PATH | 从客户端收到请求后，该选项设置的目录用于作为请求体 临时存放的目录。如果 WebDAV 模块启用，那么推荐设置 该路径为同 一文件系统上的目录作为最终的目的地 |
| --http-proxy-temp-path=PATH       | 在使用代理后，通过该选项设置存放临时文件路径                 |
| --http-fastcgi-temp-path=PATH     | 设置 FastCGI 临时文件的目录                                  |
| --http-uwsgi-temp-path=PATH       | 设置 uWSG工临时文件的目录                                    |
| --http-scgi-temp-path=PATH        | 设置 SCGII临时文件的目录                                     |

PCRE的配置参数

| 选项                    | 解释                                                       |
| :---------------------- | :--------------------------------------------------------- |
| --without-pcre          | 如果确定Nginx不用解析正则表达式,那么可以使用这个参数       |
| --with-pcre             | 强制使用PCRE库                                             |
| --with-pcre=DIR         | 指定PCRE库的源码位置,在编译nginx时会进入该目录编译PCRE源码 |
| --with-pcre-opt=OPTIONS | 编译PCRE源码是希望加入的编译选项                           |

OpenSSL的配置参数

| 选项                       | 解释                                                         |
| :------------------------- | :----------------------------------------------------------- |
| --with-openssl=DIR         | 指定OpenSSL库的源码位置,在编译nginx时会进入该目录编译OpenSSL.如果web服务器需要使用HTTPS,那么Nginx要求必须使用OpenSSL |
| --with-openssl-opt=OPTIONS | 编译OpenSSL源码时希望加入的编译选项                          |

zlib的配置参数

| 选项                    | 解释                                                         |
| :---------------------- | :----------------------------------------------------------- |
| --with-zlib=DIR         | 指定zlib库的源码位置,在编译nginx时会进入该目录编译zlib.如果需要使用gzip压缩就必须要zlib库的支持 |
| --with-zlib-opt=OPTIONS | 编译zlib源码时希望加入的编译选项                             |
| --with-zlib-asm=CPU     | 指定对特定的CPU使用zlib库的汇编优化功能,目前支持两种架构:pentium和pentiumpro. |

**5、精简配置**

```bash
cd /usr/local/nginx/conf/
cp nginx.conf{,.bak}
cat >nginx.conf<<EOF
worker_processes  8;
worker_rlimit_nofile 65535;


events {
    use epoll;
    worker_connections  10240;
}

http {

    include       mime.types;
    default_type  application/octet-stream;


log_format logstash_json '{ "@timestamp": "$time_local", '
                         '"@fields": { '
                         '"remote_addr": "$remote_addr", '
                         '"request_time": "$request_time", '
                         '"status": "$status", '
                         '"real server": "$upstream_addr",'
                         '"upstream_status": "$upstream_status"'
                         '"request": "$request", '
                         '"request_method": "$request_method", '
                         '"http_referrer": "$http_referer", '
                         '"body_bytes_sent":"$body_bytes_sent", '
                         '"http_x_forwarded_for": "$http_x_forwarded_for", '
                         '"http_user_agent": "$http_user_agent" } }';

    sendfile   on;
    tcp_nopush on; 
    tcp_nodelay on; 
    server_tokens off;
    add_header X-Frame-Options SAMEORIGIN;   

    keepalive_timeout  120;
    client_body_buffer_size    128K;
    client_header_buffer_size 32k;
    client_max_body_size 500M;
    
    include vhosts/*.conf;
}
EOF

cat >proxy.default.conf<<EOF
proxy_redirect    off;
proxy_connect_timeout 900;
proxy_send_timeout 1800;
proxy_read_timeout 1800;
proxy_buffer_size 256k;
proxy_buffers   32 32k;
proxy_set_header   Host $host:$server_port;
proxy_set_header   X-Real-IP   $remote_addr;
proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header   REMOTE_ADD $remote_addr;
proxy_ignore_client_abort  on; 

real_ip_recursive  on;
real_ip_header     X-Real-IP;
real_ip_header     X-Forwarded-For;
set_real_ip_from   192.168.2.79;
EOF


cat >./vhosts/test.conf<<EOF
upstream web_38020 {
        server 192.168.129.91:8030  srun_id=web_91;
	    server 192.168.129.93:8030  srun_id=web_93;
        jvm_route $cookie_JSESSIONID|sessionid reverse;
	}

server      {
        listen       38020;
        server_name  test.com.cn;

        if ($request_method !~* GET|POST|HEAD) {
            return 403;
           }
        access_log  logs/web_38020_access.log  logstash_json;
        error_log logs/web_38020_error.log  error;

        location   / {
                include  proxy.default.conf;
              	proxy_pass  http://web_38020;
                proxy_intercept_errors on;
                error_page    404  /404.html;
                location = /404.html {
                root  /opt/nginx/nginx_prod/html;
                }
        }
	

       location /status {
                stub_status on;
                access_log off;
                allow 127.0.0.1;
                allow 192.168.129.86;
                allow 192.168.129.87;
                allow 192.168.127.158;
                deny all;
        }

}
EOF
```



# nginx 多策略流量分发

**1、场景描述** 

在实际生产环境中，流量分发有很多情况，下面主要讲讲以下两种流量分发场景：

1. 新版本上线，为了保证新版本稳定性，需要用线上的流量的引入，对新版本进行真实流量测试。如果新版本上线有问题，为降低影响范围，我们对流量的引入应该为从小到大的策略。
2. 现如今是移动端的时代，而移动端和pc端的设备的不同，需要对移动端和pc的流量进行不同的处理，同时可以针对两种设备的不同需求可以单独升级，可控性强，且架构灵活。

**2、nginx策略配置**

针对以上两种场景，nginx做为强大的web服务器，通过简单的配置来就可以满足我们的需求，下面我们就开始实战：

```
nginx version: nginx/1.16.1os version: centos 7
```

完成以上需求，主要依赖于nginx的两个模块：

1. ngx_http_split_clients_module 文档参考地址: http://nginx.org/en/docs/http/ngx_http_split_clients_module.html
2. ngx_http_map_module 文档参考地址：http://nginx.org/en/docs/http/ngx_http_map_module.html

**3、流量按比例分配[ngx_http_split_clients_module]**

按比例分配流量，通过ngx_http_split_clients_module模块实现，该模块可通过客户端的某些属性对客户端通过hash算法按比例分配，这些属性包括客户端ip等，通过hash函数，将不同客户端ip进行比例分配，从而可以将部分流量引入新版本服务中，下面看一下具体配置：

```nginx
user nobody;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
user nobody;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # 根据内置变量变量${remote_addr}进行1:1分发，并将v1和v2的值赋予$version变量
    split_clients "${remote_addr}AAA" $version {
                   50%               v1;
                   *                 v2;
    }
    
    # v1版本服务
    server {
          listen 8081;
          location  / {
              return 200 "v1\n";
          }
    }
    # v2版本服务
    server {
          listen 8082;
          location  / {
              return 200 "v2\n";
          }
    }

    server {
        listen 80;
        location / {
            proxy_pass http://127.0.0.1/$version;
        }
        # v2版本转发
        location  /v2 {
            proxy_pass http://127.0.0.1:8082/;
        }
        # v1版本转发
        location  /v1 {
            proxy_pass http://127.0.0.1:8081/;
        }
    }
}
```

在配置中，我们利用`split_clients`指令对`$remote_addr`变量进行hash运算，并按1:1比例随机地将`$version`的值赋予v1和v2，*表示剩余的比例，即1-50%，这样就可以通过`$version`的值进行流量分配，具体可看nginx配置，已有注释。可以看到在版本转发时，在`proxy_pass`转发路径最后加了/，是为了把版本路径(v1|v2)去掉，然后再进行转发，可以保持原有的请求uri路径不变，此处算是一个小技巧。

实际效果：

![640](assets/640.gif)

**4、移动端和pc端流量分配[ngx_http_map_module]**
ngx_http_map_module模块可通过客户端属性按一定规则匹配映射为新的变量，我们可以对客户端的ua进行正则匹配来区分流量，从而进行流量分发，下面是nginx配置文件示例：

```nginx
user nobody;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;


    map "${http_user_agent}" $uatype {
           default           nomobile;
           "~*mobile"        mobile;
    }
    
    # pc端服务
    server {
          listen 8082;
          location  / {
              return 200 "nomobile\n";
          }
    }
    
    # 移动端服务
    server {
          listen 8081;
          location  / {
              return 200 "mobile\n";
          }
    }

    server {
        listen 80;
        location / {
            proxy_pass http://127.0.0.1/$uatype;
        }
        # pc端版本转发
        location  /nomobile {
            proxy_pass http://127.0.0.1:8082/;
        }
        # 移动端版本转发
        location  /mobile {
            proxy_pass http://127.0.0.1:8081/;
        }
    }
}
```

在nginx配置中，我们可以看到使用map指令，对客户端的ua进行正则匹配，一旦匹配成功，$uatype将被分配为mobile，并根据此变量的值进行转发，剩下未匹配的由default 指定，此时$uatype为nomobile，从而转发到pc端服务，同时在转发到后端时，同样在proxy_pass后加/，也是为了去掉nomobile和mobile前缀。在使用map的正则匹配时，代表区分大小写的匹配，*则为不区分大小写。

实际效果：

![641](assets/641.gif)

**5、总结**
以上只是列举典型的流量分发方式，我们可以根据$http_name或者$arg_name来定制化需求，$http_name获取自定义头部，$arg_name获取自定义uri参数，这就给予我们更多的可能，比如我们可以再用户登录后，添加自定义头部，使用自定义头部，map指令进行流量拆分，更多的用途需要我们自行发挥想象进行探索。



# nginx 实现四层代理

```bash
wget http://nginx.org/download/nginx-1.18.0.tar.gz
#编译
yum install gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel -y 
tar -xzvf nginx-1.18.0.tar.gz
cd nginx-1.18.0
./configure --with-stream --without-http --prefix=/usr/local/nginx --without-http_uwsgi_module 
make && make install

#############
--without-http_scgi_module --without-http_fastcgi_module
--with-stream：开启 4 层透明转发(TCP Proxy)功能；
--without-xxx：关闭所有其他功能，这样生成的动态链接二进制程序依赖最小；
```





# nginx 正向代理

> 注意：Nginx本身不支持HTTPS正向代理，需要安装ngx_http_proxy_connect_module模块后才可以支持HTTPS正向代理，否则会遇到HTTP 400错误。

参考文档：

- <https://github.com/chobits/ngx_http_proxy_connect_module>

**1、安装Nginx和模块**

```
yum -y install make zlib zlib-devel gcc-c++ libtool  openssl openssl-devel  wget pcre pcre-devel git
git clone https://github.com/chobits/ngx_http_proxy_connect_module.git
wget http://nginx.org/download/nginx-1.14.2.tar.gz
tar -xzvf nginx-1.14.2.tar.gz
cd nginx-1.14.2/
patch -p1 <../ngx_http_proxy_connect_module/patch/proxy_connect_1014.patch
./configure  --with-http_stub_status_module --with-http_ssl_module --add-module=../ngx_http_proxy_connect_module
make && make install
```

**2、虚拟主机配置**

```
[root@ docker ~]# mkdir -p /usr/local/nginx/conf/conf.d/

[root@ docker ~]# vim /usr/local/nginx/conf/nginx.conf
user  nobody;
worker_processes  1;
events {
	worker_connections  1024;
}
http {
	include       mime.types;
	default_type  application/octet-stream;
	sendfile        on;
	keepalive_timeout  65;
	include /usr/local/nginx/conf/conf.d/*.conf;

}

[root@ docker ~]# vim /usr/local/nginx/conf/conf.d/test.conf
server {
        listen 90;
        server_name 10.0.0.90;
        resolver 223.5.5.5;
        proxy_connect;
        proxy_connect_allow            443 563;
        proxy_connect_connect_timeout  10s;
        proxy_connect_read_timeout     10s;
        proxy_connect_send_timeout     10s;
location / {
        proxy_pass http://$host;
        proxy_set_header Host $host;
        }
}
```

**3、客户端配置** 

**全局的代理设置：** 

```shell
vim /etc/profile
##代理
export http_proxy=http://10.0.0.90:90
export https_proxy=http://10.0.0.90:90
export ftp_proxy=http://10.0.0.90:90
```

**yum的代理设置：** 

```shell
vim /etc/yum.conf 
proxy=http://http://10.0.0.90:90
```

**wget的代理设置：** 

```shell
vim /etc/wgetrc 
http_proxy=http://10.0.0.90:90
ftp_proxy=http://10.0.0.90:90
```

**4、测试代理**

**方法一：** 

访问HTTP网站，可以直接这样的方式:

```shell
curl ‐I ‐‐proxy 10.0.0.90:90 http://www.baidu.com
curl ‐I ‐‐proxy 10.0.0.90:90 https://www.baidu.com
```

**方法二：** 

**使用浏览器访问** 

这里使用的是firefox浏览器

![1582623559546](./assets/1582623559546.png)

![1582623570881](./assets/1582623570881.png)

![1582880069845](assets/1582880069845.png)

**如何确定访问是不是走的代理那？** 

可以在浏览器上设置好代理后，然后将你代理的nginx关掉，然后重新打开一个网页，会发现测试不可以访问网站了！！

![1582623613946](./assets/1582623613946.png)









# nginx 配置HTTPS

什么是https？

HTTP：是互联网上应用最为广泛的一种网络协议，是一个客户端和服务器端请求和应答的标准（TCP），用于从WWW服务器传输超文本到本地浏览器的传输协议，它可以使浏览器更加高效，使网络传输减少。

HTTPS：全称：Hyper Text Transfer Protocol over Secure Socket Layer，则是以安全为目标的HTTP通道，简单讲是HTTP的安全版，即HTTP下加入SSL层，HTTPS的安全基础是SSL，因此加密的详细内容就需要SSL。

HTTPS协议的主要作用可以分为两种：一种是建立一个信息安全通道，来保证数据传输的安全；另一种就是确认网站的真实性。

**1.配置过程**

首先需要申请一个证书，可以申请一个免费的。

**2.证书申请方式**

**阿里云申请**

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





**Certbot申请**

官网：<https://certbot.eff.org/>

Let’s Encrypt提供了免费的证书申请服务，同时也提供了官方客户端 Certbot，打开首页，就可以得到官方的安装教程。官方教程给出了四种常用服务器和不同的Linux、Unix的安装使用方案，可以说是十分的贴心了。

![6023080-46b89fc91bd3ef7a](./assets/6023080-46b89fc91bd3ef7a.jpg)



**openssl自签证书**

**3.自签证书测试**

**安装nginx**

```shell
yum -y install make zlib zlib-devel gcc-c++ libtool  openssl openssl-devel  wget pcre pcre-devel
wget http://nginx.org/download/nginx-1.14.2.tar.gz
tar -zxvf nginx-1.14.2.tar.gz
cd nginx-1.14.2
./configure --with-http_stub_status_module --with-http_ssl_module
make
make install
```

**检查Nginx的SSL模块**

```shell
$ /usr/local/nginx/sbin/nginx -V
nginx version: nginx/1.14.2
built by gcc 4.8.5 20150623 (Red Hat 4.8.5-39) (GCC)
built with OpenSSL 1.0.2k-fips  26 Jan 2017
TLS SNI support enabled
configure arguments: --with-http_stub_status_module --with-http_ssl_module
```

**准备私钥和证书**

创建私钥

```shell
$ cd /usr/local/nginx
$ mkdir -p ssl
$ cd ssl/
$ openssl genrsa -des3 -out server.key 1024
Enter pass phrase for server.key:123456
Verifying - Enter pass phrase for server.key:123456
$  ll
-rw-r--r-- 1 root root 963 2020-02-26 02:43 server.key
```

签发证书

```shell
$ openssl req -new -key server.key -out server.csr
Enter pass phrase for server.key: 123456
# 然后一路会回车
Country Name (2 letter code) [XX]:
State or Province Name (full name) []:
Locality Name (eg, city) [Default City]:
Organization Name (eg, company) [Default Company Ltd]:
Organizational Unit Name (eg, section) []:
Common Name (eg, your name or your server's hostname) []:
Email Address []:

A challenge password []:回车
An optional company name []:回车

```

删除私钥口令

```bash
$ cd /usr/local/nginx/ssl
$ cp server.key server.key.ori
$ openssl rsa -in server.key.ori -out server.key
Enter pass phrase for server.key.ori:123456
```

生成使用签名请求证书和私钥生成自签证书

```shell
$ openssl x509 -req -days 365 -in server.csr -signkey server.key -out server.crt
```

**4.开启Nginx SSL**

```shell
# 创建虚拟主机子目录
mkdir -p /usr/local/nginx/conf/conf.d

# 精简主配置文件
cat >/usr/local/nginx/conf/nginx.conf<<EOF
user  nobody;
worker_processes  1;
events {
	worker_connections  1024;
}
http {
	include       mime.types;
	default_type  application/octet-stream;
	sendfile        on;
	keepalive_timeout  65;
	include conf.d/*.conf;
}
EOF

# 启动nginx，并查看进程
/usr/local/nginx/sbin/nginx

# 创建虚拟主机子配置文件
cat >/usr/local/nginx/conf/conf.d/hack.conf<<EOF
server {
    listen       443 ssl;
    server_name  www.hack.com;
    ssl on;
    ssl_certificate /usr/local/nginx/ssl/server.crt;
    ssl_certificate_key /usr/local/nginx/ssl/server.key;

    location / {
    #定义站点目录
        root   /usr/local/nginx/html;
        index index.php  index.html index.htm;
    }
}
EOF

# 重新加载配置文件
/usr/local/nginx/sbin/nginx -t
/usr/local/nginx/sbin/nginx -s reload
```

绑定windows的hosts：

```
10.0.0.41 www.hack.com
```

上传 [hack.html](assets\hack.html) 到/usr/local/nginx/html目录。

然后谷歌浏览器访问：https://www.hack.com/hack.html

![1582706367414](assets/1582706367414.png)

此时，你会发现，http://www.hack.com/hack.html，浏览器访问不了了，需要进行rewrite跳转。

**5.rewrite跳转**

以上配置有个不好的地方，如果用户忘了使用https或者443端口，那么网站将无法访问，因此需要将80端口的访问转到443端口并使用ssl加密访问。只需要增加一个server段，使用301永久重定向。

```shell
cat >/usr/local/nginx/conf/conf.d/hack.conf<<\EOF
server {
    listen 80;
    server_name www.hack.com;
    rewrite ^(.*) https://$server_name$1 permanent;
}

server {
    listen       443 ssl;
    server_name  www.hack.com;
    ssl on;
    ssl_certificate /usr/local/nginx/ssl/server.crt;
    ssl_certificate_key /usr/local/nginx/ssl/server.key;


    location / {
    #定义站点目录
        root   /usr/local/nginx/html;
        index index.php  index.html index.htm;
    }
}
EOF

# 重新加载配置文件
/usr/local/nginx/sbin/nginx -t
/usr/local/nginx/sbin/nginx -s reload
```

这时，浏览器访问 http://www.hack.com/hack.html，nginx会将请求跳转到 https://www.hack.com/hack.html，详细可以查看nginx日志。







# openresty 通过Lua+Redis实现动态封禁 IP

OpenResty（也称为 ngx_openresty）

OpenResty是一个基于 Nginx 与 Lua 的高性能 Web 平台，其内部集成了大量精良的 Lua 库、第三方模块以及大多数的依赖项。

用于方便地搭建能够处理超高并发、扩展性极高的动态 Web 应用、Web 服务和动态网关。

OpenResty通过汇聚各种设计精良的 Nginx 模块（主要由 OpenResty 团队自主开发），从而将 Nginx 有效地变成一个强大的通用 Web 应用平台。这样，Web 开发人员和系统工程师可以使用 Lua 脚本语言调动 Nginx 支持的各种 C 以及 Lua 模块，快速构造出足以胜任 10K 乃至 1000K 以上单机并发连接的高性能 Web 应用系统。

OpenResty的目标是让你的Web服务直接跑在Nginx服务内部，充分利用 Nginx 的非阻塞 I/O 模型，不仅仅对 HTTP 客户端请求,甚至于对远程后端诸如 MySQL、PostgreSQL、Memcached 以及 Redis 等都进行一致的高性能响应。

**1、下载**

```
wget https://openresty.org/download/openresty-1.15.8.1.tar.gz
```

**2、安装**

```bash
yum install -y gcc gcc-c++ zlib-devel pcre-devel openssl-devel readline-devel
tar -zxvf openresty-1.15.8.1.tar.gz
cd openresty-1.15.8.1 
./configure --prefix=/home/openresty \ 
--user=admin --group=admin \ 
--with-http_ssl_module \ 
--with-http_flv_module \ 
--with-http_stub_status_module \ 
--with-http_gzip_static_module \ 
--with-pcre \ 
--with-luajit \ 
--with-stream \ 
--with-http_iconv_module \ 
--with-http_realip_module  

gmake 
gmake install
```

**添加环境变量**

```bash
echo 'export PATH=/home/openresty/nginx/sbin/:$PATH' >>/etc/profile
source /etc/profile
```



**3、nginx.conf 或虚拟主机host 中，添加对 lua 脚本的支持**

```bash
lua_package_path "/home/openresty/lualib/resty/redis.lua;";  #告诉openresty库地址
error_log /home/openresty/nginx/logs/openresty.debug.log debug;
```

所有 / 的请求会被分发给lua 脚本处理

```
location / {
        default_type text/html;
        access_by_lua_file "/home/openresty/nginx/lua/access_by_redis.lua";
}
```



**4、编写lua脚本**

需要安装redis，最后的效果：http://host/  6秒内访问超过10次，自动封 IP 30秒

```lua
vim /home/openresty/nginx/lua/access_by_redis.lua

ip_bind_time = 30  --封禁IP多长时间
ip_time_out = 6    --指定统计ip访问频率时间范围
connect_count = 10 --指定ip访问频率计数最大值
--上面的意思就是6秒内访问超过10次，自动封 IP 30秒。

--连接redis
local redis = require "resty.redis"
local cache = redis.new()
local ok , err = cache.connect(cache,"127.0.0.1","6379")
cache:set_timeout(60000)

--如果连接失败，跳转到脚本结尾
if not ok then
  goto Lastend
end
 
--查询ip是否在封禁段内，若在则返回403错误代码
--因封禁时间会大于ip记录时间，故此处不对ip时间key和计数key做处理
is_bind , err = cache:get("bind_"..ngx.var.remote_addr)

if is_bind == '1' then
  ngx.exit(ngx.HTTP_FORBIDDEN)
  -- 或者 ngx.exit(403)
  -- 当然，你也可以返回500错误啥的，搞一个500页面，提示，亲您访问太频繁啥的。
  goto Lastend
end

start_time , err = cache:get("time_"..ngx.var.remote_addr)
ip_count , err = cache:get("count_"..ngx.var.remote_addr)

--如果ip记录时间大于指定时间间隔或者记录时间或者不存在ip时间key则重置时间key和计数key
--如果ip时间key小于时间间隔，则ip计数+1，且如果ip计数大于ip频率计数，则设置ip的封禁key为1
--同时设置封禁key的过期时间为封禁ip的时间
 
if start_time == ngx.null or os.time() - start_time > ip_time_out then
  res , err = cache:set("time_"..ngx.var.remote_addr , os.time())
  res , err = cache:set("count_"..ngx.var.remote_addr , 1)
else
  ip_count = ip_count + 1
  res , err = cache:incr("count_"..ngx.var.remote_addr)
  if ip_count >= connect_count then
    res , err = cache:set("bind_"..ngx.var.remote_addr,1)
    res , err = cache:expire("bind_"..ngx.var.remote_addr,ip_bind_time) --fix keys
  end
end
--结尾标记
::Lastend::
local ok, err = cache:close()
```

测试程序

```python
package main

import (
    "net/http"
    "fmt"
    "io/ioutil"
    "os"
)

func main()  {

    for i := 1 ; i<= 20 ;i++  {
        resp,err := http.Get("http://192.168.138.128")
        defer resp.Body.Close()
        if err != nil {
            os.Exit(-1)
        }
        //time.Sleep(1*time.Second)
        body, _ := ioutil.ReadAll(resp.Body)
        fmt.Println("i is", i)
        fmt.Println(string(body))
    }

}
```



# nginx 日志切割

```bash
#!/bin/bash
NGINX_PATH=/opt/nginx/nginx_prod
LOG_PATH=$NGINX_PATH/logs
NGINX_LOG_LIST=/root/script/nginx_log_cut/nginx_log_list.txt
YESTERDAY=$(date -d 'yesterday' +%Y-%m-%d)

for i in $(cat $NGINX_LOG_LIST)
do
    mv $LOG_PATH/$i $LOG_PATH/$i.$YESTERDAY
done

$NGINX_PATH/sbin/nginx -s reopen


#!/bin/bash
#初始化
LOGS_PATH=/data/nginx/logs/
www.domain.com 

YESTERDAY=$(date -d "yesterday" +%Y-%m-%d)
#按天切割日志
mv ${LOGS_PATH}/access.log ${LOGS_PATH}/access_${YESTERDAY}.log
#向 Nginx 主进程发送 USR1 信号，重新打开日志文件，否则会继续往mv后的文件写内容，导致切割失败.
kill -USR1 `ps axu | grep "nginx: master process" | grep -v grep | awk '{print $2}'`
#删除7天前的日志
cd ${LOGS_PATH}
find . -mtime +7 -name "*20[1-9][3-9]*" | xargs rm -f
exit 0
```

# nginx windows版本 1024限制

> Windows版本因为文件访问句柄数被限制为1024了，当访问量大时就会无法响应。 会有如下错误提示：

```
maximum number of descriptors supported by select() is 1024
```

使用专门的windows版本的nginx，已修改了文件句柄数据的限制。

```
nginx for windows官网：http://nginx-win.ecsds.eu/
nginx for windows下载载地址： http://nginx-win.ecsds.eu/download/
```

下载后里面有个简要的更新信息和安装指南Readme nginx-win version.txt。 找到conf文件夹中的nginx-win.conf，把它复制一份更名为nginx.conf，然后在此文件中做配置。



# nginx 图片服务器配置

nginx负载：

```bash
[root@ sftuat04 conf]# cat nginx.conf
worker_processes  4;

events {
    use epoll;
    worker_connections  10240;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    server_tokens off;
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout  120;
    client_body_buffer_size    128K;
    client_header_buffer_size 32k;
    client_max_body_size 300M;
    add_header X-Frame-Options SAMEORIGIN;

    gzip on;
    gzip_min_length  1k;
    gzip_buffers     4 16k;
    gzip_http_version 1.0;
    gzip_comp_level 4;
    gzip_types       text/plain application/x-javascript text/css application/xml text/javascript application/x-httpd-php image/jpeg image/gif image/png;
    gzip_vary on;

  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
              '$status "$http_referer" '
             '"$http_user_agent" "$http_x_forwarded_for"';


log_format logstash_json '{ "@timestamp": "$time_local", '
                         '"@fields": { '
                         '"remote_addr": "$remote_addr", '
                         '"request_time": "$request_time", '
                         '"status": "$status", '
                         '"real server": "$upstream_addr",'
                         '"upstream_status": "$upstream_status"'
                         '"request": "$request", '
                         '"request_method": "$request_method", '
                         '"http_referrer": "$http_referer", '
                         '"body_bytes_sent":"$body_bytes_sent", '
                         '"http_x_forwarded_for": "$http_x_forwarded_for", '
                         '"http_user_agent": "$http_user_agent" } }';

    include /opt/nginx/nginx_uat/conf/vhost/*.conf;

}
[root@ sftuat04 conf]# cat proxy.default.conf
proxy_redirect    off;
proxy_connect_timeout 3600s;
proxy_send_timeout 3600s;
proxy_read_timeout 3600s;
proxy_buffer_size 256k;
proxy_buffers   32 32k;
proxy_set_header   Host $host:$server_port;
proxy_set_header   X-Real-IP   $remote_addr;
proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header   REMOTE_ADD $remote_addr;
proxy_ignore_client_abort  on;
[root@ sftuat04 vhost]# cat images_28030.conf
    upstream  images_28030  {
              server   192.168.127.149:80;
        }


    server {
        listen       28030;
        server_name  sfa2.liby.com.cn;

	charset utf-8,gbk;

        access_log  logs/access_uat.log  logstash_json;

        location / {
                proxy_pass http://images_28030;
                proxy_connect_timeout 300s;
                proxy_send_timeout 600s;
                proxy_read_timeout 600s;
                proxy_buffer_size 128k;
                proxy_buffers   32 64k;
                proxy_set_header   Host $host:$server_port;
                proxy_set_header   X-Real-IP  $remote_addr;
                proxy_set_header   X-Forwarded-For  $proxy_add_x_forwarded_for;
                proxy_set_header   REMOTE_ADD $remote_addr;
                real_ip_recursive  on;
                real_ip_header     X-Real-IP;
                real_ip_header     X-Forwarded-For;
                set_real_ip_from   192.168.2.79;
                proxy_intercept_errors on;
         }


	location /menu {
		root /opt/nginx/nginx_uat/html;
		index  index.html;
		}


    }
```

nginx_web：

```bash
[root@ sfauat14 conf]# cat nginx.conf

#user  nobody;
worker_processes  4;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  65535;
    use epoll;
    multi_accept on;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
    #                  '$status $body_bytes_sent "$http_referer" '
    #                  '"$http_user_agent" "$http_x_forwarded_for"';

    #access_log  logs/access.log  main;

    sendfile   on;
    tcp_nopush on;
    tcp_nodelay on;
    server_tokens off;
    add_header X-Frame-Options SAMEORIGIN;

    keepalive_timeout  120;
    client_body_buffer_size    128K;
    client_header_buffer_size 32k;
    client_max_body_size 500M;

    #gzip  on;

    server {
        listen       80;
        server_name  192.168.127.149;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            autoindex  on;
            root   /opt/appdate/images;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

    }

}
```

# upstream 的5种权重分配方式

1、轮询（默认）

每个请求按时间顺序逐一分配到不同的后端服务器，如果后端服务器down掉，能自动剔除。

```
upstream backserver {
        server 192.168.0.14;
        server 192.168.0.15;
}
```

2、weight

指定轮询几率，weight和访问比率成正比，用于后端服务器性能不均的情况。

```
upstream backserver {
         server 192.168.0.14 weight=3;
         server 192.168.0.15 weight=7;
}
```

权重越高，在被访问的概率越大，如上例，分别是30%，70%。

3、IP绑定 ip_hash--不可给服务器加权重

每个请求按访问ip的hash结果分配，这样每个访客固定访问一个后端服务器，可以解决session的问题。

```bash
upstream backserver {
         ip_hash;
         server 192.168.0.14:88;
         server 192.168.0.15:80;
}
```

4、fair（第三方）

按后端服务器的响应时间来分配请求，响应时间短的优先分配。

```bash
upstream backserver {
         server 10.0.0.10:8080; 
         server 10.0.0.11:8080; 
         fair;
}
```

5、url_hash（第三方）

按访问url的hash结果来分配请求，使每个url定向到同一个后端服务器，后端服务器为缓存时比较有效。

```bash
upstream backserver {
        server squid1:3128;
        server squid2:3128;
        hash $request_uri;
        hash_method crc32;
}

upstream bakend{ #定义负载均衡设备的Ip及设备状态
      ip_hash;
      server 10.0.0.11:9090 down;
      server 10.0.0.11:8080 weight=2;
      server 10.0.0.11:6060;
      server 10.0.0.11:7070 backup;
}
```

每个设备的状态设置为:

1. down 表示单前的server暂时不参与负载
2. weight 默认为1.weight越大，负载的权重就越大。
3. max_fails：允许请求失败的次数默认为1.当超过最大次数时，返回proxy_next_upstream模块定义的错误
4. fail_timeout ： max_fails次失败后，暂停的时间。
5. backup： 其它所有的非backup机器down或者忙的时候，请求backup机器。所以这台机器压力会最轻。

> 故障转移：

用了nginx负载均衡后，在两台tomcat正常运行的情况下，访问http://localhost 速度非常迅速，通过测试程序也可以看出是得到的负载均衡的效果，但是我们试验性的把其中一台tomcat（server localhost:8080）关闭后，再查看http://localhost，发现反应呈现了一半反映时间快，一半反映时间非常非常慢的情况，但是最后都能得到正确结果.

> 解决办法：

问题解决，主要是proxy_connect_timeout这个参数是连接的超时时间。设置成1，表示是1秒后超时会连接到另外一台服务器。



# nginx 的两种认证方式

**auth_basic 本机认证：**

```bash
yum -y install httpd-tools  # 安装 htpasswd 工具
cd /usr/local/nginx-1.10.2/conf
htpasswd -c pass.db wang  # 创建认证用户 wang 并输入密码，添加用户时输入 htpasswd pass.db username

vim /usr/local/nginx-1.10.2/conf/vhost/local.conf
server {
    listen       80;
    server_name  local.server.com;
    
    auth_basic "User Authentication";
    auth_basic_user_file /usr/local/nginx-1.10.2/conf/pass.db;
    
    location / {
        root   /data/www;
        index  index.html;
    }
}
```

这样就实现了本机认证，需要维护 pass.db 文件

**ngx_http_auth_request_module 第三方认证：**

```bash
1. 编译 Nginx 时添加 --with-http_auth_request_module
2. 该模块可以将客户端输入的用户名、密码 username:password 通过 Base64 编码后写入 Request Headers 中
   例如：wang:wang -> Authorization:Basic d2FuZzp3YW5n=
3. 然后通过第三方程序解码后跟数据库中用户名、密码进行比较，Nginx 服务器通过 header 的返回状态判断是否认证通过。
 vim /usr/local/nginx-1.10.2/conf/vhost/local.conf  #先编辑本机配置文件，也就是用户直接访问的虚拟主机

server {
    listen 80;
    server_name local.server.com;

    auth_request /auth;

    location / {
        root   html;
        index  index.html;
    }

    location /auth {
        proxy_pass http://auth.server.com/HttpBasicAuthenticate.php;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
    }
}

# auth_request /auth; # 启用认证
# proxy_pass http://auth.server.com/HttpBasicAuthenticate.php; # 认证服务器地址
# 参考地址：http://nginx.org/en/docs/http/ngx_http_auth_request_module.html
vim /usr/local/nginx-1.10.2/conf/vhost/auth.conf  # 这是第三方认证服务器，认证逻辑使用的 PHP 代码

server {
    listen       80;
    server_name  auth.server.com;

    location ~ \.php$ {
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  /usr/local/nginx-1.10.2/html$fastcgi_script_name;
        include        fastcgi_params;
    }
}

vim /usr/local/nginx-1.10.2/html/HttpBasicAuthenticate.php

<?php

if(isset($_SERVER['PHP_AUTH_USER'], $_SERVER['PHP_AUTH_PW'])){
    $username = $_SERVER['PHP_AUTH_USER'];
    $password = $_SERVER['PHP_AUTH_PW'];

    if ($username == 'wang' && $password == '123456'){
        return true;
    }
}

header('WWW-Authenticate: Basic realm="Git Server"');
header('HTTP/1.0 401 Unauthorized');

?>

# 用户访问 local.server.com 弹出框中输入的用户名、密码保存在 $_SERVER 变量中
# 中间 if 段，只做演示用，工作中应该是拿用户输入的用户名、密码跟数据库中的数据做比较
# 用户访问 local.server.com 就会去 auth.servere.com 做用户认证，认证通过后继续访问 local.server.com

# 目前 Nginx 的第三方认证，工作中自己搭建的 git + gitweb 在使用中，配置文件如下：( 认证逻辑大家使用自己喜欢的语言编写即可 )

 vim /usr/local/nginx-1.10.2/conf/vhost/git.server.com

server {
    listen      80;
    server_name git.server.com;
    root        /usr/local/share/gitweb;

    client_max_body_size 50m;

    #auth_basic "Git User Authentication";
    #auth_basic_user_file /usr/local/nginx-1.10.2/conf/pass.db;

    auth_request /auth;

    location ~ ^.*\.git/objects/([0-9a-f]+/[0-9a-f]+|pack/pack-[0-9a-f]+.(pack|idx))$ {
        root /data/git;
    }

    location ~ /.*\.git/(HEAD|info/refs|objects/info/.*|git-(upload|receive)-pack)$ {
        root          /data/git;
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        fastcgi_connect_timeout 24h;
        fastcgi_read_timeout 24h;
        fastcgi_send_timeout 24h;
        fastcgi_param SCRIPT_FILENAME     /usr/local/libexec/git-core/git-http-backend;
        fastcgi_param PATH_INFO           $uri;
        fastcgi_param GIT_HTTP_EXPORT_ALL "";
        fastcgi_param GIT_PROJECT_ROOT    /data/git;
        fastcgi_param REMOTE_USER $remote_user;
        include fastcgi_params;
    }

    try_files $uri @gitweb;

    location @gitweb {
        fastcgi_pass  unix:/var/run/fcgiwrap.socket;
        fastcgi_param GITWEB_CONFIG    /etc/gitweb.conf;
        fastcgi_param SCRIPT_FILENAME  /usr/local/share/gitweb/gitweb.cgi;
        fastcgi_param PATH_INFO        $uri;
        include fastcgi_params;
    }

    location /auth {
        proxy_pass http://auth.server.com/HttpBasicAuthenticate.php;
        proxy_pass_request_body off;
        proxy_set_header Content-Length "";
        proxy_set_header X-Original-URI $request_uri;
    }
}
```



# nginx 设置404错误页面

**第一种：Nginx自己的错误页面**

Nginx访问一个静态的html页面，当这个页面没有的时候，Nginx抛出404，那么如何返回给客户端404呢？ 看下面的配置，这种情况下不需要修改任何参数，就能实现这个功能。

```
server {
    listen      80;：wq
    server_name  www.test.com;
        root   /var/www/test;
        index  index.html index.htm;
    location / {
    }
    # 定义错误页面码，如果出现相应的错误页面码，转发到那里。
    error_page  404 403 500 502 503 504  /404.html;
    # 承接上面的location。
    location = /404.html {
    # 放错误页面的目录路径。
        root   /usr/share/nginx/html;
    }
}
```

**第二种：反向代理的错误页面**

如果后台Tomcat处理报错抛出404，想把这个状态叫Nginx反馈给客户端或者重定向到某个连接，配置如下：

```bash
upstream www {
    server 192.168.1.201:7777  weight=20 max_fails=2 fail_timeout=30s;
    ip_hash;
}
server {
    listen       80;
    server_name www.test.com;
    root   /var/www/test;
    index  index.html index.htm;
 
    location / {
        if ($request_uri ~* '^/$') {
                    rewrite .*   http://www.test.com/index.html redirect;
        }
        # 关键参数：这个变量开启后，我们才能自定义错误页面，当后端返回404，nginx拦截错误定义错误页面
        proxy_intercept_errors on;
        proxy_pass      http://www;
        proxy_set_header HOST   $host;
        proxy_set_header X-Real-IP      $remote_addr;
        proxy_set_header X-Forwarded-FOR $proxy_add_x_forwarded_for;
    }
    error_page    404  /404.html;
    location = /404.html {
        root   /usr/share/nginx/html;
    }
}
```

**第三种：Nginx解析php代码的错误页面**

如果后端是php解析的，需要加一个变量 在http段中加一个变量 fastcgi_intercept_errors on 就可以了。 指定一个错误页面：

```bash
error_page    404  /404.html;
location = /404.html {
    root   /usr/share/nginx/html;
}
指定一个url地址：
error_page 404  /404.html;
error_page 404 = http://www.test.com/error.html;
```



# nginx 目录浏览功能

在server段或http{...}中添加

```bash
root /var/www/html/; #软件包文件存放目录，即从这里下载
autoindex on; 　　　　　　 #//开启目录浏览功能； 关闭off
autoindex_exact_size off; 　　　　 #//关闭详细文件大小统计，让文件大小显示MB，GB单位，默认为b；
autoindex_localtime on;　　　　　　# //开启以服务器本地时区显示文件修改日期！
location = / {
allow 10.10.2.13;　　　　　　##location规则可以设置谁能下载谁不能下载。
deny all;
}
```

