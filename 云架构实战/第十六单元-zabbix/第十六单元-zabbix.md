[TOC]



# 第十六单元-zabbix



## 16.1 创建主机

### 16.1.1 创建主机前提及步骤

**新增一台服务器10.0.0.42（安装zabbix-agent）**

**1.配置zabbix源**

```shell
rpm -ivh https://mirrors.aliyun.com/zabbix/zabbix/3.5/rhel/7/x86_64/zabbix-release-3.5-1.el7.noarch.rpm
yum clean all
```

**2.安装zabbix-agent**

```shell
yum -y install zabbix-agent
```

**3.修改zabbix-agent配置并重启**

```shell
[root@localhost ~]# egrep -v '^$|^#' /etc/zabbix/zabbix_agentd.conf
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=10.0.0.41		#修改此处为zabbix-server的ip
ServerActive=10.0.0.41	#修改此处为zabbix-server的ip
Hostname=apache			#自己定义，一般和主机名相同
Include=/etc/zabbix/zabbix_agentd.d/*.conf

systemctl enable zabbix-agent
systemctl restart zabbix-agent
```



**4.在zabbix-server服务端（10.0.0.41）测试，是否可以获取键值。**

(1) 安装zabbix-get工具

```
yum -y install zabbix-get
```

(2) 通过zabbix_get命令测试键值

```
zabbix_get -s 10.0.0.42 -p 10050 -k "system.cpu.load[all,avg15]"
```

有数值出现，表示zabbix-server监控端可以获取zabbix-agent被监控端的数据，即可通过web界面去添加新增的被监控主机。

![1568726477470](assets/1568726477470.png)



**5.在zabbix的web界面添加主机**

configuration（配置）–>Hosts（主机）–>Create host（创建主机）

![1568726654290](assets/1568726654290.png)



![1568726851555](assets/1568726851555.png)



![1568726935758](assets/1568726935758.png)



### 16.1.2 为主机链接监控模板



![1568727081383](assets/1568727081383.png)

**链接监控模板Template OS Linux**

![1568727211009](assets/1568727211009.png)

注意：此处一定要点添加后，进行更新，否则模板链接不上。

刷新浏览器，然后等待几十秒，即可看到可用性ZBX变为绿色。

![1568727368156](assets/1568727368156.png)





### 16.1.3 为主机添加监控项

![1568727081383](assets/1568727081383.png)

![1568727975987](assets/1568727975987.png)



![1568728002621](assets/1568728002621.png)



![1568728108776](assets/1568728108776.png)

![1568728216620](assets/1568728216620.png)

![1568728531253](assets/1568728531253.png)

然后通过zabbix-get测试键值是否可以获取到数据，此操作在zabbix-server服务端进行。

```
zabbix_get -s 10.0.0.42 -k net.tcp.listen[80]
0
```

若返回值是1的话，说明Apache端口正在监听，也就是httpd服务是运行。
若返回值是0的话，说明Apache端口没有监听，也就是httpd服务是未运行。





### 16.1.4 为监控项添加触发器

![1568728842896](assets/1568728842896.png)

![1568728916333](assets/1568728916333.png)



![1568768009561](assets/1568768009561.png)



![1568768067783](assets/1568768067783.png)





### 16.1.5 为监控项添加图形

![1568768126317](assets/1568768126317.png)



![1568768160308](assets/1568768160308.png)



![1568768241351](assets/1568768241351.png)



### 16.1.6 查看监控图形

![1568768489181](assets/1568768489181.png)



![1568778591111](assets/1568778591111.png)





### 16.1.7 解决zabbix图形中文显示乱码

**1.中文乱码**

![1568776059231](assets/1568776059231.png)



![1568705421305](assets/1568705421305.png)

![1568705399600](assets/1568705399600.png)



**2.将windows目录C:\Windows\Fonts\楷体 常规 拷贝到/usr/share/zabbix/fonts/下**

![1568787924713](assets/1568787924713.png)

![1568787980653](assets/1568787980653.png)

windows10系统，需要将上传的楷体常规字体SIMKAI.TTF，改名为小写simkai.ttf

```
mv SIMKAI.TTF simkai.ttf
```

**3.修改配置文件defines.inc.php**

