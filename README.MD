# 基于ubuntu 22 快速安装 k8s 1.23.16 环境
> 支持 amd64和 arm64环境
> 
> 已配置ipv4、ipv6双网络支持。
## 一、快速配置环境：
```shell
bash init-config.sh
```
#### 运行上述脚本，将执行下述内容：
+ 配置必要的内核加载
+ 配置必要的网络环境
+ 安装docker-ce
+ 安装1.23.9版本的k8s工具
#### 如果上述部分内容你已经有了，可以查看`init-config.sh`脚本，手动执行部分命令。
#### 关于dns配置信息 
> 确保你具备 `/run/systemd/resolve/resolv.conf` 文件，也就是 `sudo systemctl enable --now systemd-resolved.service`
> 
> 如果你想要使用 `/etc/resolv.conf` 而不是`/run/systemd/resolve/resolv.conf`文件。请修改`kubeadm-config-aliyun.yaml` 中的 `#resolvConf: /etc/resolv.conf`。改成 `resolvConf: /etc/resolv.conf` 取消注释即可
## 二、初始化你的 k8s 机器
1. `sudo vim /etc/default/kubelet` 添加下述内容:
   ```shell
    KUBELET_EXTRA_ARGS=--cgroup-driver=systemd --fail-swap-on=false --feature-gates=IPv6DualStack=true --max-pods=900
   ```
2. 打开 `kubeadm-config-aliyun.yaml` 文件，根据提示修改里面的一些配置。例如ip、域名等。
3. 执行初始化命令：
    ```shell
    bash init-k8s-aliyun.sh
    ```
   > 安装完成后，会有提示让你复制秘钥文件到 $HOME/.kube 下，安装它的提示执行相关命令即可
   > 
   > 如果你是单节点运行，请在配置了config后执行 `bash single_master.sh`
4. 配置k8s秘钥
```shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
5.   #### 取消k8s初始化 （如果你不想再要当前k8s环境了的话）
   `sudo kubeadm reset -f` 执行这个，将会完全干掉当前的k8s环境。
## 三、安装其他k8s插件 (如果你没有IPV6公网地址，请使用no_ipv6后缀的部分脚本和配置)
1. 安装calico(v3.23.3)网络插件(已调整支持ipv6)
    ```shell
    kubectl apply -f calico.yaml
    ```
    #### 卸载说明
    > 卸载方式： `kubectl delete -f calico.yaml`
    ### !!!!!!!!!!!!特别说明！！！！！！！！！！！
    > 如果你部署过程中 一直发现  `calico-node-xxxxx` 这个pod init失败。请打开 `calico.yaml` 或者 `calico_noipv6.yaml`文件
    > 
    > 找到 `IP_AUTODETECTION_METHOD`的配置。将 `interface=^e.*` 补充得更详细点（正则匹配网卡出问题了，可能匹配出来了多个）。例如你的lan网卡是 'eth0'。则这里可以填`interface=^eth.*`
2. 安装ingress(1.3.0)，这里有两种方式安装,二选一:
   1. hostport。会占用本机的80和443端口。如果本机不需要nginx或者nginx配置成其他端口，可以使用。
     > `kubectl apply -f ingress_hostport.yaml`
   2. nodeport。会随机生成两个端口，分别代表http和https端口。不会占用本机的80和443。
   > `kubectl apply -f ingress_nodeport.yaml`
   > 
   > 安装完成后，执行 `kubectl get svc -n ingress-nginx` 可以看到 80和443分别映射出来的端口。
   >
   > 输入 `kubectl get pod -n ingress-nginx` 查看ingress的安装进度。等所有pod都ok了，就可以了。
   #### 卸载说明
   > `kbuectl delete -f ingress_hostport.yaml` 或者  `kbuectl delete -f ingress_nodeport.yaml` 填你安装的时候选择的方式。


3. (可选，非必须) ip-masq-agent 使容器内部能够访问外部的Ipv6公网地址。
   1. `kubectl apply -f ip-masq-agent-config.yaml`
   2. `kubectl apply -f ip-masq-agent.yaml`
   #### 卸载方式
   > ```shell
   > kubectl delete -f ip-masq-agent.yaml
   > kubectl delete -f ip-masq-agent-config.yaml
   > ```
4. 安装 helm 包管理器
   1. 通过 apt源安装 (国内可能会被墙 或者速度慢)
       ```shell
       bash install-helm.sh
       ```
       #### 卸载方式：
       `sudo apt-get remove helm`
   2. 通过snap包安装 (ubuntu自带snap)
      ```shell
      bash install-helm-snap.sh
      ```
      #### 卸载方式：
      `sudo snap remove helm`
   3. 通过二进制包安装：
      去`https://github.com/helm/helm/releases`下载安装即可
5. dns-custom 安装自定义dns服务（有时候自带的coredns不解析的时候用它挺好的）
   `kubectl apply -f dns-custom.yaml`
   #### 卸载方式：
   `kubectl delete -f dns-custom.yaml`
6. 安装证书免费签发工具cert-manager
   `bash install-CRDs-with-customdns.sh`
   #### 卸载方式
   `helm uninstall cert-manager --namespace cert-manager`
7. (可选，非必须) 添加dnspod(实际是腾讯云接口)的dns证书签名验证方式
   > 需要先安装 cert-manager 才能安装该 cert-manager的插件。
   1. 通过 https://console.cloud.tencent.com/cam/capi 获取`secretid`和 `secretkey`.
   2. 修改 `install-qcloud-cm.sh` 中的对应的参数 
   3. 执行 `bash install-qcloud-cm.sh`
   4. 证书申请demo：
      1. 修改 `test-dnspod-cert.yaml` 中的域名、证书名、命名空间
      2. 执行 `kubectl -f test-dnspod-cert.yaml`
   #### 卸载方式：
   `helm uninstall cert-manager-webhook-dnspod -n cert-manager`
8. (可选，非必须) 添加cloudflare 方式进行dns证书签名
   1. 打开`clouflare-cm.yaml` 填入你的对应信息。
   2. `apiTokenSecretRef` 和 `apiKeySecretRef` 二选一。注释掉另一方。
   3. 执行 `kubectl apply -f clouflare-cm.yaml`
   4. 证书申请demo：
      1. 修改 `test-cf-cert.yaml` 中的域名、证书名、命名空间
      2. 执行 `kubectl -f test-cf-cert.yaml`
   #### 卸载方式：
   `kubectl delete -f clouflare-cm.yaml`
9. (可选，非必须) 添加aliyun的dns证书签名验证方式
   > 需要先安装 cert-manager 才能安装该 cert-manager的插件。
   1. 通过 https://ak-console.aliyun.com/?spm=5176.2020520001.0.0.dCHOyj#/accesskey 获取`Access Key ID`和 `Access Key Secret`.
   2. 修改 `install-aliyun-cm.sh` 中的对应的参数
   3. 执行 `bash install-aliyun-cm.sh`
   4. 证书申请demo：
      1. 修改 `test-alidns-cert.yaml` 中的域名、证书名、命名空间
      2. 执行 `kubectl -f test-alidns-cert.yaml`
   #### 卸载方式：
   `kubectl delete -f alidns.yaml`
10. 安装一个web管理面板：
    1. 执行 `kubectl apply -f kuboard-v3.yaml`
    2. 安装完成后，打开 http://你的ip:30080 进行登录
    3. 默认账号 admin
    4. 默认密码 Kuboard123
    #### 卸载方式：
    `kubectl delete -f kuboard-v3.yaml`


### k8s 小版本升级
1. 查看是否有可升级的版本（仅master执行）： `sudo kubeadm upgrade plan`
2. 安装新的小版本的工具。(master和node都执行) 例如安装 1.23.12版本： `sudo apt install -y kubelet=1.23.12-00 kubeadm=1.23.12-00 kubectl=1.23.12-00 --allow-downgrades --allow-change-held-packages`
3. 执行集群升级。（仅master执行） 例如升级到 1.23.12: `sudo kubeadm upgrade apply v1.23.12`
4. 锁定 kubeadm工具版本号 (master和node都执行)： `sudo apt-mark hold kubelet kubeadm kubectl`

ps: 大版本升级需要小心，注意api版本是否兼容。k8s大版本升级只能一级一级的升上去。不能跨多个大版本升级。

### !!!k8s 系统证书问题
因为默认生成的证书有效期只有1年，所以每年都需要更新一次系统证书。

这里提供脚本把系统证书刷新成10年的
```shell
sudo bash update-kubeadm-cert.sh all
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

