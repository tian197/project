[TOC]



# Prometheus+Grafana监控部署





## 一．环境



### 1.节点

| **Node**                            | **OS**     | **Hostname** | **IP**                                       | **Remark** |
| ----------------------------------- | ---------- | ------------ | -------------------------------------------- | ---------- |
| prometheus & grafana & alertmanager | centos 7.4 | bj01         | 118.186.39.46  外网         10.240.1.1  内网 |            |
| prometheus node                     | centos 7.4 | bj02         | 10.240.1.2  内网                             |            |

### 2. 版本(截止20190107)

| **Soft/Node** | **Version** | **Download**                                                 |
| ------------- | ----------- | ------------------------------------------------------------ |
| prometheus    | 2.6.0       | https://github.com/prometheus/prometheus/releases/download/v2.6.0/prometheus-2.6.0.linux-amd64.tar.gz |
| node_exporter | 0.17.0      | https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz |
| grafana       | 5.4.2-1     | <https://dl.grafana.com/oss/release/grafana-5.4.2-1.aarch64.rpm> |



## 二．部署prometheus 

### 1. 下载&部署

首先,安装go环境

```bash
yum -y install epel-release

yum install go -y

[root@ bj01 prometheus]# go version
go version go1.11.2 linux/amd64
```



在prometheus& grafana server节点部署prometheus服务。

```bash
# promethus不用编译安装，解压目录中有配置文件与启动文件
[root@ bj01 ~]# 
mkdir -p /etc/prometheus/
wget https://github.com/prometheus/prometheus/releases/download/v2.6.0/prometheus-2.6.0.linux-amd64.tar.gz
tar -zxvf prometheus-2.6.0.linux-amd64.tar.gz
cd prometheus-2.6.0.linux-amd64
mv prometheus promtool  /usr/local/bin/prometheus
cp prometheus.yml /etc/prometheus/
# 验证
prometheus --version
```



### 2. 配置文件

```yml
[root@ bj01 prometheus]# cd /etc/prometheus/
[root@ bj01 prometheus]# cat prometheus.yml
# my global config
global:
  scrape_interval:     15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: 'prometheus'
    scrape_interval: 5s

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'bj02'       #新增的监控节点
    scrape_interval: 10s
    static_configs:
    - targets: ['10.240.1.2:9100']
```



### 3. 设置用户

```bash
groupadd prometheus
useradd -g prometheus -s /sbin/nologin prometheus
chown -R prometheus:prometheus /usr/local/bin/prometheus
```

### 4. 设置开机启动

```bash
vim /usr/lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/
After=network.target

[Service]
# Type设置为notify时，服务会不断重启
Type=simple
User=prometheus
# --storage.tsdb.path是可选项，默认数据目录在运行目录的./dada目录中
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
Restart=on-failure

[Install]
WantedBy=multi-user.target

chown prometheus:prometheus /usr/lib/systemd/system/prometheus.service
systemctl daemon-reload
systemctl enable prometheus
```

### 5. 设置firewalld

```bash
firewall-cmd --zone=public --add-port=9090/tcp --permanent 
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
```

### 6. 启动并验证

**1) 查看服务转态**

```bash
systemctl start prometheus
systemctl status prometheus
```

**2) web ui**

Prometheus自带有简单的UI，http://118.186.39.46:9090

在Status菜单下，Configuration，Rule，Targets等，

Statu-->Configuration展示prometheus.yml的配置

Statu-->Targets展示监控具体的监控目标，这里监控目标"linux"暂未设置node_exporter，未scrape数据



### 7.查看启动参数

