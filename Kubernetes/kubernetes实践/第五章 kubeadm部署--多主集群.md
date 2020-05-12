[TOC]







# 第五章 kubeadm部署--高可用集群

# 1.1 高可用架构说明

Kubernetes的高可用主要指的是控制平面的高可用，简单说，就是有多套Master节点组件和Etcd组件，工作节点通过负载均衡连接到各Master。

## 1.1.1 HA的两种部署方式

一种是将etcd与Master节点组件混布在一起： 

![1021348-20200308140147463-765399450](../assets/1021348-20200308140147463-765399450.png)



另外一种方式是，使用独立的Etcd集群，不与Master节点混布署。

![1021348-20200308140156958-1688658338](../assets/1021348-20200308140156958-1688658338.png)

**组件说明：**

- kube-apiserver：集群核心，集群API接口、集群各个组件通信的中枢；集群安全控制；

- etcd：集群的数据中心，用于存放集群的配置以及状态信息，非常重要，如果数据丢失那么集群将无法恢复；因此高可用集群部署首先就是etcd是高可用集群；

- kube-scheduler：集群Pod的调度中心；默认kubeadm安装情况下–leader-elect参数已经设置为true，保证master集群中只有一个kube-scheduler处于活跃状态；

- kube-controller-manager：集群状态管理器，当集群状态与期望不同时，kcm会努力让集群恢复期望状态，比如：当一个pod死掉，kcm会努力新建一个pod来恢复对应replicas set期望的状态；默认kubeadm安装情况下–leader-elect参数已经设置为true，保证master集群中只有一个kube-controller-manager处于活跃状态；

- kubelet：kubernetes node上的 agent，负责与node上的docker engine打交道；

- kube-proxy：每个node上一个，负责service vip到endpoint pod的流量转发，原理是通过设置iptables规则实现。

## 1.1.2 组件高可用实现

**kube-apiserver 高可用实现：**

- 使用Nginx 4层透明代理功能实现k8s节点(master节点和worker节点)高可用访问kube-apiserver；
- kube-apiserver 本身是无状态的，所以只要一个实例正常，就可以保证集群高可用；
- 集群内的Pod使用k8s服务域名kubernetes访问kube-apiserver，kube-dns会自动解析多个kube-apiserver节点的IP，所以也是高可用的。在每个Nginx进程，后端对接多个apiserver实例，Nginx对他们做健康检查和负载均衡；
- kubelet、kube-proxy、controller-manager、schedule通过本地nginx ( 监听我们的 vip )访问kube-apiserver，从而实现kube-apiserver高可用；



**kube-controller-manage 高可用实现：**

- kube-controller-manager（k8s控制器管理器）是一个守护进程，它通过kube-apiserver监视集群的共享状态（kube-apiserver收集或监视到的一些集群资源状态，供kube-controller-manager或其它客户端watch）, 控制器管理器并尝试将当前的状态向所定义的状态迁移（移动、靠近），它本身是有状态的，会修改集群状态信息，如果多个控制器管理器同时生效，则会有一致性问题，所以kube-controller-manager的高可用，只能是主备模式，而kubernetes集群是采用租赁锁实现leader选举，需要在启动参数中加入--leader-elect=true。 

- 该集群包含 3 个节点，启动后将通过竞争选举机制产生一个 leader 节点，其它节点为阻塞状态。当 leader 节点不可用时，阻塞的节点将再次进行选举产生新的 leader 节点，从而保证服务的可用性。



**kube-scheduler 高可用实现：**

- kube-scheduler作为kubemaster核心组件运行在master节点上面，主要是watch kube-apiserver中未被调度的Pod，如果有，通过调度算法找到最适合的节点Node，然后通过kube-apiserver以对象（pod名称、Node节点名称等）的形式写入到etcd中来完成调度，kube-scheduler的高可用与kube-controller-manager一样，需要使用选举的方式产生。 

- 该集群包含 3 个节点，启动后将通过竞争选举机制产生一个 leader 节点，其它节点为阻塞状态。当 leader 节点不可用后，剩余节点将再次进行选举产生新的 leader 节点，从而保证服务的可用性。



