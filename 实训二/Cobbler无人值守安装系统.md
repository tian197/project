[TOC]





# Cobbler无人值守安装系统

# 1.1 Cobbler简介

> Cobbler是通过将DHCP、TFTP、DNS、HTTP等服务进行集成，创建一个中央管理节点，其可以实现的功能有配置服务，创建存储库，解压缩操作系统媒介，代理或集成一个配置管理系统，控制电源管理等。 Cobbler的最终目的是实现无需进行人工干预即可安装机器。在进行进一步的操作之前，我们有必要先了解下pxe和kickstart 。


Cobbler是一个快速网络安装linux的服务，而且在经过调整也可以支持网络安装windows。该工具使用python开发，小巧轻便（才15k行python代码），使用简单的命令即可完成PXE网络安装环境的配置，同时还可以管理DHCP、DNS、TFTP、RSYNC以及yum仓库、构造系统ISO镜像。 Cobbler支持命令行管理，web界面管理，还提供了API接口，可以方便二次开发使用。 Cobbler客户端Koan支持虚拟机安装和操作系统重新安装，同时支持服务器的电源管理，使重装系统更便捷。更多内容可以查看cobbler官方网站！

cobbler官方网站：http://cobbler.github.io/



# 1.2 Cobbler功能

- pxe支持
- dhcp管理
- dns服务管理（bind，dnsmasq）
- 电源管理
- kickstart支持
- yum仓库管理
- tftp（pxe启动时需要）
- apache，提供ks得安装源，并提供定制化得ks配置，同时，它和apache做了深度整合，通过cobbler，可以使redhat/centos/fedora系统得快速部署，同时也支持suse、debian（ubuntu）系统，通过配置开可以支持windows



# 1.3 Cobbler框架

![1583055454979](assets/1583055454979.png)

`Cobbler`的配置结构基于一组注册的对象。每个对象表示一个与另一个实体相关联的实体。当一个对象指向另一个对象时，它就继承了被指向对象的数据，并可覆盖或添加更多特定信息。

- 发行版(`distros`)： 表示一个操作系统。它承载了内核和`initrd`的信息，以及内核参数等其他数据。
- 配置文件(`profiles`)：包含一个发行版、一个`kickstart`文件以及可能的存储库，还包括更多特定的内核参数等其他数据。
- 系统(`systems`)：表示要配给的机器。它包括一个配置文件或一个镜像、`IP`和`MAC`地址、电源管理（地址、凭据、类型）以及更为专业的数据等信息。
- 镜像(`images`)：可以替换一个保函不屑于此类别的文件的发行版对象（例如，无法分为内核和`initrd`的对象）。



# 1.4 Cobbler工作原理

![1583055517826](assets/1583055517826.png)

**Server端**

- 启动`Cobbler`服务
- 进行`Cobbler`错误检查，执行`cobbler check`命令
- 进行配置同步，执行`cobbler sync`命令
- 复制相关启动文件到`TFTP`目录中
- 启动`DHCP`服务，提供地址分配
- `DHCP`服务分配IP地址
- `TFTP`传输启动文件
- `Server`端接收安装信息
- `Server`端发送`ISO`镜像与`Kickstart`文件

**Client端**

- 客户端以`PXE`模式启动
- 客户端获取`IP`地址
- 通过`TFTP`服务器获取启动文件
- 进入`Cobbler`安装选择界面
- 根据配置信息准备安装系统
- 加载`Kickstart`文件
- 传输系统安装的其它文件
- 进行安装系统



# 1.5 Cobbler部署

## 1.5.1 环境介绍

| 主机名  | 系统           | 外网ip    | 内网ip      |
| ------- | -------------- | --------- | ----------- |
| cobbler | CentOS7.3.1611 | 10.0.0.44 | 172.16.1.44 |
|         |                |           |             |

说明：虚拟机网卡采用NAT模式或者仅主机模式，不要使用桥接模式，因为后面会搭建DHCP服务器，在同一个局域网多个DHCP服务会有冲突。VMware的NAT模式的dhcp服务也关闭，避免干扰。

## 1.5.2 安装

```shell

[root@ cobbler ~]# yum -y install cobbler cobbler-web tftp-server pykickstart httpd dhcp xinetd debmirror

cobbler        #cobbler程序包
cobbler-web     #cobbler的web服务包
pykickstart    #cobbler检查kickstart语法错误
httpd      #Apache web服务
dhcp       #Dhcp服务
tftp      #tftp服务
xinetd　　#诸多服务的超级守护进程

#启动cobbler及httpd并加入开机启动
[root@ cobbler ~]# systemctl start httpd cobblerd
[root@ cobbler ~]# systemctl enable httpd cobblerd

```

## 1.5.3 配置cobbler

检查Cobbler的配置，如果看不到下面的结果，再次重启cobbler。

```shell
[root@ cobbler ~]# cobbler check   #类似一个使用手册，告诉我们需要完成以下内容
The following are potential configuration items that you may want to fix:

1 : The 'server' field in /etc/cobbler/settings must be set to something other than localhost, or kickstarting features will not work.  This should be a resolvable hostname or IP for the boot server as reachable by all machines that will use it.
2 : For PXE to be functional, the 'next_server' field in /etc/cobbler/settings must be set to something other than 127.0.0.1, and should match the IP of the boot server on the PXE network.
3 : change 'disable' to 'no' in /etc/xinetd.d/tftp
4 : Some network boot-loaders are missing from /var/lib/cobbler/loaders, you may run 'cobbler get-loaders' to download them, or, if you only want to handle x86/x86_64 netbooting, you may ensure that you have installed a *recent* version of the syslinux package installed and can ignore this message entirely.  Files in this directory, should you want to support all architectures, should include pxelinux.0, menu.c32, elilo.efi, and yaboot. The 'cobbler get-loaders' command is the easiest way to resolve these requirements.
5 : enable and start rsyncd.service with systemctl
6 : comment out 'dists' on /etc/debmirror.conf for proper debian support
7 : comment out 'arches' on /etc/debmirror.conf for proper debian support
8 : The default password used by the sample templates for newly installed machines (default_password_crypted in /etc/cobbler/settings) is still set to 'cobbler' and should be changed, try: "openssl passwd -1 -salt 'random-phrase-here' 'your-password-here'" to generate new one
9 : fencing tools were not found, and are required to use the (optional) power management features. install cman or fence-agents to use them

Restart cobblerd and then run 'cobbler sync' to apply changes.

```

看到上面出现的问题，然后一个一个的进行解决，先进行设置为可以动态配置，也可以直接更改配置文件。

```
[root@ cobbler ~]# sed -ri '/allow_dynamic_settings:/c\allow_dynamic_settings: 1' /etc/cobbler/settings
[root@ cobbler ~]# grep allow_dynamic_settings /etc/cobbler/settings
allow_dynamic_settings: 1
[root@ cobbler ~]# systemctl restart cobblerd
```

逐个解决上面的问题

```shell
#1.配置server地址
[root@ cobbler ~]# cobbler setting edit --name=server --value=10.0.0.44

#2.配置next_server地址
[root@ cobbler ~]# cobbler setting edit --name=next_server --value=10.0.0.44

#3.配置xinetd管理tftp
[root@ cobbler ~]# sed -ri '/disable/c\disable = no' /etc/xinetd.d/tftp
[root@ cobbler ~]# systemctl enable xinetd
[root@ cobbler ~]# systemctl restart xinetd

#4.boot-loaders
[root@ cobbler ~]# cobbler get-loaders

#5.启动rsync
[root@ cobbler ~]# systemctl start rsyncd
[root@ cobbler ~]# systemctl enable rsyncd

#6和7.debian support
[root@ cobbler ~]# sed -i 's#@dists="sid";#\#@dists="sid";#gp' /etc/debmirror.conf
[root@ cobbler ~]# sed -i 's#@arches="i386";#\#@arches="i386";#g' /etc/debmirror.conf

#8.default_password_crypted
# 注意：这里设置的密码是clbbler安装完系统后，默认root用户初始化登录密码，用 openssl 生成一串密码后加入到 cobbler 的配置文件（/etc/cobbler/settings）里，替换 default_password_crypted 字段

[root@ cobbler ~]# openssl passwd -1 -salt `openssl rand -hex 4` '123456'
$1$random-p$mzxQ/Sx848sXgvfwJCoZM0
[root@ cobbler ~]# cobbler setting edit --name=default_password_crypted --value='$1$random-p$mzxQ/Sx848sXgvfwJCoZM0'

#9.安装fencing tools
[root@ cobbler ~]# yum -y install fence-agents

#解决完后再次检查
[root@ cobbler ~]# systemctl restart cobblerd
[root@ cobbler ~]# cobbler check
No configuration problems found.  All systems go.
```