```shell
devops@mgt-prod-prometheus:/etc/prometheus$ prometheus -h
usage: prometheus [<flags>]

The Prometheus monitoring server

Flags:
  -h, --help                     Show context-sensitive help (also try --help-long and --help-man).
      --version                  Show application version.
      --config.file="prometheus.yml"
                                 Prometheus configuration file path.
      --web.listen-address="0.0.0.0:9090"
                                 Address to listen on for UI, API, and telemetry.
      --web.read-timeout=5m      Maximum duration before timing out read of the request, and closing idle connections.
      --web.max-connections=512  Maximum number of simultaneous connections.
      --web.external-url=<URL>   The URL under which Prometheus is externally reachable (for example, if Prometheus is served via a reverse proxy). Used for
                                 generating relative and absolute links back to Prometheus itself. If the URL has a path portion, it will be used to prefix all HTTP
                                 endpoints served by Prometheus. If omitted, relevant URL components will be derived automatically.
      --web.route-prefix=<path>  Prefix for the internal routes of web endpoints. Defaults to path of --web.external-url.
      --web.user-assets=<path>   Path to static asset directory, available at /user.
      --web.enable-lifecycle     Enable shutdown and reload via HTTP request.
      --web.enable-admin-api     Enable API endpoints for admin control actions.
      --web.console.templates="consoles"
                                 Path to the console template directory, available at /consoles.
      --web.console.libraries="console_libraries"

```





## 三．部署node_exporter

Node_exporter收集机器的系统数据，这里采用prometheus官方提供的exporter，除node_exporter外，官方还提供consul，memcached，haproxy，mysqld等exporter，具体可查看官网。

这里在prometheus node节点部署相关服务。

### **1.下载&部署**

```shell
[root@ bj02 ~]# 
wget https://github.com/prometheus/node_exporter/releases/download/v0.17.0/node_exporter-0.17.0.linux-amd64.tar.gz
tar -zxvf node_exporter-0.17.0.linux-amd64.tar.gz
cd node_exporter-0.17.0.linux-amd64/
mv node_exporter-0.17.0.linux-amd64 /usr/local/bin/node_exporter
```



### **2.设置用户**

```bash
groupadd prometheus
useradd -g prometheus -s /sbin/nologin prometheus
chown -R prometheus:prometheus /usr/local/bin/node_exporter
```



### **3.设置开机启动**

```bash
vim /usr/lib/systemd/system/node_exporter.service

[Unit]
Description=node_exporter
Documentation=https://prometheus.io/
After=network.target

[Service]
Type=simple
User=prometheus
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target

chown -R prometheus:prometheus /usr/lib/systemd/system/node_exporter.service
systemctl daemon-reload
systemctl enable node_exporter.service
systemctl start node_exporter.service
```

### **4. 验证**

访问：http://118.186.39.46:9090，可见node1主机已经可被监控



## 四 . 部署grafana

在prometheus& grafana server节点部署grafana服务。

### **1. 下载&安装**

```bash
Redhat & Centos(ARM64): 

cd /usr/local/src/
wget https://dl.grafana.com/oss/release/grafana-5.4.2-1.x86_64.rpm 
sudo yum localinstall grafana-5.4.2-1.x86_64.rpm 

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server
```

### **2. 配置文件**

配置文件位于/etc/grafana/grafana.ini，这里暂时保持默认配置即可。

### **3.设置firewalld**

```bash
firewall-cmd --zone=public --add-port=3000/tcp --permanent 
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
```

### **4. 添加数据源**

**1）登陆**

访问：http://118.186.39.46:3000，默认账号/密码：admin/admin



**2）添加数据源**

在登陆首页，点击"Add data source"按钮，跳转到添加数据源页面，配置如下：

```bash
Settings
Name		Prometheus		Default
HTTP
URL			http://localhost:9090
Access		Server(Default)
```





## 五 . Prometheus使用

### 1.prometheus的配置文件

**(1).grafana配置面板**

详细查看: https://github.com/starsliao/Prometheus



**(2).static_configs配置**

单个增加bj01的node监控

```yml
# my global config
global:
  scrape_interval:     15s 
  evaluation_interval: 15s 

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
    - targets: ['118.186.39.46:9090']

  - job_name: 'bj01'
    scrape_interval: 10s
    static_configs:
    - targets: ['10.240.1.1:9100']
```



