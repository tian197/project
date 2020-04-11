# NTP时间同步服务器

## 1.1 NTP 简介

NTP（ Network Time Protocol，网络时间协议）是用来使网络中的各个计算机时间同步的一种协

议。它的用途是把计算机的时钟同步到世界协调时 UTC，其精度在局域网内可达 0.1ms，在互联

网上绝大多数的地方其精度可以达到 1-50ms。

NTP 服务器就是利用 NTP 协议提供时间同步服务的。



**NTP服务端：   c701    10.0.0.41**    

**NTP客户端：   c702    10.0.0.42**

### 1.1.2 NTP服务器安装

```shell
yum -y install ntp        
```



### 1.1.3 配置NTP服务

```shell
vim /etc/ntp.conf 

# restrict default kod nomodify notrap nopeer noquery
# nomodify客户端可以同步
restrict default nomodify


# 将默认时间同步源注释改用可用源
# server 0.centos.pool.ntp.org iburst
# server 1.centos.pool.ntp.org iburst
# server 2.centos.pool.ntp.org iburst
# server 3.centos.pool.ntp.org iburst
server ntp1.aliyun.com
```



### 1.1.4 重启ntp并设置开机自启

```shell
systemctl restart ntpd
systemctl enable ntpd
```



## 客户端同步时间

```shell
[root@ c702 yum.repos.d]# systemctl stop ntpd
[root@ c702 yum.repos.d]# ntpdate 10.0.0.41
 6 Nov 18:36:39 ntpdate[2151]: adjust time server 10.0.0.41 offset -0.019067 sec
```

注意：此处需要等待服务端几分钟。

添加到定时任务

```shell
cat >>/var/spool/cron/root<<EOF
#crond m01
*/5 * * * * /usr/sbin/ntpdate 10.0.0.41 >/dev/null 2>&1
EOF
```

