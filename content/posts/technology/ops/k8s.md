---
title: "空服务器部署K8S流程"
date: 2024-08-04T10:50:34+08:00
draft: false
---

### 前言
网上有很多安装K8S的流程，但有写文章覆盖不全，有些文章描述不清，给人带来很大困惑。\
于是结合自己的安装经历和网上的流程，整合一篇从空服务器安装的过程，便于自己再次部署和给其他人提供参考。

### 0.环境检查
```shell
# 先更新源，再把服务器重启下，有的服务器有问题，一次性的，关机后启动不了，由于安装k8s会修改内核参数，后面起不来了说不清楚，避免背锅
apt update 
shutdown -r now
```

### 1.环境准备
#### 1.1 修改镜像源
##### 
```shell
# 1.备份原文件
mv /etc/apt/sources.list /etc/apt/sources.list.bak

# 2.查询系统版本号
cat /etc/os-release
# 系统版本号，需要与国内源对应，否则可能会出问题。
# 可以在镜像站查找 https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/ 自己的系统版本版对应的配置

# 3.1 写入通用源信息（ubuntu）
cat > /etc/apt/sources.list << EOF
deb http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-backports main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse
deb-src http://mirrors.aliyun.com/ubuntu/ jammy-proposed main restricted universe multiverse

EOF

# 3.2 写入通用源信息（yum）
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.32/rpm/repodata/repomd.xml.key
exclude=kubelet kubeadm kubectl cri-tools kubernetes-cni
EOF

# 4.更新源
apt update #更新软件列表
apt upgrade #更新本地软件

# 5.安装工具
 

```
#### 1.2 硬盘挂载
部分服务器存在没有挂载硬盘的情况，需要手动检查挂载
```shell
# 0.查看是否有硬盘未挂载
df -h # 查看当前已挂载硬盘
fdisk -l # 查看所有硬盘
# 对比上面两个结果，若存在未挂载的硬盘，则继续挂载

# 1.对硬盘进行分区
fdisk /dev/sdb

# 进入交互界面后，可以使用 m 产看帮助
# 构建一个新分区依次输入：
n  # 创建新分区，可以默认直接回车
p  # 创建主分区，可以默认直接回车，分区号和扇区如无特殊要求，默认即可
w  # 将分区表写入磁盘并退出

# 2.格式化
# 对上一步完成的分区进行格式化
# 2T 以上建议用 xfs 格式，2T以下建议 ext4 格式
mkfs.ext4 /dev/sdb1

# 3.创建一个目录并挂载
mkdir /data
mount /dev/sdb1 /data

# 4.添加自动挂载
echo '/dev/sdb1 /data ext4 defaults 0 0' >> /etc/fstab #注意这里是追加，别覆盖了
mount -a # 执行自动挂载

# 补充：如果k8s集群需要挂载nfs文件系统，服务器必须安装nfs-common
apt -y install nfs-common
showmount -e 192.168.10.100
cat '192.168.10.100:/nfs/share  /share nfs  vers=4,minorversion=0,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,_netdev,noresvport  0  0' >> /etc/fstab
```

#### 1.3 修改系统配置
```shell
# 1.关闭防火墙
systemctl disable --now ufw 
apt purge ufw 

# 2.关闭selinux 
setenforce 0 #临时关闭
sed -i s#SELINUX=enforcing#SELINUX=disabled# /etc/selinux/config #永久关闭

# 3.关闭交换空间
swapoff -a && sysctl -w vm.swappiness=0
sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab

# 4.同步时区
ln -svf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# 5.配置limit
cat >> /etc/security/limits.conf <<'EOF'
* soft nofile 655360
* hard nofile 131072
* soft nproc 655350
* hard nproc 655350
* soft memlock unlimited
* hard memlock unlimited
EOF

# 6.优化sshd连接配置
# UseDNS打开状态下，当客户端试图登录SSH服务器时，服务器端先根据客户端的IP地址进行PTR反向查询出客户端的主机名
# 然后根据查询出的客户端主机名进行DNS正向A记录查询，验证与其原始IP地址是否一致，这是防止客户端欺骗的一种措施，
# 但一般我们的是动态IP不会有PTR记录，打开这个选项不过是在白白浪费时间而已，不如将其关闭。
sed -i 's@#UseDNS yes@UseDNS no@g' /etc/ssh/sshd_config

# 当GSSAPIAuthentication选项开启时，登陆的时候客户端需要对服务器端的IP地址进行反解析，
# 如果服务器的IP地址没有配置PTR记录，很容易在这里卡住到超时。
sed -i 's@^GSSAPIAuthentication yes@GSSAPIAuthentication no@g' /etc/ssh/sshd_config

# 7.内核优化
cat > /etc/sysctl.d/k8s.conf <<'EOF'
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1

net.ipv6.conf.all.disable_ipv6 = 1
fs.may_detach_mounts = 1
vm.overcommit_memory=1
vm.panic_on_oom=0
fs.inotify.max_user_watches=89100
fs.file-max=52706963
fs.nr_open=52706963
net.netfilter.nf_conntrack_max=2310720
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_max_tw_buckets = 36000
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_orphans = 327680
net.ipv4.tcp_orphan_retries = 3
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.ip_conntrack_max = 65536
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_timestamps = 0
net.core.somaxconn = 16384
EOF

sysctl --system #启用配置

```
### 2.安装组件

