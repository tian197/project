[TOC]







# Hadoop集群完全分布式部署



# 1.1 Hadoop简介

Hadoop是Apache软件基金会旗下的一个开源分布式计算平台。以Hadoop分布式文件系统（HDFS，Hadoop Distributed Filesystem）和MapReduce（Google MapReduce的开源实现）为核心的Hadoop为用户提供了系统底层细节透明的分布式基础架构。

对于Hadoop的集群来讲，可以分成两大类角色：Master和Salve。一个HDFS集群是由一个NameNode和若干个DataNode组成的。其中NameNode作为主服务器，管理文件系统的命名空间和客户端对文件系统的访问操作；集群中的DataNode管理存储的数据。MapReduce框架是由一个单独运行在主节点上的JobTracker和运行在每个集群从节点的TaskTracker共同组成的。主节点负责调度构成一个作业的所有任务，这些任务分布在不同的从节点上。主节点监控它们的执行情况，并且重新执行之前的失败任务；从节点仅负责由主节点指派的任务。当一个Job被提交时，JobTracker接收到提交作业和配置信息之后，就会将配置信息等分发给从节点，同时调度任务并监控TaskTracker的执行。

从上面的介绍可以看出，HDFS和MapReduce共同组成了Hadoop分布式系统体系结构的核心。HDFS在集群上实现分布式文件系统，MapReduce在集群上实现了分布式计算和任务处理。HDFS在MapReduce任务处理过程中提供了文件操作和存储等支持，MapReduce在HDFS的基础上实现了任务的分发、跟踪、执行等工作，并收集结果，二者相互作用，完成了Hadoop分布式集群的主要任务。







安装方式：

1、Hadoop本地模式安装

Hadoop本地模式只是用于本地开发调试，或者快速安装体验Hadoop，这部分做简单的介绍。

2、Hadoop伪分布式模式安装

学习Hadoop一般是在伪分布式模式下进行。这种模式是在一台机器上各个进程上运行Hadoop的各个模块，伪分布式的意思是虽然各个模块是在各个进程上分开运行的，但是只是运行在一个操作系统上的，并不是真正的分布式。

3、完全分布式安装

完全分布式模式才是生产环境采用的模式，Hadoop运行在服务器集群上，生产环境一般都会做HA，以实现高可用。



# 1.2 环境介绍









