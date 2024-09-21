echo "----------------- ${GR}Installing Kubectl${NC} -------------------------------"
sudo rm /usr/local/bin/kubectl
curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.18.0/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

echo "----------------- ${GR}Installing k3d${NC} -------------------------------"
sudo rm $(which k3d)
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash