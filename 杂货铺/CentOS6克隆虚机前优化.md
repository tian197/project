# Centos6克隆虚机的前提



> 进行以下操作时需要系统可以连外网

## 系统安装好后进行两删除一清空

```shell
sed -ri '/HWADDR|UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth*
>/etc/udev/rules.d/70-persistent-net.rules
echo ">/etc/udev/rules.d/70-persistent-net.rules" >>/etc/rc.local
```



## 修改yum源

```shell
yum -y install wget
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-6.repo
yum clean all >/dev/null
yum makecache >/dev/null
```

## 关闭iptables防火墙

```shell
/etc/init.d/iptables stop
chkconfig iptables off
chkconfig |grep iptables
```

## 关闭SELINUX

```shell
setenforce 0
sed -i 's/SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config
```

## 设置时间同步

```shell
echo "*/5 * * * * /usr/sbin/ntpdate time.nist.gov >/dev/null 2>&1" >> /var/spool/cron/root
```

## 安装常用的工具

```shell
yum install gcc gcc-c++  wget cmake curl unzip zip telnet vim tree nmap sysstat lrzsz dos2unix -y
```

####以上优化做完后，就可以将新建的虚机关闭，然后进行克隆