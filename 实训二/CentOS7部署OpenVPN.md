[TOC]









# CentOS7部署OpenVPN

# 1.1 VPN介绍

​	VPN直译就是虚拟专用通道，是提供给企业之间或者个人与公司之间安全数据传输的隧道，可以对网络加密，使得其安全性能提升，OpenVPN无疑是Linux下开源VPN的先锋，提供了良好的性能和友好的用户GUI。

常用的VPN协议有PPTP、L2TP、OpenVPN

PPTP、L2TP、OpenVPN三种隧道协议的优缺点对比

易用性： PPTP > L2TP > OpenVPN

速度： PPTP > OpenVPN UDP > L2TP > OpenVPN TCP

安全性： OpenVPN > L2TP > PPTP

稳定性： OpenVPN > L2TP > PPTP

网络适用性：OpenVPN > PPTP > L2TP



## 1.1.1 Openvpn工作原理

openvpn通过使用公开密钥（非对称密钥，加密解密使用不同的key，一个称为Publice key，另外一个是Private key）对数据进行加密的。这种方式称为TLS加密。

openvpn使用TLS加密的工作过程是，首先VPN Sevrver端和VPN Client端要有相同的CA证书，双方通过交换证书验证双方的合法性，用于决定是否建立VPN连接。

然后使用对方的CA证书，把自己目前使用的数据加密方法加密后发送给对方，由于使用的是对方CA证书加密，所以只有对方CA证书对应的Private key才能解密该数据，这样就保证了此密钥的安全性，并且此密钥是定期改变的，对于窃听者来说，可能还没有破解出此密钥，VPN通信双方可能就已经更换密钥了。



## 1.1.2 应用场景

- Peer-to-Peer VPN(点对点连接)，这种场景，将Internet 两台机器（公网地址）使用VPN连接起来
- Remote AccessVPN(远程访问)，该实现方案，旨在解决，移动办公，经常出差不在办公室的，公司生产环境连接。在这个场景种远程访问者一般没有公网IP，他们使用内网地址通过防火墙设备及逆行NAT转换后连接互联网
- SIte-to-Site VPN(站点对站点连接) ，用于连接两个或者多个地域上不同的局域网LAN，每个LAN有一台OpenVPN
  服务器作为接入点，组成虚拟专用网络，使得不同LAN里面的主机和服务器都能够相互通讯



# 1.2 安装部署



## 1.2.1 环境介绍



环境：
本次实验环境采用TUN模式Remote Access VPN，openvpn服务器共两张网卡























