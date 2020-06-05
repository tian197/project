# 配置本地镜像YUM源



## 创建挂载目录

```
mkdir -p /mnt/yum
```

## 上传centos6.8镜像

```
CentOS-6.8-x86_64-bin-DVD1.iso
```

## 挂载

```shell
mount -o loop CentOS-6.8-x86_64-bin-DVD1.iso  /mnt/yum/
```

## 创建repo文件，让yum源配置生效

```shell
cd /etc/yum.repos.d
rm -f *

cat >CentOS-6.8.repo<<EOF
[Packages]
name=centos6.8
baseurl=file:///mnt/yum
gpgcheck=0
EOF
```

## repo配置完，更新yum缓存

```shell
yum clean all
yum makecache
```

## 验证是否挂载成功

```shell
yum repolist
```

