[TOC]







# 第二十单元-iptables防火墙



## 20.1 防火墙概念

​	所谓防火墙指的是一个由软件和硬件设备组合而成、在内部网和外部网之间、专用网与公共网之间的界面上构造的保护屏障.是一种获取安全性方法的形象说法，它是一种计算机硬件和软件的结合，使Internet与Intranet之间建立起一个安全网关（Security Gateway），从而保护内部网免受非法用户的侵入，**防火墙主要由服务访问规则、验证工具、包过滤和应用网关4个部分组成**，**防火墙就是一个位于计算机和它所连接的网络之间的软件或硬件。****该计算机流入流出的所有网络通信和数据包均要经过此防火墙。**

​	在网络中，所谓“防火墙”，是指一种将内部网和公众访问网（如Internet）分开的方法，它实际上是一种隔离技术。防火墙是在两个网络通讯时执行的一种访问控制尺度，它能允许你“同意”的人和数据进入你的网络，同时将你“不同意”的人和数据拒之门外，最大限度地阻止网络中的黑客来访问你的网络。换句话说，如果不通过防火墙，公司内部的人就无法访问Internet，Internet上的人也无法和公司内部的人进行通信。



### 20.1.1 软件防火墙

​	软件防火墙单独使用软件系统来完成防火墙功能，将软件部署在系统主机上，其安全性较硬件防火墙差，同时占用系统资源，在一定程度上影响系统性能。其一般用于单机系统或是极少数的个人计算机，很少用于计算机网络中。

![1571886382978](assets/1571886382978.png)



### 20.1.2 硬件防火墙

把软件防火墙嵌入在硬件中，一般的软件安全厂商所提供的硬件防火墙便是在硬件服务器厂商定制硬件，然后再把linux系统与自己的软件系统嵌入，也就是说硬件防火墙是指把防火墙程序做到芯片里面，由硬件执行这些功能，能减少CPU的负担，使路由更稳定。

![1571887004118](assets/1571887004118.png)







## 20.1 iptables防火墙简介

​	iptables是unix/linux自带的一款优秀的开放源代码的完全自由的**基于包过滤**的防火墙工具，它的功能十分强大，使用灵活，可以对流入和流出服务器的数据包进行控制。

​	iptables是linux2.4及2.6内核集成的服务。iptables主要工作在OSI七层的二（数据层），三（网络层），四层（传输层），如果重新编译内核，iptables也可以支持七层（应用层）的控制。



## 20.2 iptables企业应用场景

1.主机防火墙（filter边的INPUT链）。

2.网关（共享上网）（nat表的POSTROUTING链）。

3.端口及IP（一对一）映射（nat表的POSTROUTING链）。



## 20.3 iptables中表（tables）和链（chains）

​	iptables采用“表”和“链”的分层结构。在REHL4中是三张表五个链。现在REHL5成了四张表五个链了，不过多出来的那个表用的也不太多，所以基本还是和以前一样。下面罗列一下这四张表和五个链。注意一定要明白这些表和链的关系及作用。

![1571887541838](assets/1571887541838.png)



**规则表：**

1.filter表——三个链：INPUT、FORWARD、OUTPUT

作用：过滤数据包  内核模块：iptables_filter.

2.Nat表——三个链：PREROUTING、POSTROUTING、OUTPUT

作用：用于网络地址转换（IP、端口） 内核模块：iptable_nat

3.Mangle表——五个链：PREROUTING、POSTROUTING、INPUT、OUTPUT、FORWARD

作用：修改数据包的服务类型、TTL、并且可以配置路由实现QOS内核模块：iptable_mangle(别看这个表这么麻烦，咱们设置策略时几乎都不会用到它)

4.Raw表——两个链：OUTPUT、PREROUTING

作用：决定数据包是否被状态跟踪机制处理  内核模块：iptable_raw

(这个是REHL4没有的，不过不用怕，用的不多)

 

**规则链：**

1.INPUT——进来的数据包应用此规则链中的策略

2.OUTPUT——外出的数据包应用此规则链中的策略

3.FORWARD——转发数据包时应用此规则链中的策略

