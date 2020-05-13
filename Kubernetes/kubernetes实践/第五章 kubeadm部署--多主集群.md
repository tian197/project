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



# 1.2 kubeadm 部署介绍

## 1.2.1 环境介绍

本次实验采用VM虚机；kubernetes组件版本为1.18.0。

| 主机名  | 角色   | 配置  |  外网IP   |   内网IP    |   系统    | 内核版本                    | 备注 |
| :-----: | ------ | ----- | :-------: | :---------: | :-------: | --------------------------- | ---- |
| k8s-m01 | master | 2核4G | 10.0.0.61 | 172.16.1.61 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |      |
| k8s-m02 | master | 2核4G | 10.0.0.62 | 172.16.1.62 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |      |
| k8s-m03 | master | 2核4G | 10.0.0.63 | 172.16.1.63 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |      |
| k8s-n01 | node   | 2核4G | 10.0.0.64 | 172.16.1.64 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |      |
|         | VIP    |       | 10.0.0.88 |             |           |                             |      |



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



# 1.4 部署 etcd 高可用集群

本次采用二进制外部部署实现该可用。官网也有kubeadm搭建高可用的etcd。

>  https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/setup-ha-etcd-with-kubeadm/ 

## 1.4.1 etcd介绍

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



## 1.4.2 下载和分发 etcd 二进制文件

```bash
mkdir -p /data/work && cd /data/work
wget https://github.com/etcd-io/etcd/releases/download/v3.4.4/etcd-v3.4.4-linux-amd64.tar.gz
tar -zxvf etcd-v3.4.4-linux-amd64.tar.gz

for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    scp etcd-v3.4.4-linux-amd64/etcd* root@${node}:/usr/local/bin/
    ssh root@${node} "chmod +x /usr/local/bin/*"
done
```



## 1.4.3 创建 etcd 数据和证书目录

```bash
for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    ssh root@${node} "mkdir -p /data/etcd /etc/etcd/pki/"
done
```



## 1.4.4 下载 [cfssl](https://github.com/cloudflare/cfssl) 创建证书

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

- ca证书 自己给自己签名的权威证书，用来给其他证书签名
- client certificate：用于服务端认证客户端,例如etcdctl、etcd proxy、fleetctl、docker客户端
- server certificate: 服务端使用，客户端以此验证服务端身份,例如docker服务端、kube-apiserver
- peer certificate: 双向证书，用于etcd集群成员间通信

==**注意：以下证书生成均在k8s-m01上配置核生成，然后进行分发。**==

**1、创建ca证书文件**

```bash
cd /etc/kubernetes/pki
cfssl print-defaults config > ca-config.json
cfssl print-defaults csr > ca-csr.json

#修改证书文件
cat >ca-config.json<<EOF
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "server": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            },
            "client": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "client auth"
                ]
            },
            "peer": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
EOF

# 修改证书签名请求
cat >ca-csr.json<<EOF
{
    "CN": "etcd",
    "key": {
        "algo": "rsa",
        "size": 2048
    }
}
EOF
```

- server auth表示client可以用该ca对server提供的证书进行验证

- client auth表示server可以用该ca对client提供的证书进行验证

**2、生成CA证书和私钥：**

```bash
cd /etc/etcd/pki
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

#etcd集群的ca证书
$ ls *.pem
ca-key.pem  ca.pem
```

**3、生成客户端证书**

```bash
cd /etc/etcd/pki
cat >client.json<<EOF
{
    "CN": "client",
    "key": {
        "algo": "ecdsa",
        "size": 256
    }
}
EOF

# 生成证书
cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=client client.json  | cfssljson -bare client -

#etcd集群的client私钥
#etcd集群的client证书，apiserver访问etcd使用
$ ls client*.pem
client-key.pem  client.pem
```

**4、生成server，peer证书**