**etcd 高可用实现：**

etcd是一个高可用的分布式键值(key-value)数据库。由 CoreOS 开发，常用于服务注册和发现、共享配置以及并发控制（如 leader 选举、分布式锁等）。etcd内部采用raft协议作为一致性算法，etcd基于Go语言实现。

etcd与zookeeper相比算是轻量级系统，两者的一致性协议也一样，etcd的raft比zookeeper的paxos简单。

**1、使用场景**

- 配置管理
- 服务注册于发现
- 选主
- 应用调度
- 分布式队列
- 分布式锁

**2、原理**

etcd推荐使用奇数作为集群节点个数。因为奇数个节点和其配对的偶数个节点相比，容错能力相同，却可以少一个节点。综合考虑性能和容错能力，etcd官方文档推荐的etcd集群大小是3,5,7。由于etcd使用是Raft算法，每次写入数据需要有2N+1个节点同意可以写入数据，所以部分节点由于网络或者其他不可靠因素延迟收到数据更新，但是最终数据会保持一致，高度可靠。随着节点数目的增加，每次的写入延迟会相应的线性递增，除了节点数量会影响写入数据的延迟，如果节点跟接节点之间的网络延迟，也会导致数据的延迟写入。

**结论：**

- 节点数并非越多越好，过多的节点将会导致数据延迟写入。
- 节点跟节点之间的跨机房，专线之间网络延迟，也将会导致数据延迟写入。
- 受网络IO和磁盘IO的延迟
- 为了提高吞吐量，etcd通常将多个请求一次批量处理并提交Raft，增加节点，读性能会提升，写性能会下降，减少节点，写性能会提升



# 1.2 kubeadm部署介绍

## 1.2.1 环境介绍

本次实验采用VM虚机；由于资源有限；使用master和node混合部署。

| 主机名  | 角色        | 配置  |  外网IP   |   内网IP    |   系统    | 内核版本                    | 备注 |
| :-----: | ----------- | ----- | :-------: | :---------: | :-------: | --------------------------- | ---- |
| k8s-m01 | master+node | 2核4G | 10.0.0.61 | 172.16.1.61 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |      |
| k8s-m02 | master+node | 2核4G | 10.0.0.62 | 172.16.1.62 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |      |
| k8s-m03 | master+node | 2核4G | 10.0.0.63 | 172.16.1.63 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |      |
|         | VIP         |       | 10.0.0.88 |             |           |                             |      |

组件版本：

|      |      |      |
| ---- | ---- | ---- |
|      |      |      |
|      |      |      |
|      |      |      |





## 1.2.2 环境初始化

 [envpre.sh](assets\envpre.sh) 

