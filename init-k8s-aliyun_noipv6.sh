#!/bin/bash
sudo kubeadm init --config=kubeadm-config-aliyun_noipv6.yaml --upload-certs --ignore-preflight-errors=swap --ignore-preflight-errors=Mem