## 1.5.4 配置DHCP

```shell
[root@ cobbler ~]# cobbler setting edit --name=manage_dhcp --value=1
[root@ cobbler ~]# vim /etc/cobbler/dhcp.template
#修改一下几处
subnet 10.0.0.0 netmask 255.255.255.0 {   #这里改为分配的网段和掩码
     option routers             10.0.0.254;  #如果有网关，这里改为网关地址
     option domain-name-servers 223.5.5.5;   #如果有DNS，这里改为DNS地址
     option subnet-mask         255.255.255.0;  #改为分配的IP的掩码
     range dynamic-bootp        10.0.0.100 10.0.0.200;  #改为分配的IP的范围

```

## 1.5.5 同步cobbler配置

```
[root@ cobbler ~]# cobbler sync
```

查看一下dhcp，查看cobbler是否可以管理`dhcp`

```shell
[root@ cobbler ~]# cat /etc/dhcp/dhcpd.conf
# ******************************************************************
# Cobbler managed dhcpd.conf file
# generated from cobbler dhcp.conf template (Sun Mar  1 11:25:17 2020)
# Do NOT make changes to /etc/dhcpd.conf. Instead, make your changes
# in /etc/cobbler/dhcp.template, as /etc/dhcpd.conf will be
# overwritten.
# ******************************************************************

ddns-update-style interim;

allow booting;
allow bootp;

ignore client-updates;
set vendorclass = option vendor-class-identifier;

option pxe-system-type code 93 = unsigned integer 16;

subnet 10.0.0.0 netmask 255.255.255.0 {
     option routers             10.0.0.254;
     option domain-name-servers 223.5.5.5;
     option subnet-mask         255.255.255.0;
     range dynamic-bootp        10.0.0.100 10.0.0.200;
     default-lease-time         21600;
     max-lease-time             43200;
     next-server                10.0.0.44;
     class "pxeclients" {
          match if substring (option vendor-class-identifier, 0, 9) = "PXEClient";
          if option pxe-system-type = 00:02 {
                  filename "ia64/elilo.efi";
          } else if option pxe-system-type = 00:06 {
                  filename "grub/grub-x86.efi";
          } else if option pxe-system-type = 00:07 {
                  filename "grub/grub-x86_64.efi";
          } else if option pxe-system-type = 00:09 {
                  filename "grub/grub-x86_64.efi";
          } else {
                  filename "pxelinux.0";
          }
     }

}

# group for Cobbler DHCP tag: default
group {
}
```

## 1.5.6 cobbler命令帮助

| 命令             | 说明                                       |
| ---------------- | ------------------------------------------ |
| cobbler check    | 核对当前设置是否有问题                     |
| cobbler list     | 列出所有的cobbler元素                      |
| cobbler report   | 列出元素的详细信息                         |
| cobbler sync     | 同步配置到数据目录，更改配置最好都执行一下 |
| cobbler reposync | 同步yum仓库                                |
| cobbler distro   | 查看导入的发行版系统信息                   |
| cobbler system   | 查看添加的系统信息                         |
| cobbler profile  | 查看配置信息                               |

这时候创建一个新虚拟机可以获取到如下信息，没有镜像选择，只能从本地启动。

![1583062308505](assets/1583062308505.png)

# 1.6 Cobbler安装centos6.8

注意：由于我这台是在`centos7`系统上面配置的`cobbler`，并没有centos6.8镜像，所以需要上传了一个`centos6.8`的镜像并进行挂载。

## 1.6.1 创建挂载点并挂载