```bash
#!/bin/sh

#定义K8S主机字典
declare -A MASTERS
MASTERS=([k8s-m01]="10.0.0.61" [k8s-m02]="10.0.0.62" [k8s-m03]="10.0.0.63")
# 打印字典所有的key  ：echo ${!MASTERS[*]}
# 打印字典所有的value：echo ${MASTERS[*]}


echo -e "\033[42;37m >>> 免密登陆 <<< \033[0m"
yum -y install sshpass &>/dev/null
if [ -f ~/.ssh/id_dsa.pub ]
then
    for ip in ${MASTERS[*]}
      do
	    echo -e "\033[33m $ip \033[0m"
        sshpass -p "123456" ssh-copy-id -i ~/.ssh/id_dsa.pub -p 22 -o StrictHostKeyChecking=no root@$ip &>/dev/null
	    ssh root@$ip "echo "$ip-ssh连接测试成功""
    done
else
    ssh-keygen -t dsa -f ~/.ssh/id_dsa -P "" &>/dev/null
	 for ip in ${MASTERS[*]}
      do
	    echo -e "\033[33m $ip \033[0m"
        sshpass -p "123456" ssh-copy-id -i ~/.ssh/id_dsa.pub -p 22 -o StrictHostKeyChecking=no root@$ip &>/dev/null
	    ssh root@$ip "echo "$ip-ssh连接测试成功""
    done
fi

echo -e "\033[42;37m >>> 修改主机名 <<< \033[0m"
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m" 
    ssh root@${MASTERS[$hostname]} "hostnamectl set-hostname $hostname  && hostname"
done

echo -e "\033[42;37m >>> 添加hosts解析 <<< \033[0m"
cat >/etc/hosts<<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
${MASTERS[k8s-m01]} k8s-m01
${MASTERS[k8s-m02]} k8s-m02
${MASTERS[k8s-m03]} k8s-m03
EOF
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m" 
    scp /etc/hosts root@${MASTERS[$hostname]}:/etc/hosts
done

echo -e "\033[42;37m >>> 时间同步 <<< \033[0m"
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m" 
    ssh root@${MASTERS[$hostname]} "echo '*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1'>/var/spool/cron/root && crontab -l"
done


echo -e "\033[42;37m >>> 优化内核 <<< \033[0m"
cat >/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
net.ipv4.tcp_tw_recycle=0
vm.swappiness=0
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m"
	scp  /etc/sysctl.d/kubernetes.conf root@${MASTERS[$hostname]}:/etc/sysctl.d/
    ssh root@${MASTERS[$hostname]} "modprobe ip_vs_rr && modprobe br_netfilter && sysctl -p /etc/sysctl.d/kubernetes.conf"
done

echo -e "\033[42;37m >>> 关闭swap分区 <<< \033[0m"
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m" 
    ssh root@${MASTERS[$hostname]} "swapoff -a && sed -ri 's/.*swap.*/#&/' /etc/fstab"
done

echo -e "\033[42;37m >>> 关闭防火墙和SElinux <<< \033[0m"
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m" 
    ssh root@${MASTERS[$hostname]} "systemctl stop firewalld && systemctl disable firewalld && systemctl status firewalld.service|grep Active;setenforce 0 && sed -i  '/^SELINUX/s#enforcing#disabled#g' /etc/selinux/config"
done

echo -e "\033[42;37m >>> 安装docker <<< \033[0m"
mkdir -p /etc/docker/
cat >/etc/docker/daemon.json<<EOF
{
    "registry-mirrors": ["https://docker.mirrors.ustc.edu.cn","https://hub-mirror.c.163.com","https://dockerhub.azk8s.cn"],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "max-concurrent-downloads": 20,
    "live-restore": true,
    "storage-driver": "overlay2",
    "max-concurrent-uploads": 10,
    "debug": true,
    "log-opts": {
    "max-size": "100m",
    "max-file": "10"
    }
}
EOF
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m"
    ssh root@${MASTERS[$hostname]} "mkdir -p /etc/docker/ && yum install -y yum-utils device-mapper-persistent-data lvm2 &>/dev/null && wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo &>/dev/null && yum makecache &>/dev/null && yum install docker-ce-18.06.3.ce -y &>/dev/null && systemctl daemon-reload && systemctl restart docker && systemctl enable docker && systemctl status docker|grep Active"
	scp /etc/docker/daemon.json root@${MASTERS[$hostname]}:/etc/docker/
done

echo -e "\033[42;37m >>> 升级内核 <<< \033[0m"
for hostname in ${!MASTERS[*]}
do
    echo -e "\033[33m ${MASTERS[$hostname]} \033[0m" 
    ssh root@${MASTERS[$hostname]} "rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org && rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm && yum --enablerepo=elrepo-kernel install kernel-lt -y && grub2-set-default  0 && grub2-mkconfig -o /etc/grub2.cfg && reboot"
done

```





# 1.3 下载 [cfssl](https://github.com/cloudflare/cfssl) 创建CA根证书

为确保安全，kubernetes系统各组件需要使用 x509证书对通信进行加密和认证。

CA (Certificate Authority) 是自签名的根证书，用来签名后续创建的其它证书。

**1、下载cfssl**

