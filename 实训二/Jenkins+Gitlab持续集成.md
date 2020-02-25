[TOC]







# Jenkins+Gitlab持续集成









# GitLab的安装及使用教程

## GitLab安装

1.安装依赖软件

```shell
yum -y install policycoreutils-python openssh-server openssh-clients postfix
```

2.设置postfix开机自启，并启动，postfix支持gitlab发信功能

```shell
systemctl enable postfix && systemctl start postfix
```

3.下载gitlab安装包，然后安装

centos 7系统的下载地址: https://mirrors.tuna.tsinghua.edu.cn/gitlab-ce/yum/el7

```shell
rpm -ivh gitlab-ce-10.0.2-ce.0.el7.x86_64.rpm
```

4.修改配置文件gitlab.rb

```shell
vim /etc/gitlab/gitlab.rb
修改如下：
external_url 'http://10.0.0.41:8888'
```

因为修改了配置文件，故需要重新加载配置内容。

```shell
gitlab-ctl reconfigure
gitlab-ctl restart
```

gitlab默认用户名密码` root : 5ivel!fe`



5.邮件配置

```
vim /etc/gitlab/gitlab.rb

gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = "smtp.qq.com"
gitlab_rails['smtp_port'] = 465
gitlab_rails['smtp_user_name'] = "602616568@qq.com"
gitlab_rails['smtp_password'] = "ipqqrjogfyabbegj"
gitlab_rails['smtp_domain'] = "qq.com"
gitlab_rails['smtp_authentication'] = "login"
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['smtp_tls'] = true
gitlab_rails['gitlab_email_from'] = '602616568@qq.com'
```

修改完后重启配置：

```
gitlab-ctl reconfigure
```

打开邮件测试控制台：

```
gitlab-rails console 
```

测试邮件发送：

Notify.test_email(‘接收方邮件地址’,’邮件标题’,’邮件内容’).deliver_now 



## GitLab常用命令

```shell
sudo gitlab-ctl start # 启动所有 gitlab 组件；
sudo gitlab-ctl stop # 停止所有 gitlab 组件；
sudo gitlab-ctl restart # 重启所有 gitlab 组件；
sudo gitlab-ctl status # 查看服务状态；
sudo gitlab-ctl reconfigure # 启动服务；
sudo vim /etc/gitlab/gitlab.rb # 修改默认的配置文件；
gitlab-rake gitlab:check SANITIZE=true --trace # 检查gitlab；
sudo gitlab-ctl tail # 查看日志；
```

