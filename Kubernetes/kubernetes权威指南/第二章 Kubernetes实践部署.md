[TOC]





# 第二章 Kubernetes部署

**官方提供的三种部署方式**

**1.minikube**

Minikube是一个工具，可以在本地快速运行一个单点的Kubernetes，仅用于尝试Kubernetes或日常开发的用户使用。 部署地址：<https://kubernetes.io/docs/setup/minikube/>

**2.kubeadm**

Kubeadm也是一个工具，提供kubeadm init和kubeadm join，用于快速部署Kubernetes集群。 部署地址：<https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm/>

**3.二进制包**

推荐，从官方下载发行版的二进制包，手动部署每个组件，组成Kubernetes集群。 下载地址：<https://github.com/kubernetes/kubernetes/releases>



# 1.1 kubeadm部署集群

## 1.1.1 环境介绍

| 主机名 | 外网IP | 内网IP | 系统 | 备注 |
| ------ | ------ | ------ | ---- | ---- |
|        |        |        |      |      |
|        |        |        |      |      |
|        |        |        |      |      |

