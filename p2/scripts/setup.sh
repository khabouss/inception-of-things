#!/bin/bash

curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -

sleep 20
# Use K3s kubectl directly
# alias kubectl='/usr/local/bin/kubectl'

for app in app-first app-second app-third ingress; do
    kubectl apply -n kube-system -f /vagrant/${app}.yaml --validate=false
done
# kubectl apply -n kube-system -f /vagrant/app-first.yaml --validate=false
# kubectl apply -n kube-system -f /vagrant/app-second.yaml --validate=false
# kubectl apply -n kube-system -f /vagrant/app-third.yaml --validate=false
# kubectl apply -n kube-system -f /vagrant/ingress.yaml --validate=false