

# Supervisor管理集群

文档：supervisor进程管理.note
链接：http://note.youdao.com/noteshare?id=e10ef4356add0c9d694ecb373fb403c3&sub=D31D963E5127467F915F5F85B745DDE8

## 应用场景

​	公司服务器众多，项目多以tomcat为主，而且服务器上tomcat节点比较多，此时通过脚本管理tomcat已经非常棘手，就需要一个统一的进程管理工具去统一管理项目。

## centos7 安装配置supervisor

```bash
systemctl   stop   firewalld.service
systemctl   disable firewalld.service

setenforce 0
sed -i  '/^SELINUX/s#enforcing#disabled#g' /etc/selinux/config

yum install -y wget 
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
yum clean all
yum makecache

yum -y install gcc gcc-c++  cmake curl  nmap  lrzsz unzip zip ntpdate telnet vim tree bash-completion iptables-services ntp dos2unix lsof net-tools sysstat

echo "*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1">>/var/spool/cron/root


#安装supervisor
yum -y install supervisor

#设置开机自启
systemctl enable supervisord.service


#配置jdk环境
tar -zxvf jdk-8u60-linux-x64.tar.gz -C /usr/local/
chown -R root.root /usr/local/jdk1.8.0_60
cat>>/etc/profile<<EOF
export JAVA_HOME=/usr/local/jdk1.8.0_60
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
export CLASSPATH=.\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib/tools.jar
EOF

source /etc/profile
java -version


#安装tomcat
tar -zxvf apache-tomcat-7.0.47.tar.gz
mkdir -p /opt/tomcat01
cp -a apache-tomcat-7.0.47/* /opt/tomcat01/


#通过supervisor管理tomcat

#创建supervisor管理tomcat的子配置文件
vim /etc/supervisord.d/tomcat01.ini
[program:tomcat01]
command=/opt/tomcat01/bin/catalina.sh run
environment=JAVA_HOME="/usr/local/jdk1.8.0_60",JAVA_BIN="/usr/local/jdk1.8.0_60/bin"


#常用supervisorctl命令
supervisorctl status
supervisorctl stop tomcat
supervisorctl start tomcat
supervisorctl restart tomcat
supervisorctl reread
supervisorctl update
```

