[TOC]







# 第三单元-mysql数据库的高级管理



## 3.1 mysql密码的修改与恢复

### 3.1.1 修改密码

**命令行修改**

```
mysqladmin -uroot -p123456 password 654321
```

​		

**数据库内修改**
方法一：

```
update mysql.user set password=password('123456') where user='root' and host='localhost';
flush privileges;
```

方法二：

```
set password for root@'localhost' =password('654321');
#注：这种方法无需刷新权限
```

方法三：命令行执行

```
mysql_secure_installation
#安全配置向导，会对数据库进行简单的优化。
```





### 3.1.2 忘记mysql密码后的恢复

```
1、/etc/init.d/mysqld stop
2、mysqld_safe --skip-grant-tables --user=mysql &>/dev/null &
3、直接mysql无密码登录	
4、然后设置新密码
```





## 3.2 mysql备份与恢复

### 3.2.1 备份的概念与分类

**概念**

为防止文件、数据丢失或损坏等可能出现的意外情况，将电子计算机存储设备中的数据复制到磁带等大容量存储设备中,从而在原文中独立出来单独贮存的程序或文件副本; 如果系统的硬件或存储媒体发生故障，“备份”工具可以帮助您保护数据免受意外的损失。

mysql数据备份其实就是通过SQL语句的形式将数据DUMP出来，以文件的形式保存，而且导出的文件还是可编辑的，这和Oracle数据库的rman备份还是很不一样的，mysql更像是一种逻辑备份从库中抽取SQL语句，这就包括建库，连库，建表，插入等就像是将我们之前的操作再通过SQL语句重做一次。



**分类**

**一般的备份可分为：**

1、系统备份：指的是用户操作系统因磁盘损伤或损坏，计算机病毒或人为误删除等原因造成的系统文件丢失，从而造成计算机操作系统不能正常引导，因此使用系统备份，将操作系统事先贮存起来，用于故障后的后备支援。

2、数据备份：指的是用户将数据包括文件，数据库，应用程序等贮存起来，用于数据恢复时使用。

**备份更专业地可分为：**

i. 全量备份：完全备份就是指对某一个时间点上的所有数据或应用进行的一个完全拷贝

ii. 增量备份：增量备份是指在一次全备份或上一次增量备份后，以后每次的备份只需备份与前一次相比增加和者被修改的文件

iii. 差异备份：差异备份是指在一次全备份后到进行差异备份的这段时间内，对那些增加或者修改文件的备份





### 3.2.2 备份工具：mysqldump、mydumper、xtrabackup



#### 3.2.2.1 使用mysqldump工具备份与恢复

**1.命令介绍：**

mysqldump是mysql提供的一个基于命令行的mysql数据备份工具，提供了丰富的参数选择，用于各种需求形式的备份，如单库备份，多库备份，单表与多表备份，全库备份，备份表结构，备份表数据等。



**2.备份还原语法格式：**

**以下为备份还原，lol数据库和hero表为演练。**

**（1）、单库备份及还原**

```
备份
mysqldump -uroot -p123456 lol >/opt/backup/lol.sql
注意：此操作只备份其中的表（包括创建表的语句和数据）。

还原
mysql -uroot -p123456 -e 'create database lol;'
mysql -uroot -p123456 lol </opt/backup/lol.sql
```

**（2）、多库备份及还原**

```
备份
mysqldump -uroot -p123456 -B 库1 库2 库3 >/opt/backup/mysql_bak_db.sql

还原
mysql -uroot -p123456 </opt/backup/mysql_bak_db.sql
```

**注意：多个库之间用空格分隔**

**（3）、单表备份及还原**

```
备份
mysqldump -uroot -p123456 lol hero>/opt/backup/hero.sql

还原
mysql -uroot -p123456 lol </opt/backup/hero.sql
```

**（4）、多表备份及还原**

```
备份
mysqldump -uroot -p123456 库名 表1 表2>/opt/backup/mysql_bak_db.sql

还原
mysql -uroot -p123456 库名 </opt/backup/mysql_bak_db.sql
```

**（5）、全库备份**

```
mysqldump -uroot -p123456 -A >/opt/backup/mysql_bak_db.sql
或者
mysqldump -uroot –p123456 --all-databases >/opt/backup/mysql_bak_db.sql
```



