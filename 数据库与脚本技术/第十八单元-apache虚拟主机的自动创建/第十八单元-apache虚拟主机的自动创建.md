[TOC]







# 第十八单元-apache虚拟主机的自动创建

**安装httpd：**

```shell
yum install httpd -y
```



## 18.1 apache虚拟主机的创建

脚本创建虚拟主机

```shell
[root@ localhost ~]# cd /opt/scripts

[root@ localhost scripts]# vim add_virthosts.sh
#!/bin/bash

sed -i '/^DocumentRoot/s@DocumentRoot@\#DocumentRoot@g' /etc/httpd/conf/httpd.conf
mkdir -p /var/www/bw

cat >/etc/httpd/conf.d/virthost.conf<<EOF
<VirtualHost 10.0.0.21:80>
  DocumentRoot "/var/www/bw"
  ServerName www.bw.com
</VirtualHost>
EOF

echo 'this is bw' >>/var/www/bw/index.html

```

重启httpd服务

```
/etc/init.d/httpd restart
```



## 18.2 优化创建虚拟主机脚本



### 18.2.1 优化思路与流程分析

优化需求：

- 创建过程交互式进行，要求用户输入创建的ip、端口及虚拟主机域名
- 虚拟主机的主目录在/var/www/下，目录名称为虚拟主机域名
- 创建过程中如果用户回车无效，要求再次输入
- apache若不正常则报警



### 18.2.2 变量设置与优化编程

**优化一：**

1.创建过程交互式进行，要求用户输入创建的ip、端口及虚拟主机域名

2.虚拟主机的主目录在/var/www/下，目录名称为虚拟主机域名

```shell
[root@ localhost scripts]# cat add_virthosts.sh
#!/bin/bash

sed -i '/^DocumentRoot/s@DocumentRoot@\#DocumentRoot@g' /etc/httpd/conf/httpd.conf
WebRoot=/var/www/

read -p 'please input your IP: '  ip

read -p 'please input your Port: '  port

read -p 'please input your DomainName: ' domain
mkdir -p $domain

cat >/etc/httpd/conf.d/$WebDir.conf<<EOF
<VirtualHost $ip:$port>
  DocumentRoot "$WebRoot$domain"
  ServerName "$domain"
</VirtualHost>
EOF

echo "this is $webdir" >>$WebRoot$webdir/index.html
/etc/init.d/httpd restart

```



**优化二：**

创建过程中如果用户回车无效，要求再次输入

```shell
[root@ localhost scripts]# cat add_virthosts.sh
#!/bin/bash

sed -i '/^DocumentRoot/s@DocumentRoot@\#DocumentRoot@g' /etc/httpd/conf/httpd.conf
WebRoot=/var/www/

fun_input(){
    output_var=$1
    input_var=""
	while [ -z $input_var ]
	do
	  read -p "$output_var: " input_var
	done
	echo $input_var
}


ip=$(fun_input 'please input your IP')

port=$(fun_input 'please input your Port')

domain=$(fun_input 'please input your DomainName')
mkdir -p $WebRoot$domain

cat >/etc/httpd/conf.d/$domain.conf<<EOF
<VirtualHost $ip:$port>
  DocumentRoot "$WebRoot$domain"
  ServerName "$domain"
</VirtualHost>
EOF

echo "this is $domain" >>$WebRoot$domain/index.html

/etc/init.d/httpd restart

```







脚本调试

定义判断输入函数

监控httpd服务并使用邮件报警

综合脚本调试











