[TOC]







# 第六单元-msql优化与常见故障排查



## 6.1 mysql优化

### 6.1.1 为什么要优化

​	优化，就是让数据库发挥更好的性能。一般情况下,数据库的优化指的就是**查询性能的优化**,让数据库对查询的响应尽可能的快.

​	仅对数据库系统本身而言,影响到查询性能的因素，包括数据库参数设置(其实就是通过参数控制数据库系统的内存,i/o,缓存，备份等一些管理性的东西),索引,分区,sql语句.分区则主要是针对大数据量的情况下，它分散了数据文件的分布，减少磁盘竞争，使效率得到提升。

### 6.1.2 硬件优化

​	在谈到基于硬件来进行数据库性能瓶颈分析的时候，常被大家误解为简单的使用更为强劲的主机或者存储来替换现有的设备。我们在谈论基于硬件进行优化的时候，不能仅仅将数据库使用的硬件划分为主机和存储两部分，而是需要进一步对硬件进行更细的分解，就分为：cpu、内存、磁盘、RAID卡、存储设备等方面。

**最容易出现性能瓶颈的地方主要会出现在以下几个方面：**

1.IO资源方面瓶颈，主要表现在服务器 iowait 很高，系统响应较慢，数据库中经常会存在大量执行状态的 session。

​	优化措施：

​	增加内存，加大可缓存的数据量

​	改善底层存储设备的 IO 能力(例如：把机械盘换成高性能ssd)

2.CPU资源方面瓶颈，主要表现在服务器CPU利用率中 usr 所占比例很高，iowait却很小

​	优化措施：

​	将运算尽可能从数据库端迁移到应用端，降低数据库主机的计算量

​	提升CPU处理能力，要么增加 CPU 数目（如果支持），要么换CPU更强劲的主机

### 6.1.3 网络优化

​	一般来说应用与数据库之间的网络交互所需的资源并不是非常大，但是在分布式的集群环境中，各个数据库节点之间的网络环境经常会称为系统的瓶颈。

优化措施：

廉价一点的解决方案是通过**万兆交换机来替换现在常用的千兆交换机**，来提升网络处理能力降低网络延时。不过这个方案主要提升的是吞吐量方面，对于延时方面的提升可能并不一定能满足某些要求非常高的场景。

这时候就该考虑使用更为昂贵但也更高效的方案：

用 Infiniband 替换普通交换机来极大的降低网络方面所带来的数据交换延时。
Infiniband：
InfiniBand架构是一种支持多并发链接的“转换线缆”技术，在这种技术中，每种链接都可以达到2.5 Gbps的运行速度。这种架构在一个链接的时候速度是500 MB/秒，四个链接的时候速度是2 GB/秒，12个链接的时候速度可以达到6 GB /秒。



## 6.2 mysql配置优化

### 6.2.1 mysql参数说明及优化

**1.普通参数设置**
**back_log**：设置MySQL能处理的**连接数量**，就是TCP/IP连接的侦听队列的大小。默认数值是50，可适当放大；

**interactive_timeout**：服务器在关闭一个交互连接前等待活动的秒数，默认数值是28800

**max_connections**：允许同时连接的客户的数量。增加该值能增加mysqld的文件描述符的数量。这个数字应该增加，否则，将经常看到 Too many connections 错误。 默认数值是100，可改为1024 

**key_buffer_size**：用于设置索引块的缓冲区大小，增加它可更好处理的索引(对所有读和多重写)，但是太大时，系统将开始变慢。默认数值是8388600(8M)，可根据服务器内存的大小设置更大的值。 

**table_cache**：为所有线程打开表的数量。增加该值能增加mysqld要求的文件描述符的数量。MySQL对每个唯一打开的表需要2个文件描述符。默认数值是64，可适当增加，如512。

**wait_timeout**：服务器在关闭一个非交互连接之前等待活动的秒数。 默认数值是28800。



**2.InnoDB设置**

**innodb_buffer_pool_size** : 默认值为 128M. 这是最主要的优化选项,指定 InnoDB 使用多少内存来加载数据和索引，针对专用MySQL服务器,建议指定为物理内存的 50-80%这个范围. 例如,拥有64GB物理内存的机器,缓存池应该设置为50GB左右. 

如果将该值设置得更大可能会存在风险,比如没有足够的空闲内存留给操作系统和依赖文件系统缓存的某些MySQL子系统(subsystem),包括二进制日志(binary logs),InnoDB事务日志(transaction logs)等.

**innodb_log_file_size**：默认值是48M. 有很高**写入吞吐量的系统需要增加该值**. 将此值设置为4G以下是很安全的. 不能设置太大，日志文件太大的缺点是增加了崩溃时所需的修复时间。



**3.主从复制(Replication)参数优化**

**log-bin**：启用二进制日志. 默认情况下二进制日志不是事故安全的(not crash safe), 建议大多数用户应该以稳定性为目标. 在这种情况下,还需要启用: sync_binlog=1, sync_relay_log=1, relay-log-info-repository=TABLE and master-info-repository=TABLE.

