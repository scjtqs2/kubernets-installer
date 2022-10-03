#!/bin/bash
sudo kubeadm init --config=kubeadm-config-aliyun.yaml --upload-certs --ignore-preflight-errors=swap --ignore-preflight-errors=Mem