```shell
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl_1.4.1_linux_amd64 -o /usr/local/bin/cfssl
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssljson_1.4.1_linux_amd64 -o /usr/local/bin/cfssljson
curl -L https://github.com/cloudflare/cfssl/releases/download/v1.4.1/cfssl-certinfo_1.4.1_linux_amd64 -o /usr/local/bin/cfssl-certinfo
chmod +x /usr/local/bin/*
```

**容器相关证书类型：**

client certificate：用于服务端认证客户端,例如etcdctl、etcd proxy、fleetctl、docker客户端

server certificate: 服务端使用，客户端以此验证服务端身份,例如docker服务端、kube-apiserver

peer certificate: 双向证书，用于etcd集群成员间通信

==**注意：以下证书生成均在k8s-m01上配置核生成，然后进行分发。**==

**2、创建 CA 根证书和秘钥**

CA 配置文件用于配置根证书的使用场景 (profile) 和具体参数 (usage，过期时间、服务端认证、客户端认证、加密等)，后续在签名其它证书时需要指定特定场景。

```shell
# 创建临时工作目录
mkdir -p /data/work
cd /data/work
cat > ca-config.json <<EOF
{
  "signing": {
    "default": {
      "expiry": "87600h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
            "signing",
            "key encipherment",
            "server auth",
            "client auth"
        ],
        "expiry": "87600h"
      }
    }
  }
}
EOF
```

- signing ：表示该证书可用于签名其它证书，生成的 `ca.pem` 证书中 `CA=TRUE`；
- server auth ：表示 client 可以用该该证书对 server 提供的证书进行验证；
- client auth ：表示 server 可以用该该证书对 client 提供的证书进行验证；

**3、创建证书签名请求文件**

```shell
cd /data/work
cat > ca-csr.json <<EOF
{
  "CN": "kubernetes",
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "4Paradigm"
    }
  ],
  "ca": {
    "expiry": "87600h"
 }
}
EOF
```

- CN：Common Name，kube-apiserver 从证书中提取该字段作为请求的用户名 (User Name)，浏览器使用该字段验证网站是否合法；
- O：Organization，kube-apiserver 从证书中提取该字段作为请求用户所属的组 (Group)；
- kube-apiserver 将提取的 User、Group 作为 RBAC 授权的用户标识；

**生成 CA 证书和私钥：**

```shell
cd /data/work
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
ls ca*.pem
```





# 1.4 部署 etcd 存储集群

etcd是一个高可用的分布式键值(key-value)数据库。由 CoreOS 开发，常用于服务注册和发现、共享配置以及并发控制（如 leader 选举、分布式锁等）。etcd内部采用raft协议作为一致性算法，etcd基于Go语言实现。

etcd与zookeeper相比算是轻量级系统，两者的一致性协议也一样，etcd的raft比zookeeper的paxos简单。

**1、使用场景**

- 配置管理
- 服务注册于发现
- 选主
- 应用调度
- 分布式队列
- 分布式锁

**2、原理**

etcd推荐使用奇数作为集群节点个数。因为奇数个节点和其配对的偶数个节点相比，容错能力相同，却可以少一个节点。综合考虑性能和容错能力，etcd官方文档推荐的etcd集群大小是3,5,7。由于etcd使用是Raft算法，每次写入数据需要有2N+1个节点同意可以写入数据，所以部分节点由于网络或者其他不可靠因素延迟收到数据更新，但是最终数据会保持一致，高度可靠。随着节点数目的增加，每次的写入延迟会相应的线性递增，除了节点数量会影响写入数据的延迟，如果节点跟接节点之间的网络延迟，也会导致数据的延迟写入。

**结论：**

- 节点数并非越多越好，过多的节点将会导致数据延迟写入。
- 节点跟节点之间的跨机房，专线之间网络延迟，也将会导致数据延迟写入。
- 受网络IO和磁盘IO的延迟
- 为了提高吞吐量，etcd通常将多个请求一次批量处理并提交Raft，增加节点，读性能会提升，写性能会下降，减少节点，写性能会提升