```bash
cd /etc/etcd/pki
cat >etcd.json<<EOF
{
    "CN": "etcd",
    "hosts": [
        "127.0.0.1",
        "10.0.0.61",
        "10.0.0.62",
        "10.0.0.63"
    ],
    "key": {
        "algo": "ecdsa",
        "size": 256
    },
    "names": [
        {
            "C": "CN",
            "L": "BJ",
            "ST": "BJ"
        }
    ]
}
EOF

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=server etcd.json | cfssljson -bare server

cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=peer etcd.json | cfssljson -bare peer

$ ls *pem
ca-key.pem  ca.pem  client-key.pem  client.pem  peer-key.pem  peer.pem  server-key.pem  server.pem
```

**5、分发证书到etcd服务器**

```bash
for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    scp /etc/etcd/pki/*pem root@${node}:/etc/etcd/pki/
done
```



## 1.4.5 创建并分发 etcd 启动文件

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
  --cert-file=/etc/etcd/pki/server.pem \\
  --key-file=/etc/etcd/pki/server-key.pem \\
  --trusted-ca-file=/etc/etcd/pki/ca.pem \\
  --peer-cert-file=/etc/etcd/pki/peer.pem \\
  --peer-key-file=/etc/etcd/pki/peer-key.pem \\
  --peer-trusted-ca-file=/etc/etcd/pki/ca.pem \\
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



## 1.4.6 启动 etcd 服务

etcd首次进程启动会等待其他节点加入etcd集群，启动第一个etcd，可能会卡住；因为单独etcd还无法进行选举；当三个etcd都启动后，即可恢复正常。启动完后查看状态。

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    ssh -fn root@${node_ip} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd && systemctl status etcd|grep Active"
done
```

## 1.4.7  验证 etcd 集群状态

**查看集群健康状态：**

```bash
for node_ip in 10.0.0.{61..63}
  do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    ETCDCTL_API=3 /usr/local/bin/etcdctl \
    --endpoints=https://${node_ip}:2379 \
    --cacert=/etc/etcd/pki/ca.pem \
    --cert=/etc/etcd/pki/server.pem \
    --key=/etc/etcd/pki/server-key.pem endpoint health
  done
```

- 输出均为 healthy 时表示集群服务正常。

**查看当前etcd集群leader：**

```bash
declare -A ETCD_CLUSTERS
export ETCD_CLUSTERS=([k8s-m01]="10.0.0.61" [k8s-m02]="10.0.0.62" [k8s-m03]="10.0.0.63")
export ETCD_ENDPOINTS="https://${ETCD_CLUSTERS[k8s-m01]}:2379,https://${ETCD_CLUSTERS[k8s-m02]}:2379,https://${ETCD_CLUSTERS[k8s-m03]}:2379"

ETCDCTL_API=3 /usr/local/bin/etcdctl \
  -w table --cacert=/etc/etcd/pki/ca.pem \
  --cert=/etc/etcd/pki/server.pem \
  --key=/etc/etcd/pki/server-key.pem \
  --endpoints=${ETCD_ENDPOINTS} endpoint status
```

输出：

```bash
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|        ENDPOINT        |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://10.0.0.61:2379 | 373881ac0e3f8182 |   3.4.4 |   20 kB |      true |      false |         2 |          8 |8 |        |
| https://10.0.0.62:2379 | 19f3c191758492d6 |   3.4.4 |   20 kB |     false |      false |         2 |          8 |8 |        |
| https://10.0.0.63:2379 | f83fa3bd8f58acc0 |   3.4.4 |   25 kB |     false |      false |         2 |          8 |8 |        |
+------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

**etcd注意事项：**

1.ETCD3.4版本ETCDCTL_API=3 etcdctl 和 etcd --enable-v2=false 成为了默认配置，如要使用v2版本，执行etcdctl时候需要设置ETCDCTL_API环境变量，例如：ETCDCTL_API=2 etcdctl

2.ETCD3.4版本会自动读取环境变量的参数，所以EnvironmentFile文件中有的参数，不需要再次在ExecStart启动参数中添加，二选一，如同时配置，会触发以下类似报错“etcd: conflicting environment variable "ETCD_NAME" is shadowed by corresponding command-line flag (either unset environment variable or disable flag)”