**(3).file_sd_configs自动发现**

创建node_exporter节点的相关json文件

```bash
mkdir -p /etc/prometheus/node_conf/
[root@ bj01 prometheus]# vim /etc/prometheus/node_conf/bj.json
[
   {
    "targets": ["10.240.1.2:9100"],
    "labels": {
        "env": "bj",
        "name": "bj02"
     }
  }
]


#当json文件多时,可以使用/etc/prometheus/node_conf/*.json
```

**在prometheus.yml配置中添加,file_sd_configs一栏**

```yml
# my global config
global:
  scrape_interval:     15s 
  evaluation_interval: 15s 

alerting:
  alertmanagers:
  - static_configs:
    - targets:
      # - alertmanager:9093

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s

    static_configs:
    - targets: ['118.186.39.46:9090']
    
  - job_name: 'bj'
    file_sd_configs:
      - files: ['/etc/prometheus/node_conf/bj.json']

```

此时,访问http://118.186.39.46:9090  ,即可查看到所以监控到的节点

**(4).服务发现**

prometheus中与服务发现有关的配置有以下几项（前缀就是支持的系统，sd表示service discovery）：

```bash
azure_sd_config
consul_sd_config
dns_sd_config
ec2_sd_config
openstack_sd_config
file_sd_config
gce_sd_config
kubernetes_sd_config
marathon_sd_config
nerve_sd_config
serverset_sd_config
triton_sd_config
```
服务发现是prometheus最强大的功能之一，这个功能配合relabel_config、*_exporter可以做成很多事情。

**(5).Prometheus配置的热加载**

Prometheus配置信息的热加载有两种方式：

第一种热加载方式：查看Prometheus的进程id，发送 SIGHUP 信号:

```bash
kill -HUP <pid>
```


第二种热加载方式：发送一个POST请求到 /-/reload ，需要在启动时给定 --web.enable-lifecycle 选项：

```bash
curl -X POST http://localhost:9090/-/reload
```

我们使用的是第一种热加载方式，systemd unit文件如下：

```bash
[root@ bj01 prometheus]# cat /usr/lib/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/
After=network.target

[Service]
# Type设置为notify时，服务会不断重启
Type=simple
User=root
# --storage.tsdb.path是可选项，默认数据目录在运行目录的./dada目录中
ExecStart=/opt/prometheus/prometheus \
 --config.file=/opt/prometheus/prometheus.yml \
 --storage.tsdb.path=/var/lib/prometheus \
 --storage.tsdb.retention=365d \
 --web.listen-address=:9090 \
 --web.external-url=https://prometheus.frognew.com
ExecReload=/bin/kill  -HUP  $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target
```



### 2.使用relabel_config扩展采集能力

[relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#%3Crelabel_config%3E)，顾名思义，可以用来重新设置标签。标签是附属在每个监控目标的每个指标上的。

但有些标签是双下划线开头的，例如`__address__`，这样的标签是内置的有特殊意义的，不会附着在监控指标上。

这样的标签有：

```bash
__address__         : 检测目标的地址 
__scheme__          : http、https等
__metrics_path__    : 获取指标的路径
```

上面的三个标签将被组合成一个完整url，这个url就是监控目标，可以通过这个url读取到指标。

relabel_config提供了标签改写功能，通过标签改写，可以非常灵活地定义url。

另外在每个服务发现配置中，还会定义与服务相关的内置指标，例如kubernetes_sd_config的node的类型中又定义了：

```shell
__meta_kubernetes_node_name: The name of the node object.
__meta_kubernetes_node_label_<labelname>: Each label from the node object.
__meta_kubernetes_node_annotation_<annotationname>: Each annotation from the node object.
__meta_kubernetes_node_address_<address_type>: The first address for each node address type, if it exists.
```

在上一节中，是直接从默认的地址`http://< NODE IP>/metrics`中采集到每个node数据的，这里用relabel修改一下，改成从apiserver中获取：

```shell
  - job_name: 'kubernetes-nodes'
    kubernetes_sd_configs:
    - role: node
      api_server: https://192.168.88.10
      tls_config:
        ca_file:   /opt/app/k8s/admin/cert/ca/ca.pem
        cert_file: /opt/app/k8s/admin/cert/apiserver-client/cert.pem
        key_file:  /opt/app/k8s/admin/cert/apiserver-client/key.pem
    bearer_token_file: /opt/app/k8s/apiserver/cert/token.csv
    scheme: https
    tls_config:
      ca_file:   /opt/app/k8s/admin/cert/ca/ca.pem
      cert_file: /opt/app/k8s/admin/cert/apiserver-client/cert.pem
      key_file:  /opt/app/k8s/admin/cert/apiserver-client/key.pem
    relabel_configs:
    - action: labelmap
      regex: __meta_kubernetes_node_label_(.+)
    - target_label: __address__
      replacement: 192.168.88.10
    - source_labels: [__meta_kubernetes_node_name]
      regex: (.+)
      target_label: __metrics_path__
      replacement: /api/v1/nodes/${1}/proxy/metrics

```

其实就是在原先的配置后面增加了一节`relabel_configs`的配置。

重新加载配置文件，过一小会儿，就会发现target的url发生了变化。

relabel_config是一个很强大的功能，除了修改标签，还可以为采集的指标添加上新标签：

```shell
    - source_labels: [__meta_kubernetes_node_name]
      regex: (.+)
      replacement: hello_${1}
      target_label: label_add_by_me

```

在配置文件中加上上面的内容后，为每个指标都将被添加了一个名为`label_add_by_me`的标签。



### 3.prometheus的查询语句

prometheus的查询语句也是很重要的内容，除了用来查询数据，后面将要讲的告警规则也要用查询语句描述。

查询语句直接就是指标的名称：

```bash
go_memstats_other_sys_bytes
```

但是可以通过标签筛选：

```
go_memstats_other_sys_bytes{instance="192.168.88.10"}
```

标签属性可以使用4个操作符：

```bash
=: Select labels that are exactly equal to the provided string.
!=: Select labels that are not equal to the provided string.
=~: Select labels that regex-match the provided string (or substring).
!~: Select labels that do not regex-match the provided string (or substring).
```

并且可以使用多个标签属性，用“,”间隔，彼此直接是与的关系，下面是prometheus文档中的一个例子：

```
http_requests_total{environment=~"staging|testing|development",method!="GET"}
```

甚至只有标签：

```
{instance="192.168.88.10"}
```

对查询出来的结果进行运算也是可以的：

```bash
# 时间范围截取，Range Vector Selectors
http_requests_total{job="prometheus"}[5m]
 
# 时间偏移
http_requests_total offset 5m
 
# 时间段内数值累加
sum(http_requests_total{method="GET"} offset 5m) 
```

还可以进行多元运算：[Operators](https://prometheus.io/docs/prometheus/latest/querying/operators/)，以及使用函数：[Functions](https://prometheus.io/docs/prometheus/latest/querying/functions/)。



### 4.Prometheus配置热加载

**发送SIGHUP信号给应用程序的主进程：**

```bash
kill -1 pid
```

‘’-1‘’是指“终端断线”

**发送post请求给指定端点：**

```bash
curl -XPOST http://ip:9090/-/reload
对于此种方法要注意在启动时加上以上所说的--web.enable-lifecycle启动参数
```



## 六.alertmanager报警

alertmanager是用来接收prometheus发出的告警，然后按照配置文件的要求，将告警用对应的方式发送出去。

### 1.下载部署

```bash
wget https://github.com/prometheus/alertmanager/releases/download/v0.16.0-alpha.0/alertmanager-0.16.0-alpha.0.linux-amd64.tar.gz

tar -zxvf alertmanager-0.16.0-alpha.0.linux-amd64.tar.gz
cd alertmanager-0.16.0-alpha.0.linux-amd64/
mv alertmanager amtool /usr/local/bin/
```

### 2.设置启动用户

```bash
chown -R prometheus:prometheus /usr/local/bin/prometheus
```

### 3.设置开机自启

```bash
[root@ bj01 prometheus]# vim /usr/lib/systemd/system/alertmanager.service
[Unit]
Description=Prometheus
Documentation=https://prometheus.io/
After=network.target

[Service]
# Type设置为notify时，服务会不断重启
Type=simple
User=root
ExecStart=/opt/prometheus/alertmanager \
 --config.file=/opt/prometheus/alertmanager.yml

ExecReload=/bin/kill  -HUP  $MAINPID
Restart=on-failure

[Install]
WantedBy=multi-user.target




chown prometheus:prometheus /usr/lib/systemd/system/alertmanager.service
systemctl daemon-reload
systemctl enable prometheus
```

### 4.设置防火墙

```bash
firewall-cmd --zone=public --add-port=9093/tcp --permanent 
firewall-cmd --reload
firewall-cmd --zone=public --list-ports
```

### 5.配置文件

创建alert_rules存放报警规则

```bash
mkdir -p /etc/prometheus/alert_rules
```

修改prometheus.yml配置

```bash
[root@ bj01 prometheus]# cat prometheus.yml
# my global config
global:
  scrape_interval:     15s 
  evaluation_interval: 15s 
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['10.240.1.1:9093']
      # - alertmanager:9093


rule_files:
   - "node_down.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.
    static_configs:
    - targets: ['118.186.39.46:9090']

  - job_name: 'bj'
    file_sd_configs:
      - files: ['/etc/prometheus/*.json']

```

创建报警规则

```bash
[root@ bj01 prometheus]# cat alert_rules/node_down.yml
groups:
- name: example
  rules:
  - alert: Instance Down
    expr: up == 0
    for: 15s
    labels:
      user: devops
      severity: Warning
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 1 minutes."
```



### 6.启动并验证

```bash
systemctl start alertmanager
systemctl status alertmanager
```

访问: http://118.186.39.46:9093



### 7.查看启动参数

```bash
devops@mgt-prod-prometheus:/etc/prometheus$ alertmanager -h
usage: alertmanager [<flags>]

Flags:
  -h, --help                     Show context-sensitive help (also try --help-long and --help-man).
      --config.file="alertmanager.yml"
                                 Alertmanager configuration file name.
      --storage.path="data/"     Base path for data storage.
      --data.retention=120h      How long to keep data for.
      --alerts.gc-interval=30m   Interval between alert GC.
      --log.level=info           Only log messages with the given severity or above.
      --web.external-url=WEB.EXTERNAL-URL
                                 The URL under which Alertmanager is externally reachable (for example, if Alertmanager is served via a reverse proxy). Used for
                                 generating relative and absolute links back to Alertmanager itself. If the URL has a path portion, it will be used to prefix all
                                 HTTP endpoints served by Alertmanager. If omitted, relevant URL components will be derived automatically.
      --web.route-prefix=WEB.ROUTE-PREFIX
                                 Prefix for the internal routes of web endpoints. Defaults to path of --web.external-url.
      --web.listen-address=":9093"

```



## 七. 日常使用

### 1. 语法检查

**rules规则语法检查**

```bash
promtool check rules /path/to/example.rules.yml
```

**promethues配置语法检查**

```bash
promtool check config prometheus.yml
```



### 2.微信报警

**实现WeChat 告警-准备工作**

step 1: 访问[网站](https://work.weixin.qq.com/) 注册企业微信账号（不需要企业认证）。
step 2: 访问[apps](https://work.weixin.qq.com/wework_admin/loginpage_wx#apps) 创建第三方应用，点击创建应用按钮 -> 填写应用信息：

#### alertmanager.yml配置

```yml
[root@ bj01 prometheus]# cat alertmanager.yml
global:
  resolve_timeout: 5m
  #wechat_api_corp_id: 'wwbda907e51f13bb00'
  #wechat_api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'
  #wechat_api_secret: '3w4yN2HaAx_nY1tbD5msD41lUVd07_bxbyH2ad6jb7g'

templates:
  - 'templ ate/*.tmpl'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'wechat'
receivers:
  - name: 'wechat'
    wechat_configs: # 企业微信报警配置
    - to_party: '2'
      agent_id: '1000004'
      corp_id: 'wwbda907e51f13bb00'
      api_secret: '3w4yN2HaAx_nY1tbD5msD41lUVd07_bxbyH2ad6jb7g'
      message: '{{ template "wechat.html" . }}'
      api_url: 'https://qyapi.weixin.qq.com/cgi-bin/'
      send_resolved: true

#inhibit_rules:
#  - source_match:
#      severity: 'critical'
#    target_match:
#      severity: 'warning'
#    equal: ['alertname', 'dev', 'instance']
```



#### prometheus.yml配置

```yml
[root@ bj01 prometheus]# cat prometheus.yml
# my global config
global:
  scrape_interval:     15s 
  evaluation_interval: 15s

# Alertmanager configuration
alerting:
  alertmanagers:
  - static_configs:
    - targets: ['10.240.1.1:9093']

rule_files:
   - "./rules/*.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s

    static_configs:
    - targets: ['118.186.39.46:9090']
    
    file_sd_configs:
      - files: ['/opt/prometheus/conf/*.json']

```

#### node_down.yml配置

```yml
[root@ bj01 prometheus]# cat rules/node_down.yml
groups:
- name: node_down
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 10s
    labels:
      severity: critital
    annotations:
      summary: "{{$labels.instance}}: has been down"
      description: "{{$labels.instance}}: job {{$labels.job}} has been down"
```



#### wechat.tmpl配置

```yml
[root@ bj01 prometheus]# cat template/wechat.tmpl
{{ define "wechat.html" }}
  {{ range .Alerts.Firing }}
    ===================
    告警程序:  prometheus_alert
    告警级别:  {{ .Labels.severity }}
    告警类型:  {{ .Labels.alertname }}
    主机名称:  {{ .Labels.name }}
    故障节点:  {{ .Labels.instance }}
    告警主题:  {{ .Annotations.summary }}
    告警详情:  {{ .Annotations.description }}
    触发时间:  {{ .StartsAt.Format "2006-01-02 15:04:05" }}
    ===================
  {{ end }}
  {{ range .Alerts.Resolved }}
    ===================
    恢复信息:
    恢复主机:  {{ .Labels.name }}
    告警主题:  {{ .Annotations.summary }}
    当前状态:  已恢复!
    恢复时间:  {{ .EndsAt.Format "2006-01-02 15:04:05" }}
    ===================
  {{ end }}
{{ end }}

```



# alertmanage抑制规则的使用

prometheus服务端通过配置文件可以设置告警，下面是一个告警设置的配置文件alert.yml：

```bash
groups:

- name: goroutines_monitoring
  rules:
  - alert: TooMuchGoroutines
    expr: go_goroutines{job="prometheus"} > 20
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "too much goroutines of job prometheus."
      description: "testing"
- name: goroutines_monitoring
  rules:
  - alert: TooMuchGoroutines
    expr: go_goroutines{job="prometheus"} > 30
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "too much goroutines of job prometheus."
      description: "testing"


```

在prometheus的告警配置文件中配置了2条告警规则，prometheus会产生2条告警，通过设置AlterManager的告警抑制规则，让同一指标只产生一条告警。对应上面的抑制规则设置：

```bash
inhibit_rules:
  - source_match:
    altername: 'TooMuchGoroutines'
    severity: 'critical'
  target_match:
    severity: 'warning'
  # Apply inhibition if the alertname is the same.
  equal: ['alertname', 'instance']
```