**3.常用参数解析：**

**（1）、-B等同于--databases**

如果想一次备份多个库需要添加B参数，B参数会在备份数据中添加create database和use语句

**（2）、-F**
在备份之前会先刷新日志，可以看到二进制文件前滚产生新的二进制文件。
**（3）、--master-data**
有二个值1或者2，等于1会在备份数据中增加如下语句：

```
CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000040',MASTER_LOG_POS=4543;
```

等于2会在备份数据中增加如下语句：

```
-- CHANGE MASTER TO MASTER_LOG_FILE='mysql-bin.000040',MASTER_LOG_POS=4543;
```

唯一区别就是有没有被“--”注释掉，如果备份的数据用于slave，等于1即可，此时从库就知道应该从哪个地方开始读二进制日志，如果仅用于备份标识当前二进制是哪一个和位置点等于2合适。

**（4）、-x**  

锁表，备份的时候锁表来保证数据一致性。

**（5）、-d**  

只备份表结构不备份数据。

**（6）、-A等同于--all-databases**

备份所有数据库

**（7）、-X等同于--xml**

导出为xml文件

**（8）、--single-transaction** 
Innodb引擎保证数据一致性的参数，使用此参数后会话的安全隔离级别会被置为repeatble-read，此时其它会话提交的数据是不可视的，从而保证数据的一致性。
**更多参数请参考help**



**4.还原备份**

方法一：

```mysql
#备份lol数据库
[root@ c6s02 ~]# mysqldump -uroot -p123456 -B lol >lol.sql


#先删除lol数据库
[root@ c6s02 ~]# mysql -uroot -p123456

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| lol                |
| mysql              |
| performance_schema |
| test               |
| wg                 |
+--------------------+
6 rows in set (0.00 sec)

mysql> drop database lol;
Query OK, 3 rows affected (0.03 sec)

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test               |
| wg                 |
+--------------------+
5 rows in set (0.00 sec)

mysql> \q

#测试恢复并查看
[root@ c6s02 ~]# mysql -uroot -p123456 <lol.sql
Warning: Using a password on the command line interface can be insecure.

[root@ c6s02 ~]# mysql -uroot -p123456
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| lol                |
| mysql              |
| performance_schema |
| test               |
| wg                 |
+--------------------+
6 rows in set (0.00 sec)

mysql> select * from lol.hero;
+----+--------+--------+-----------+--------+
| id | 角色   | 职业   | 攻击力    | 血量   |
+----+--------+--------+-----------+--------+
|  1 | 蛮王   | 战士   |       200 | NULL   |
|  2 | 狗头   | 战士   |       100 | NULL   |
|  3 | 剑圣   | 战士   |       300 | NULL   |
+----+--------+--------+-----------+--------+
3 rows in set (0.00 sec)
```

方法二：source方法

```
[root@ c6s02 ~]# mysql -uroot -p123456
mysql> source /root/lol.sql
```











#### 3.2.2.2 Mydumper工具介绍与使用

**1.介绍**
mydumper是针对mysql数据库备份的一个轻量级第三方的开源工具，备份方式为逻辑备份。它支持多线程，备份速度远高于原生态的mysqldump以及众多优异特性。因此该工具是DBA们的不二选择。



**2.mydumper的特点**

- 轻量级C语言写的
- 执行速度比mysqldump快10倍，多线程逻辑备份,生产的多个备份文件
- 事务性和非事务性表一致的快照(适用于0.2.2以上版本)
- 支持文件压缩，支持导出binlog，支持多线程恢复，支持将备份文件切块
- 多线程恢复(适用于0.2.1以上版本)
- 以守护进程的工作方式，定时快照和连续二进制日志(适用于0.5.0以上版本)
- 保证备份数据的一致性,
- 与mysqldump相同，备份时对 MyISAM 表施加FTWRL (FLUSH TABLES WITH READ LOCK), 会阻塞DML 语句



**3.mydumper安装**

此项目托管在github。

github地址：https://github.com/maxbube/mydumper

安装

