# docker命令

[toc]

## 容器生命周期管理
### run

    docker run ：创建一个新的容器并运行一个命令
语法
```
docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
OPTIONS说明：
Usage: docker run [OPTIONS] IMAGE [COMMAND] [ARG...]    
  
  -d, --detach=false         指定容器运行于前台还是后台，默认为false     
  -i, --interactive=false   打开STDIN，用于控制台交互    
  -t, --tty=false            分配tty设备，该可以支持终端登录，默认为false    
  -u, --user=""              指定容器的用户    
  -a, --attach=[]            登录容器（必须是以docker run -d启动的容器）  
  -w, --workdir=""           指定容器的工作目录   
  -c, --cpu-shares=0        设置容器CPU权重，在CPU共享场景使用    
  -e, --env=[]               指定环境变量，容器中可以使用该环境变量    
  -m, --memory=""            指定容器的内存上限    
  -P, --publish-all=false    指定容器暴露的端口    
  -p, --publish=[]           指定容器暴露的端口   
  -h, --hostname=""          指定容器的主机名    
  -v, --volume=[]            给容器挂载存储卷，挂载到容器的某个目录    
  --volumes-from=[]          给容器挂载其他容器上的卷，挂载到容器的某个目录  
  --cap-add=[]               添加权限，权限清单详见：http://linux.die.net/man/7/capabilities    
  --cap-drop=[]              删除权限，权限清单详见：http://linux.die.net/man/7/capabilities    
  --cidfile=""               运行容器后，在指定文件中写入容器PID值，一种典型的监控系统用法    
  --cpuset=""                设置容器可以使用哪些CPU，此参数可以用来容器独占CPU    
  --device=[]                添加主机设备给容器，相当于设备直通    
  --dns=[]                   指定容器的dns服务器    
  --dns-search=[]            指定容器的dns搜索域名，写入到容器的/etc/resolv.conf文件    
  --entrypoint=""            覆盖image的入口点    
  --env-file=[]              指定环境变量文件，文件格式为每行一个环境变量    
  --expose=[]                指定容器暴露的端口，即修改镜像的暴露端口    
  --link=[]                  指定容器间的关联，使用其他容器的IP、env等信息    
  --lxc-conf=[]              指定容器的配置文件，只有在指定--exec-driver=lxc时使用    
  --name=""                  指定容器名字，后续可以通过名字进行容器管理，links特性需要使用名字    
  --net="bridge"             容器网络设置:  
                                bridge 使用docker daemon指定的网桥       
                                host    //容器使用主机的网络    
                                container:NAME_or_ID  >//使用其他容器的网路，共享IP和PORT等网络资源    
                                none 容器使用自己的网络（类似--net=bridge），但是不进行配置   
  --privileged=false         指定容器是否为特权容器，特权容器拥有所有的capabilities    
  --restart="no"             指定容器停止后的重启策略:  
                                no：容器退出时不重启    
                                on-failure：容器故障退出（返回值非零）时重启   
                                always：容器退出时总是重启    
  --rm=false                 指定容器停止后自动删除容器(不支持以docker run -d启动的容器)    
  --sig-proxy=true           设置由代理接受并处理信号，但是SIGCHLD、SIGSTOP和SIGKILL不能被代理 
```
> 实例
使用docker镜像nginx:latest以后台模式启动一个容器,并将容器命名为mynginx。

    docker run --name mynginx -d nginx:latest
使用镜像nginx:latest以后台模式启动一个容器,并将容器的80端口映射到主机随机端口。

    docker run -P -d nginx:latest
使用镜像nginx:latest以后台模式启动一个容器,将容器的80端口映射到主机的80端口,主机的目录/data映射到容器的/data。

    docker run -p 80:80 -v /data:/data -d nginx:latest
使用镜像nginx:latest以交互模式启动一个容器,在容器内执行/bin/bash命令。
```
runoob@runoob:~$ docker run -it nginx:latest /bin/bash
root@b8573233d675:/#
```

### start/stop/restart
```
docker start :启动一个或多少已经被停止的容器
docker stop :停止一个运行中的容器
docker restart :重启容器
```
语法
```
docker start [OPTIONS] CONTAINER [CONTAINER...]
docker stop [OPTIONS] CONTAINER [CONTAINER...]
docker restart [OPTIONS] CONTAINER [CONTAINER...]
```
实例
```
启动已被停止的容器myrunoob
docker start myrunoob
停止运行中的容器myrunoob
docker stop myrunoob
重启容器myrunoob
docker restart myrunoob
```
### kill

    docker kill :杀掉一个运行中的容器。