## 1.4.1 下载和分发 etcd 二进制文件

```bash
cd /data/work
wget https://github.com/etcd-io/etcd/releases/download/v3.4.4/etcd-v3.4.4-linux-amd64.tar.gz
tar -zxvf etcd-v3.4.4-linux-amd64.tar.gz

for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    scp etcd-v3.4.4-linux-amd64/etcd* root@${node}:/usr/local/bin/
    ssh root@${node} "chmod +x /usr/local/bin/*"
done
```



## 1.4.2 创建etcd数据和证书目录

```bash
for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    ssh root@${node} "mkdir -p /data/etcd /etc/etcd/ssl"
done
```



## 1.4.3 创建 etcd 证书和私钥

**创建etcd证书签名请求：**

```shell
cd /data/work/
cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "10.0.0.61",
    "10.0.0.62",
    "10.0.0.63"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "k8s",
      "OU": "4Paradigm"
    }
  ]
}
EOF
```

`hosts`：指定授权使用该证书的 etcd 节点 IP 列表，**需要将 etcd 集群所有节点 IP 都列在其中**；

**生成etcd证书和私钥：**

```shell
cd /data/work/
cfssl gencert -ca=ca.pem \
    -ca-key=ca-key.pem \
    -config=ca-config.json \
    -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
ls etcd*pem
```

**分发生成的证书和私钥到各 etcd 节点：**

```shell
cd /data/work/
for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    scp *.pem root@${node}:/etc/etcd/ssl/
done
```

## 1.4.4 创建并分发 etcd 启动文件

```bash
cd /data/work
# etcd 集群字典
declare -A ETCD_CLUSTERS
export ETCD_CLUSTERS=([k8s-m01]="10.0.0.61" [k8s-m02]="10.0.0.62" [k8s-m03]="10.0.0.63")
# etcd 数据目录
export ETCD_DATA_DIR=/data/etcd/
# etcd 集群间通信的 IP 和端口
export ETCD_NODES="k8s-m01=https://${ETCD_CLUSTERS[k8s-m01]}:2380,k8s-m02=https://${ETCD_CLUSTERS[k8s-m02]}:2380,k8s-m03=https://${ETCD_CLUSTERS[k8s-m03]}:2380"

# 生成每个节点的启动文件
for node in k8s-m{01..03}
do
cat > etcd.$node.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos
[Service]
Type=notify
WorkingDirectory=${ETCD_DATA_DIR}
ExecStart=/usr/local/bin/etcd \\
  --data-dir=${ETCD_DATA_DIR} \\
  --name=$node \\
  --cert-file=/etc/etcd/ssl/etcd.pem \\
  --key-file=/etc/etcd/ssl/etcd-key.pem \\
  --trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \\
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \\
  --peer-trusted-ca-file=/etc/etcd/ssl/ca.pem \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --listen-peer-urls=https://${ETCD_CLUSTERS[$node]}:2380 \\
  --initial-advertise-peer-urls=https://${ETCD_CLUSTERS[$node]}:2380 \\
  --listen-client-urls=https://${ETCD_CLUSTERS[$node]}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://${ETCD_CLUSTERS[$node]}:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=${ETCD_NODES} \\
  --initial-cluster-state=new \\
  --auto-compaction-mode=periodic \\
  --auto-compaction-retention=1 \\
  --max-request-bytes=33554432 \\
  --quota-backend-bytes=6442450944 \\
  --heartbeat-interval=250 \\
  --election-timeout=2000
Restart=on-failure
RestartSec=5
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
# 分发到对应服务器
scp etcd.$node.service root@${ETCD_CLUSTERS[$node]}:/etc/systemd/system/etcd.service
done
```

