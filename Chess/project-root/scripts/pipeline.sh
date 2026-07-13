#!/bin/bash
set -ex

source scripts/common.sh

echo "🚀 PIPELINE START"

# 🔍 Check kubectl connectivity
echo "Checking Kubernetes cluster..."
kubectl get nodes

# 🔨 Build
echo "🔨 Building application..."
bash scripts/build.sh

# 🐳 Docker
echo "🐳 Building & pushing Docker image..."
bash scripts/docker.sh

# 🔄 Update config
echo "🔄 Updating deployment image..."
bash scripts/update_config.sh

# ☁️ Terraform
echo "☁️ Provisioning infrastructure..."
bash scripts/terraform.sh

# ☸️ Kubernetes
echo "☸️ Deploying to Kubernetes..."
bash scripts/k8s.sh

# ⏳ Wait for service
echo "⏳ Waiting for LoadBalancer IP (max 3 minutes)..."

COUNT=0
MAX_RETRY=36   # 36 x 5 sec = 3 minutes

while [ $COUNT -lt $MAX_RETRY ]; do
  IP=$(kubectl get svc chess-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  
  if [ -n "$IP" ]; then
    break
  fi

  echo "Waiting... ($COUNT)"
  COUNT=$((COUNT+1))
  sleep 5
done

# 🌐 Handle result
if [ -z "$IP" ]; then
  echo "⚠️ External IP not assigned."

  echo "👉 If using local cluster, try:"
  echo "minikube service chess-service -n $NAMESPACE"

  echo "👉 Or check:"
  echo "kubectl get svc -n $NAMESPACE"

else
  echo "🎉 SUCCESS"
  echo "🌐 Application URL: http://$IP:$APP_PORT"
fi