# 1.5 nginx+keepalived 高可用四层代理

之前提到；kube-apiserver是无状态的；可以使用Nginx 4层透明代理功能实现k8s节点(master节点和worker节点)高可用访问kube-apiserver。

## 1.5.1 nginx 配置

**1、编译安装nginx**

```bash
cd /data/work
wget http://nginx.org/download/nginx-1.18.0.tar.gz
#编译
yum install gcc gcc-c++ pcre pcre-devel zlib zlib-devel openssl openssl-devel -y 
tar -xzvf nginx-1.18.0.tar.gz
cd nginx-1.18.0
./configure --with-stream --without-http --prefix=/usr/local/nginx --without-http_uwsgi_module 
make && make install

#############
--without-http_scgi_module --without-http_fastcgi_module
--with-stream：开启 4 层透明转发(TCP Proxy)功能；
--without-xxx：关闭所有其他功能，这样生成的动态链接二进制程序依赖最小；
```

分发到其它机器：

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    scp -r /usr/local/nginx root@${node_ip}:/usr/local/
done
```

**2、配置Nginx文件，开启4层透明转发**

```bash
cat > /usr/local/nginx/conf/nginx.conf<<EOF
worker_processes 1;
events {
    worker_connections  1024;
}
stream {
    upstream backend {
        hash $remote_addr consistent;
        server 10.0.0.61:6443        max_fails=3 fail_timeout=30s;
        server 10.0.0.62:6443        max_fails=3 fail_timeout=30s;
        server 10.0.0.63:6443        max_fails=3 fail_timeout=30s;
    }
    server {
        listen *:8443;
        proxy_connect_timeout 1s;
        proxy_pass backend;
    }
}
EOF
```

分发配置文件：

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    scp /usr/local/nginx/conf/nginx.conf root@${node_ip}:/usr/local/nginx/conf/
done
```

**3、配置Nginx启动文件**

```bash
cat > /etc/systemd/system/nginx.service <<EOF
[Unit]
Description=kube-apiserver nginx proxy
After=network.target
After=network-online.target
Wants=network-online.target
[Service]
Type=forking
ExecStartPre=/usr/local/nginx/sbin/nginx -t -c /usr/local/nginx/conf/nginx.conf
ExecStart=/usr/local/nginx/sbin/nginx -c /usr/local/nginx/conf/nginx.conf
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s stop
PrivateTmp=true
Restart=always
RestartSec=5
StartLimitInterval=0
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target
EOF
```

分发启动文件：

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    scp /etc/systemd/system/nginx.service root@${node_ip}:/etc/systemd/system/
done
```

启动nginx：

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    ssh root@$node_ip "systemctl daemon-reload && systemctl enable nginx && systemctl restart nginx && systemctl status nginx |grep 'Active:'"
done
```



## 1.5.2 keepalived配置

==高可用方案需要一个VIP，供集群内部访问；本次部署使用keepalived的非抢占模式。==

**1、所有master节点安装keeplived**

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    ssh root@$node_ip "yum -y install keepalived"
done
```

**2、生成配置文件**

```bash
cd /data/work
for node_ip in 10.0.0.{61..63}
do
echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
cat > keepalived.${node_ip}.conf<<EOF
! Configuration File for keepalived
global_defs {
   router_id ${node_ip}
   script_user root
   enable_script_security
}
vrrp_script chk_nginx {
    script "/etc/keepalived/check_port.sh 8443"
    interval 2
    weight -30
}
vrrp_instance VI_1 {
    state BACKUP
    interface ens33
    virtual_router_id 251
    priority 100
    advert_int 1
    mcast_src_ip ${node_ip}
    nopreempt
    authentication {
        auth_type PASS
        auth_pass 11111111
    }
    track_script {
         chk_nginx
    }
    virtual_ipaddress {
        10.0.0.88
    }
}
EOF
done
```

修改priority优先级：

```bash
cd /data/work
NODE_IPS=(10.0.0.61 10.0.0.62 10.0.0.63)
for (( i=0; i < 3; i++ ))
  do
    num=`expr 100 - 10 \* $i`
    echo -e "\033[42;37m >>> ${NODE_IPS[i]} <<< \033[0m"
    sed -i "/priority/s#100#${num}#g" keepalived.${NODE_IPS[i]}.conf
  done
