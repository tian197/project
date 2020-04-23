# YUM仓库配置与使用

## 应用场景

在项目实施过程中，很多实施单位存在没有外网的情况。此时，在服务器上直接使用Yum命令根本无法使用，为了方便在本地搭建环境，为了方便快捷安装软件依赖包，我们采用临时解决方案进行本地Yum仓库搭建，不但可以供搭建机器使用，更可以供整个服务器群使用。



## yum仓库搭建

### 服务端搭建

**1.1 修改yum配置文件**

yum下载软件不清空

```shell
sed -i 's#keepcache=0#keepcache=1#g' /etc/yum.conf
```



**1.2 创建目录用来做 YUM 仓库的使用**

```shell
mkdir -p /yum/centos7
```



**1.3 安装 createrepo 软件，用于生成 yum 仓库数据库的软件**

```shell
yum -y install createrepo   yum-utils 
```



**1.4 初始化repodata索引文件**

```shell
cd /yum/centos7

# 只下载软件不安装
yumdownloader tree

#更新repodata索引文件
createrepo -pdo /yum/centos7/ /yum/centos7/
```



**1.5提供yum服务**

可以用Apache或nginx提供web服务，但用Python的http模块更简单，适用于内网环境

```shell
cd /yum/centos7/
python -m SimpleHTTPServer 81 &>/dev/null &
```

可以通过浏览器输入本机IP查看: 如http://10.0.0.41:81/



**1.6添加新的rpm包**

```shell
# 只下载软件不安装
yumdownloader pcre-devel openssl-devel 

# 每加入一个rpm包就要更新一下
createrepo --update /yum/centos7/
```



### 客户端配置

```shell
mv /etc/yum.repos.d/epel.repo /etc/yum.repos.d/epel.repo.ori

cat >/etc/yum.repos.d/centos7.repo<<EOF
[centos7]
name=Server
baseurl=http://10.0.0.41:81
enable=1
gpgcheck=0
EOF
```

**临时使用指定的自己指定的centos7 库**

```shell
yum --enablerepo=centos7 --disablerepo=base,extras,updates,epel list
```

**永久使用**

```shell
sed -i -e '19a enabled=0' -e '29a enabled=0' -e '39a enabled=0' /etc/yum.repos.d/CentOS-Base.repo
```

### 测试下载

注释`/etc/resolv.conf`

```bash
[root@ c7-42 yum.repos.d]# cat /etc/resolv.conf
#nameserver 223.5.5.5
#nameserver 223.6.6.6

[root@ c7-42 yum.repos.d]# ping qq.com
ping: qq.com: Name or service not known
```

服务端安装nginx或者找nginx相关rpm

```
[root@ c7-41 centos7]# yum -y install nginx
```

找到nginx所有的相关rpm

```bash
[root@ c7-41 7]# cd /var/cache/yum/x86_64/7/
[root@ c7-41 7]# find . -name '*.rpm'
./base/packages/createrepo-0.9.9-28.el7.noarch.rpm
./base/packages/deltarpm-3.6-3.el7.x86_64.rpm
./base/packages/python-chardet-2.2.1-3.el7.noarch.rpm
./base/packages/yum-utils-1.1.31-52.el7.noarch.rpm
./base/packages/python-deltarpm-3.6-3.el7.x86_64.rpm
./base/packages/python-kitchen-1.1.1-5.el7.noarch.rpm
./base/packages/centos-indexhtml-7-9.el7.centos.noarch.rpm
./base/packages/dejavu-fonts-common-2.33-6.el7.noarch.rpm
./base/packages/dejavu-sans-fonts-2.33-6.el7.noarch.rpm
./base/packages/fontconfig-2.13.0-4.3.el7.x86_64.rpm
./base/packages/fontpackages-filesystem-1.44-8.el7.noarch.rpm
./base/packages/gd-2.0.35-26.el7.x86_64.rpm
./base/packages/gperftools-libs-2.6.1-1.el7.x86_64.rpm
./base/packages/libX11-1.6.7-2.el7.x86_64.rpm
./base/packages/libX11-common-1.6.7-2.el7.noarch.rpm
./base/packages/libXau-1.0.8-2.1.el7.x86_64.rpm
./base/packages/libXpm-3.5.12-1.el7.x86_64.rpm
./base/packages/libxcb-1.13-1.el7.x86_64.rpm
./epel/packages/nginx-1.16.1-1.el7.x86_64.rpm
./epel/packages/nginx-all-modules-1.16.1-1.el7.noarch.rpm
./epel/packages/nginx-filesystem-1.16.1-1.el7.noarch.rpm
./epel/packages/nginx-mod-http-image-filter-1.16.1-1.el7.x86_64.rpm
./epel/packages/nginx-mod-http-perl-1.16.1-1.el7.x86_64.rpm
./epel/packages/nginx-mod-http-xslt-filter-1.16.1-1.el7.x86_64.rpm
./epel/packages/nginx-mod-mail-1.16.1-1.el7.x86_64.rpm
./epel/packages/nginx-mod-stream-1.16.1-1.el7.x86_64.rpm
```

然后，添加到自己的yum仓库

```bash
[root@ c7-41 7]# find . -name '*.rpm'|xargs -i cp {} /yum/centos7
```

更新自己的yum仓库

```bash
[root@ c7-41 centos7]# cd /yum/centos7/
[root@ c7-41 centos7]# createrepo --update /yum/centos7/
```

客户端重新加载yum缓存并下载nginx

```shell
yum clean all
yum makecache
yum -y install nginx
```



