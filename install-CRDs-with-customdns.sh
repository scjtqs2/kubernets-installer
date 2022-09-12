#!/bin/bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install   cert-manager jetstack/cert-manager   --namespace cert-manager   --create-namespace   --version v1.9.1   --set installCRDs=true --set prometheus.enabled=false \
--set 'extraArgs={--acme-http01-solver-nameservers=172.16.119.119:53,--dns01-recursive-nameservers-only,--dns01-recursive-nameservers=172.16.119.119:53,--enable-certificate-owner-ref=true}'