```

分发配置文件：

```bash
cd /data/work
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    scp keepalived.${node_ip}.conf root@${node_ip}:/etc/keepalived/keepalived.conf
done
```

**3、创建健康检查脚本并分发**

```bash
cat >/etc/keepalived/check_port.sh<<\EOF
CHK_PORT=$1
 if [ -n "$CHK_PORT" ];then
        PORT_PROCESS=`ss -lntp|grep $CHK_PORT|wc -l`
        if [ $PORT_PROCESS -eq 0 ];then
                echo "Port $CHK_PORT Is Not Used,End."
                systemctl stop keepalived.service
        fi
 else
        echo "Check Port Cant Be Empty!"
 fi
EOF
```

分发：

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    scp /etc/keepalived/check_port.sh root@${node_ip}:/etc/keepalived/
    ssh root@${node_ip} "chmod +x /etc/keepalived/check_port.sh"
done
```

**4、启动keeplived**

```bash
for node_ip in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node_ip} <<< \033[0m"
    ssh root@${node_ip} "systemctl daemon-reload && systemctl enable keepalived && systemctl restart keepalived && systemctl status keepalived |grep Active"
    sleep 2
done
```

**5、测试keepalived**

依次停掉nginx服务；检查VIP飘移情况。



# 1.6 kubeadm 部署集群

创建kubeadm工作目录

```bash
for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    ssh root@${node} "mkdir -p /data/work/kubeadm"
done
```



## 1.6.1 安装 kubeadm、kubelet、kubectl

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
    ssh  root@${node} "yum clean all &>/dev/null && yum makecache &>/dev/null && yum install -y kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0 &>/dev/null && systemctl enable --now kubelet"
done

```

配置kubectl自动补全

```bash
yum install -y bash-completion
source /usr/share/bash-completion/bash_completion
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> /etc/profile
```



## 1.6.2 初始化 master

### 1.6.2.1 拉取镜像

此处借助于阿里云已经构建好；三台master均需要拉取；否则初始化会因为拉取镜像失败。

```bash
----------------------------------------kubeadm镜像-------------------------------------
cd /data/work/kubeadm
cat >k8s.images<<EOF
kube-apiserver:v1.18.0
kube-controller-manager:v1.18.0
kube-proxy:v1.18.0
kube-scheduler:v1.18.0
coredns:1.6.7
etcd:3.4.3-0
pause:3.2
EOF

for i in `cat k8s.images`
do
    REPO=$(echo "$i"|awk -F ':' '{print $1}')
    TAG=$(echo "$i"|awk -F ':' '{print $2}')
    sudo docker pull registry.cn-beijing.aliyuncs.com/crazywjj/$i
    sudo docker tag  registry.cn-beijing.aliyuncs.com/crazywjj/$i k8s.gcr.io/$REPO:$TAG
    sudo docker rmi -f registry.cn-beijing.aliyuncs.com/crazywjj/$i
done
```

### 1.6.2.2 获得默认配置文件

```
cd /data/work/kubeadm
kubeadm config print init-defaults > kubeadm-init.yaml
```

### 1.6.2.3 修改初始化文件

 [kubeadm-init.yaml](C:\Users\Administrator\Desktop\kubeadm-init.yaml) 

```yaml
vim kubeadm-init.yaml
apiVersion: kubeadm.k8s.io/v1beta2
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: 10.0.0.61
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  name: k8s-m01
  taints:
  - effect: NoSchedule
    key: node-role.kubernetes.io/master
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta2
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controlPlaneEndpoint: "10.0.0.88:8443"
controllerManager: {}
dns:
  type: CoreDNS