**sync_relay_log**：这个参数和sync_binlog是一样的，当设置为1时，slave的I/O线程每次接收到master发送过来的binlog日志都要写入系统缓冲区，然后刷入relay log中继日志里，这样是最安全的，因为在崩溃的时候，你最多会丢失一个事务，但会造成磁盘的大量I/O。当设置为0时，并不是马上就刷入中继日志里，而是由操作系统决定何时来写入，虽然安全性降低了，但减少了大量的磁盘I/O操作

**expire-logs-days**：默认旧日志会一直保留. 推荐设置为 1-10 天. 保存更长的时间并没有太多用处,因为从备份中恢复会快得多.

**server-id**：在一个主从复制体系(replication topology )中的所有服务器都必须设置唯一的 server-id.

**binlog_format=ROW**：修改为基于行的复制，可以通过减少资源锁定提高性能.
其他配置(Misc)

**character-set-server=utf8mb4、collation-server=utf8mb4_general_ci** ：utf8编码对新应用来说是更好的默认选项.

**skip-name-resolve**：禁用反向域名解析. DNS解析在某些系统上可能有点慢，不稳定,所以如果不需要基于主机名的解析,建议避免这种解析.



## 6.3 mysql常见故障排查

### 6.3.1 故障排查思路

在mysql的数据库中，故障可分为三类，硬件故障，网络故障，mysql服务本身的故障。

遇到故障，首先应该仔细分析提示信息，就是报警信息，一般都能给出故障的问题所在；如果报警信息比较模糊，则可分析相应日志文件，包括mysql本身的日志文件，还有操作系统的日志文件，细心分析，就能定位问题所在，从而找出解决问题。



### 6.3.2 故障排查案例

**1.启动故障**

**故障一：**

![1570151561575](assets/1570151561575.png)

原因分析：MySQL的数据目录$datadir目录，及其下属目录、文件权限属性置不正确，导致MySQL无法正常读写文件，无法启动

解决办法：chown –R mysql:mysql  数据目录的属主：属组

**故障二：**

![1570151615164](assets/1570151615164.png)

原因分析：已有其他mysqld实例启动，且占用了相同端口

解决办法：修改port选项，指定其他未用端口

**故障三：**

![1570151651212](assets/1570151651212.png)

原因分析：安装后没有初始化数据库造成

解决办法：根据实际情况使用mysql_install_db工具进行数据库的初始化



**2.连接故障**

**故障一：**

```shell
ERROR 1045 (28000): Access denied for user 'usera'@'localhost' (using password:YES)
ERROR 1045 (28000): Access denied for user 'usera'@'localhost' (using password:NO)  
```

原因分析：客户端远程访问的用户账号并未创建； 用户账号存在，但未对其所在的客户端的IP进行远程访问授权允许；密码不正确

解决方法：对第一种情况，使用grant语句对相应用户进行授权

```shell
grant all privileges on *.* to '用户名'@'ip' identified by '密码' with grant option;
flush priviges;
```

对后一种情况，使用grant设置相应用户能在所有ip上远程连接mysql：

```shell
GRANT ALL PRIVILEGES ON *.* TO '用户名'@'%' IDENTIFIED BY '密码' WITH GRANT OPTION;
flush priviges;
```

**故障二：**

```shell
ERROR 2003 (HY000): Can't connect to MySQL server on '192.168.8.88' (10065)
```

原因分析：防火墙阻挡了连接

解决方法：设置iptables规则或者关闭防火墙



**故障三：**

```shell
ERROR 2003 (HY000): Can't connect to MySQL server on 'hostxxxxx' (10061)
```

原因分析：数据库没有启动

解决办法：启动数据库即可



**故障四:**

```shell
ERROR 2002 (HY000): Can't connect to local MySQL server server through socket '/var/lib/mysql/mysql.sock'(111)
```

原因分析：mysqld的mysql.sock没在相应的位置

解决办法：

```shell
/etc/rc.d/init.d/mysql stop

chown -R mysql:msyql /var/lib/mysql

vim /etc/my.cnf

[mysqld]
datadir=/usr/local/mysql/data
socket=/var/lib/mysql/mysql.sock
[mysql.server]
user=mysql
basedir=/usr/local/mysql
[client]
socket=/var/lib/mysql/mysql.sock
```

启动数据库



**3.字符乱码**

关闭MySQL服务（mysqladmin -u root shutdown -p）

修改/etc/下的my.cnf，保存并关闭

在[client] 在下面添加

```shell
default-character-set=utf8
```

在[mysqld]下添加

```shell
default-character-set=utf8
init_connect='SET NAMES utf8' （设定连接mysql数据库时使用utf8编码，以让mysql数据库为utf8运行）
```


启动MySQL服务（bin/mysqld_safe &），

数据库内重新查看编码显示

```shell
show variables like 'character%';
```



**4.其他常见故障解决思路**

1）too many connections错误的解决步骤：

查看当前mysql允许的最大连接数:

```shell
mysql> show variables like 'max_connections';
```

（可以通过show  variables like "%max%"，可以查看到所有的最大值限制信息）

查看当前的链接数:

```
mysql> show processlist;
```

增加允许的最大链接数:

```
mysql> set global max_connections=200;
```

2）Host '127.0.0.1' is blocked because of many connection errors.错误解决访求：

执行`mysqladmin flush-hosts`来解除锁定

