[TOC]



# 第十五单元-Zabbix

![improved_dashboard1](assets/improved_dashboard1.png)



## 15.1 Zabbix是什么

​	Zabbix是一个高度集成的企业级开源网络监控解决方案，与Cacti、nagios类似，提供分布式监控以及集中的web管理界面。



## 15.2 Zabbix的功能

​	zabbix具备常见商业监控软件所具备的功能，例如主机性能监控，网络设备性能监控，数据库性能监控，ftp等通用协议的监控，能够灵活利用可定制警告机制，允许用户对事件发送基于E-mail的警告，保证相关人员可以快速解决。还能够利用存储数据提供杰出的报表及实时的图形化数据处理，实现对监控主机7x24小时集中监控。



## 15.3 Zabbix的组件

​	Zabbix通过C/S模式采集数据通过B/S模式在web端展示和配置，zabbix-server服务端监听端口为10051，而zabbix-agent客户端监听端口为10050。





## 15.4 实验环境

| 主机                | 操作系统 | IP地址    | 主要软件                                              |
| ------------------- | -------- | --------- | ----------------------------------------------------- |
| zabbix-server服务端 | centos7  | 10.0.0.41 | httpd, php5.6, mysql5.6, zabbix-server,  zabbix-agent |
| zabbix-agent客户端  | centos7  | 10.0.0.42 | zabbix-server,  zabbix-agent                          |



## 15.5 zabbix-server服务端操作

### 15.5.1 搭建LAMP环境

```
yum -y install httpd mariadb mariadb-server php php-mysql php-gd
```

**#整合apache和php**

```
vim /etc/httpd/conf/httpd.conf
DirectoryIndex index.html index.php
AddType application/x-httpd-php .php
```

**#启动Apache和MariaDB并查**看

```
systemctl start httpd mariadb
systemctl status httpd mariadb
```

**#将服务设置为开机自动启动**

```
systemctl enable httpd mariadb
```

**#设置mariadb登录密码**

```
/usr/bin/mysqladmin -u root password '123456'
```



### 15.5.2 安装zabbix

**#配置zabbix源**

```shell
rpm -ivh https://mirrors.aliyun.com/zabbix/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
yum clean all
```

**#安装Zabbix server, frontend, agent**

```shell
yum -y install zabbix-server-mysql zabbix-web-mysql zabbix-agent
```

**#启动并设置开机自启zabbix-server，zabbix-agent**

```shell
systemctl restart zabbix-server zabbix-agent
systemctl enable zabbix-server zabbix-agent
```



### 15.5.3 初始化mysql数据库

```sql
mysql -uroot -p123456

mysql> create database zabbix character set utf8 collate utf8_bin;
mysql> grant all privileges on zabbix.* to zabbix@localhost identified by '123456';
mysql> quit;

zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -uzabbix -p123456 zabbix
```



### 15.5.4 编辑zabbix-server配置文件

```shell
vim /etc/zabbix/zabbix_server.conf
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=123456	#只修改此处
```



### 15.5.5 复制zabbix站点文件到apache站点目录

```
mkdir -p /var/www/html/zabbix
cp -a /usr/share/zabbix/* /var/www/html/zabbix/
```



### 15.5.6 重启httpd，zabbix-server，zabbix-agent

```
systemctl restart httpd zabbix-server zabbix-agent
```





### 15.5.7 访问zabbix页面

```shell
http://10.0.0.41/zabbix/

默认用户名：Admin 
密码：zabbix
```



![1568705020421](assets/1568705020421.png)





![1568705050617](assets/1568705050617.png)

页面会出现部分参数，failed，需要调整一下参数：

```
vim /etc/php.ini 
date.timezone = Asia/Shanghai
```

重启httpd

```
systemctl restart httpd
```


然后刷新http://10.0.0.41/zabbix/页面，报错消失。



![1568705199734](assets/1568705199734.png)

![1568705225006](assets/1568705225006.png)



![1568705243633](assets/1568705243633.png)

![1568705269528](assets/1568705269528.png)

![1568705318524](assets/1568705318524.png)













