[TOC]



# 第三单元 DNS服务（二）



## 3.1 特殊域名解析

### 3.1.1 什么是DNS负载均衡

DNS负载均衡是一种用来帮助将对某个域的请求分配在不同机器上的技术，这样就不需要使用某个单一机器来承载全部负载。这种方法有助于提高网站和(或)Web应用程序的性能，因为流量负载可以在众多的服务器上共享，而不是由一个单一机器承担。



### 3.1.2 负载均衡如何工作

一个域名对应一个机器IP是最简单的DNS路由版本，然而许多公司使用一个单一域名指向多个IP地址，从而允许多个服务器具有同时处理请求的能力。

大多数客户端只使用收到的第一个IP地址表示域名，DNS负载均衡利用了这一点，将负载分配在所有可用的机器上。DNS可以在每次收到新的请求时，以不同的顺序发送域名可用的IP地址列表。

所谓的轮转方式，是在IP地址列表的顺序上进行改变-加之客户端使用列表中的第一个IP地址作为域名–从而允许不同的客户端发送给不同的服务器来处理它们的请求。因此，请求负载被有效地被分配到了多个服务器机器上，而不是依赖于一台机器来处理所有传入的请求。

下面是利用DNS工作原理处理负载均衡的工作原理图：

![3654482496-54f6c9fe72e0d_articlex](assets/3654482496-54f6c9fe72e0d_articlex.png)

举例：

```
www	IN	A	172.18.9.4
www	IN	A	172.18.9.5
www	IN	A	172.18.9.6
```



### 3.1.3 直接域名解析

DNS直接将域名解析到对应IP服务器。

```
wg.com.	IN	A	172.18.9.7
```



### 3.1.4 泛域名解析

所谓“泛域名解析”是指：利用通配符* （星号）来做**次级域名**以实现所有的次级域名均指向同一IP地址。

举例：

```shell
*	IN	A	10.0.0.21
```

**泛解析的用途**
1.可以让域名支持无限的子域名(这也是泛域名解析最大的用途)。

2.防止用户错误输入导致的网站不能访问的问题。

3.可以让直接输入网址登陆网站的用户输入简洁的网址即可访问网站

```
*.baidu.com

mail.baidu.com

www.baidu.com

oa.baidu.com
```



## 3.2 反向区域的资源记录

### 3.2.1 PTR记录--反向解析

**在主配置文件中定义区域**
vim /etc/named.conf 中 添加如下内容。通常反向解析区域名，约定俗成的规则为该网络地址反写拼接 “.in-addr.arpa”，如下

```shell
zone "0.0.10.in-addr.arpa" IN {
        type master;
        file "10.0.0.zone";
};
```



**定义区域解析库文件**
在 /var/named/ 目录下，创建10.0.0.zone，解析库文件 
`/var/named/10.0.0.zone` 中添加如下内容

```shell
[root@ c6m01 named]# cat 0.0.10.zone
$TTL 86400
$ORIGIN 0.0.10.in-addr.arpa.
@       IN      SOA     www.bw.com.   admin.bw.com. (
        2017011301
        1H
        5M
        7D
        1D
)
       IN      NS      www.bw.com.
22     IN      PTR     www.bw.com.
```



**检查语法重启bind服务**

```shell
[root@ c6m01 ~]# named-checkconf -z
zone bw.com/IN: loaded serial 0
zone 0.0.10.in-addr.arpa/IN: loaded serial 2017011301
zone localhost.localdomain/IN: loaded serial 0
zone localhost/IN: loaded serial 0
zone 1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa/IN: loaded serial 0
zone 1.0.0.127.in-addr.arpa/IN: loaded serial 0
zone 0.in-addr.arpa/IN: loaded serial 0
[root@ c6m01 ~]# echo $?
0
[root@ c6m01 ~]# /etc/init.d/named restart
```

**测试反向解析**

```shell
[root@ c6m01 ~]# nslookup 10.0.0.22
Server:		10.0.0.21
Address:	10.0.0.21#53

22.0.0.10.in-addr.arpa	name = www.bw.com.
```

