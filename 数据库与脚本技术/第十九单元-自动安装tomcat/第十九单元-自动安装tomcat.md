[TOC]







# 第十九单元-自动安装tomcat





**脚本安装jdk：**

```
[root@ c6m01 scripts]# cat jdk.sh
#!/bin/bash

tar -zxvf /root/jdk-8u60-linux-x64.tar.gz -C /usr/local/
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

发现执行jdk.sh脚本后，`source /etc/profile`环境变量没有生效。

```shell
[root@ c6m01 scripts]# sh jdk.sh

[root@ c6m01 ~]# java -version
-bash: java: command not found
```

解决如下：

方法一：

脚本中声明的环境变量时已经生效了，只是当前的xshell或crt等终端的bash环境没有生效，需要重新连接xshell或crt连接终端，即可生效。

方法二：

改变执行脚本的方式，通过source执行脚本，`source jdk.sh`即可。