- `WorkingDirectory`、`--data-dir`：指定工作目录和数据目录为 `${ETCD_DATA_DIR}`，需在启动服务前创建这个目录；
- `--name`：指定节点名称，当 `--initial-cluster-state` 值为 `new` 时，`--name` 的参数值必须位于 `--initial-cluster` 列表中；
- `--cert-file`、`--key-file`：etcd server 与 client 通信时使用的证书和私钥；
- `--trusted-ca-file`：签名 client 证书的 CA 证书，用于验证 client 证书；
- `--peer-cert-file`、`--peer-key-file`：etcd 与 peer 通信使用的证书和私钥；
- `--peer-trusted-ca-file`：签名 peer 证书的 CA 证书，用于验证 peer 证书；



## 1.4.5 启动etcd服务

etcd首次进程启动会等待其他节点加入etcd集群，启动第一个etcd，可能会卡住；因为单独etcd还无法进行选举；当三个etcd都启动后，即可恢复正常。启动完后查看状态。

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    ssh -fn root@${node_ip} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd && systemctl status etcd|grep Active"
done
```

## 1.4.6  验证etcd集群状态

**查看集群健康状态：**

```bash
for node_ip in 10.0.0.{61..63}
  do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    ETCDCTL_API=3 /usr/local/bin/etcdctl \
    --endpoints=https://${node_ip}:2379 \
    --cacert=/etc/etcd/ssl/ca.pem \
    --cert=/etc/etcd/ssl/etcd.pem \
    --key=/etc/etcd/ssl/etcd-key.pem endpoint health
  done
```

- 输出均为 healthy 时表示集群服务正常。

**查看当前etcd集群leader：**

```
declare -A ETCD_CLUSTERS
export ETCD_CLUSTERS=([k8s-m01]="10.0.0.61" [k8s-m02]="10.0.0.62" [k8s-m03]="10.0.0.63")
export ETCD_NODES="k8s-m01=https://${ETCD_CLUSTERS[k8s-m01]}:2380,k8s-m02=https://${ETCD_CLUSTERS[k8s-m02]}:2380,k8s-m03=https://${ETCD_CLUSTERS[k8s-m03]}:2380"
ETCDCTL_API=3 /usr/local/bin/etcdctl \
  -w table --cacert=/etc/etcd/ssl/ca.pem \
  --cert=/etc/etcd/ssl/etcd.pem \
  --key=/etc/etcd/ssl/etcd-key.pem \
  --endpoints=${ETCD_ENDPOINTS} endpoint status
```

输出：

```bash
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|        ENDPOINT        |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://10.0.0.61:2379 | 373881ac0e3f8182 |   3.4.4 |   20 kB |     false |      false |        15 |         32 |                 32 |        |
| https://10.0.0.62:2379 | 19f3c191758492d6 |   3.4.4 |   20 kB |      true |      false |        15 |         32 |                 32 |        |
| https://10.0.0.63:2379 | f83fa3bd8f58acc0 |   3.4.4 |   25 kB |     false |      false |        15 |         32 |                 32 |        |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

```

**etcd注意事项：**

1.ETCD3.4版本ETCDCTL_API=3 etcdctl 和 etcd --enable-v2=false 成为了默认配置，如要使用v2版本，执行etcdctl时候需要设置ETCDCTL_API环境变量，例如：ETCDCTL_API=2 etcdctl

2.ETCD3.4版本会自动读取环境变量的参数，所以EnvironmentFile文件中有的参数，不需要再次在ExecStart启动参数中添加，二选一，如同时配置，会触发以下类似报错“etcd: conflicting environment variable "ETCD_NAME" is shadowed by corresponding command-line flag (either unset environment variable or disable flag)”





# 1.5 kubeadm部署集群

创建kubeadm工作目录

```
for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    ssh root@${node} "mkdir -p /data/work/kubeadm"
done
```



## 1.5.1 安装 kubeadm、kubelet、kubectl

==**以下操作均在k8s-m01上完成。**==

```bash
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpghttps://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    scp /etc/yum.repos.d/kubernetes.repo root@${node}:/etc/yum.repos.d/
    ssh -fn root@${node} "yum clean all &>/dev/null && yum makecache &>/dev/null && yum install -y kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0 &>/dev/null && systemctl enable --now kubelet"
done

```

配置kubectl自动补全

```bash
source <(kubectl completion bash) 
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

