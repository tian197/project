#安装Apache
yum -y install httpd

#启动
/etc/init.d/httpd start

#查看httpd进程
ps -ef|grep httpd		

#查看httpd端口号
ss -lntp|grep 80

#添加到开机自启动
chkconfig httpd on

##客户端测试
浏览器访问测试：http://10.0.0.21:80

##安装elinks测试
yum -y install elinks
elinks http://10.0.0.21:80

#通过curl测试
[root@ c6m01 ~]# curl http://10.0.0.21:80/index.html
this is bw
this is bw
[root@ c6m01 ~]# curl http://10.0.0.21
this is bw
this is bw
[root@ c6m01 ~]# curl http://10.0.0.21:80
this is bw
this is bw


#ab 命令压力测试
注意：-c参数指定的数量一定要小于-n参数指定的
ab -c 500 -n 1000 http://10.0.0.21














