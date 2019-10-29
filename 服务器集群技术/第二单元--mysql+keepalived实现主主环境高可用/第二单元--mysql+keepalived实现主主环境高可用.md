[TOC]









# 第二单元--mysql+keepalived实现主主环境高可用

**在第一单元的基础上，增加了keepalived软件实现两台mysql服务器高可用。**



# 2.1 keepalived介绍

keepalived是集群管理中保证集群高可用的一个服务软件，其功能类似于heartbeat，用来防止单点故障。



## 2.1.1 Keepalived 定义

​       Keepalived 是一个基于VRRP协议来实现的LVS服务高可用方案，可以利用其来避免单点故障。一个LVS服务会有2台服务器运行Keepalived，一台为主服务器（MASTER），一台为备份服务器（BACKUP），但是对外表现为一个虚拟IP，主服务器会发送特定的消息给备份服务器，当备份服务器收不到这个消息的时候，即主服务器宕机的时候， 备份服务器就会接管虚拟IP，继续提供服务，从而保证了高可用性。Keepalived是VRRP的完美实现，因此在介绍keepalived之前，先介绍一下VRRP的原理。



## 2.1.2 keepalived工作原理

​	keepalived是基于VRRP协议实现的保证集群高可用的一个服务软件，主要功能是实现真机的故障隔离和负载均衡器间的失败切换，防止单点故障。在了解keepalived原理之前先了解一下VRRP协议。

**VRRP的工作工程：**

```
(1) 虚拟路由器中的路由器根据优先级选举出 Master。 Master 路由器通过发送免费 ARP 报文，将自己的虚拟 MAC 地址通知给与它连接的设备或者主机，从而承担报文转发任务；
(2) Master 路由器周期性发送 VRRP 报文，以公布其配置信息（优先级等）和工作状况；
(3) 如果 Master 路由器出现故障，虚拟路由器中的 Backup 路由器将根据优先级重新选举新的 Master；
(4) 虚拟路由器状态切换时， Master 路由器由一台设备切换为另外一台设备，新的 Master 路由器只是简单地发送一个携带虚拟路由器的 MAC 地址和虚拟 IP地址信息的ARP 报文，这样就可以更新与它连接的主机或设备中的ARP 相关信息。网络中的主机感知不到 Master 路由器已经切换为另外一台设备。
(5) Backup 路由器的优先级高于 Master 路由器时，由 Backup 路由器的工作方式（抢占方式和非抢占方式）决定是否重新选举 Master。
VRRP优先级的取值范围为0到255（数值越大表明优先级越高）
```

**Keepalived的工作原理，建议答出如下内容:**

keepalived高可用之间是通过VRRP协议通信:

(1) VRRP协议是虚拟路由冗余协议,VRRP的出现是为了解决静态路由单点故障.

(2) VRRP是通过一种竞选协议机制来将路由任务交给某台VRRP路由的.

(3) VRRP是通过IP多播的方式(默认多播地址224.0.0.18) ,实现高可用对之间通信

(4) 工作主节点发包，备节点接包，当备节点接收不到主节点发的数据包时，就启动接管程序主节点资源.备节点备节点可以多个,通过优先级竞选,但一般keepalived系统运维工作中都是一对.

(5) VRRP使用了加密协议加密数据,但keepalived官方目前还是推荐用明文的方式配置认证类型和密码.



## 2.1.3 keepalived运行时启动的进程

keepalived运行时，会启动3个进程，分别为：core(核心进程)，check和vrrp 

​    \- core：负责主进程的启动，维护和全局配置文件的加载；

​    \- check：负责健康检查

​    \- vrrp：用来实现vrrp协议

**总结：在vrrp协议的基础上实现了服务器主机的负载均衡，VRRP负责调度器之间的高可用。**



# 2.2 keepalived安装部署

分别在两台mysql安装：

```shell
yum -y install keepalived
chkconfig keepalived on
/etc/init.d/keepalived start

# 检查服务是否开启	  ps -ef |grep keep 
# 查看软件是否存在	   rpm -qa keepalived  
# 查看软件列表		rpm -ql keepalived  
```



## 2.2.1 keepalived默认配置文件说明

​	在yum安装好keepalived之后，keepalived会产生一个配置文件/etc/keepalived/keepalived.conf ，配置文件包含了三个段：全局定义段、VRRP实例定义段、虚拟服务器定义段。

```shell
global_defs {
   notification_email {   #指定keepalived在发生切换时需要发送email到的对象。
     acassen@firewall.loc
   }
   notification_email_from  huangxin202823@163.com #指定发件人
   smtp_server smtp.163.com #指定smtp服务器地址
   smtp_connect_timeout 3  #指定smtp连接超时时间
   router_id LVS_DEVEL  #运行keepalived的一个标识
}
vrrp_sync_group VG_1{ #监控多个网段的实例              
    group{              
        inside_network #实例名              
        outside_network              }
        notify_master /path/xx.sh  #指定当切换到master时，执行的脚本       
        netify_backup /path/xx.sh  #指定当切换到backup时，执行的脚本       
        notify_fault "path/xx.shVG_1"  #故障时执行的脚本       
        notify /path/xx.sh   #脚本所在目录       
        smtp_alert  #使用global_defs中提供的邮件地址和smtp服务器发送邮件通知}
#VRRP实例定义段
vrrp_instance VI_1 {
    state MASTER  #指定哪个为master，哪个为backup
    interface eth0  #设置实例绑定的网卡
    virtual_router_id 51  #VRID标记
    priority 100   #优先级，高优先级的DR会抢占为master （默认为抢占模式）
     advert_int 1 #检查间隔，1秒
    authentication { #设置认证
       auth_type PASS #认证方式
       auth_pass 1111  #认证字符串（使用 openssl rand -hex 6生成随机字符串）
    }

    virtual_ipaddress {  #设置VIP
<IPADDR>/<MASK> brd <IPADDR> dev <STRING>scope <SCOPE> label <LABEL>
        192.168.200.17/24 deveth1
        192.168.200.100/24 deveth2 label eth2:1
    }
    sorry_server 127.0.0.1 80 #web服务器全部失败，可以指定Sorry web
}
  
virtual_server 192.168.200.100 443 {
    delay_loop 6  #健康检查时间间隔，单位秒
    lb_algo rr   #负载调度算法，支持的算法：rr|wrr|lc|wlc|lblc|sh|dh
    lb_kind DR  #LVS的类型：有NAT|DR|TUN
    nat_mask 255.255.255.0  #子网掩码
    persistence_timeout 50   #会话保持时间，单位秒（可以适当延长时间以保持session）
    protocol TCP  #转发协议类型，有TCP和UDP两种
    real_server 192.168.201.100443 {   #定义RS 服务
    weight 1	#权重
    #inhibit_on_failure #当服务器健康检查失效时，将weight设置为0不是直接从ipvs中删除
    #notify_up <STRING>|<QUOTED-STRING>#Server启动时执行的脚本
    #notify_down <STRING>|<QUOTED-STRING>#Server down时执行的脚本
 
        #后端RS服务器的检查 （HTTP_GET 和SSL_GET）：
        SSL_GET { 
           url {  #检查url,可以指定多个，status_codeand digest
              path /
             digest ff20ad   #或者status_code 200 ....
           }
           connect_timeout 3 #连接超时时间
           nb_get_retry 3  #重连次数
          delay_before_retry 3 #重连间隔时间
      }
        #也可以通过TCP_CHECK判断RealServer的健康状况：
    }
}
```