```shell
rpm安装
wget https://github.com/maxbube/mydumper/releases/download/v0.9.5/mydumper-0.9.5-2.el7.x86_64.rpm
rpm -ivh mydumper-0.9.5-2.el7.x86_64.rpm

或者
源码安装
yum -y install glib2-devel mysql-devel zlib-devel pcre-devel cmake gcc-c++ git
git clone https://github.com/maxbube/mydumper.git
cd mydumper
cmake .
make && make install


#测试安装可能会有以下报错：
报错一：
[root@ c6s02 mydumper]# mydumper -V
mydumper: error while loading shared libraries: libmysqlclient.so.18: cannot open shared object file: No such file or directory

#解决办法：
[root@ c6s02 ~]# find / -name libmysqlclient.so.18.1.0
/usr/local/mysql/lib/libmysqlclient.so.18.1.0	--#找到自己mysql数据库下的libmysqlclient.so.18.1.0并做软连接
/root/mysql-5.6.45/libmysql/libmysqlclient.so.18.1.0

#做软连接
[root@ c6s02 ~]# ln -sv  /usr/local/mysql/lib/libmysqlclient.so.18.1.0 /lib64/libmysqlclient.so.18

报错二：
mydumper: error while loading shared libraries: libpcre.so.1: cannot open shared object file: No such file or directory

wget https://ftp.pcre.org/pub/pcre/pcre-8.00.tar.gz
tar -zxvf  pcre-8.00.tar.gz
cd pcre-8.00
./configure --enable-utf8
make
make check
make install

#显示以下效果表示安装成功
[root@ c6s02 ~]# mydumper -V
mydumper 0.10.0, built against MySQL 5.6.45
```



**4.mydumper语法及参数介绍**

```
mydumper -u [USER] -p [PASSWORD] -h [HOST] -P [PORT] -t [THREADS] -b -c -B [DB] -o [directory]
```

注意：命令行之间要有空格 -u 用户名  -p 密码 之间必须有空格

```
-B, --database 需要备份的库
-T, --tables-list 需要备份的表，用，分隔
-o, --outputdir 输出文件的目录
-s, --statement-size Attempted size of INSERT statement in bytes, default 1000000
-r, --rows 试图分裂成很多行块表
-c, --compress 压缩输出文件
-e, --build-empty-files 即使表没有数据，还是产生一个空文件
-x, --regex 支持正则表达式
-i, --ignore-engines 忽略的存储引擎，用，分隔
-m, --no-schemas 不导出表结构
-k, --no-locks 不执行临时共享读锁 警告：这将导致不一致的备份
-l, --long-query-guard 长查询，默认60s
--kill-long-queries kill掉长时间执行的查询(instead of aborting)
-b, --binlogs 导出binlog
-D, --daemon 启用守护进程模式
-I, --snapshot-interval dump快照间隔时间，默认60s，需要在daemon模式下
-L, --logfile 日志文件
-h, --host
-u, --user
-p, --password
-P, --port
-S, --socket
-t, --threads 使用的线程数，默认4
-C, --compress-protocol 在mysql连接上使用压缩
-V, --version
 -v, --verbose 更多输出, 0 = silent, 1 = errors, 2 = warnings, 3 = info, default 2
```



**5.myloader参数介绍：**

```
-d, --directory 导入备份目录
-q, --queries-per-transaction 每次执行的查询数量, 默认1000
-o, --overwrite-tables 如果表存在删除表
-B, --database 需要还原的库
-e, --enable-binlog 启用二进制恢复数据
-h, --host
-u, --user
-p, --password
-P, --port
-S, --socket
-t, --threads 使用的线程数量，默认4
-C, --compress-protocol 连接上使用压缩
-V, --version
-v, --verbose 更多输出, 0 = silent, 1 = errors, 2 = warnings, 3 = info, default 2
```



**6.mydumper输出文件：**

```
metadata:元数据 记录备份开始和结束时间，以及binlog日志文件位置。
table data:每个表一个文件
table schemas:表结构文件
binary logs: 启用--binlogs选项后，二进制文件存放在binlog_snapshot目录下
daemon mode:在这个模式下，有五个目录0，1，binlogs，binlog_snapshot，last_dump。
备份目录是0和1，间隔备份，如果mydumper因某种原因失败而仍然有一个好的快照，
当快照完成后，last_dump指向该备份。
```

