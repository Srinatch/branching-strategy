# Kubernetes NGINX with Persistent Volume (PVC)

## Project Overview

This project demonstrates a complete Kubernetes setup using:

- Namespace
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- Deployment (NGINX)
- Service (NodePort)

The goal is to show how to run a containerized application with **persistent storage** in Kubernetes.

---

## Architecture

User → Service → Pod → PVC → PV → Storage

- Service exposes the application
- Deployment manages Pods
- PVC provides persistent storage
- PV stores actual data

---

## 📁 Project Structure

k8s-nginx-pvc/
│
├── 1-namespace/
├── 2-storage/
├── 3-deployment/
├── 4-service/
└── README.md

---

## 🚀 Prerequisites

Make sure you have:

- Kubernetes cluster (Minikube / Kind)
- kubectl installed
- Docker installed

---

## ⚙️ Deployment Steps

### 1️⃣ Start Cluster

```bash
minikube start

Create Namespace
---------------------------------
kubectl apply -f namespace/

Create Storage (PV + PVC)
---------------------------------
kubectl apply -f storage/

Deploy Application
---------------------------------
kubectl apply -f deployment/

Expose Service
---------------------------------
kubectl apply -f service/

Verification
---------------------------------
kubectl get all -n nginx-prod

kubectl get pv

kubectl get pvc -n nginx-prod

Access Application
---------------------------------
minikube service nginx-service -n nginx-prod

Testing Persistent Storage
---------------------------------
Step 1: Enter Pod
-------------------------
kubectl exec -it <pod-name> -n nginx-prod -- /bin/bash

Step 2: Create File
-------------------------
echo "Hello Kubernetes" > /usr/share/nginx/html/test.html

Step 3: Delete Pod
-------------------------
kubectl delete pod <pod-name> -n nginx-prod



## -----------------------------------------
sudo apt update && sudo apt upgrade -y


sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab


cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter


cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system


sudo apt install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd


sudo apt update
sudo apt install -y apt-transport-https curl

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl


sudo kubeadm init --pod-network-cidr=192.168.0.0/16


mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico Network
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

kubectl get nodes


sudo kubeadm join <MASTER-IP>:6443 --token xxxx \
--discovery-token-ca-cert-hash sha256:xxxx


kubectl get nodes


kubectl create deployment nginx --image=nginx

kubectl expose deployment nginx --type=NodePort --port=80

kubectl get svc

# Scale Application

kubectl scale deployment nginx --replicas=3

kubectl get pods -o wide

kubectl taint nodes --all node-role.kubernetes.io/control-plane-