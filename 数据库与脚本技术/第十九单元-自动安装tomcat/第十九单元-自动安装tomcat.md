[TOC]







# 第十九单元-自动安装tomcat



## 19.1 脚本安装jdk

注意：脚本中通过`cat`，追加到文件内容时，如果有特殊符号`$`，需要在`$`前加上转义符`\`。

```shell
#上传jdk-8u60-linux-x64.tar.gz到/root目录

[root@ c6m01 ~]# cd /opt/scripts/
[root@ c6m01 scripts]# vim jdk.sh
#!/bin/bash

tar -zxf /root/jdk-8u60-linux-x64.tar.gz -C /usr/local/
chown -R root.root /usr/local/jdk1.8.0_60

if [ $(grep JAVA_HOME /etc/profile|wc -l) -eq 3 ]
then
   echo "java_env is ok"
else
cat >>/etc/profile<<EOF
####java_env####
export JAVA_HOME=/usr/local/jdk1.8.0_60
export PATH=\$JAVA_HOME/bin:\$JAVA_HOME/jre/bin:\$PATH
export CLASSPATH=.\$CLASSPATH:\$JAVA_HOME/lib:\$JAVA_HOME/jre/lib:\$JAVA_HOME/lib/tools.jar
EOF
fi

source /etc/profile

```

此处有一些小问题：

发现执行`jdk.sh`脚本后，`source /etc/profile`环境变量没有生效。

```shell
[root@ c6m01 scripts]# sh jdk.sh

[root@ c6m01 ~]# java -version
-bash: java: command not found
```

**解决如下：**

**方法一：**

脚本中声明的环境变量时已经生效了，只是当前的`xshell`或`crt`等终端的`bash`环境没有生效，需要重新连接`xshell`或`crt`连接终端，即可生效。

**方法二：**

改变执行脚本的方式，通过`source`执行脚本，`source jdk.sh`即可。





## 19.2 脚本安装单实例tomcat

上传`apache-tomcat-7.0.47.tar.gz`到`/root`目录。

```shell
[root@ c6m01 ~]# cd /opt/scripts/
[root@ c6m01 scripts]# vim tomcat.sh
#!/bin/bash

tar -zxf /root/apache-tomcat-7.0.47.tar.gz -C /usr/local/
/usr/local/apache-tomcat-7.0.47/bin/startup.sh

```





## 19.3 批量安装tomcat

ssh批量部署的方法，设置批量部署的ip地址，并将jdk与tomcat以及全自动安装脚本准备好，修改批量部署的脚本即可。

> 注意：前提是需要做好ssh免密码登录。

```shell
[root@ c6m01 ~]# cd /opt/scripts/
[root@ c6m01 scripts]# vim many_tomcat.sh
#!/bin/bash

jdk='jdk-8u60-linux-x64.tar.gz'
tomcat='apache-tomcat-7.0.47.tar.gz'

iplist=(10.0.0.22)


for ip in ${iplist[*]}
do
    scp /root/$jdk  root@$ip:/root/
    scp /root/$tomcat  root@$ip:/root/
    ssh root@$ip </opt/scripts/jdk.sh
    ssh root@$ip </opt/scripts/tomcat.sh
done

```