etcd:
  external:
    endpoints:
    - https://10.0.0.61:2379
    - https://10.0.0.62:2379
    - https://10.0.0.63:2379
    caFile: /etc/etcd/pki/ca.pem
    certFile: /etc/etcd/pki/client.pem
    keyFile: /etc/etcd/pki/client-key.pem
imageRepository: k8s.gcr.io
kind: ClusterConfiguration
kubernetesVersion: v1.18.0
networking:
  dnsDomain: cluster.local
  podSubnet: "10.244.0.0/16"
  serviceSubnet: 10.96.0.0/12
scheduler: {}
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
featureGates:
  SupportIPVSProxyMode: true
mode: ipvs
```

### 1.6.2.4 初始化

```bash
kubeadm init --config kubeadm-init.yaml
W0513 18:29:38.851019   28937 configset.go:202] WARNING: kubeadm cannot validate component configs for API groups [kubelet.config.k8s.io kubeproxy.config.k8s.io]
[init] Using Kubernetes version: v1.18.0
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8s-m01 kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 10.0.0.61 10.0.0.88]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] External etcd mode: Skipping etcd/ca certificate authority generation
[certs] External etcd mode: Skipping etcd/server certificate generation
[certs] External etcd mode: Skipping etcd/peer certificate generation
[certs] External etcd mode: Skipping etcd/healthcheck-client certificate generation
[certs] External etcd mode: Skipping apiserver-etcd-client certificate generation
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "admin.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
W0513 18:29:43.155355   28937 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[control-plane] Creating static Pod manifest for "kube-scheduler"
W0513 18:29:43.156777   28937 manifests.go:225] the default kube-apiserver authorization-mode is "Node,RBAC"; using "Node,RBAC"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests".This can take up to 4m0s
[apiclient] All control plane components are healthy after 33.540748 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config-1.18" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Skipping phase. Please see --upload-certs
[mark-control-plane] Marking the node k8s-m01 as control-plane by adding the label "node-role.kubernetes.io/master=''"
[mark-control-plane] Marking the node k8s-m01 as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
[bootstrap-token] Using token: abcdef.0123456789abcdef
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[endpoint] WARNING: port specified in controlPlaneEndpoint overrides bindPort in the controlplane address
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join 10.0.0.88:8443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:e08d290a7d69d7591d845e9f38ed51e746e854c9d8c6592e4626131046f27eda \
    --control-plane

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join 10.0.0.88:8443 --token abcdef.0123456789abcdef \
    --discovery-token-ca-cert-hash sha256:e08d290a7d69d7591d845e9f38ed51e746e854c9d8c6592e4626131046f27eda

```

 上面有2个 `kubeadm join` ，之前在单主模式下，只会出现worker node的加入命令。 

设置KUBERNETES_MASTER环境变量：

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



### 1.6.2.5 分发证书到其它master节点

>  https://kubernetes.io/zh/docs/setup/production-environment/tools/kubeadm/high-availability/ 

 该脚本会将证书从第一个控制平面节点复制到另一个控制平面节点： 

```bash
USER=root
CONTROL_PLANE_IPS="10.0.0.62 10.0.0.63"
for host in ${CONTROL_PLANE_IPS}; do
    echo -e "\033[42;37m >>> ${host} <<< \033[0m"
    scp /etc/kubernetes/pki/ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/ca.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.key "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/sa.pub "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.crt "${USER}"@$host:/etc/kubernetes/pki/
    scp /etc/kubernetes/pki/front-proxy-ca.key "${USER}"@$host:/etc/kubernetes/pki/
done
```

 必须保证证书已经上传到了节点，然后分别在`k8s-m02，k8s-m03`进行join的操作。 

```bash
kubeadm join 10.0.0.88:8443 --token abcdef.0123456789abcdef --discovery-token-ca-cert-hash sha256:e08d290a7d69d7591d845e9f38ed51e746e854c9d8c6592e4626131046f27eda --control-plane
```

设置KUBERNETES_MASTER环境变量：

```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