```shell
vim /usr/share/zabbix/include/defines.inc.php

define('ZBX_GRAPH_FONT_NAME',           'simkai');   #修改此处为msyh
define('ZBX_FONT_NAME', 'simkai');		#修改此处为msyh
```

**4.刷新网页**

![1568776257610](assets/1568776257610.png)



### 16.1.8 打开zabbix前端报警

![1568768602800](assets/1568768602800.png)







## 16.2 监控apache端口

通过监控apache默认端口80，来判断服务是否正常。

创建监控项：

![1569231369321](assets/1569231369321.png)

创建触发器：

![1569231429984](assets/1569231429984.png)



创建监控项的图形：

![1569231489963](assets/1569231489963.png)



## 16.3 监控网卡流量







## 16.4 配置邮件、微信报警

**注意：发送邮件微信报警的前提是能连外网。**



### 16.4.1 配置邮件报警（服务端配置）

**1．解压sendmail程序的压缩包，并复制到/usr/local/bin**

```
tar -zxvf sendEmail-v1.56.tar.gz
cp sendEmail-v1.56/sendEmail /usr/local/bin/
```

**2.上传sendEmail.sh到服务器并增加可执行权限**

```
cp sendEmail.sh /usr/lib/zabbix/alertscripts
chmod -R 777 /usr/lib/zabbix/alertscripts/sendEmail.sh
```

**3.编辑脚本，将绑定的邮箱地址和密码写上**

```
vim  /usr/lib/zabbix/alertscripts/sendEmail.sh
```

![1568783802973](assets/1568783802973.png)

设置163邮箱授权码

![1568790785895](assets/1568790785895.png)





**4.测试脚本**

```
sh /usr/lib/zabbix/alertscripts/sendEmail.sh  接收邮件的邮箱  标题 内容
```

去邮箱查看是否收到了邮件

![1568784377378](assets/1568784377378.png)

**5. zabbix创建报警媒介**

![1568784461473](assets/1568784461473.png)



![1568784625277](assets/1568784625277.png)

```
名称：sendmail

类型：脚本

脚本名称：sendEmail.sh

脚本参数：       //新增以下三个参数

{ALERT.SENDTO}

{ALERT.SUBJECT}

{ALERT.MESSAGE}
```



**关联报警用户和媒介**

![1568784714389](assets/1568784714389.png)

![1568784776598](assets/1568784776598.png)

![1568784827009](assets/1568784827009.png)

![1568784881135](assets/1568784881135.png)



![1568784943869](assets/1568784943869.png)



![1568785329283](assets/1568785329283.png)



```
告警主机 : {HOST.NAME}
告警  IP   : {HOST.IP}
告警时间 : {EVENT.DATE}-{EVENT.TIME}
告警等级 : {TRIGGER.SEVERITY}
告警信息 : {TRIGGER.NAME}:{ITEM.VALUE}
事件  ID   : {EVENT.ID}
```



![1568786049271](assets/1568786049271.png)

启用激活 

![1568794171956](assets/1568794171956.png)



测试，监控一个apache服务把服务停掉，看看是否能够收到邮件

在报表菜单的动作日志下面可以查看邮件发送的状态

![1568786393233](assets/1568786393233.png)





## 16.5 zabbix+grafana

grafana和zabbix-server安装在一台机器（10.0.0.41）

### 16.5.1 安装grafana

```
wget <https://dl.grafana.com/oss/release/grafana-6.3.5-1.x86_64.rpm> 
sudo yum -y localinstall grafana-6.3.5-1.x86_64.rpm 

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
```

### 16.5.2 安装grafana-zabbix插件

```bash
grafana-cli plugins install alexanderzobnin-zabbix-app
systemctl restart grafana-server
```

### 16.5.3 Web端访问3000端口

**1.http://10.0.0.41:3000**

![1568799928067](assets/1568799928067.png)



```
用户名：admin
密  码：admin 
```

**2.初次登陆需要修改登陆密码：**

![1568800013008](assets/1568800013008.png)



**3.启用zabbix插件**

![1568800183400](assets/1568800183400.png)



**4.点击配置，选择data sources 的zabbix APP进行配置http://10.0.0.41/zabbix/api_jsonrpc.php**

![1568800416328](assets/1568800416328.png)





**5.去官网找合适的模板去导入**

https://grafana.com/grafana/dashboards

















