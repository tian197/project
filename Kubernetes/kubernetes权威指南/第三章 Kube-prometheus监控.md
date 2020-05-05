[TOC]



# 第三章 Kube-prometheus监控

# 1.1 介绍

很多地方提到Prometheus Operator是kubernetes集群监控的终极解决方案，但是目前Prometheus Operator已经不包含完整功能，完整的解决方案已经变为kube-prometheus。项目地址为：

https://github.com/coreos/kube-prometheus

kube-prometheus 是一整套监控解决方案，它使用 Prometheus 采集集群指标，Grafana 做展示，包含如下组件：

| 组件                                                         | 功能描述                                                     |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| The Prometheus Operator                                      | 可以非常简单的在kubernetes集群中部署Prometheus服务，并且提供对kubernetes集群的监控，并且可以配置和管理prometheus |
| Highly available Prometheus                                  | 高可用监控工具                                               |
| Highly available Alertmanager                                | 高可用告警工具，用于接收 Prometheus 发送的告警信息，它支持丰富的告警通知渠道，而且很容易做到告警信息进行去重，降噪，分组等，是一款前卫的告警通知系统。 |
| node-exporter                                                | 用于采集服务器层面的运行指标，包括机器的loadavg、filesystem、meminfo等基础监控，类似于传统主机监控维度的zabbix-agent |
| ==Prometheus Adapter for Kubernetes Metrics APIs （k8s-prometheus-adapter）== | 轮询Kubernetes API，并将Kubernetes的结构化信息转换为metrics  |
| ==kube-state-metrics==                                       |                                                              |
| grafana                                                      | 用于大规模指标数据的可视化展现，是网络架构和应用分析中最流行的时序数据展示工具 |

其中 k8s-prometheus-adapter 使用 Prometheus 实现了 metrics.k8s.io 和 custom.metrics.k8s.io API，所以**不需要再部署** metrics-server（ metrics-server 通过 kube-apiserver 发现所有节点，然后调用 kubelet APIs（通过 https 接口）获得各节点（Node）和 Pod 的 CPU、Memory 等资源使用情况。 从 Kubernetes 1.12 开始，kubernetes 的安装脚本移除了 Heapster，从 1.13 开始完全移除了对 Heapster 的支持，Heapster 不再被维护）。

# 1.2 部署

## 1.2.1 下载源码

```bash
cd /etc/kubernetes
git clone https://github.com/coreos/kube-prometheus.git
```



## 1.2.2 执行安装

```bash
# 导入或者下载所需要的镜像
# 安装 prometheus-operator
kubectl apply -f manifests/setup
# 安装 promethes metric adapter
kubectl apply -f manifests/
```



## 1.2.3 查看资源

```bash
$ kubectl get pod -n monitoring
NAME                                   READY   STATUS    RESTARTS   AGE
alertmanager-main-0                    2/2     Running   0          108m
alertmanager-main-1                    2/2     Running   0          108m
alertmanager-main-2                    2/2     Running   0          108m
grafana-5c55845445-k62r4               1/1     Running   0          118m
kube-state-metrics-957fd6c75-trc98     3/3     Running   0          118m
node-exporter-9tsp7                    2/2     Running   0          118m
node-exporter-qch48                    2/2     Running   0          118m
prometheus-adapter-5949969998-xwppl    1/1     Running   0          118m
prometheus-k8s-0                       3/3     Running   0          108m
prometheus-k8s-1                       3/3     Running   1          108m
prometheus-operator-574fd8ccd9-jbpdc   2/2     Running   0          118m



$ kubectl get svc -n monitoring
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
alertmanager-main       NodePort    10.98.87.182    <none>        9093:39093/TCP               118m
alertmanager-operated   ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   109m
grafana                 NodePort    10.111.101.35   <none>        3000:33000/TCP               118m
kube-state-metrics      ClusterIP   None            <none>        8443/TCP,9443/TCP            118m
node-exporter           ClusterIP   None            <none>        9100/TCP                     118m
prometheus-adapter      ClusterIP   10.104.17.189   <none>        443/TCP                      118m
prometheus-k8s          NodePort    10.102.162.72   <none>        9090:39090/TCP               118m
prometheus-operated     ClusterIP   None            <none>        9090/TCP                     108m
prometheus-operator     ClusterIP   None            <none>        8443/TCP                     118m


$ kubectl get ep -n monitoring
NAME                    ENDPOINTS                                                        AGE
alertmanager-main       10.244.4.10:9093,10.244.4.11:9093,10.244.4.12:9093               118m
alertmanager-operated   10.244.4.10:9094,10.244.4.11:9094,10.244.4.12:9094 + 6 more...   109m
grafana                 10.244.4.7:3000                                                  118m
kube-state-metrics      10.244.4.8:9443,10.244.4.8:8443                                  118m
node-exporter           10.0.0.61:9100,10.0.0.62:9100                                    118m
prometheus-adapter      10.244.4.9:6443                                                  118m
prometheus-k8s          10.244.4.13:9090,10.244.4.14:9090                                118m
prometheus-operated     10.244.4.13:9090,10.244.4.14:9090                                109m
prometheus-operator     10.244.4.6:8443                                                  118m

```

