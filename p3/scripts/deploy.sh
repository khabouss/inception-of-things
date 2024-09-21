#!/bin/bash

# Define colors
GR='\033[0;32m'  # Green
NC='\033[0m'     # No Color
CYAN='\033[0;36m'  # Cyan
RED='\033[0;31m'  # Red
YELLOW='\033[1;33m' # Yellow

# Function to log messages
log_message() {
    echo -e "${CYAN}==> $1${NC}"
}

# Function to log errors
log_error() {
    echo -e "${RED}ERROR: $1${NC}"
}

# Delete existing k3d cluster
log_message "Deleting existing k3d cluster..."
if ! sudo k3d cluster delete iot-cluster; then
    log_error "Failed to delete cluster. Exiting."
    exit 1
fi

# Create new k3d cluster
log_message "Creating k3d cluster..."
if ! sudo k3d cluster create iot-cluster -p "8888:30080"; then
    log_error "Failed to create cluster. Exiting."
    exit 1
fi

# Create a namespace for ArgoCD
log_message "Creating a namespace for ArgoCD..."
if ! sudo kubectl create namespace argocd; then
    log_error "Failed to create namespace. Exiting."
    exit 1
fi

# Install ArgoCD in the k3d cluster
log_message "Installing ArgoCD in the k3d cluster..."
if ! sudo kubectl apply -n argocd -f ./confs/argocd.yaml; then
    log_error "Failed to install ArgoCD. Exiting."
    exit 1
fi

# Wait for ArgoCD pods to be ready
log_message "Running ArgoCD and waiting for the pods to be ready..."
sleep 5
if ! sudo kubectl wait -n argocd --for=condition=Ready pods --all --timeout=-1s; then
    log_error "Pods not ready in time. Exiting."
    exit 1
fi

# Change ArgoCD service to NodePort
log_message "Changing ArgoCD service to NodePort..."
if ! sudo kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'; then
    log_error "Failed to change service type. Exiting."
    exit 1
fi

# Display ArgoCD URL
log_message "Fetching ArgoCD service details..."
sudo kubectl get service argocd-server -n argocd
sudo kubectl get service argocd-server -n argocd -o jsonpath='{.spec.ports[0].port}'

# Get ArgoCD password
log_message "Getting ArgoCD password..."
PASSWORD=$(sudo kubectl get secret argocd-initial-admin-secret -n argocd -o yaml | grep " password:" | cut -d ":" -f 2 | cut -d " " -f 2 | base64 --decode)
if [ -z "$PASSWORD" ]; then
    log_error "Failed to retrieve password. Exiting."
    exit 1
else
    echo "$PASSWORD"
fi

# Create a namespace for development
log_message "Creating a namespace for development..."
if ! sudo kubectl create namespace dev; then
    log_error "Failed to create development namespace. Exiting."
    exit 1
fi

# Create a CRD for ArgoCD
log_message "Creating a CRD for ArgoCD..."
if ! sudo kubectl apply -f confs/application.yaml; then
    log_error "Failed to create CRD. Exiting."
    exit 1
fi

# Wait for application to be created
log_message "Waiting for application to be created..."
while [ "$POD_STATE" != "Running" ]; do echo "Waiting for app to be created";
POD_STATE=$(sudo kubectl get po -n dev  --output="jsonpath={.items..phase}") && sleep 10;
done;
# POD_STATE=""
# while [ "$POD_STATE" != "Running" ]; do
#     POD_STATE=$(sudo kubectl get po -n dev --output="jsonpath={.items..phase}") && sleep 10
# done

# Forward port to ArgoCD server
log_message "Forwarding port 8080 to the argocd-server service..."
sudo kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &