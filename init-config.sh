#!/bin/bash
echo "配置内核模块加载"
sudo tee /etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF

sudo tee /etc/modules-load.d/ipvs.conf<<EOF
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

sudo modprobe overlay

sudo modprobe br_netfilter

echo "执行网络配置"
sudo tee /etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.disable_ipv6 = 0
net.ipv6.conf.default.disable_ipv6 = 0
net.ipv6.conf.lo.disable_ipv6 = 0
net.ipv6.conf.all.forwarding=1
fs.inotify.max_user_instances=81920
fs.inotify.max_user_watches=2621440
EOF

sudo sysctl --system

sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
## 安装docker
echo "开始安装docker"
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
# 安装containerd替代docker-ce
#VERSION_STRING=5:20.10.24~3-0~ubuntu-jammy
#sudo apt-get install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin -y
#
#sudo mkdir -p /etc/docker
#sudo tee /etc/docker/daemon.json<<EOF
#{
#    "ipv6": true,
#    "experimental": true,
#    "fixed-cidr-v6": "fd00:dead:beef::/48",
#    "ip6tables": true,
#  "registry-mirrors": [],
#    "exec-opts": ["native.cgroupdriver=systemd"],
#  "log-driver": "json-file",
#  "log-opts": {
#    "max-size": "100m"
#  },
#  "storage-driver": "overlay2",
#  "storage-opts": [
#    "overlay2.override_kernel_check=true"
#  ]
#}
#EOF
#
#sudo systemctl enable docker
#sudo systemctl restart docker

# 配置 containerd
sudo apt install -y containerd.io
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
sudo sed -i 's/k8s.gcr.io/registry.aliyuncs.com\/google_containers/g' /etc/containerd/config.toml
sudo sed -i 's/registry.k8s.io/registry.aliyuncs.com\/google_containers/g' /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# 安装k8s
echo "开始安装k8s"
#curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo apt-key add -

sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/k8s.list
sudo apt-get update
sudo apt install -y kubelet=1.26.6-00 kubeadm=1.26.6-00 kubectl=1.26.6-00 --allow-downgrades --allow-change-held-packages
sudo apt-mark hold kubelet kubeadm kubectl
echo "KUBELET_EXTRA_ARGS=--cgroup-driver=systemd --fail-swap-on=false --max-pods=900"| sudo tee /etc/default/kubelet

