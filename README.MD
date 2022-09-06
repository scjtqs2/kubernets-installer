# 基于ubuntu 22 快速安装 k8s 1.23.9 环境
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

## 二、初始化你的 k8s 机器
1. `sudo vim /etc/default/kubelet` 添加下述内容:
   ```shell
    KUBELET_EXTRA_ARGS=--cgroup-driver=systemd --fail-swap-on=false --feature-gates=IPv6DualStack=true
   ```
2. 打开 `kubeadm-config-aliyun.yaml` 文件，根据提示修改里面的一些配置。例如ip、域名等。
3. 执行初始化命令：
    ```shell
    bash init-k8s-aliyun.sh
    ```
   > 安装完成后，会有提示让你复制秘钥文件到 $HOME/.kube 下，安装它的提示执行相关命令即可
   > 
   > 如果你是单节点运行，请在配置了config后执行 `bash single_master.sh`
4. 安装calico(v3.23.3)网络插件(已调整支持ipv6)
    ```shell
    kubectl apply -f calico.yaml
    ```
5. 安装ingress(1.3.0)，这里有两种方式安装,二选一:
   1. hostport。会占用本机的80和443端口。如果本机不需要nginx或者nginx配置成其他端口，可以使用。
     > `kubectl apply -f ingress_hostport.yaml`
   2. nodeport。会随机生成两个端口，分别代表http和https端口。不会占用本机的80和443。
   > `kubectl apply -f ingress_nodeport.yaml`
   > 
   > 安装完成后，执行 `kubectl get svc -n ingress-nginx` 可以看到 80和443分别映射出来的端口。
6. (可选，非必须) 使容器内部能够访问外部的Ipv6公网地址。
   1. `kubectl apply -f ip-masq-agent-config.yaml`
   2. `kubectl apply -f ip-masq-agent.yaml`
7. 安装 helm 包管理器
    ```shell
    bash install-helm.sh
    ```
8. 安装自定义dns服务（有时候自带的coredns不解析的时候用它挺好的）
   `kubectl apply -f dns-custom.yaml`
9. 安装证书免费签发工具cert-manager
   `bash install-CRDs-with-customdns.sh`
10. (可选，非必须) 添加dnspod(实际是腾讯云接口)的dns证书签名验证方式
    1. 通过 https://console.cloud.tencent.com/cam/capi 获取`secretid`和 `secretkey`.
    2. 修改 `install-qcloud-cm.sh` 中的对应的参数 
    3. 执行 `bash install-qcloud-cm.sh`
    4. 证书申请demo：
       1. 修改 `test-dnspod-cert.yaml` 中的域名、证书名、命名空间
       2. 执行 `kubectl -f test-dnspod-cert.yaml`
11. (可选，非必须) 添加cloudflare 方式进行dns证书签名
    1. 打开`clouflare-cm.yaml` 填入你的对应信息。
    2. `apiTokenSecretRef` 和 `apiKeySecretRef` 二选一。注释掉另一方。
    3. 执行 `kubectl apply -f clouflare-cm.yaml`
    4. 证书申请demo：
       1. 修改 `test-cf-cert.yaml` 中的域名、证书名、命名空间
       2. 执行 `kubectl -f test-cf-cert.yaml`
12. 安装一个web管理面板：
    1. 执行 `kubectl apply -f kuboard-v3.yaml`
    2. 安装完成后，打开 http://你的ip:30080 进行登录
    3. 默认账号 admin
    4. 默认密码 Kuboard123