**7.常用备份示例：**

备份单个库 

```
mydumper -u 用户名 -p 密码 -B 需要备份的库名 -o /tmp/bak

-B,需要备份的库   -o 输出文件的目录（备份输出指定的目录）
```

备份所有数据库

```
全库备份期间除了information_schema与performance_schema之外的库都会被备份

mydumper -u 用户名 -p 密码 -o /tmp/bak
 
 -o 输出文件的目录（备份输出指定的目录）
```

备份单表

```
mydumper -u 用户名 -p 密码 -B 库名 -T 表名 -o /tmp/bak

-T 需要备份的表，多表用逗号分隔 -o指定输出备份文件路径 
```

备份多表

```
mydumper -u 用户名 -p 密码 -B 库名 -T 表1,表2 -o /tmp/bak

当前目录自动生成备份日期时间文件夹,不指定-o参数及值时默认为：export-20150703-145806

mydumper -u 用户名 -p 密码 -B 数据库名字 -T 表名
```

不带表结构备份表

```
mydumper -u 用户名 -p 密码 -B 数据名字 -T 表名 -m

-m 不导出表结构
```

压缩备份及连接使用压缩协议(非本地备份时)

```
mydumper -u 用户名 -p 密码 -B 数据库名字 -o /tmp/bak -c -C

-c  压缩输出文件 -C 在mysql连接上使用压缩协议  -o 输出文件的目录（备份输出指定的目录）
```

备份特定表

```
mydumper -u 用户名 -p 密码 -B 数据库名字  --regex=actor* -o /tmp/bak

只备份以actor*开头的表

-x 正则表达式: 'db.table'  --regex  
```

过滤特定库，如本来不备份mysql及test库

```
mydumper -u 用户名 -p 密码 -B 数据库名字 --regex '^(?!(mysql|test))' -o /tmp/bak
```

基于空表产生表结构文件

```
mydumper -u 用户名 -p 密码 -B 数据库名字 -T 空表 -e -o /tmp/bak

-e 即使表没有数据，还是产生一个空文件 
```

设置长查询的上限，如果存在比这个还长的查询则退出mydumper，也可以设置杀掉这个长查询

```
mydumper -u leshami -p pwd -B sakila --long-query-guard 200 --kill-long-queries
```

备份时输出详细更多日志

```
mydumper -u 用户名 -p 密码 -B 数据库名字 -T 空表 -v 3 -o /tmp/bak

-v 更多输出, 0 = silent, 1 = errors, 2 = warnings, 3 = info,详细输出 default 2
```

导出binlog，使用-b参数，会自动在导出目录生成binlog_snapshot文件夹及binlog

```
mydumper -u leshami -p pwd -P 3306 -b -o /tmp/bak
```

总结：
mysql备份，备份数据库、备份数据表。恢复也是恢复数据库，恢复数据表。







#### 3.2.2.3 xtrabackup

课外阅读：Xtrabackup工具介绍与使用

a) 了解Xtrabackup的介绍与使用举例

Xtrabackup是由percona提供的mysql数据库备份工具, 有两个主要的工具：xtrabackup、innobackupex，备份过程快速、可靠，备份过程不会打断正在执行的事务，能够基于压缩等功能节约磁盘空间和流量，自动实现备份检验，还原速度快，备份可在线备份，但是恢复要关闭服务器，恢复后再启动.



### 3.3 mysql大数据库的备份思路

小量的数据库我们可以每天进行完整备份，因为这也用不了多少时间。但当数据库很大时，我们就不太可能每天进行一次完整备份了，而且改成每周一次完整备份，每天一次增量备份类似这样的备份策略。**增量备份的原理就是使用了MySQL的二进制日志，所以我们必须启用二进制日志功能。**

mysqldump   数据量<=30G

xtrabackup   数据量>=30G



## 3.4 mysql的安全配置

### 3.4.1 mysql用户的操作

**查看用户:**

```
select user,host from mysql.user;
```

**创建用户：**

```
CREATE USER '用户'@'主机' IDENTIFIED BY '密码';
create user 'boy'@'locahost' identified by '123456';  #只能连接
```

**删除用户：**