### 1.6.2.6  查看k8s集群状态 

```bash
$ kubectl get nodes
NAME      STATUS     ROLES    AGE     VERSION
k8s-m01   NotReady   master   21m     v1.18.0
k8s-m02   NotReady   master   3m12s   v1.18.0
k8s-m03   NotReady   master   8s      v1.18.0

$ kubectl get componentstatuses
NAME                 STATUS    MESSAGE             ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health":"true"}
etcd-2               Healthy   {"health":"true"}
etcd-1               Healthy   {"health":"true"}

$ kubectl get pods --all-namespaces
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-66bff467f8-dd6dq          0/1     Pending   0          22m
kube-system   coredns-66bff467f8-n8nh6          0/1     Pending   0          22m
kube-system   kube-apiserver-k8s-m01            1/1     Running   0          22m
kube-system   kube-apiserver-k8s-m02            1/1     Running   0          4m33s
kube-system   kube-apiserver-k8s-m03            1/1     Running   0          88s
kube-system   kube-controller-manager-k8s-m01   1/1     Running   0          22m
kube-system   kube-controller-manager-k8s-m02   1/1     Running   0          4m33s
kube-system   kube-controller-manager-k8s-m03   1/1     Running   0          88s
kube-system   kube-proxy-dft62                  1/1     Running   1          4m34s
kube-system   kube-proxy-lbqcl                  1/1     Running   1          90s
kube-system   kube-proxy-n9bv4                  1/1     Running   1          22m
kube-system   kube-scheduler-k8s-m01            1/1     Running   0          22m
kube-system   kube-scheduler-k8s-m02            1/1     Running   0          4m33s
kube-system   kube-scheduler-k8s-m03            1/1     Running   0          89s
```

- NotReady，因为corednspod没有启动，缺少网络pod



# 1.7 安装网络插件Flannel

**1、下载yml**

```bash
cd /data/work/kubeadm
curl -o kube-flannel.yml https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```

需要注意的是：

flannel 默认会使用主机的第一张物理网卡，如果你有多张网卡，需要通过配置单独指定。修改 kube-flannel.yml 中的以下部分。

```bash
vim kube-flannel.yml
      containers:
      - name: kube-flannel
        image: quay.io/coreos/flannel:v0.12.0-amd64
        command:
        - /opt/bin/flanneld
        args:
        - --ip-masq
        - --kube-subnet-mgr
        - --iface=ens33		# 指定网卡
```

**2、拉取镜像**

```bash
cd /data/work/
cat >flannel.images<<EOF
v0.12.0-amd64
v0.12.0-arm
v0.12.0-arm64
v0.12.0-ppc64le
v0.12.0-s390x
EOF

for i in `cat flannel.images`
do
    sudo docker pull registry.cn-beijing.aliyuncs.com/crazywjj/flannel:$i
    sudo docker tag  registry.cn-beijing.aliyuncs.com/crazywjj/flannel:$i quay.io/coreos/flannel:$i
    sudo docker rmi -f registry.cn-beijing.aliyuncs.com/crazywjj/flannel:$i
done
```

**3、执行kube-flannel.yml**

```bash
kubectl apply -f kube-flannel.yml
```

**4、检查集群状态**

