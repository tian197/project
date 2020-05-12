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
