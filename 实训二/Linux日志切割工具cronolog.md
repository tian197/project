# Linux日志切割工具cronolog详解

[TOC]



# 一、前言

大家都知道apache服务器，默认日志文件是不分割的，一个整文件既不易于管理，也不易于分析统计。本博文主要讲解Web服务器日志切割工具cronolog，下面我们就来详细的讲解一下。



# 二、cronolog 简介

```
Welcome to cronolog.org, the home of the cronolog web log rotation program.cronolog is a simple filter program that reads log file entries from standard input and writes each entry to the output file specified by a filename template and the current date and time. When the expanded filename changes, the current file is closed and a new one opened. cronolog is intended to be used in conjunction with a Web server, such as Apache, to split the access log into daily or monthly logs.
```



cronolog 是一个简单的过滤程序，读取日志文件条目从标准输入和输出的每个条目并写入指定的日志文件的文件名模板和当前的日期和时间。当扩展文件名的变化，目前的文件是关闭，新开辟的。cronolog 旨在和一个Web服务器一起使用，如Apache，分割访问日志为每天或每月的日志。



# 三、cronolog 特点

cronolog主要和Web服务器配置使用，特别是Apache服务器，Apache 默认日志文件是不分割的，一个整文件既不易于管理，也不易于分析统计。安装cronolog后，可以将日志文件按时间分割，易于管理和分析。下面是与Apache配置的一些指令：

TransferLog "|/usr/sbin/cronolog /web/logs/%Y/%m/%d/access.log"

ErrorLog    "|/usr/sbin/cronolog /web/logs/%Y/%m/%d/errors.log"

下面是具体案例，

/web/logs/2002/12/31/access.log/web/logs/2002/12/31/errors.log

/web/logs/2003/01/01/access.log/web/logs/2003/01/01/errors.log



# 四、cronolog 安装

1.安装yum源

```
[root@node6 src]# yum install -y wget vim
[root@node6 src]# wget http://ftp.sjtu.edu.cn/fedora/epel/6/i386/epel-release-6-8.noarch.rpm
[root@node6 src]# rpm -ivh epel-release-6-8.noarch.rpm
warning: epel-release-6-8.noarch.rpm: Header V3 RSA/SHA256 Signature, key ID 0608b895: NOKEY
Preparing...                ########################################### [100%]
   1:epel-release           ########################################### [100%]
```

2.安装ntp

```
[root@node6 src]# yum install -y ntp
```

3.时间同步

```
[root@node6 src]# ntpdate 202.120.2.101
28 Dec 17:59:17 ntpdate[1413]: step time server 202.120.2.101 offset -25666.776448 sec
```

4.安装cronolog

(1).直接用yum安装

```
[root@node6 src]# yum install -y cronolog httpd
```

(2).源码安装

```
[root@node6 src]# wget http://cronolog.org/download/cronolog-1.6.2.tar.gz
[root@node6 src]# tar xf cronolog-1.6.2.tar.gz
[root@node6 src]# cd cronolog-1.6.2
[root@node6 cronolog-1.6.2]# ./configure
[root@node6 cronolog-1.6.2]# make && make install
[root@localhost ~]# which cronolog
/usr/local/sbin/cronolog
```

好了，到这里我们的cronolog就安装完成了，下面我们来说一下cronolog如何使用。

# 五、cronolog 使用

(1).基本使用

```
[root@node6 ~]# cronolog -h

usage: cronolog [OPTIONS] logfile-spec
   -H NAME,   --hardlink=NAME maintain a hard link from NAME to current log
   -S NAME,   --symlink=NAME  maintain a symbolic link from NAME to current log
   -P NAME,   --prev-symlink=NAME  maintain a symbolic link from NAME to previous log
   -l NAME,   --link=NAME     same as -S/--symlink
   -h,        --help          print this help, then exit
   -p PERIOD, --period=PERIOD set the rotation period explicitly
   -d DELAY,  --delay=DELAY   set the rotation period delay
   -o,        --once-only     create single output log from template (not rotated)
   -x FILE,   --debug=FILE    write debug messages to FILE
​                              ( or to standard error if FILE is "-")

   -a,        --american         American date formats
   -e,        --european         European date formats (default)
   -s,    --start-time=TIME   starting time
   -z TZ, --time-zone=TZ      use TZ for timezone
   -V,      --version         print version number, then exit
```

cronolog 一般是采取管道的方式来工作的，采用如下的形式：

```
[root@node6 ~]# loggenerator | cronolog log_file_pattern
```

其中，loggenerator为产生log的程序，而log_file_pattern是日志文件的路径，可以在其中加入cronolog所支持的时间相关的pattern字符，如/www/log/%y/%m/%d/access.log。其pattern为％字符后跟一特殊字符，简述如下：

转义符:  

%    %字符

n    换行

t    水平制表符

时间域:  

H    小时(00..23)

I    小时(01..12)

p    该locale下的AM或PM标识

M    分钟(00..59)

S    秒 (00..61, which allows for leap seconds)

X    该locale下时间表示符(e.g.: "15:12:47")

Z    时区。若时区不能确定，则无意义

日期域:  

a    该locale下的工作日简名(e.g.: Sun..Sat)

A    该locale下的工作日全名(e.g.: Sunday ..  Satur-ay)

b    该locale下的月份简称(e.g.: Jan .. Dec)

B    该locale下的月份全称(e.g.:  January .. December)

c    该locale下的日期和时间(e.g.: "Sun Dec 15  14:12:47 GMT 1996")

d    当月中的天数 (01 .. 31)

j    当年中的天数 (001 .. 366)

m    月数 (01 .. 12)

U    当年中的星期数，以周日作为一周开始,其中第一周为首个含星期天的星期(00..53)

W    当年中的星期数，以星期一作为一周的开始,其中第一周为首个含星期天的星期(00..53)

w    工作日数(0 .. 6, 0表示星期天)

x    该locale下的日期表示(e.g. "13/04/97")

y    两位数的年份(00 .. 99)

Y    四位数的年份(1970 .. 2038)

(2).切割apache日志

编辑httpd.conf文件，将其中的

```
[root@localhost ~]# vim /usr/local/apache2/conf/httpd.conf
```

将默认日志： CustomLog "logs/access_log" combined

修改为：CustomLog "|/usr/local/sbin/cronolog /log/www/access_%Y%m%d.log" combined 即可。其中%Y%m%d为日志文件分割方式，即为“年月日”。

```
[root@localhost ~]# /usr/local/apache2/bin/apachectl restart
```

(3).下面是效果

```
[root@localhost ~]# cd /log/www/

[root@localhost www]# ll
total 15072
-rw-r--r-- 1 root root   16028 Dec 26 15:16 access_20131225.log
-rw-r--r-- 1 root root 2406307 Dec 26 23:59 access_20131226.log
-rw-r--r-- 1 root root 8292792 Dec 27 23:59 access_20131227.log
-rw-r--r-- 1 root root 4682211 Dec 28 18:56 access_20131228.log
```

# 六、cronolog 总结

好了，到这里我们的cronolog工具就讲解完成了。有博友会问为什么不用apache自带的日志分割工具？apache自带的日志分割工具rotatelogs，据专家说在进行日志切割时容易丢日志，所以这里我们就用cronolog来做日志切割。