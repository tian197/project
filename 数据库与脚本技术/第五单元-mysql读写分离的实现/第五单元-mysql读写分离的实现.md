[TOC]







# 第五单元-mysql读写分离的实现

读写分离拓扑图如下：



![1569982149850](assets/1569982149850.png)





## 5.1 为什么要实现mysql读写分离

​	大型网站为了软解大量的并发访问，除了在网站实现分布式负载均衡，远远不够。到了数据业务层、数据访问层，如果还是传统的数据结构，或者只是单单靠一台服务器来处理如此多的数据库连接操作，数据库必然会崩溃，特别是数据丢失的话，后果更是不堪设想。这时候，我们会考虑如何减少数据库的连接，下面就进入我们今天的主题。

​	利用主从数据库来实现读写分离，从而分担主数据库的压力。在多个服务器上部署mysql，将其中一台认为主数据库，而其他为从数据库，实现主从同步。其中**主数据库负责主动写的操作**，而**从数据库则只负责主动读的操作**（slave从数据库仍然会被动的进行写操作，为了保持数据一致性），这样就可以很大程度上的避免数据丢失的问题，同时也可减少数据库的连接，减轻主数据库的负载。



## 5.2 mysql读写分离

### 5.2.1 mysql读写分离概述

​	mysql本身不能实现读写分离的功能，需要借助中间件实现，例如：Amoeba，Mysql Proxy，Atlas。今天主要介绍Amoeba实现mysql读写分离。

​	Amoeba(变形虫)项目，该开源框架于2008发布一款Amoeba for mysql软件，该软件致力于mysql的分布式数据库前端代理层，**主要的作用是应用服务访问mysql服务器时充当SQL路由功能，并具有负载均衡、高可用性、SQL过滤、读写分离、可路由相关SQL的到目标数据库、可并发请求多台数据库全并结果的作用。**通过Amoeba能够完成多数据源的高可用、负载均衡、数据切片的功能。

目前Amoeba已在很多企业的生产线上面使用；其版本可在官网进行下载。其工作原理图如下：

![1569983319818](assets/1569983319818.png)



### 5.2.2 mysql读写分离原理

读写分离就是利用mysql的主从复制完成的，本质就是**在主服务器上修改**，数据会同步到从服务器，**从服务器只能提供读取数据，不能写入**，实现备份的同时也实现了数据库性能的优化，以及提升了服务器安全。



## 5.2 mysql读写分离配置

本次mysql读写分离使用Amoeba实现，以下为实验过程。

### 5.2.1 mysql读写分离部署配置

**1.环境介绍**

| 主机名       | ip        | 系统      | 软件                      |
| ------------ | --------- | --------- | ------------------------- |
| amoeba       | 10.0.0.23 | centos6.8 | amoeba-mysql-3.0.5，mysql |
| mysql-master | 10.0.0.21 | centos6.8 | mysql， mysql-server      |
| mysql-slave  | 10.0.0.22 | centos6.8 | mysql， mysql-server      |

注：mysql版本和安装方式无要求，实现主从即可。



**2.配置jdk环境**

上传jdk-8u60-linux-x64.tar.gz

```shell
[root@ amoeba ~]# tar -zxvf jdk-8u60-linux-x64.tar.gz  -C /usr/local/
[root@ amoeba ~]# vim /etc/profile
#添加如下三行到全局环境变量
export JAVA_HOME=/usr/local/jdk1.8.0_60
export PATH=$JAVA_HOME/bin:$JAVA_HOME/jre/bin:$PATH
export CLASSPATH=.$CLASSPATH:$JAVA_HOME/lib:$JAVA_HOME/jre/lib:$JAVA_HOME/lib/tools.jar

[root@ amoeba ~]# source /etc/profile
[root@ amoeba ~]# java -version
java version "1.8.0_60"
Java(TM) SE Runtime Environment (build 1.8.0_60-b27)
Java HotSpot(TM) 64-Bit Server VM (build 25.60-b23, mixed mode)
```



**3.下载安装Amoeba**

我这里下载的是amoeba-mysql-3.0.5-RC-distribution.zip。Amoeba安装非常简单，直接解压即可使用，这里将Amoeba解压到/usr/local/amoeba目录下，这样就安装完成了。

```shell
[root@ amoeba ~]# yum -y install unzip

#解压并改名
[root@ amoeba ~]# unzip amoeba-mysql-3.0.5-RC-distribution.zip -d /usr/local/
[root@ amoeba ~]# mv /usr/local/amoeba-mysql-3.0.5-RC /usr/local/amoeba
```



**4.配置Amoeba**

Amoeba的配置文件在本环境下位于/usr/local/amoeba/conf目录下。配置文件比较多，但是仅仅使用读写分离功能，只需配置两个文件即可，分别是dbServers.xml和amoeba.xml，如果需要配置ip访问控制，还需要修改access_list.conf文件，下面首先介绍dbServers.xml

```shell
[root@ amoeba ~]# cd /usr/local/amoeba/conf/

[root@ amoeba conf]# cat dbServers.xml
<?xml version="1.0" encoding="gbk"?>

<!DOCTYPE amoeba:dbServers SYSTEM "dbserver.dtd">
<amoeba:dbServers xmlns:amoeba="http://amoeba.meidusa.com/">

		<!--
			Each dbServer needs to be configured into a Pool,
			If you need to configure multiple dbServer with load balancing that can be simplified by the following configuration:
			 add attribute with name virtual = "true" in dbServer, but the configuration does not allow the element with name factoryConfig
			 such as 'multiPool' dbServer
		-->

	<dbServer name="abstractServer" abstractive="true">
		<factoryConfig class="com.meidusa.amoeba.mysql.net.MysqlServerConnectionFactory">
			<property name="connectionManager">${defaultManager}</property>
			<property name="sendBufferSize">64</property>
			<property name="receiveBufferSize">128</property>

			<!-- mysql port -->
			<property name="port">3306</property>	#设置Amoeba要连接的mysql数据库的端口，默认是3306

			<!-- mysql schema -->
			<property name="schema">testdb</property> #设置缺省的数据库，当连接amoeba时，操作表必须显式的指定数据库名，即采用dbname.tablename的方式，不支持 use dbname指定缺省库，因为操作会调度到各个后端mysql

			<!-- mysql user -->
			<property name="user">amoeba</property> #设置amoeba连接后端数据库服务器的账号

			<property name="password">123456</property> #设置amoeba连接后端数据库服务器的密码，因此需要在所有后端数据库上创建该用户，并授权amoeba服务器可连接
		</factoryConfig>

		<poolConfig class="com.meidusa.toolkit.common.poolable.PoolableObjectPool">
			<property name="maxActive">500</property> #最大连接数，默认500
			<property name="maxIdle">500</property>   #最大空闲连接数
			<property name="minIdle">1</property>     #最小空闲连接数
			<property name="minEvictableIdleTimeMillis">600000</property>
			<property name="timeBetweenEvictionRunsMillis">600000</property>
			<property name="testOnBorrow">true</property>
			<property name="testOnReturn">true</property>
			<property name="testWhileIdle">true</property>
		</poolConfig>
	</dbServer>

	<dbServer name="master"  parent="abstractServer"> #设置一个后端可写的mysql，这里定义为master，这个名字可以任意命名，后面还会用到
		<factoryConfig>
			<!-- mysql ip -->
			<property name="ipAddress">10.0.0.21</property> #设置后端可写mysql地址
		</factoryConfig>
	</dbServer>

	<dbServer name="slave"  parent="abstractServer"> #设置后端可读mysql
		<factoryConfig>
			<!-- mysql ip -->
			<property name="ipAddress">10.0.0.22</property>
		</factoryConfig>
	</dbServer>

	<dbServer name="myslave" virtual="true"> #设置定义一个虚拟的dbserver，实际上相当于一个dbserver组，这里将可读的数据库ip统一放到一个组中，将这个组的名字命名为myslave
		<poolConfig class="com.meidusa.amoeba.server.MultipleServerPool">
			<!-- Load balancing strategy: 1=ROUNDROBIN , 2=WEIGHTBASED , 3=HA-->
			<property name="loadbalance">1</property> #选择调度算法，1表示复载均衡，2表示权重，3表示HA， 这里选择1

			<!-- Separated by commas,such as: server1,server2,server1 -->
			<property name="poolNames">slave</property>  #myslave组成员
		</poolConfig>
	</dbServer>

</amoeba:dbServers>
```

另一个配置文件amoeba.xml

```shell
[root@ amoeba conf]# cat amoeba.xml
<?xml version="1.0" encoding="gbk"?>

<!DOCTYPE amoeba:configuration SYSTEM "amoeba.dtd">
<amoeba:configuration xmlns:amoeba="http://amoeba.meidusa.com/">

	<proxy>

		<!-- service class must implements com.meidusa.amoeba.service.Service -->
		<service name="Amoeba for Mysql" class="com.meidusa.amoeba.mysql.server.MySQLService">
			<!-- port -->
			<property name="port">8066</property> #设置amoeba监听的端口，默认是8066

			<!-- bind ipAddress -->
			<!--
			<property name="ipAddress">127.0.0.1</property> #下面配置监听的接口，如果不设置，默认监听所以的IP
			 -->

			<property name="connectionFactory">
				<bean class="com.meidusa.amoeba.mysql.net.MysqlClientConnectionFactory">
					<property name="sendBufferSize">128</property>
					<property name="receiveBufferSize">64</property>
				</bean>
			</property>

			<property name="authenticateProvider">
				<bean class="com.meidusa.amoeba.mysql.server.MysqlClientAuthenticator">

# 提供客户端连接amoeba时需要使用这里设定的账号 (这里的账号密码和amoeba连接后端数据库服务器的密码无关)
					<property name="user">root</property>

					<property name="password">123456</property>

					<property name="filter">
						<bean class="com.meidusa.toolkit.net.authenticate.server.IPAccessController">
							<property name="ipFile">${amoeba.home}/conf/access_list.conf</property>
						</bean>
					</property>
				</bean>
			</property>

		</service>

		<runtime class="com.meidusa.amoeba.mysql.context.MysqlRuntimeContext">

			<!-- proxy server client process thread size -->
			<property name="executeThreadSize">128</property>

			<!-- per connection cache prepared statement size  -->
			<property name="statementCacheSize">500</property>

			<!-- default charset -->
			<property name="serverCharset">utf8</property>

			<!-- query timeout( default: 60 second , TimeUnit:second) -->
			<property name="queryTimeout">60</property>
		</runtime>

	</proxy>

	<!--
		Each ConnectionManager will start as thread
		manager responsible for the Connection IO read , Death Detection
	-->
	<connectionManagerList>
		<connectionManager name="defaultManager" class="com.meidusa.toolkit.net.MultiConnectionManagerWrapper">
			<property name="subManagerClassName">com.meidusa.toolkit.net.AuthingableConnectionManager</property>
		</connectionManager>
	</connectionManagerList>

		<!-- default using file loader -->
	<dbServerLoader class="com.meidusa.amoeba.context.DBServerConfigFileLoader">
		<property name="configFile">${amoeba.home}/conf/dbServers.xml</property>
	</dbServerLoader>

	<queryRouter class="com.meidusa.amoeba.mysql.parser.MysqlQueryRouter">
		<property name="ruleLoader">
			<bean class="com.meidusa.amoeba.route.TableRuleFileLoader">
				<property name="ruleFile">${amoeba.home}/conf/rule.xml</property>
				<property name="functionFile">${amoeba.home}/conf/ruleFunctionMap.xml</property>
			</bean>
		</property>
		<property name="sqlFunctionFile">${amoeba.home}/conf/functionMap.xml</property>
		<property name="LRUMapSize">1500</property>
		<property name="defaultPool">multiPool</property>

#这两个选项默认是注销掉的，需要取消注释，这里用来指定前面定义好的俩个读写池
		
		<property name="writePool">master</property> #设置amoeba默认的可写的db池，这里设置为master
		<property name="readPool">slave</property> #设置amoeba默认的可读的db池，这里设置为slave
		
		<property name="needParse">true</property>
	</queryRouter>
</amoeba:configuration>
```



**5.在masterdb(10.0.0.21)上创建数据库testdb**

```shell
[root@ mysql-master ~]# mysql -uroot -p123456
mysql> create database testdb;
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| test               |
| testdb             |
+--------------------+
```

查看slavedb(10.0.0.22)是否复制成功

```shell
[root@ mysql-slave ~]# mysql -uroot -p123456
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| test               |
| testdb             |
+--------------------+
```

分别在masterdb(10.0.0.21)和slavedb(10.0.0.22)上为amoedb用户授权

```
mysql> GRANT ALL ON *.* TO 'amoeba'@'10.0.0.23' IDENTIFIED BY '123456';
mysql> flush privileges;
```

**6.启动amoeba**

```shell
[root@ amoeba conf]# /usr/local/amoeba/bin/launcher
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=16m; support was removed in 8.0
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=96m; support was removed in 8.0

The stack size specified is too small, Specify at least 228k
Error: Could not create the Java Virtual Machine.
Error: A fatal exception has occurred. Program will exit.
```

以上启动报错，由于stack size太小，导致JVM启动失败。
其实Amoeba已经考虑到这个问题，并将JVM参数配置写在属性文件里。现在，让我们通过该属性文件修改JVM参数。
修改/usr/local/amoeba/jvm.properties文件JVM_OPTIONS参数。

```shell
[root@ amoeba amoeba]# vim /usr/local/amoeba/jvm.properties
原来： JVM_OPTIONS="-server -Xms256m -Xmx1024m -Xss196k -XX:PermSize=16m -XX:MaxPermSize=96m"
改为： JVM_OPTIONS="-server -Xms256m -Xmx1024m -Xss256k -XX:PermSize=16m -XX:MaxPermSize=96m"
```

再次启动

```
[root@ amoeba amoeba]# /usr/local/amoeba/bin/launcher
2019-08-26 14:30:22,677 INFO  context.MysqlRuntimeContext - Amoeba for Mysql current versoin=5.1.45-mysql-amoeba-proxy-3.0.4-BETA
log4j:WARN ip access config load completed from file:/usr/local/amoeba/conf/access_list.conf
2019-08-26 14:30:23,005 INFO  net.ServerableConnectionManager - Server listening on 0.0.0.0/0.0.0.0:8066.
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=16m; support was removed in 8.0
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=96m; support was removed in 8.0
 2019-08-26 14:33:57 [INFO] Project Name=Amoeba-MySQL, PID=24645 , starting...
log4j:WARN log4j config load completed from file:/usr/local/amoeba/conf/log4j.xml
2019-08-26 14:33:57,761 INFO  context.MysqlRuntimeContext - Amoeba for Mysql current versoin=5.1.45-mysql-amoeba-proxy-3.0.4-BETA
log4j:WARN ip access config load completed from file:/usr/local/amoeba/conf/access_list.conf
2019-08-26 14:33:58,103 INFO  net.ServerableConnectionManager - Server listening on 0.0.0.0/0.0.0.0:8066.
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option PermSize=16m; support was removed in 8.0
Java HotSpot(TM) 64-Bit Server VM warning: ignoring option MaxPermSize=96m; support was removed in 8.0
 2019-08-26 14:34:34 [INFO] Project Name=Amoeba-MySQL, PID=24675 , starting...
log4j:WARN log4j config load completed from file:/usr/local/amoeba/conf/log4j.xml
2019-08-26 14:34:34,959 INFO  context.MysqlRuntimeContext - Amoeba for Mysql current versoin=5.1.45-mysql-amoeba-proxy-3.0.4-BETA
log4j:WARN ip access config load completed from file:/usr/local/amoeba/conf/access_list.conf
2019-08-26 14:34:35,250 INFO  net.ServerableConnectionManager - Server listening on 0.0.0.0/0.0.0.0:8066.
```

以上输出无Error报错，即是启动成功。

**7.查看端口**

```shell
[root@ amoeba amoeba]# ss -lntp|grep 8066
LISTEN     0      128                      :::8066                    :::*      users:(("java",24675,56))
```



### 5.2.2 mysql读写分离测试

**1.远程登陆mysql客户端通过指定amoeba配置文件中指定的用户名、密码、和端口以及amoeba服务器ip地址链接mysql数据库**

```shell
[root@ amoeba conf]# yum -y install mysql
[root@ amoeba conf]# mysql -h10.0.0.23 -uroot -p123456 -P8066

mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| test               |
| testdb             |
| wg                 |
+--------------------+
```

**2.在testdb库中创建表test_table并插入数据**

