#!/bin/bash

echo "Updating kubeconfig..."
aws eks --region ap-south-1 update-kubeconfig --name my-cluster

echo "Deploying to Kubernetes..."
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

echo "Getting service URL..."
kubectl get svc