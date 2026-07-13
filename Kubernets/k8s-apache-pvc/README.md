Deployment Commands
------------------------------------
kubectl apply -f 1-namespace/
kubectl apply -f 2-storage/
kubectl apply -f 3-deployment/
kubectl apply -f 4-service/
Access Application
------------------------------------
minikube service apache-service -n apache-prod

Test Persistent Storage (Apache)
------------------------------------
kubectl get pods -n apache-prod
kubectl exec -it <pod-name> -n apache-prod -- /bin/bash

Inside container:
------------------------------------
echo "Hello Apache" > /usr/local/apache2/htdocs/test.html

Delete pod:
------------------------------------
kubectl delete pod <pod-name> -n apache-prod

# Kubernetes Apache with Persistent Volume (PVC)
-----------------------------------------------------
## Project Overview
------------------------------------
This project demonstrates Kubernetes deployment using Apache (httpd) with persistent storage.

Components used:
------------------------------------

- Namespace
- PersistentVolume (PV)
- PersistentVolumeClaim (PVC)
- Deployment (Apache)
- Service (NodePort)

---

## Architecture
------------------------------------
User → Service → Pod → PVC → PV → Storage

---

## Project Structure
------------------------------------
k8s-apache-pvc/
├── 1-namespace/
├── 2-storage/
├── 3-deployment/
├── 4-service/
└── README.md

---

## Deployment Steps
------------------------------------
### Start Cluster
------------------------------------

```bash
minikube start
Apply Resources
kubectl apply -f 1-namespace/
kubectl apply -f 2-storage/
kubectl apply -f 3-deployment/
kubectl apply -f 4-service/

Verification
------------------------------------
kubectl get all -n apache-prod
kubectl get pv
kubectl get pvc -n apache-prod

Access Application
------------------------------------
minikube service apache-service -n apache-prod