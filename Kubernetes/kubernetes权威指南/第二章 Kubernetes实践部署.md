[TOC]





# 第二章 Kubernetes部署

**官方提供的三种部署方式**

**1.minikube**

Minikube是一个工具，可以在本地快速运行一个单点的Kubernetes，仅用于尝试Kubernetes或日常开发的用户使用。 部署地址：<https://kubernetes.io/docs/setup/minikube/>

**2.kubeadm**

Kubeadm也是一个工具，提供kubeadm init和kubeadm join，用于快速部署Kubernetes集群。 部署地址：<https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/>

**3.二进制包**

推荐，从官方下载发行版的二进制包，手动部署每个组件，组成Kubernetes集群。 下载地址：<https://github.com/kubernetes/kubernetes/releases>



# 1.1 kubeadm部署集群

## 1.1.1 环境介绍

| 主机名  | 角色   |  外网IP   |   内网IP    |   系统    | 内核版本                    | 安装软件 |
| :-----: | ------ | :-------: | :---------: | :-------: | --------------------------- | :------: |
| k8s-m01 | master | 10.0.0.61 | 172.16.1.61 | centos7.7 | 4.4.218-1.el7.elrepo.x86_64 |          |
|         |        |           |             |           |                             |          |
|         |        |           |             |           |                             |          |



## 1.1.2 初始化准备

**1、修改主机名**

```shell
hostnamectl set-hostname k8s-m01
hostnamectl set-hostname k8s-m02
hostnamectl set-hostname k8s-m03
```

**2、添加hosts解析**

```shell
cat >/etc/hosts<<EOF
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
10.0.0.61 k8s-m01
10.0.0.62 k8s-m02
10.0.0.63 k8s-m03
EOF
```

**3、时间同步**

```shell
echo "*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1" >/var/spool/cron/root
```

**4、加载并优化内核参数**

```shell
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

modprobe ip_vs_rr
modprobe br_netfilter
sysctl -p /etc/sysctl.d/kubernetes.conf
```

> 注：tcp_tw_recycle 和 Kubernetes 的 NAT 冲突，必须关闭 ，否则会导致服务不通；
> 关闭不使用的 IPV6 协议栈，防止触发 docker BUG；
>
> 报错：sysctl: cannot stat /proc/sys/net/bridge/bridge-nf-call-iptables；解决措施：modprobe br_netfilter

**5、关闭swap分区**

如果开启了swap分区，kubelet会启动失败(可以通过将参数 --fail-swap-on 设置为false来忽略swap on)，故需要在每个node节点机器上关闭swap分区。

```shell
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
```

**6、关闭并禁用firewalld及selinux**

 在每台机器上关闭防火墙，清理防火墙规则，设置默认转发策略 

```shell
systemctl stop firewalld
systemctl disable firewalld
iptables -F && iptables -X && iptables -F -t nat && iptables -X -t nat
iptables -P FORWARD ACCEPT
setenforce 0
sed -i  '/^SELINUX/s#enforcing#disabled#g' /etc/selinux/config
```

**7、设置rsyslogd 和systemd journald**

systemd 的 journald 是 Centos 7 缺省的日志记录工具，它记录了所有系统、内核、Service Unit 的日志。相比 systemd，journald 记录的日志有如下优势：

- 可以记录到内存或文件系统；(默认记录到内存，对应的位置为 /run/log/jounal)；
- 可以限制占用的磁盘空间、保证磁盘剩余空间；
- 可以限制日志文件大小、保存的时间；
- journald 默认将日志转发给 rsyslog，这会导致日志写了多份，/var/log/messages 中包含了太多无关日志，不方便后续查看，同时也影响系统性能。

```bash
mkdir /var/log/journal
mkdir /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/99-prophet.conf <<EOF
[Journal]
# 持久化保存到磁盘
Storage=persistent
     
# 压缩历史日志
Compress=yes
     
SyncIntervalSec=5m
RateLimitInterval=30s
RateLimitBurst=1000
     
# 最大占用空间 10G
SystemMaxUse=10G
     
# 单日志文件最大 200M
SystemMaxFileSize=200M
     
# 日志保存时间 2 周
MaxRetentionSec=2week
     
# 不将日志转发到 syslog
ForwardToSyslog=no
EOF
     
systemctl restart systemd-journald
```

**8、升级内核**

```shell
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-3.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install kernel-lt -y
grub2-set-default  0 && grub2-mkconfig -o /etc/grub2.cfg
reboot
```



**9、安装docker**

```bash
yum install -y yum-utils device-mapper-persistent-data lvm2
wget -P /etc/yum.repos.d/ https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache
yum install docker-ce-18.06.3.ce -y
systemctl start docker
systemctl enable docker

```





# 1.2 K8S集群部署

## 1.2.1 安装 kubeadm、kubelet、kubectl

所有节点都安装 kubeadm、kubelet、kubectl，注意：node节点的kubectl不是必须的。

```bash
# 配置yum源
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpghttps://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
yum clean all
yum makecache

# 安装-由于k8s更新很快，建议制定需要的版本
yum install -y kubelet-1.18.0 kubeadm-1.18.0 kubectl-1.18.0
systemctl enable kubelet
```

## 1.2.2 初始化master

```bash
# 获得默认配置文件
kubeadm config print init-defaults > kubeadm.conf

# 查看需要的镜像
kubeadm config images list --config kubeadm.conf
输出：
k8s.gcr.io/kube-apiserver:v1.18.0
k8s.gcr.io/kube-controller-manager:v1.18.0
k8s.gcr.io/kube-scheduler:v1.18.0
k8s.gcr.io/kube-proxy:v1.18.0
k8s.gcr.io/pause:3.2
k8s.gcr.io/etcd:3.4.3-0
k8s.gcr.io/coredns:1.6.7

# 拉取需要的镜像
kubeadm config images pull --config kubeadm.conf

# 初始化
kubeadm init –config kubeadm.conf
```