```
[root@ cobbler ~]# ll
total 4764676
-rw-------. 1 root root       1277 2019-09-17 22:18 anaconda-ks.cfg
-rw-r--r--  1 root root 3916431360 2020-03-01 19:54 CentOS-6.8-x86_64-bin-DVD1.iso
[root@ cobbler ~]# mkdir /centos6.8
[root@ cobbler ~]# mount -o loop CentOS-6.8-x86_64-bin-DVD1.iso /centos6.8
```

## 1.6.2 查看挂载后的目录

```
[root@ cobbler kickstarts]# ls /centos6.8/
```

## 1.6.3 导入镜像

```shell
[root@ cobbler ~]# cobbler import --path=/centos6.8 --name=centos6.8 --arch=x86_64
# --path 镜像路径
# --name 为安装源定义一个名字
# --arch 指定安装源是32位、64位、ia64, 目前支持的选项有: x86│x86_64│ia64
# 安装源的唯一标示就是根据name参数来定义，本例导入成功后，安装源的唯一标示就是：centos6.8，如果重复，系统会提示导入失败。
```

## 1.6.4 查看导入后镜像信息

```shell
[root@ cobbler ~]# cobbler distro report --name=centos6.8-x86_64
Name                           : centos6.8-x86_64
Architecture                   : x86_64
TFTP Boot Files                : {}
Breed                          : redhat
Comment                        :
Fetchable Files                : {}
Initrd                         : /var/www/cobbler/ks_mirror/centos6.8-x86_64/images/pxeboot/initrd.img
Kernel                         : /var/www/cobbler/ks_mirror/centos6.8-x86_64/images/pxeboot/vmlinuz
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart Metadata             : {'tree': 'http://@@http_server@@/cblr/links/centos6.8-x86_64'}
Management Classes             : []
OS Version                     : rhel6
Owners                         : ['admin']
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Template Files                 : {}
```

## 1.6.5 查看profile信息

```
[root@ cobbler ~]# cobbler profile report --name=centos6.8-x86_64
Name                           : centos6.8-x86_64
TFTP Boot Files                : {}
Comment                        :
DHCP Tag                       : default
Distribution                   : centos6.8-x86_64
Enable gPXE?                   : 0
Enable PXE Menu?               : 1
Fetchable Files                : {}
Kernel Options                 : {}
Kernel Options (Post Install)  : {}
Kickstart                      : /var/lib/cobbler/kickstarts/sample_end.ks
Kickstart Metadata             : {}
Management Classes             : []
Management Parameters          : <<inherit>>
Name Servers                   : []
Name Servers Search Path       : []
Owners                         : ['admin']
Parent Profile                 :
Internal proxy                 :
Red Hat Management Key         : <<inherit>>
Red Hat Management Server      : <<inherit>>
Repos                          : []
Server Override                : <<inherit>>
Template Files                 : {}
Virt Auto Boot                 : 1
Virt Bridge                    : xenbr0
  rt CPUs                      : 1
Virt Disk Driver Type          : raw
Virt File Size(GB)             : 5
Virt Path                      :
Virt RAM (MB)                  : 512
Virt Type                      : kvm
```

## 1.6.6 编辑centos6.8镜像使用的kickstart文件