4.PREROUTING——对数据包作路由选择前应用此链中的规则

（记住！所有的数据包进来的时侯都先由这个链处理）

5.POSTROUTING——对数据包作路由选择后应用此链中的规则

（所有的数据包出来的时侯都先由这个链处理）

 

**规则表之间的优先顺序：**

```
Raw——mangle——nat——filter
```



## 20.4 iptables基本语法详解

### 20.4.1 格式

```
iptables [-t table] COMMAND chain CRETIRIA -j ACTION

iptables   [-t 表名]   命令选项  ［链名］［条件匹配］ ［-j 目标动作或跳转］
```

### 20.4.2 说明

表名、链名      用于指定 iptables命令所操作的表和链，

命令选项        用于指定管理iptables规则的方式（比如：插入、增加、删除、查看等）；

条件匹配        用于指定对符合什么样 条件的数据包进行处理；

目标动作或跳转  用于指定数据包的处理方式（比如允许通过、拒绝、丢弃、跳转（Jump）给其它链处理。



### 20.4.3 iptables命令的选项

```
-A 在指定链的末尾添加（append）一条新的规则
-D  删除（delete）指定链中的某一条规则，可以按规则序号和内容删除
-I  在指定链中插入（insert）一条新的规则，默认在第一行添加
-R  修改、替换（replace）指定链中的某一条规则，可以按规则序号和内容替换
-L  列出（list）指定链中所有的规则进行查看
-E  重命名用户定义的链，不改变链本身
-F  清空（flush）
-N  新建（new-chain）一条用户自己定义的规则链
-X  删除指定表中用户自定义的规则链（delete-chain）
-P  设置指定链的默认策略（policy）
-Z 将所有表的所有链的字节和数据包计数器清零
-n  使用数字形式（numeric）显示输出结果
-v  查看规则表详细信息（verbose）的信息
-V  查看版本(version)
-h  获取帮助（help）
```



### 20.4.4 防火墙处理数据包的四种方式

1. ACCEPT 允许数据包通过
2. DROP 直接丢弃数据包，不给任何回应信息
3. REJECT 拒绝数据包通过，必要时会给数据发送端一个响应的信息。
4. LOG在/var/log/messages文件中记录日志信息，然后将数据包传递给下一条规则





## 20.5 iptables启停和规则操作

### 20.5.1 iptables启停

```shell
/etc/init.d/iptables start|stop
```



### 20.5.2 iptables规则操作

**1.iptables规则查看**

```shell
[root@ c6m01 scripts]# iptables -nL
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0           state RELATED,ESTABLISHED
ACCEPT     icmp --  0.0.0.0/0            0.0.0.0/0
ACCEPT     all  --  0.0.0.0/0            0.0.0.0/0
ACCEPT     tcp  --  0.0.0.0/0            0.0.0.0/0           state NEW tcp dpt:22
REJECT     all  --  0.0.0.0/0            0.0.0.0/0           reject-with icmp-host-prohibited

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination
REJECT     all  --  0.0.0.0/0            0.0.0.0/0           reject-with icmp-host-prohibited

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
```



**2.iptables规则清空**

在配置iptables之前，你通常需要用iptables –list命令或者iptables-save命令查看有无现存规则，因为有时需要删除现有的iptables规则：

```shell
iptables –flush 
```

或者 

```shell
iptables -F
```

这两条命令是等效的。但是并非执行后就万事大吉了。你仍然需要检查规则是不是真的清空了，因为有的linux发行版上这个命令不会清除NAT表中的规则，此时只能手动清除：

```shell
iptables -t NAT -F
```



**3.iptables规则永久生效**

**方法一：**

```shell
iptables-save > /etc/sysconfig/iptables
或者
/etc/init.d/iptables save
```

它能把规则自动保存在/etc/sysconfig/iptables中。当计算机启动时，rc.d下的脚本将用命令iptables-restore调用这个文件，从而就自动恢复了规则。

**方法二：手动修改iptables配置文件**

```
vim /etc/sysconfig/iptables
```

创建iptables文件，然后调用重启指令使其生效。













