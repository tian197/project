#安装
yum install -y vsftpd

#启动
/etc/init.d/vsftpd start

#查看vsftp进程状态
/etc/init.d/vsftpd status

#设置开机自启
chkconfig vsftpd on

#关闭防火墙和Selinux
service iptables stop
setenforce 0

#精简查看配置文件
cd /etc/vsftpd
egrep -v '^$|^#' vsftpd.conf
anonymous_enable=YES
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
xferlog_enable=YES
connect_from_port_20=YES
xferlog_std_format=YES
listen=YES
pam_service_name=vsftpd
userlist_enable=YES
tcp_wrappers=YES



#查看vsftp进程
ps -ef|grep vsftpd

#查看vsftp端口
ss -lntp|grep vsftpd

####启动后就可以进行，匿名用户测试，默认只有查看和下载权限。

#让匿名用户有增删改权限
cd /etc/vsftpd
####
vim vsftpd.conf

anon_root=/var/ftp
anon_upload_enable=YES
anon_mkdir_write_enable=YES
anon_other_write_enable=YES

#给匿名用户共享目录提权
chmod -R o+w /var/ftp/

#重启
/etc/init.d/vsftpd restart



#### ftp本地用户配置和测试

#创建tom用户，并设置密码为123456
useradd   tom
echo '123456'|passwd --stdin tom

#修改配置文件
cd /etc/vsftpd
vim	vsftpd.conf

local_root=/home/tom

#重启
/etc/init.d/vsftpd restart




####linux中权限了解
chmod 777 www
r----读----4
w----写----2
x----可执行----1












