[TOC]







# PPTV-VPN实战搭建及NTP服务配置

# 1.1 VPN介绍

## 1.1.1 VPN概述

​	VPN（全称Virtual Private Network）虚拟专用网络（1）依靠ISP和其他的NSP，在公共网络中建立专用的数据通信网络的技术，可以为企业之间或个人与企业之间提供安全的数据传输隧道服务（2）在VPN中任意两点之间的连接并没有传统专网所需的端到端的物理链路，而是利用公共网络资源动态组成的，可以理解为通过私有的隧道技术在公共数据网络上模拟出来和专用有同样功能的点到点的专线技术（3）所谓虚拟是指不需要去拉实际的长途物理线路，而是借用了公共的Internet网络实现。（4）类似VPN隧道：SSH，LVS，TUN（IPIP），PPTP，IPsec，OpenVPN



## 1.1.2 企业应用分类

（1）远程访问VPN服务

​	员工个人电脑通过远程拨号到企业办公网络，如公司的OA系统

​	运维人员远程拨号到IDC机房，远程维护服务器

（2）企业内部网络之间VPN服务

​	公司分支机构的局域网和总公司的LAN之间的VPN连接，如各大超市之间的业务结算等

（3）互联网公司多IDC机房之间VPN服务

​	不同机房之间业务管理和业务访问，数据流动

（4）企业外部VPN服务

​	在供应商，合作伙伴的LAN和本公司的LAN之间建立VPN服务

（5）访问国外的网站

​	翻墙业务应用



## 1.1.3 常见隧道协议介绍

（1）PPTP：点对点隧道协议，默认端口号1723，工作在第二层，PPTP使用TCP协议，适合在没有防火墙限制的网络中使用，比较适合远程的企业用户拨号到楪祈内部进行办公等应用

（2）L2TP

（3）IPSEC

（4）SSL VPN----Open VPN



## 1.1.4 实现VPN的常见开源产品

（1）PPTP VPN最大优势Windows原生支持，不需要安装客户端；缺点是很多小区及网络设备不支持pptp导致无法访问，开源软件pptp

（2）SSL VPN 典型Open VPN，不但适合用于pptp的场景，还适合对企业异地两地总分公司之间的VPN不间断按需连接，切断需要安装客户端

（3）IPSEC VPN适合针对企业异地两地总分公司或多个IDC机房之间的VPN不间断按需连接，并且在部署使用上更简单方便，开源产品openswan小结：

易用性：PPTP > L2TP > Open VPN

速度：PPTP > Open VPN UDP > L2TP > Open VPN TCP 

安全性：Open VPN > L2TP > PPTP

稳定性：Open VPN > L2TP > PPTP

网络适用性：Open VPN > PPTP > L2TP 



# 2.1 部署PPTP VPN服务器

## 2.1.1 检查系统是否支持

```
[root@localhost opt]# cat /dev/ppp
cat: /dev/ppp: No such device or address
```

## 2.1.2  设置内核转发