[TOC]







# Redis实现session共享之Tomcat

对于生产环境有了一定规模的tomcat集群业务来说，要实现session会话共享，比较稳妥的方式就是使用数据库持久化session。为什么要持久化session（共享session）呢？因为在客户端每个用户的Session对象存在Servlet容器中，如果Tomcat服务器重启或者宕机的话，那么该session就会丢失，而客户端的操作会由于session丢失而造成数据丢失；如果当前用户访问量巨大，每个用户的Session里存放大量数据的话，那么就很占用服务器大量的内存，进而致使服务器性能受到影响。数据库持久化session，分为物理数据库和内存数据库。物理数据库备份session，由于其性能原因，不推荐；内存数据库可以使用redis和memcached。



# 1.1 环境介绍



| 主机名   | 系统      | IP        | 角色     | 备注 |
| -------- | --------- | --------- | -------- | ---- |
| nginx    | CentOS7.7 | 10.0.0.61 | 负载均衡 |      |
| tomcat01 | CentOS7.7 | 10.0.0.62 | web应用  |      |
| tomcat02 | CentOS7.7 | 10.0.0.63 | web应用  |      |
| redis    | CentOS7.7 | 10.0.0.64 | 会话共享 |      |