#### 2.1 安装并启动containerd
```shell
# 1.添加密钥
curl -sS https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/aliyun-docker-ce.gpg

# 2.写入Containerd源信息
echo "deb [signed-by=/usr/share/keyrings/aliyun-docker-ce.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/aliyun-docker-ce.list

# 3.更新软件源
apt update

# 4.安装containerd组件
apt -y install containerd.io

# 5.加载模块
# 临时生效
modprobe -- overlay
modprobe -- br_netfilter
# 持久化
cat > /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

# 6.重新初始化containerd的配置文件
containerd config default | tee /etc/containerd/config.toml 
# 修改Cgroup的管理者为systemd组件
sed -ri 's#^(\s*SystemdCgroup = ).*$#\1true#' /etc/containerd/config.toml 
# 修改pause的基础镜像名称
sed -ri 's#^(\s*sandbox_image = ).*$#\1"registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"#' /etc/containerd/config.toml
# 设置镜像保存路径
sed -ri 's#^(\s*root = ).*$#\1"/data/containerd/root"#' /etc/containerd/config.toml  #保存持久化数据,默认值/var/lib/containerd
sed -ri 's#^(\s*state = ).*$#\1"/data/containerd/run"#' /etc/containerd/config.toml #保存运行时临时数据,默认值/run/containerd 
# 设置镜像仓库地址
sed -ri 's#^(\s*config_path = ).*$#\1"/etc/containerd/certs.d"#' /etc/containerd/config.toml


# 7.配置国内镜像（重要）
mkdir -p /etc/containerd/certs.d/docker.io
cat > /etc/containerd/certs.d/docker.io/hosts.toml << EOF
server = "https://docker.io"

[host."https://docker.1panel.live"]
  capabilities = ["pull", "resolve"]
  
[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]

[host."https://dockerhub.timeweb.cloud"]
  capabilities = ["pull", "resolve"]

[host."https://4fb4b8dbaee8420cbcb88afdafa26584.mirror.swr.myhuaweicloud.com"]
  capabilities = ["pull", "resolve"]

EOF

# 8.启动containerd
systemctl daemon-reload # 刷新服务守护
systemctl restart containerd  # 重启服务
systemctl enable containerd # 设置开机启动
systemctl status containerd # 查看运行状态
 
# （可选）9.配置crictl客户端连接的运行时位置 ，使用ctr管理时必须配置
cat > /etc/crictl.yaml <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

```

#### 2.2 安装并启动K8S
```shell
# 1.添加源密钥
curl -fsSL https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/deb/Release.key | apt-key add - 
# 2.写入K8S源信息
cat > /etc/apt/sources.list.d/kubernetes.list <<EOF
deb https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/deb/ /
EOF
# 3.更新软件列表
sudo apt update 
# 4.安装k8s相关工具
apt install -y kubelet kubeadm kubectl
systemctl enable kubelet #设置开机自启动
```

