#!/bin/bash
set -ex

source secrets/credentials.env

echo "🔧 Checking & Installing dependencies..."

install_if_missing() {
    if ! command -v $1 &> /dev/null
    then
        echo "$1 not found, installing..."
        sudo apt-get update -y
        sudo apt-get install -y $2
    else
        echo "$1 already installed ✅"
    fi
}

# Basic tools
install_if_missing docker docker.io
install_if_missing git git
install_if_missing python3 python3
install_if_missing pip3 python3-pip

# 🔥 Install AWS CLI
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI..."
    sudo apt-get update
    sudo apt-get install -y awscli
else
    echo "AWS CLI already installed ✅"
fi

# 🔥 Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
else
    echo "kubectl already installed ✅"
fi

# 🔥 Install Terraform (official way)
if ! command -v terraform &> /dev/null; then
    echo "Installing Terraform..."
    sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
    sudo apt-add-repository "deb https://apt.releases.hashicorp.com $(lsb_release -cs) main"
    sudo apt-get update && sudo apt-get install -y terraform
else
    echo "Terraform already installed ✅"
fi

# 🔐 Docker login
echo "🔐 Checking Docker login..."
if ! docker system info | grep -i username > /dev/null; then
    echo "🔐 Docker login required"
    docker login -u $DOCKER_USERNAME
else
    echo "Docker already logged in ✅"
fi

# 🔐 AWS configuration
echo "🔐 AWS Login Setup..."
if ! aws sts get-caller-identity &> /dev/null; then
    read -p "Enter AWS Access Key: " AWS_ACCESS
    read -sp "Enter AWS Secret Key: " AWS_SECRET
    echo

    aws configure set aws_access_key_id "$AWS_ACCESS"
    aws configure set aws_secret_access_key "$AWS_SECRET"
    aws configure set region ap-south-1

    echo "AWS configured ✅"
else
    echo "AWS already configured ✅"
fi

# ☸️ Kubernetes cluster check
echo "☸️ Checking Kubernetes cluster..."
if ! kubectl get nodes &> /dev/null; then
    echo "⚠️ No Kubernetes cluster found."

    echo "👉 Starting Minikube..."
    if ! command -v minikube &> /dev/null; then
        echo "Installing Minikube..."
        curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        chmod +x minikube-linux-amd64
        sudo mv minikube-linux-amd64 /usr/local/bin/minikube
    fi

    minikube start
else
    echo "Kubernetes already running ✅"
fi

# 📥 Clone repo
echo "📥 Cloning repo..."
if [ ! -d "repo" ]; then
    git clone -b $GIT_BRANCH $GITHUB_REPO repo
else
    cd repo && git pull && cd ..
fi

echo "✅ Setup completed"