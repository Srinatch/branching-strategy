# 🚀 End-to-End CI/CD Pipeline (GitHub → Jenkins → AWS → Docker → Kubernetes)

## 📌 Overview

This project demonstrates a complete automated CI/CD pipeline:

* Source Code Management: GitHub
* CI/CD Tool: Jenkins
* Infrastructure: AWS (Terraform)
* Containerization: Docker
* Orchestration: Kubernetes

On every Git push:

1. Jenkins triggers automatically
2. Application builds
3. Docker image is created & pushed
4. AWS infrastructure is provisioned
5. Kubernetes deploys the application
6. Application becomes accessible via LoadBalancer

---

## 📁 Project Structure

```
project-root/
│
├── app/                # Application source code
├── jenkins/            # Jenkins pipeline
├── terraform/          # AWS infrastructure
├── kubernetes/         # K8s manifests
├── scripts/            # Automation scripts
└── README.md
```

---

## ⚙️ Prerequisites

Ensure the following tools are installed on Jenkins server:

* Python3
* Docker
* Terraform
* kubectl
* AWS CLI

Verify using:

```
python3 --version
docker --version
terraform -version
kubectl version --client
aws --version
```

---

## 🔐 Required Configurations

### 1. AWS Credentials

Configure AWS CLI:

```
aws configure
```

### 2. DockerHub Login

```
docker login
```

### 3. Jenkins Setup

* Install required plugins:

  * GitHub Integration
  * Pipeline
* Add credentials:

  * DockerHub credentials
  * GitHub access token (if private repo)

---

## 🔄 Pipeline Workflow

### Step 1: Code Push

Push code to GitHub repository.

### Step 2: Jenkins Trigger

Webhook triggers Jenkins pipeline automatically.

### Step 3: Execution Stages

| Stage           | Description                           |
| --------------- | ------------------------------------- |
| Check Tools     | Verifies required tools are installed |
| Build App       | Installs dependencies                 |
| Docker Build    | Builds Docker image                   |
| Docker Push     | Pushes image to registry              |
| Terraform Apply | Creates AWS resources                 |
| K8s Deploy      | Deploys app to Kubernetes             |

---

## ▶️ How to Run

### 1. Clone Repository

```
git clone https://github.com/<your-repo>.git
cd project-root
```

### 2. Update Required Values

Update the following files:

#### 🔁 Docker Image Name

* File: `scripts/docker.sh`
* File: `kubernetes/deployment.yaml`

Replace:

```
your-dockerhub-username/app:latest
```

#### 🔁 AWS AMI

* File: `terraform/main.tf`

Replace with valid AMI ID for your region.

---

### 3. Run Manually (Optional)

```
chmod +x scripts/*.sh

./scripts/check_tools.sh
./scripts/build.sh
./scripts/docker.sh
./scripts/terraform.sh
./scripts/deploy.sh
```

---

## 🌐 Access Application

After deployment:

```
kubectl get svc
```

Copy the `EXTERNAL-IP` and open in browser:

```
http://<EXTERNAL-IP>
```

---

## ❌ Failure Handling

If any stage fails:

* Pipeline stops immediately
* `cleanup.sh` runs automatically
* Terraform destroys created resources

---

## 🧹 Cleanup (Manual)

To destroy resources manually:

```
cd terraform
terraform destroy -auto-approve
```

---

## ⚠️ Notes

* Ensure Docker daemon is running
* Ensure AWS permissions are correct
* Kubernetes cluster must be configured

---

## 🔥 Future Improvements

* Use AWS EKS instead of EC2
* Add Helm charts
* Add monitoring (Prometheus + Grafana)
* Add CI quality gates (SonarQube)
* Implement blue-green deployment

---

## 👨‍💻 Author

DevOps CI/CD Pipeline Example