```shell
mysql> use testdb;

mysql> create table test_table(id int,password varchar(40) not null);


mysql> show tables;
+------------------+
| Tables_in_testdb |
+------------------+
| test_table       |
+------------------+
1 row in set (0.00 sec)

mysql> insert into test_table(id,password) values('1','test1');
Query OK, 1 row affected (0.01 sec)

mysql> select * from test_table;
+------+----------+
| id   | password |
+------+----------+
|    1 | test1    |
+------+----------+
1 row in set (0.00 sec)

```

**3.分别登陆masterdb和slavedb查看数据**

```shell
查看masterdb
[root@ mysql-master ~]# mysql  -uroot -p123456

mysql>  select * from testdb.test_table;
+------+----------+
| id   | password |
+------+----------+
|    1 | test1    |
+------+----------+

查看slavedb
[root@ mysql-slave ~]# mysql -uroot -p123456

mysql>  select * from testdb.test_table;
+------+----------+
| id   | password |
+------+----------+
|    1 | test1    |
+------+----------+
```

**4.停掉masterdb，然后在客户端分别执行插入和查询功能**

```shell
[root@ mysql-master ~]# /etc/init.d/mysqld stop
Stopping mysqld:                                           [  OK  ]

[root@ amoeba conf]# mysql -h10.0.0.23 -uroot -p123456 -P8066

mysql> insert into test_table(id,password) values('2','test2');
ERROR 1044 (42000): Amoeba could not connect to MySQL server[10.0.0.21:3306],Connection refused

mysql> select * from testdb.test_table;
+------+----------+
| id   | password |
+------+----------+
|    1 | test1    |
+------+----------+
1 row in set (0.01 sec)
```

**可以看到，关掉masterdb和写入报错，读正常。**

**5.开启masterdb上的msyql 关闭slave上的mysql**

masterdb：

```shell
[root@ mysql-master ~]# /etc/init.d/mysqld start
Starting mysqld:                                           [  OK  ]
```

slavedb：

```shell
[root@ mysql-slave ~]# /etc/init.d/mysqld stop
Stopping mysqld:                                           [  OK  ]
```

**客户端再次尝试插入和查询功能**

```
mysql> insert into test_table(id,password) values('2','test2');

mysql> select * from testdb.test_table;
ERROR 1044 (42000): poolName=myslave, no valid pools
```

**可以看到插入成功，读取失败。**



**6.开启slavedb上的mysql，查看数据是否自动同步**

slavedb:

```shell
[root@ mysql-slave ~]# /etc/init.d/mysqld start
Starting mysqld:                                           [  OK  ]
```

客户端：

```shell
[root@ amoeba conf]# mysql -h10.0.0.23 -uroot -p123456 -P8066

mysql> select * from test_table;
+------+----------+
| id   | password |
+------+----------+
|    1 | test1    |
|    2 | test2    |
+------+----------+
```

接着客户端插入数据：

```shell
mysql>  insert into test_table(id,password) values('3','test3');

mysql> select * from test_table;
+------+----------+
| id   | password |
+------+----------+
|    1 | test1    |
|    2 | test2    |
|    3 | test3    |
+------+----------+
```

OK 一切正常，到此表明amoeba实现了mysql的读写分离。



### 5.2.3 mysql数据切分

**1.什么是切片**

简单来说，就是指通过某种特定的条件，将我们存放在同一个数据库中的数据分散存放到多个数据库（主机）上面，以达到分散单台设备负载的效果，而我们的应用在操作时可以忽略数据在哪个服务器上。

**2.为什么要切片**

当系统数据量发展到一定程度后，往往需要进行数据库的垂直切分和水平切分，以实现负载均衡和性能提升，而数据切分后随之会带来多数据源整合等等问题。如果仅仅从应用程序的角度去解决这类问题，无疑会加重应用程度的复杂度，因此需要一个成熟的第三方解决方案。

Amoeba正是解决此类问题的一个开源方案，Amoeba位于应用程序和数据库服务器之间，相当于提供了一个代理，使得应用程序只要连接一个Amoeba，相当于只是在操作一个单独的数据库服务器，而实际上却是在操作多个数据库服务器，这中间的工作全部交由Amoeba去完成。