## 1.2.4 清除资源

```bash
kubectl delete --ignore-not-found=true -f manifests/ -f manifests/setup
# 强制删除pod
kubectl delete pod prometheus-k8s-1 -n monitoring --force --grace-period=0
```

以上各组件说明：

- MerticServer： k8s集群资源使用情况的聚合器，收集数据给k8s集群内使用；如kubectl，hpa，scheduler
- PrometheusOperator：是一个系统监测和警报工具箱，用来存储监控数据。
- NodeExPorter：用于各个node的关键度量指标状态数据。
- kubeStateMetrics：收集k8s集群内资源对象数据，指定告警规则。
- Prometheus：采用pull方式收集apiserver，scheduler，control-manager，kubelet组件数据，通过http协议传输。
- Grafana：是可视化数据统计和监控平台。

## 1.2.5 端口暴露--此处采用nodeport

Kubernetes 服务的 NodePort 默认端口范围是 30000-32767，在某些场合下，这个限制不太适用，我们可以自定义它的端口范围，操作步骤如下：

编辑`vi /etc/kubernetes/manifests/kube-apiserver.yaml`配置文件，增加配置`--service-node-port-range=2-65535`

```yml
vi /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  annotations:
    kubeadm.kubernetes.io/kube-apiserver.advertise-address.endpoint: 10.0.0.61:6443
  creationTimestamp: null
  labels:
    component: kube-apiserver
    tier: control-plane
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --advertise-address=10.0.0.61
    - --service-node-port-range=2-65535
```



**nodeport方式：**

==修改grafana-service文件：==

```yml
cd /etc/kubernetes/kube-prometheus/
cat >manifests/grafana-service.yaml<<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: grafana
  name: grafana
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - name: http
    port: 3000
    targetPort: http
    nodePort: 33000
  selector:
    app: grafana
EOF
kubectl apply -f manifests/grafana-service.yaml
```

==修改Prometheus-service文件：==

```yml
cd /etc/kubernetes/kube-prometheus/
cat >manifests/prometheus-service.yaml<<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    prometheus: k8s
  name: prometheus-k8s
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - name: web
    port: 9090
    targetPort: web
    nodePort: 39090
  selector:
    app: prometheus
    prometheus: k8s
  sessionAffinity: ClientIP
EOF
kubectl apply -f manifests/prometheus-service.yaml
```

==修改alertmanager-service文件：==

```bash
cd /etc/kubernetes/kube-prometheus/
cat >manifests/alertmanager-service.yaml<<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    alertmanager: main
  name: alertmanager-main
  namespace: monitoring
spec:
  type: NodePort
  ports:
  - name: web
    port: 9093
    targetPort: web
    nodePort: 39093
  selector:
    alertmanager: main
    app: alertmanager
  sessionAffinity: ClientIP
EOF
kubectl apply -f manifests/alertmanager-service.yaml
```









