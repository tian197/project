

# NFS共享存储

## NFS共享存储

**网络文件系统**，英文Network File System(NFS)，是由SUN公司研制的UNIX表示层协议(pressentation layer protocol)，能使使用者访问网络上别处的文件就像在使用自己的计算机一样。

NFS在文件传送或信息传送过程中**依赖于RPC协议**。RPC，远程过程调用 (Remote Procedure Call) 是能使客户端执行其他系统中程序的一种机制。NFS本身是没有提供信息传输的协议和功能的。

NFS应用场景，常用于**文件共享**，**多台服务器共享同样的数据**，可扩展性比较差，本身高可用方案不完善，取而代之的数据量比较大的可以采用MFS、TFS、HDFS等等分布式文件系统。

## 应用场景

在企业集群架构的工作场景中，NFS作为所有前端web服务的共享存储，存储的内容一般包括网站用户上传的图片、附件、头像等。

注意，网站的程序代码就不要放在NFS共享里了，因为网站程序是开发运维人员统一发布，不存在发布延迟问题，直接批量发布到web节点提供访问比共享到NFS里访问效率会更高些。NFS是当前互联网系统架构中常用的数据存储服务之一，中小型网站公示应用频率居高，大公司或门户除了使用NFS外，还可能会使用更为复杂的分布式文件系统。



## centos7 安装配置nfs服务

### nfs的服务端操作

```shell
yum -y install nfs-utils rpcbind
```

**手动创建配置文件**

```shell
vim /etc/exports
/data 10.0.0.0/24(rw,sync,no_root_squash,no_all_squash)

/data: 共享目录位置。
10.0.0.0/24: 客户端 IP 范围，* 代表所有，即没有限制。
rw: 权限设置，可读可写。
sync: 同步共享目录。
no_root_squash: 可以使用 root 授权。
no_all_squash: 可以使用普通用户授权
```

**创建共享目录**

```
mkdir -p /data
```

**添加开始自启并重启nfs-server**

```shell
systemctl enable rpcbind
systemctl enable nfs-server
systemctl restart rpcbind
systemctl restart nfs-server
```



### nfs客户端操作

```shell
yum -y install nfs-utils rpcbind

systemctl enable rpcbind
systemctl restart rpcbind

#客户端不安装nfs-utils则不能挂载nfs共享目录；但可以不开启
```

**创建挂载目录并挂载**

```shell
mkdir -p /data
mount 10.0.0.42:/data /data

#查看挂载情况
[root@ c701 ~]# df -h
Filesystem           Size  Used Avail Use% Mounted on
/dev/mapper/cl-root   17G  2.7G   15G  16% /
devtmpfs             478M     0  478M   0% /dev
tmpfs                489M     0  489M   0% /dev/shm
tmpfs                489M  6.7M  482M   2% /run
tmpfs                489M     0  489M   0% /sys/fs/cgroup
/dev/sda1           1014M  121M  894M  12% /boot
tmpfs                 98M     0   98M   0% /run/user/0
10.0.0.42:/data       17G  1.9G   16G  11% /data
```

**添加到开机自动挂载**

```shell
echo '/bin/mount 10.0.0.42:/data /data'>>/etc/rc.local
```



### 测试共享目录

```shell
#分别两台机器的data目录下创建不同的目录然后查看共享情况

[root@ c702 data]# mkdir www
[root@ c701 data]# mkdir aaa


[root@ c701 data]# ll
total 0
drwxr-xr-x 2 root root 6 2019-11-04 17:31 aaa
drwxr-xr-x 2 root root 6 2019-11-04 17:30 www

[root@ c702 data]# ll
total 0
drwxr-xr-x 2 root root 6 2019-11-04 17:31 aaa
drwxr-xr-x 2 root root 6 2019-11-04 17:30 www
```