语法

    docker kill [OPTIONS] CONTAINER [CONTAINER...]
OPTIONS说明：
-s :向容器发送一个信号
实例
杀掉运行中的容器mynginx

    runoob@runoob:~$ docker kill -s KILL mynginx

### rm

    docker rm ：删除一个或多少容器
语法
```
docker rm [OPTIONS] CONTAINER [CONTAINER...]
OPTIONS说明：
-f :通过SIGKILL信号强制删除一个运行中的容器
-l :移除容器间的网络连接，而非容器本身
-v :-v 删除与容器关联的卷
```
实例
```
强制删除容器db01、db02
docker rm -f db01、db02
移除容器nginx01对容器db01的连接，连接名db
docker rm -l db 
删除容器nginx01,并删除容器挂载的数据卷
docker rm -v nginx01
```

### pause/unpause
```
docker pause :暂停容器中所有的进程。
docker unpause :恢复容器中所有的进程。
```
语法
```
docker pause [OPTIONS] CONTAINER [CONTAINER...]
docker unpause [OPTIONS] CONTAINER [CONTAINER...]
```
实例
```
暂停数据库容器db01提供服务。
docker pause db01
恢复数据库容器db01提供服务。
docker unpause db01
```

### create

    docker create ：创建一个新的容器但不启动它
用法同 docker run
语法

    docker create [OPTIONS] IMAGE [COMMAND] [ARG...]
语法同 docker run
> 实例
```
使用docker镜像nginx:latest创建一个容器,并将容器命名为myrunoob
runoob@runoob:~$ docker create  --name myrunoob  nginx:latest
```

### exec

    docker exec ：在运行的容器中执行命令
语法

    docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
OPTIONS说明：
```
-d :分离模式: 在后台运行
-i :即使没有附加也保持STDIN 打开
-t :分配一个伪终端
```
实例
```
在容器mynginx中以交互模式执行容器内/root/runoob.sh脚本
runoob@runoob:~$ docker exec -it mynginx /bin/sh /root/runoob.sh
http://www.runoob.com/
在容器mynginx中开启一个交互模式的终端
runoob@runoob:~$ docker exec -i -t  mynginx /bin/bash
root@b1a0703e41e7:/#
```

## 容器操作
### ps

    docker ps : 列出容器
语法

    docker ps [OPTIONS]
OPTIONS说明：
```
-a :显示所有的容器，包括未运行的。
-f :根据条件过滤显示的内容。
--format :指定返回值的模板文件。
-l :显示最近创建的容器。
-n :列出最近创建的n个容器。
--no-trunc :不截断输出。
-q :静默模式，只显示容器编号。
-s :显示总的文件大小。
```
实例
```
列出所有在运行的容器信息。
runoob@runoob:~$ docker ps
CONTAINER ID   IMAGE           COMMAND                   PORTS        NAMES
09b93464c2f7   nginx:latest   "nginx -g 'daemon off"  80/tcp, 443/tcp myrunoob
96f7f14e99ab   mysql:5.6      "docker-entrypoint.sh" 0.0.0.0:3306->3306/tcp   mymysql
列出最近创建的5个容器信息。
runoob@runoob:~$ docker ps -n 5
CONTAINER ID        IMAGE               COMMAND                   CREATED           
09b93464c2f7        nginx:latest        "nginx -g 'daemon off"    2 days ago   ...     
b8573233d675        nginx:latest        "/bin/bash"               2 days ago   ...     
b1a0703e41e7        nginx:latest        "nginx -g 'daemon off"    2 days ago   ...    
f46fb1dec520        5c6e1090e771        "/bin/sh -c 'set -x \t"   2 days ago   ...   
a63b4a5597de        860c279d2fec        "bash"                    2 days ago   ...
列出所有创建的容器ID。
runoob@runoob:~$ docker ps -a -q
09b93464c2f7
```

### inspect

    docker inspect : 获取容器/镜像的元数据。
语法

    docker inspect [OPTIONS] NAME|ID [NAME|ID...]
OPTIONS说明：
```
-f :指定返回值的模板文件。
-s :显示总的文件大小。
--type :为指定类型返回JSON。
```
> 实例

```
获取镜像mysql:5.6的元信息。
runoob@runoob:~$ docker inspect mysql:5.6
[
    {
        "Id": "sha256:2c0964ec182ae9a045f866bbc2553087f6e42bfc16074a74fb820af235f070ec",
        "RepoTags": [
            "mysql:5.6"
        ],
        "RepoDigests": [],
        "Parent": "",
        "Comment": "",
        "Created": "2016-05-24T04:01:41.168371815Z",
        "Container": "e0924bc460ff97787f34610115e9363e6363b30b8efa406e28eb495ab199ca54",
        "ContainerConfig": {
            "Hostname": "b0cf605c7757",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "ExposedPorts": {
                "3306/tcp": {}
            },
...
获取正在运行的容器mymysql的 IP。
runoob@runoob:~$ docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' mymysql
172.17.0.3
```
### top

    docker top :查看容器中运行的进程信息，支持 ps 命令参数。
语法

    docker top [OPTIONS] CONTAINER [ps OPTIONS]
容器运行时不一定有/bin/bash终端来交互执行top命令，而且容器还不一定有top命令，可以使用docker top来实现查看container中正在运行的进程。

> 实例
```
查看容器mymysql的进程信息。
runoob@runoob:~/mysql$ docker top mymysql
UID    PID    PPID    C      STIME   TTY  TIME       CMD
999    40347  40331   18     00:58   ?    00:00:02   mysqld
查看所有运行容器的进程信息。
for i in  `docker ps |grep Up|awk '{print $1}'`;do echo \ &&docker top $i; done
```

### attach

    docker attach :连接到正在运行中的容器。
语法

    docker attach [OPTIONS] CONTAINER
要attach上去的容器必须正在运行，可以同时连接上同一个container来共享屏幕（与screen命令的attach类似）。
官方文档中说attach后可以通过CTRL-C来detach，但实际上经过我的测试，如果container当前在运行bash，CTRL-C自然是当前行的输入，没有退出；如果container当前正在前台运行进程，如输出nginx的access.log日志，CTRL-C不仅会导致退出容器，而且还stop了。这不是我们想要的，detach的意思按理应该是脱离容器终端，但容器依然运行。好在attach是可以带上--sig-proxy=false来确保CTRL-D或CTRL-C不会关闭容器。
> 实例

```
容器mynginx将访问日志指到标准输出，连接到容器查看访问信息。
runoob@runoob:~$ docker attach --sig-proxy=false mynginx
192.168.239.1 - - [10/Jul/2016:16:54:26 +0000] "GET / HTTP/1.1" 304 0 "-" "Mozilla/5.0 (Windows NT 
```

### events

    docker events : 从服务器获取实时事件
语法

    docker events [OPTIONS]
OPTIONS说明：
```
-f ：根据条件过滤事件；
--since ：从指定的时间戳后显示所有事件;
--until ：流水时间显示到指定的时间为止；
```
实例
```
显示docker 2016年7月1日后的所有事件。
runoob@runoob:~/mysql$ docker events  --since="1467302400"
2016-07-08T19:44:54.501277677+08:00 network connect 66f958fd13dc4314ad20034e576d5c5eba72e0849dcc38ad9e8436314a4149d4 

显示docker 镜像为mysql:5.6 2016年7月1日后的相关事件。
runoob@runoob:~/mysql$ docker events -f "image"="mysql:5.6" --since="1467302400" 
2016-07-11T00:38:53.975174837+08:00 container start 
如果指定的时间是到秒级的，需要将时间转成时间戳。如果时间为日期的话，可以直接使用，如--since="2016-07-01"。
```

### logs

    docker logs : 获取容器的日志

语法
```
docker logs [OPTIONS] CONTAINER
OPTIONS说明：
-f : 跟踪日志输出
--since :显示某个开始时间的所有日志
-t : 显示时间戳
--tail :仅列出最新N条容器日志
```
实例
```
跟踪查看容器mynginx的日志输出。
runoob@runoob:~$ docker logs -f mynginx
查看容器mynginx从2016年7月1日后的最新10条日志。
docker logs --since="2016-07-01" --tail=10 mynginx
```

### wait

    docker wait : 阻塞运行直到容器停止，然后打印出它的退出代码。
语法

    docker wait [OPTIONS] CONTAINER [CONTAINER...]
实例

    docker wait CONTAINER


### export

    docker export :将文件系统作为一个tar归档文件导出到STDOUT。
语法

    docker export [OPTIONS] CONTAINER
OPTIONS说明：
-o :将输入内容写到文件。
实例
```
将id为a404c6c174a2的容器按日期保存为tar文件。
runoob@runoob:~$ docker export -o mysql-`date +%Y%m%d`.tar a404c6c174a2
runoob@runoob:~$ ls mysql-`date +%Y%m%d`.tar
mysql-20160711.tar
```
### port

    docker port :列出指定的容器的端口映射，或者查找将PRIVATE_PORT NAT到面向公众的端口。
语法

    docker port [OPTIONS] CONTAINER [PRIVATE_PORT[/PROTO]]
实例
```
查看容器mynginx的端口映射情况。
runoob@runoob:~$ docker port mymysql
3306/tcp -> 0.0.0.0:3306
```

## 容器rootfs命令
### commit

    docker commit :从容器创建一个新的镜像。
语法

    docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
OPTIONS说明：
```
-a :提交的镜像作者；
-c :使用Dockerfile指令来创建镜像；
-m :提交时的说明文字；
-p :在commit时，将容器暂停。
```
实例
```
将容器a404c6c174a2 保存为新的镜像,并添加提交人信息和说明信息。
runoob@runoob:~$ docker commit -a "runoob.com" -m "my apache" a404c6c174a2  mymysql:v1 
sha256:37af1236adef1544e8886be23010b66577647a40bc02c0885a6600b33ee28057
runoob@runoob:~$ docker images mymysql:v1
```

### cp

    docker cp :用于容器与主机之间的数据拷贝。
语法

    docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH|-
    docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH
OPTIONS说明：
-L :保持源目标中的链接
实例
```
将主机/www/runoob目录拷贝到容器96f7f14e99ab的/www目录下。
docker cp /www/runoob 96f7f14e99ab:/www/
将主机/www/runoob目录拷贝到容器96f7f14e99ab中，目录重命名为www。
docker cp /www/runoob 96f7f14e99ab:/www
将容器96f7f14e99ab的/www目录拷贝到主机的/tmp目录中。
docker cp  96f7f14e99ab:/www /tmp/
```

### diff

    docker diff : 检查容器里文件结构的更改。
语法

    docker diff [OPTIONS] CONTAINER
实例
```
查看容器mymysql的文件结构更改。
runoob@runoob:~$ docker diff mymysql
```

## 镜像仓库
### login
docker login : 登陆到一个Docker镜像仓库，如果未指定镜像仓库地址，默认为官方仓库 Docker Hub
docker logout : 登出一个Docker镜像仓库，如果未指定镜像仓库地址，默认为官方仓库 Docker Hub
语法
```
docker login [OPTIONS] [SERVER]
docker logout [OPTIONS] [SERVER]
OPTIONS说明：
-u :登陆的用户名
-p :登陆的密码
```
实例
```
登陆到Docker Hub
docker login -u 用户名 -p 密码
登出Docker Hub
docker logout
```

### pull

    docker pull : 从镜像仓库中拉取或者更新指定镜像
语法

    docker pull [OPTIONS] NAME[:TAG|@DIGEST]
OPTIONS说明：
-a :拉取所有 tagged 镜像
--disable-content-trust :忽略镜像的校验,默认开启
实例
```
从Docker Hub下载java最新版镜像。
docker pull java
从Docker Hub下载REPOSITORY为java的所有镜像。
docker pull -a java
```
### push

    docker push : 将本地的镜像上传到镜像仓库,要先登陆到镜像仓库
语法

    docker push [OPTIONS] NAME[:TAG]
OPTIONS说明：
--disable-content-trust :忽略镜像的校验,默认开启
实例
```
上传本地镜像myapache:v1到镜像仓库中。
docker push myapache:v1
```
### search

    docker search : 从Docker Hub查找镜像
语法

    docker search [OPTIONS] TERM
OPTIONS说明：
```
--automated :只列出 automated build类型的镜像；
--no-trunc :显示完整的镜像描述；
-s :列出收藏数不小于指定值的镜像。
```
实例
```
从Docker Hub查找所有镜像名包含java，并且收藏数大于10的镜像
runoob@runoob:~$ docker search -s 10 java
```

## 本地镜像管理
### images

    docker images : 列出本地镜像。
语法

    docker images [OPTIONS] [REPOSITORY[:TAG]]
