#!/bin/bash

# Install K3s with specific configurations
curl -sfL https://get.k3s.io | K3S_KUBECONFIG_MODE="644" INSTALL_K3S_EXEC="--flannel-iface eth1" sh -

# Wait for the node token to be available
sleep 10
sudo chmod 644 /etc/rancher/k3s/k3s.yaml
NODE_TOKEN="/var/lib/rancher/k3s/server/node-token"

until [ -e ${NODE_TOKEN} ]; do
  sleep 2
done

# Copy node token and kubeconfig to shared folder
sudo cat ${NODE_TOKEN}
sudo cp ${NODE_TOKEN} /vagrant/
KUBE_CONFIG="/etc/rancher/k3s/k3s.yaml"
sudo cp ${KUBE_CONFIG} /vagrant/