```
drop user 'user'@'主机域';

**特殊的删除方法：**
delete from mysql.user where  user='bbs' and host='172.16.1.%'; 
flush privileges;
```

**创建用户同时授权：**

```
grant all on *.* to boy@'172.16.1.%' identified by '123456';
flush privileges;
```



### 3.4.2 mysql用户的权限设置

权限可以分为四个层级：全局级别（*.*）、数据库级别(数据库名.*)、表级别(数据库名.表名)、列级别(  权限（列）    数据库名.表名)。

全局级别的权限存放在mysql.user表中，数据库级别的权限存放在mysql.db或者mysql.host，表级别的权限存放在mysql.tables_priv中，列级别的权限存放在mysql.columns_priv中。

**查看用户对应的权限：**

```
show grants for 用户@主机域\G
show grants for root@localhost\G
```

**给用户授权：**

```
GRANT ALL ON 数据库.表 TO '用户'@'localhost';
GRANT ALL ON db1.* TO 'jeffrey'@'localhost';
GRANT ALL ON *.* TO 'boy'@'localhost';
```

**收回权限：**

```
REVOKE INSERT ON *.* FROM boy@localhost;
```

**可以授权的用户权限：**

```
INSERT,SELECT, UPDATE, DELETE, CREATE, DROP, RELOAD, SHUTDOWN, PROCESS, FILE, REFERENCES, INDEX, ALTER, SHOW DATABASES, SUPER, CREATE TEMPORARY TABLES, LOCK TABLES, EXECUTE, REPLICATION SLAVE, REPLICATION CLIENT, CREATE VIEW, SHOW VIEW, CREATE ROUTINE, ALTER ROUTINE, CREATE USER, EVENT, TRIGGER, CREATE TABLESPACE
```



## 3.5 mysql日志类型

### 3.5.1 二进制日志（log-bin）

二进制日志非常重要，二进制日志会记录mysql数据库的所有变更操作，其实和oracle的redolog日志原理差不多，由于它记录的所有的操作，于是我们就可以使用某个时间点之后的二进制日志做前滚操作，来增量恢复数据。

mysql的二进制日志可以使用mysqlbinlog来进行查看和过滤，一直过滤到我们想要的数据再导入数据库，而且也是非常方便的，但尤其要强调的是要严格按照二进制日志生成的顺序执行。

**用途：**记录所有变更操作，用于增量备份

**配置：**在my.cnf中添加

```
[mysqld]
log-bin =mysql-bin
log-bin-index =mysql-bin.index
```



### 3.5.2 中继日志（relay-log）

顾名思义，传递日志，主要用在主从复制的架构中，只在从库中有中继日志（多级复制除外）在从库中将主库复制过来的二进制日志保存为中继日志，**用于从库重构数据**。

**配置：**在my.cnf中添加

```
[mysqld]
relay-log =relay-log
relay_log_index= relay-log.index
```



### 3.5.3 慢查询日志（slow_query_log）

慢查询日志主要用于mysql优化，从数据库中找出哪些SQL语句是比较慢的，将其放到一个文件中，后续可以使用mysqlsla工具去对慢查询语句进行分析，将分析结果提交给开发进行SQL优化。

**用途：**找出慢查询进行优化

**配置：**在my.cnf中添加

```
[mysqld]
slow_query_log= 1
long-query-time= 2  
slow_query_log_file= /data/3306/slow.log
```



### 3.5.4 一般查询日志

会记录所有访问mysql的行业，因此会产生大量日志，一般建议关闭。

配置：在my.cnf中添加

```
[mysqld]
general_log = 1
log_output =FILE
general_log_file= /home/mysql/mysql/log/mysql.log 
```



### 3.5.5 错误日志

记录mysql产生的错误，这个日志在排错的时候相当有用，一般建议开启。

配置：在my.cnf中添加

```
[mysqld]
log-warnings =1
log-error =/home/mysql/mysql/log/mysql.err
```



### 3.5.6 事务日志

缓存事务提交的数据，实现将随机IO转换成顺序IO。

配置：在my.cnf中添加

```
[mysqld]
innodb_log_buffer_size= 16M
innodb_log_file_size= 128M
innodb_log_files_in_group= 3
```