```bash
$ kubectl get pods --all-namespaces -o wide
NAMESPACE     NAME                              READY   STATUS    RESTARTS   AGE
kube-system   coredns-66bff467f8-dd6dq          1/1     Running   0          51m
kube-system   coredns-66bff467f8-n8nh6          1/1     Running   0          51m
kube-system   kube-apiserver-k8s-m01            1/1     Running   0          52m
kube-system   kube-apiserver-k8s-m02            1/1     Running   0          34m
kube-system   kube-apiserver-k8s-m03            1/1     Running   0          31m
kube-system   kube-controller-manager-k8s-m01   1/1     Running   0          52m
kube-system   kube-controller-manager-k8s-m02   1/1     Running   0          34m
kube-system   kube-controller-manager-k8s-m03   1/1     Running   0          31m
kube-system   kube-flannel-ds-amd64-6ntfd       1/1     Running   0          2m20s
kube-system   kube-flannel-ds-amd64-8q8xp       1/1     Running   0          2m20s
kube-system   kube-flannel-ds-amd64-dbtfm       1/1     Running   0          2m20s
kube-system   kube-proxy-dft62                  1/1     Running   1          34m
kube-system   kube-proxy-lbqcl                  1/1     Running   1          31m
kube-system   kube-proxy-n9bv4                  1/1     Running   1          51m
kube-system   kube-scheduler-k8s-m01            1/1     Running   0          52m
kube-system   kube-scheduler-k8s-m02            1/1     Running   0          34m
kube-system   kube-scheduler-k8s-m03            1/1     Running   0          31m


$ kubectl get svc
NAME         TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1    <none>        443/TCP   32m

$ kubectl get cs
NAME                 STATUS    MESSAGE             ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true"}
```

**5、查看ipvs路由规则**

```
for node in 10.0.0.{61..63}
do
    echo -e "\033[42;37m >>> ${node} <<< \033[0m"
    ssh  root@${node} "yum -y install ipvsadm &>/dev/null && ipvsadm -ln"
done
```

输出：

```bash
 >>> 10.0.0.61 <<<
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.1:443 rr
  -> 10.0.0.61:6443               Masq    1      1          0
  -> 10.0.0.62:6443               Masq    1      0          0
  -> 10.0.0.63:6443               Masq    1      1          0
TCP  10.96.0.10:53 rr
  -> 10.244.0.2:53                Masq    1      0          0
  -> 10.244.1.2:53                Masq    1      0          0
TCP  10.96.0.10:9153 rr
  -> 10.244.0.2:9153              Masq    1      0          0
  -> 10.244.1.2:9153              Masq    1      0          0
UDP  10.96.0.10:53 rr
  -> 10.244.0.2:53                Masq    1      0          0
  -> 10.244.1.2:53                Masq    1      0          0
 >>> 10.0.0.62 <<<
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.1:443 rr
  -> 10.0.0.61:6443               Masq    1      0          0
  -> 10.0.0.62:6443               Masq    1      1          0
  -> 10.0.0.63:6443               Masq    1      1          0
TCP  10.96.0.10:53 rr
  -> 10.244.0.2:53                Masq    1      0          0
  -> 10.244.1.2:53                Masq    1      0          0
TCP  10.96.0.10:9153 rr
  -> 10.244.0.2:9153              Masq    1      0          0
  -> 10.244.1.2:9153              Masq    1      0          0
UDP  10.96.0.10:53 rr
  -> 10.244.0.2:53                Masq    1      0          0
  -> 10.244.1.2:53                Masq    1      0          0
 >>> 10.0.0.63 <<<
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.1:443 rr
  -> 10.0.0.61:6443               Masq    1      0          0
  -> 10.0.0.62:6443               Masq    1      0          0
  -> 10.0.0.63:6443               Masq    1      1          0
TCP  10.96.0.10:53 rr
  -> 10.244.0.2:53                Masq    1      0          0
  -> 10.244.1.2:53                Masq    1      0          0
TCP  10.96.0.10:9153 rr
  -> 10.244.0.2:9153              Masq    1      0          0
  -> 10.244.1.2:9153              Masq    1      0          0
UDP  10.96.0.10:53 rr
  -> 10.244.0.2:53                Masq    1      0          0
  -> 10.244.1.2:53                Masq    1      0          0
```





# 1.8 验证高可用功能

将master1关机，如果还是可以执行kubectl命令，创建pod等，说明高可用搭建成功。

这是因为vip已漂移到master2，只要VIP存在，apiserver就还是可以接收我们的指令。



