OPTIONS说明：
```
-a :列出本地所有的镜像（含中间映像层，默认情况下，过滤掉中间映像层）；
--digests :显示镜像的摘要信息；
-f :显示满足条件的镜像；
--format :指定返回值的模板文件；
--no-trunc :显示完整的镜像信息；
-q :只显示镜像ID。
```
实例
```
查看本地镜像列表。
runoob@runoob:~$ docker images
列出本地镜像中REPOSITORY为ubuntu的镜像列表。
root@runoob:~# docker images  ubuntu
```

### rmi

    docker rmi : 删除本地一个或多少镜像。
语法

    docker rmi [OPTIONS] IMAGE [IMAGE...]
OPTIONS说明：
```
-f :强制删除；
--no-prune :不移除该镜像的过程镜像，默认移除；
```
实例
```
强制删除本地镜像runoob/ubuntu:v4。
root@runoob:~# docker rmi -f runoob/ubuntu:v
```

### tag

    docker tag : 标记本地镜像，将其归入某一仓库。
语法

    docker tag [OPTIONS] IMAGE[:TAG] [REGISTRYHOST/][USERNAME/]NAME[:TAG]
实例
```
将镜像ubuntu:15.10标记为 runoob/ubuntu:v3 镜像。
root@runoob:~# docker tag ubuntu:15.10 runoob/ubuntu:v3
root@runoob:~# docker images   runoob/ubuntu:v3
```

### build

    docker build : 使用Dockerfile创建镜像。
语法

    docker build [OPTIONS] PATH | URL | -
OPTIONS说明：
```
--build-arg=[] :设置镜像创建时的变量；
--cpu-shares :设置 cpu 使用权重；
--cpu-period :限制 CPU CFS周期；
--cpu-quota :限制 CPU CFS配额；
--cpuset-cpus :指定使用的CPU id；
--cpuset-mems :指定使用的内存 id；
--disable-content-trust :忽略校验，默认开启；
-f :指定要使用的Dockerfile路径；
--force-rm :设置镜像过程中删除中间容器；
--isolation :使用容器隔离技术；
--label=[] :设置镜像使用的元数据；
-m :设置内存最大值；
--memory-swap :设置Swap的最大值为内存+swap，"-1"表示不限swap；
--no-cache :创建镜像的过程不使用缓存；
--pull :尝试去更新镜像的新版本；
-q :安静模式，成功后只输出镜像ID；
--rm :设置镜像成功后删除中间容器；
--shm-size :设置/dev/shm的大小，默认值是64M；
--ulimit :Ulimit配置。
```
实例
```
使用当前目录的Dockerfile创建镜像。
docker build -t runoob/ubuntu:v1 . 
使用URL github.com/creack/docker-firefox 的 Dockerfile 创建镜像。
docker build github.com/creack/docker-firefox
```
### history

    docker history : 查看指定镜像的创建历史。
语法

    docker history [OPTIONS] IMAGE
OPTIONS说明：
```
-H :以可读的格式打印镜像大小和日期，默认为true；
--no-trunc :显示完整的提交记录；
-q :仅列出提交记录ID。
```

实例
```
查看本地镜像runoob/ubuntu:v3的创建历史。
root@runoob:~# docker history runoob/ubuntu:v3
```

### save

    docker save : 将指定镜像保存成 tar 归档文件。
语法

    docker save [OPTIONS] IMAGE [IMAGE...]
OPTIONS说明：
-o :输出到的文件。
实例
```
将镜像runoob/ubuntu:v3 生成my_ubuntu_v3.tar文档
runoob@runoob:~$ docker save -o my_ubuntu_v3.tar runoob/ubuntu:v3
runoob@runoob:~$ ll my_ubuntu_v3.tar
-rw------- 1 runoob runoob 142102016 Jul 11 01:37 my_ubuntu_v3.ta
```

### import

    docker import : 从归档文件中创建镜像。
语法

    docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]
OPTIONS说明：
-c :应用docker 指令创建镜像；
-m :提交时的说明文字；
实例
```
从镜像归档文件my_ubuntu_v3.tar创建镜像，命名为runoob/ubuntu:v4
runoob@runoob:~$ docker import  my_ubuntu_v3.tar runoob/ubuntu:v4  
runoob@runoob:~$ docker images runoob/ubuntu:v4
```

### info|version

info

    docker info : 显示 Docker 系统信息，包括镜像和容器数。。
语法

    docker info [OPTIONS]
实例

查看docker系统信息。
$ docker info

version

    docker version :显示 Docker 版本信息。
语法

    docker version [OPTIONS]
OPTIONS说明：

    -f :指定返回值的模板文件。
实例

显示 Docker 版本信息。
$ docker version