```shell
[root@ cobbler ~]# cd /var/lib/cobbler/kickstarts/
[root@ cobbler kickstarts]# cp sample_end.ks centos6.8.ks
[root@ cobbler kickstarts]# vim centos6.8.ks
# This kickstart file should only be used with EL > 5 and/or Fedora > 7.
# For older versions please use the sample.ks kickstart file.
# Install OS instead of upgrade
install
# Use text mode install
text
# System keyboard
keyboard us
# System language
lang en_US
# System timezone
timezone  Asia/ShangHai
#Root password
rootpw --iscrypted $default_password_crypted
# System authorization information
auth  --useshadow  --enablemd5
# Firewall configuration
firewall --disabled
# SELinux configuration
selinux --disabled
# Use network installation
url --url=$tree

# Clear the Master Boot Record
zerombr
# System bootloader configuration
bootloader --location=mbr
# Partition clearing information
clearpart --all --initlabel
part /boot --fstype=ext4 --size=200
part swap --fstype=swap --size=2048
part / --fstype=ext4 --grow --size=200 --asprimary

# If any cobbler repo definitions were referenced in the kickstart profile, include them here.
$yum_repo_stanza
# Network information
$SNIPPET('network_config')
# Do not configure the X Window System
skipx
# Run the Setup Agent on first boot
firstboot --disable
# Reboot after installation
reboot


%pre
$SNIPPET('log_ks_pre')
$SNIPPET('kickstart_start')
$SNIPPET('pre_install_network_config')
# Enable installation monitoring
$SNIPPET('pre_anamon')
%end

%packages
$SNIPPET('func_install_if_enabled')
@core
@base
tree
nmap
wget
lftp
lrzsz
telnet
%end

%post --nochroot
$SNIPPET('log_ks_post_nochroot')
%end

%post
$SNIPPET('log_ks_post')
# Start yum configuration
$yum_config_stanza
# End yum configuration
$SNIPPET('post_install_kernel_options')
$SNIPPET('post_install_network_config')
$SNIPPET('func_register_if_enabled')
$SNIPPET('download_config_files')
$SNIPPET('koan_environment')
$SNIPPET('redhat_register')
$SNIPPET('cobbler_register')
# Enable post-install boot notification
$SNIPPET('post_anamon')
# Start final steps
$SNIPPET('kickstart_done')
# End final steps

sed -ri "/^#UseDNS/c\UseDNS no" /etc/ssh/sshd_config
sed -ri "/^GSSAPIAuthentication/c\GSSAPIAuthentication no" /etc/ssh/sshd_config
%end

# 动态编辑指定使用新的kickstart文件
[root@ cobbler kickstarts]# cobbler profile edit --name=centos6.8-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos6.8.ks

# 验证是否更改成功
[root@ cobbler kickstarts]# cobbler profile report --name=centos6.8-x86_64 |grep Kickstart
Kickstart                      : /var/lib/cobbler/kickstarts/centos6.8.ks
Kickstart Metadata             : {}
```

## 1.6.7 同步cobbler配置

注意：系统镜像文件centos6.8.ks，每修改一次都要进行同步。

```
[root@ cobbler kickstarts]# cobbler sync
```



## 1.6.8 新建虚拟机进行测试

![1583067422714](assets/1583067422714.png)

用键盘方向键选择安装的系统，如果超时未选择，默认不安装，安装完后即可登录系统。





# 1.7 Cobbler安装centos7.3

由于我这里实在`centos7.3`系统上面配置的`cobbler`，所以直接挂载/dev/cdrom即可。

**以下操作可参考上边的centos6.8。**

```shell
[root@ cobbler ~]# mkdir /centos7.3
[root@ cobbler ~]# mount -o loop /dev/cdrom /centos7.3
[root@ cobbler ~]# cobbler import --path=/centos7.3 --name=centos7.3 --arch=x86_64
[root@cobbler ~]# cd /var/lib/cobbler/kickstarts/
[root@ cobbler kickstarts]# cp centos6.8.ks centos7.3.ks
#注意：centos7的系统默认的文件系统是xfs
[root@ cobbler kickstarts]# sed -i '/fstype=ext4/ s#ext4#xfs#g' centos7.3.ks
[root@ cobbler kickstarts]# cobbler profile edit --name=centos7.3-x86_64 --kickstart=/var/lib/cobbler/kickstarts/centos7.3.ks
[root@ cobbler kickstarts]# cobbler profile report --name=centos7.3-x86_64 |grep Kickstart
[root@ cobbler kickstarts]# cobbler sync
```

新建一台虚机，选择centos7.3，即可。

![1583071612973](assets/1583071612973.png)

> 如果出现/sbin/dmsquash-live-root: line 286: printf: write error: No space left on device因为内存不足2G的原因

# 1.8 cobbler Web界面配置

web界面有很多功能，包括上传镜像、编辑kickstart、等等很多在命令行操作的都可以在web界面直接操作。
在上面已经安装了cobbler-web软件，访问地址：https://IP/cobbler_web 即可。默认账号为cobbler，密码也为cobbler