#### 2.3 安装负载均衡（HAProxy）
计划安装多个主节点，且没有外层负载均衡设备或服务时执行
```shell
# 1.获取安装包
wget https://www.haproxy.org/download/2.8/src/haproxy-2.8.3.tar.gz

# 2.解压
tar zxvf haproxy-2.8.3.tar.gz

# 3.编译
cd haproxy-2.8.3/
make TARGET=linux-glibc PREFIX=/data/haproxy
make install PREFIX=/data/haproxy

# 4.配置文件
mkdir -p /data/haproxy/conf
cat > /data/haproxy/conf/haproxy.cfg <<EOF 
global
    zero-warning
    chroot                /data/haproxy
    daemon
    maxconn               4000
    pidfile               /var/run/haproxy.pid
    hard-stop-after       5m

defaults
    timeout client        30s
    timeout server        30s
    timeout connect       30s
    balance               roundrobin

listen k8s_control_plane
    bind                  0.0.0.0:7443
    mode                  tcp
    log                   global
    balance               leastconn
    option                tcp-check
    server                serverA 192.168.10.10:6443 weight 6 check inter 3000 fastinter 1000 downinter 30000 rise 5 fall 3
    server                serverB 192.168.10.11:6443 weight 4 check inter 3000 fastinter 1000 downinter 30000 rise 5 fall 3

listen stats
    bind                  0.0.0.0:8080
    mode                  http
    stats                 enable
    log                   global
    stats                 uri /haproxy-status
    stats                 auth admin:123456
EOF

# 5.注册服务
cat > /etc/systemd/system/haproxy.service <<EOF
[Unit]
Description=HAProxy
DefaultDependencies=no
After=network.target

[Service]
Type=forking
ExecStart=/data/haproxy/sbin/haproxy -f /data/haproxy/conf/haproxy.cfg
LimitNOFILE=infinity

[Install]
WantedBy=multi-user.target

EOF

# 6.启用服务
systemctl daemon-reload
systemctl enable haproxy.service
systemctl start haproxy.service
```
### 3.配置并使用
#### 3.1 配置主节点
```shell
# 1.生成默认配置文件
kubeadm config print init-defaults > kubeadm-master-config.yaml

# 2.修改配置文件
vim kubeadm-master-config.yaml

# ----- kubeadm-master-config.yaml -----
kind: InitConfiguration
advertiseAddress {master的ip}
name             {master计算机名}
imageRepository  {国内镜像私服 registry.aliyuncs.com/google_containers}
#-----------------------------------------------------------------
kind: ClusterConfiguration
controlPlaneEndpoint: #apiServer对外地址和端口,负载均衡地址
apiServer:
  certSANs:           #apiServer证书列表
  - 192.168.0.23
  - 192.168.0.24
  - 192.168.0.28
  - 192.168.0.29
networking:
  serviceSubnet: 10.96.0.0/12  #svc网络
  podSubnet: 10.244.0.0/16     #pod网络
# ----- kubeadm-master-config.yaml -----

# 3.创建主节点  
kubeadm reset
kubeadm init --config kubeadm-master-config.yaml

```
#### 3.2 设置kube环境
```shell
#root用户
echo 'KUBECONFIG=/etc/kubernetes/admin.conf' >> ~/.bashrc
source ~/.bashrc
#普通用户
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
#### 3.3 配置通讯路由

```shell
# 使用flannel管理路由
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

#### 3.4 检查主节点状态
观察节点状态，检查pod都是否正常运行
```shell
# 节点状态
kubectl get node
# pod状态
kubectl get pod -A
```

#### 3.5 加入其他节点
```shell
#查看 token 和 discovery-token-ca-cert-hash
kubeadm token list
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //'
#如果是过期了，需要重新生成

# 生成work的join命令
  kubeadm token create --print-join-command
# 如果是master节点还需要重新生成certificate-key
  kubeadm init phase upload-certs --upload-certs

#添加工作节点
kubeadm join {advertiseAddress}:6443 --token {token} \
        --discovery-token-ca-cert-hash sha256:{discovery-token-ca-cert-hash}
        
#添加Master节点，对比添加work节点，需要添加 --control-plane --certificate-key {certificate-key} 选项
kubeadm join {advertiseAddress}:6443 --token {token} \
        --discovery-token-ca-cert-hash sha256:{discovery-token-ca-cert-hash} \
        --control-plane --certificate-key {certificate-key}
```

#### 3.6 节点去污
master节点默认存在污点，不允许运行pod，需要去污
```shell
# 去污
kubectl taint node {NodeName} node-role.kubernetes.io/control-plane-
```

### 4. 安装kuboard监控
```shell
kubectl label nodes {NodeName} k8s.kuboard.cn/role=etcd
kubectl apply -f https://addons.kuboard.cn/kuboard/kuboard-v3-swr.yaml
```
---

### 5.其他问题
```shell
# 若flannel节点出现  Error registering network: failed to acquire lease: node "node" pod cidr not assigned 报错
# 卸载flannel
kubectl delete -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
# 需要修改kube配置
vim /etc/kubernetes/manifests/kube-controller-manager.yaml
# 添加
--allocate-node-cidrs=true
--cluster-cidr=10.244.0.0/16 # 需要和init文件中配置的相同
# 重启

systemctl daemon-reload
systemctl restart kubelet
#再次安装
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
```

```shell
# 修改允许的端口
vim /etc/kubernetes/manifests/kube-apiserver.yaml
# 添加
- --service-node-port-range=1-65535
# 重启

systemctl daemon-reload
systemctl restart kubelet
```